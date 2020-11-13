local {round_by_value} = require("std/math.nut")
local style = require("ui/hud/style.nut")
local { menuRowColor } = require("ui/style/menuColors.nut")
local cursors = require("ui/style/cursors.nut")
local JB = require("ui/control/gui_buttons.nut")
local {safeAreaSize} = require("enlist/options/safeAreaState.nut")
local msgbox = require("ui/components/msgbox.nut")
local textButton = require("enlist/components/textButton.nut")
local scrollbar = require("ui/components/scrollbar.nut")
local checkbox = require("ui/components/checkbox.nut")
local slider = require("ui/components/slider.nut")
local mkSliderWithText = require("ui/components/optionTextSlider.nut")
local settingsHeaderTabs = require("ui/components/settingsHeaderTabs.nut")
local fa = require("daRg/components/fontawesome.map.nut")
local {dtext} = require("daRg/components/text.nut")
local { buildElems, buildDigitalBindingText, isValidDevice,eventTypeLabels,
      textListFromAction, getSticksText } = require("ui/control/formatInputBinding.nut")

local dainput = require("dainput2")
local {format_ctrl_name} = dainput
local {get_action_handle} = dainput
local { BTN_pressed, BTN_pressed_long, BTN_pressed2, BTN_pressed3,
          BTN_released, BTN_released_long, BTN_released_short } = dainput
local select = require("ui/components/select.nut")

local control = require("control")
local DataBlock = require("DataBlock")
local platform = require("globals/platform.nut")
local controlsSettingOnlyForGamePad = ::Watched(platform.is_xbox || platform.is_sony || platform.is_nswitch)
local {wasGamepad, isGamepad} = require("ui/control/active_controls.nut")
local {
  setUiClickRumble,
  isUiClickRumbleEnabled,
  setInBattleRumble,
  isInBattleRumbleEnabled,
  isAimAssistExists,
  isAimAssistEnabled,
  setAimAssist,
  stick0_dz,
  set_stick0_dz,
  stick1_dz,
  set_stick1_dz,
  aim_smooth,
  aim_smooth_set
} = require("ui/hud/state/controls_online_storage.nut")
local {importantGroups, generation, availablePresets, haveChanges, Preset, getActionsList, getActionTags, mkSubTagsFind} = require("controls_state.nut")
local findSelectedPreset = function(selected) {
  return availablePresets.value.findvalue(@(v) selected.indexof(v.preset)!=null) ?? Preset(dainput.get_user_config_base_preset())
}
local selectedPreset = Watched(findSelectedPreset(dainput.get_user_config_base_preset()))
local currentPreset =  Watched(selectedPreset.value)
currentPreset.subscribe(@(v) selectedPreset(findSelectedPreset(v.preset)))
local updateCurrentPreset = @() currentPreset(findSelectedPreset(dainput.get_user_config_base_preset()))

local actionRecording = ::Watched(null)
local configuredAxis = ::Watched(null)
local configuredButton = ::Watched(null)

local showControlsMenu = persist("showControlsMenu", @() Watched(false))
//::gui_scene.xmbMode.subscribe(@(v) ::vlog($"XMB mode = {v}"))

local function isGamepadColumn(col) {
  return col == 1
}

local function locActionName(name){
  return name!= null ? ::loc("/".concat("controls", name), name) : null
}

local function doesDeviceMatchColumn(dev_id, col) {
  if (dev_id==dainput.DEV_kbd || dev_id==dainput.DEV_pointing)
    return !isGamepadColumn(col)
  if (dev_id==dainput.DEV_gamepad || dev_id==dainput.DEV_joy)
    return isGamepadColumn(col)
  return false
}

local btnEventTypesMap = {
  [BTN_pressed] = "pressed",
  [BTN_pressed_long] = "pressed_long",
  [BTN_pressed2] = "pressed2",
  [BTN_pressed3] = "pressed3",
  [BTN_released] = "released",
  [BTN_released_long] = "released_long",
  [BTN_released_short] = "released_short",
}

local findAllowBindingsSubtags = mkSubTagsFind("allowed_bindings=")
local getAllowedBindingsTypes = ::memoize(function(ah) {
  local allowedbindings = findAllowBindingsSubtags(ah)
  if (allowedbindings==null)
    return btnEventTypesMap.keys()
  return btnEventTypesMap
    .filter(@(name, eventType) allowedbindings==null || allowedbindings.indexof(name)!=null)
    .keys()
})


local tabsList = []
local isActionDisabledToCustomize = ::memoize(
  @(action_handler) getActionTags(action_handler).indexof("disabled") != null)

local function makeTabsList() {
  tabsList = [ {id="Options" text=::loc("controls/tab/Control")} ]

  local bindingTabs = [
    {id="Movement" text=::loc("controls/tab/Movement")}
    {id="Weapon" text=::loc("controls/tab/Weapon")}
    {id="View" text=::loc("controls/tab/View")}
    {id="Squad" text=::loc("controls/tab/Squad")}
    {id="Vehicle" text=::loc("controls/tab/Vehicle")}
    {id="Plane" text=::loc("controls/tab/Plane")}
    {id="Other" text=::loc("controls/tab/Other")}
    {id="UI" text=::loc("controls/tab/UI")}
    {id="VoiceChat" text=::loc("controls/tab/VoiceChat") isEnabled = @() platform.is_pc}
    {id="Spectator" text=::loc("controls/tab/Spectator")}
  ]

  local hasActions = {}
  local total = dainput.get_actions_count()
  for (local i = 0; i < total; i++) {
    local ah = dainput.get_action_handle_by_ord(i)
    if (!dainput.is_action_internal(ah)){
      local tags = getActionTags(ah)
      foreach(tag in tags)
        hasActions[tag] <- true
    }
  }
  tabsList.extend(bindingTabs.filter(@(t) (hasActions?[t.id] ?? false) && (t?.isEnabled?() ?? true)))
}
controlsSettingOnlyForGamePad.subscribe(@(v) makeTabsList())
makeTabsList()


local currentTab = persist("currentTab", @() ::Watched(tabsList[0].id))
local selectedBindingCell = persist("selectedBindingCell", @() ::Watched(null))
local selectedAxisCell = persist("selectedAxisCell", @() ::Watched(null))

isGamepad.subscribe(function(isGp) {
  if (!isGp)
    return
  selectedBindingCell(null)
  selectedAxisCell(null)
})

local function isEscape(blk) {
  return blk.getInt("dev", dainput.DEV_none) == dainput.DEV_kbd
      && blk.getInt("btn", 0) == 1
}

local blkPropRemap = {
  minXBtn = "xMinBtn", maxXBtn = "xMaxBtn", minYBtn = "yMinBtn", maxYBtn = "yMaxBtn"
}

local pageAnim =  [
  { prop=AnimProp.opacity, from=0, to=1, duration=0.2, play=true, easing=InOutCubic}
  { prop=AnimProp.opacity, from=1, to=0, duration=0.2, playFadeOut=true, easing=InOutCubic}
]

local function startRecording(cell_data) {
  if (cell_data.singleBtn || cell_data.tag == "modifiers")
    dainput.start_recording_bindings_for_single_button()
  else
    dainput.start_recording_bindings(cell_data.ah)
  actionRecording(cell_data)
}

local function makeBgToggle(initial=true) {
  local showBg = !initial
  local function toggleBg() {
    showBg = !showBg
    return showBg
  }
  return toggleBg
}

local function set_single_button_analogue_binding(ah, col, actionProp, blk) {
  local stickBinding = dainput.get_analog_stick_action_binding(ah, col)
  local axisBinding = dainput.get_analog_axis_action_binding(ah, col)
  local binding = stickBinding ?? axisBinding
  if (binding != null) {
    binding[actionProp].devId = blk.getInt("dev", 0)
    binding[actionProp].btnId = blk.getInt("btn", 0)
    if (blk.paramCount()+blk.blockCount() == 0) {
      // empty blk, so clear bindings
      binding.devId = dainput.DEV_none
      if (axisBinding != null)
        axisBinding.axisId = 0
      if (stickBinding != null) {
        stickBinding.axisXId = 0
        stickBinding.axisYId = 0
      }
    } else if (binding.devId == dainput.DEV_none && (axisBinding != null || stickBinding != null))
      binding.devId = dainput.DEV_nullstub

    if (binding.devId != dainput.DEV_none && binding.maxVal == 0) // restore maxVal when needed
      binding.maxVal = 1
  }
}

local function loadOriginalBindingParametersTo(blk, ah, col) {
  local origBlk = DataBlock()
  dainput.get_action_binding(ah, col, origBlk)

  local actionType = dainput.get_action_type(ah)

  blk.setReal("dzone", origBlk.getReal("dzone", 0.0))
  blk.setReal("nonlin", origBlk.getReal("nonlin", 0.0))
  blk.setReal("maxVal", origBlk.getReal("maxVal", 1.0))
  if ((actionType & dainput.TYPEGRP__MASK) == dainput.TYPEGRP_STICK)
    blk.setReal("sensScale", origBlk.getReal("sensScale", 1.0))
}

local function checkRecordingFinished() {
  if (dainput.is_recording_complete()) {
    local cellData = actionRecording.value
    actionRecording(null)
    local ah = cellData?.ah

    local blk = DataBlock()
    local ok = dainput.finish_recording_bindings(blk)

    local devId = blk.getInt("dev", dainput.DEV_none)
    if (ok && ah!=null && devId!=dainput.DEV_none && !isEscape(blk)) {
      local col = cellData?.column
      if (doesDeviceMatchColumn(devId, col)) {
        ::gui_scene.clearTimer(::callee())

        local checkConflictsBlk
        if (cellData.singleBtn) {
          checkConflictsBlk = DataBlock()
          dainput.get_action_binding(ah, col, checkConflictsBlk)
          local btnBlk = checkConflictsBlk.addBlock(blkPropRemap?[cellData.actionProp] ?? cellData.actionProp)
          btnBlk.setParamsFrom(blk)
        }
        else {
          checkConflictsBlk = blk
        }

        local function applyBinding() {
          if (cellData.singleBtn) {
            set_single_button_analogue_binding(ah, col, cellData.actionProp, blk)
          }
          else if (cellData.tag == "modifiers") {
            local binding = dainput.get_analog_stick_action_binding(ah, cellData.column)
                          ?? dainput.get_analog_axis_action_binding(ah, cellData.column)

            local btn = dainput.SingleButtonId()
            btn.devId = devId
            btn.btnId = blk.getInt("btn", 0)
            binding.mod = [btn]
          }
          else {
            loadOriginalBindingParametersTo(blk, ah, col)
            dainput.set_action_binding(ah, col, blk)
            local binding = dainput.get_digital_action_binding(ah, col)
            if (binding?.eventType)
              binding.eventType = getAllowedBindingsTypes(ah)[0]
          }
          generation(generation.value+1)
          haveChanges(true)
        }

        local conflicts = dainput.check_bindings_conflicts(ah, checkConflictsBlk)
        if (conflicts == null) {
          applyBinding()
        } else {
          local actionNames = conflicts.map(@(a) dainput.get_action_name(a.action))
          local localizedNames = actionNames.map(@(a) ::loc($"controls/{a}"))
          local actionsText = ", ".join(localizedNames)
          local messageText = ::loc("controls/binding_conflict_prompt", "This conflicts with {actionsText}. Bind anyway?", {
            actionsText = actionsText
          })
          msgbox.show({
            text = messageText
            buttons = [
              { text = loc("Yes"), action = applyBinding }
              { text = loc("No") }
            ]
          })
        }
      } else {
        startRecording(cellData)
      }
    }
  }
}


local function cancelRecording() {
  ::gui_scene.clearTimer(checkRecordingFinished)
  actionRecording(null)

  local blk = DataBlock()
  dainput.finish_recording_bindings(blk)
}



local mediumText = @(text, params={}) dtext(text, {color = style.DEFAULT_TEXT_COLOR, font = Fonts.medium_text}.__update(params))

local function recordingWindow() {
  //local text = ::loc("controls/recording", "Press a button (or move mouse / joystick axis) to bind action to")
  local text
  local cellData = actionRecording.value
  local name = cellData?.name
  if (cellData) {
    local actionType = dainput.get_action_type(cellData.ah)
    if ( (actionType & dainput.TYPEGRP__MASK) == dainput.TYPEGRP_DIGITAL
          || cellData.actionProp!=null || cellData.tag == "modifiers") {
      if (isGamepadColumn(cellData.column))
        text = ::loc("controls/recording_digital_gamepad", "Press a gamepad button to bind action to")
      else
        text = ::loc("controls/recording_digital_keyboard", "Press a button on keyboard to bind action to")
    }
    else if (isGamepadColumn(cellData.column)) {
      text = ::loc("controls/recording_analogue_joystick", "Move stick or press button to bind action to")
    } else {
      text = ::loc("controls/recording_analogue_mouse", "Move mouse to bind action")
    }
  }
  return {
    size = flex()
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = Color(120,120,120,250)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    stopHotkeys = true
    stopMouse = true
    cursor = null
    hotkeys = [["^Esc", cancelRecording]]
    onDetach = cancelRecording
    watch = actionRecording
    flow = FLOW_VERTICAL
    gap = sh(8)
    children = [
      {size=[0, flex(3)]}
      dtext(locActionName(name), {color = Color(100,100,100), font=Fonts.big_text})
      mediumText(text, {
        function onAttach() {
          ::gui_scene.clearTimer(checkRecordingFinished)
          ::gui_scene.setInterval(0.1, checkRecordingFinished)
        }
        function onDetach() {
          ::gui_scene.clearTimer(checkRecordingFinished)
        }
      })
      {size=[0, flex(5)]}
    ]
  }
}

local function saveChanges() {
  control.save_config()
  haveChanges(false)
}

local function resetToDefault(target=null) {
  local function doReset() {
    local whereToReset = target?.preset == null ? selectedPreset.value?.preset : target.preset
    if (whereToReset != null)
      dainput.reset_user_config_to_preset(whereToReset, false)
    else
      control.reset_to_default()
    saveChanges()
    generation(generation.value+1)
  }

  msgbox.show({
    text = ::loc("controls/resetToDefaultsConfirmation")
    children = dtext(::loc("controls/preset", {
      preset = target?.name ?? selectedPreset.value.name
    }), {margin = hdpx(50)})
    buttons = [
      { text = loc("Yes"), action = doReset }
      { text = loc("No") }
    ]
  })
}

local function clearBinding(cellData){
  haveChanges(true)
  if (cellData.singleBtn) {
    set_single_button_analogue_binding(cellData.ah, cellData.column, cellData.actionProp, DataBlock())
  } else if (cellData.tag == "modifiers") {
    local binding = dainput.get_analog_stick_action_binding(cellData.ah, cellData.column)
                  ?? dainput.get_analog_axis_action_binding(cellData.ah, cellData.column)
    binding.mod = []
  } else {
    local blk = DataBlock()
    loadOriginalBindingParametersTo(blk, cellData.ah, cellData.column)
    dainput.set_action_binding(cellData.ah, cellData.column, blk)
  }
}

local function discardChanges() {
  if (!haveChanges.value)
    return
  control.restore_saved_config()
  generation(generation.value+1)
  haveChanges(false)
}

local function actionButtons() {
  local children = null
  local cellData = selectedBindingCell.value
  if (cellData != null) {
    local actionType = dainput.get_action_type(cellData.ah)
    local actionTypeGroup = actionType & dainput.TYPEGRP__MASK
    children = [textButton(::loc("controls/clearBinding"),
      function() {
        clearBinding(cellData)
        generation(generation.value+1)
      },
      { hotkeys = [["^J:X"]], skipDirPadNav = true })]

    if (actionTypeGroup == dainput.TYPEGRP_AXIS || actionTypeGroup == dainput.TYPEGRP_STICK)
      children.append(
        textButton(::loc("controls/axisSetup", "Axis setup"),
        function() { configuredAxis(cellData) },
        { hotkeys = [["^{0}".subst(JB.A), { description = ::loc("controls/axisSetup") }]], skipDirPadNav = true })
      )
    else if (actionTypeGroup == dainput.TYPEGRP_DIGITAL)
      children.append(
        textButton(::loc("controls/buttonSetup", "Button setup"),
          function() { configuredButton(cellData) },
          { hotkeys = [["^J:Y"]], skipDirPadNav = true })
        textButton(::loc("controls/bindBinding"),
          function() { startRecording(cellData) },
          { hotkeys = [["^{0}".subst(JB.A), { description = ::loc("controls/bindBinding") }]], skipDirPadNav = true })
      )
    if (isActionDisabledToCustomize(cellData.ah))
      children = null
  }
  return {
    watch = selectedBindingCell
    children = children
    flow = FLOW_HORIZONTAL
  }
}

local function collectBindableColumns() {
  local nColumns = dainput.get_actions_binding_columns()
  local colRange = []
  for (local i=0; i<nColumns; ++i) {
    if (!controlsSettingOnlyForGamePad.value || isGamepadColumn(i))
      colRange.append(i)
  }
  return colRange
}

local function getNotBoundActions() {
  local importantTabs = importantGroups.value

  local colRange = collectBindableColumns()
  local notBoundActions = {}

  for (local i = 0; i < dainput.get_actions_count(); ++i) {
    local ah = dainput.get_action_handle_by_ord(i)
    if (dainput.is_action_internal(ah))
      continue

    local actionGroups = getActionTags(ah)
    local isActionInImportantGroup = false
    foreach (actionGroup in actionGroups) {
      if (importantTabs.indexof(actionGroup) != null && !isActionDisabledToCustomize(ah))
        isActionInImportantGroup = true
    }

    if (actionGroups.indexof("not_important") != null)
      isActionInImportantGroup = false

    if (actionGroups.indexof("important") != null)
      isActionInImportantGroup = true

    if (!isActionInImportantGroup)
      continue

    local someBound = false
    switch (dainput.get_action_type(ah) & dainput.TYPEGRP__MASK) {
      case dainput.TYPEGRP_DIGITAL: {
        local bindings = colRange.map(@(col, _) dainput.get_digital_action_binding(ah, col))
        foreach (val in bindings)
          if (isValidDevice(val.devId) || val.devId == dainput.DEV_nullstub) {
            someBound = true
            break
          }
        break
      }
      case dainput.TYPEGRP_AXIS: {
        local axisBinding = colRange.map(@(col, _) dainput.get_analog_axis_action_binding(ah, col))
        foreach (val in axisBinding) {
          if (val.devId == dainput.DEV_pointing || val.devId == dainput.DEV_joy || val.devId == dainput.DEV_gamepad || val.devId == dainput.DEV_nullstub) {
            // using device axis
            someBound = true
            break
          }

          // using 2 digital buttons
          if (isValidDevice(val.minBtn.devId) && isValidDevice(val.maxBtn.devId)) {
            someBound = true
            break
          }

        }
        break
      }
      case dainput.TYPEGRP_STICK: {
        local stickBinding = colRange.map(@(col, _) dainput.get_analog_stick_action_binding(ah, col))
        foreach (val in stickBinding) {
          if (val.devId == dainput.DEV_pointing || val.devId == dainput.DEV_joy || val.devId == dainput.DEV_gamepad || val.devId == dainput.DEV_nullstub) {
            someBound = true
            break
          }
          if (isValidDevice(val.maxXBtn.devId) && isValidDevice(val.minXBtn.devId)
            && isValidDevice(val.maxYBtn.devId) && isValidDevice(val.minYBtn.devId)) {
            someBound = true
            break
          }
        }
        break
      }
    }

    if (!someBound) {
      local actionName = dainput.get_action_name(ah)
      local actionGroup = actionGroups?[0]
      if (!notBoundActions?[actionGroup])
        notBoundActions[actionGroup] <- { header = ::loc($"controls/tab/{actionGroup}"), controls = [] }

      notBoundActions[actionGroup].controls.append(::loc($"controls/{actionName}", actionName))
    }
  }

  if (notBoundActions.len() == 0)
    return null

  local ret = []
  foreach (action in notBoundActions) {
    ret.append($"\n\n{action.header}:\n")
    ret.append(", ".join(action.controls))
  }

  return "".join(ret)
}

local function onDiscardChanges() {
  msgbox.show({
    text = ::loc("settings/onCancelChangingConfirmation")
    buttons = [
      { text=loc("Yes"), action = discardChanges }
      { text=loc("No") }
    ]
  })
}

local skipDirPadNav = { skipDirPadNav = true }
local applyHotkeys = { hotkeys = [["^{0} | J:Start | Esc".subst(JB.B), { description={skip=true} }]] }

local onClose = @() showControlsMenu(false)

local function mkWindowButtons() {
  local function onApply() {
    local notBoundActions = platform.is_pc ? getNotBoundActions() : null
    if (notBoundActions == null) {
      saveChanges()
      onClose()
      return
    }

    msgbox.show({
      text = "".concat(::loc("controls/warningUnmapped"), notBoundActions)
      buttons = [
        { text=loc("Yes"),
          action = function() {
            saveChanges()
            onClose()
          }
        }
        { text = loc("No"), action = @() null }
      ]
    })
  }

  return @() {
    watch = haveChanges
    size = [flex(), SIZE_TO_CONTENT]
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    halign = ALIGN_RIGHT
    valign = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = style.CONTROL_BG_COLOR

    children = [
      textButton(::loc("controls/btnResetToDefaults"), resetToDefault, skipDirPadNav)
      haveChanges.value ? textButton(::loc("mainmenu/btnDiscard"), onDiscardChanges, skipDirPadNav) : null
      {size=[flex(), 1]}
      actionButtons
      textButton(::loc(haveChanges.value ? "mainmenu/btnApply" : "Ok"), onApply, skipDirPadNav.__merge(applyHotkeys))
    ]
  }
}


local function bindingTextFunc(text) {
  return {
    text = text
    color = style.DEFAULT_TEXT_COLOR
    rendObj = ROBJ_DTEXT
    font = Fonts.medium_text
    padding = hdpx(4)
  }
}


local function mkActionRowLabel(name, group=null){
  return {
    rendObj = ROBJ_DTEXT
    font = Fonts.medium_text
    color = style.DEFAULT_TEXT_COLOR
    text = locActionName(name)
    margin = [0, sh(1), 0, 0]
    size = [flex(1.5), SIZE_TO_CONTENT]
    halign = ALIGN_RIGHT
    group = group
  }
}

local function mkActionRowCells(label, columns){
  local children = [label].extend(columns)
  if (columns.len() < 2)
    children.append({size=[flex(0.75), 0]})
  return children
}

local function makeActionRow(ah, name, columns, xmbNode, showBgGen) {
  local group = ::ElemGroup()
  local isOdd = showBgGen()
  local label = mkActionRowLabel(name, group)
  local children = mkActionRowCells(label, columns)
  return ::watchElemState(@(sf) {
    xmbNode = xmbNode
    key = name
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    skipDirPadNav = true
    children = children
    rendObj = ROBJ_SOLID
    color = menuRowColor(sf, isOdd)
    group = group
  })
}


local bindingColumnCellSize = [flex(1), fontH(240)]

local function isCellSelected(cell_data, selection) {
  local selected = selection.value
  return (selected!=null) && selected.column==cell_data.column && selected.ah==cell_data.ah
    && selected.actionProp==cell_data.actionProp && selected.tag==cell_data.tag
}

local function showDisabledMsgBox(){
  return msgbox.show({
    text = ::loc("controls/bindingDisabled")
    buttons = [
      { text = loc("Ok")}
    ]
  })
}
local function bindedComp(elemList, group=null){
  return {
     group = group ?? ::ElemGroup()
     behavior = Behaviors.Marquee
     scrollOnHover = true
     size = SIZE_TO_CONTENT
     maxWidth = pw(100)
     flow = FLOW_HORIZONTAL
     valign = ALIGN_CENTER
     children = buildElems(elemList, {textFunc = bindingTextFunc, eventTypesAsTxt = true})
  }
}
local function bindingCell(ah, column, action_prop, list, tag, selection, name=null, xmbNode=null) {
  local singleBtn = action_prop!=null
  local cellData = {
    ah=ah, column=column, actionProp=action_prop, singleBtn=singleBtn, tag=tag, name=name
  }

  local group = ::ElemGroup()
  local isForGamepad = isGamepadColumn(column)

  return ::watchElemState(function(sf) {
    local hovered = (sf & S_HOVER)
    local selected = isCellSelected(cellData, selection)
    local isBindable = isForGamepad || !isGamepad.value
    return {
      watch = [selection, isGamepad]
      size = bindingColumnCellSize

      behavior = isBindable ? Behaviors.Button : null
      group = group
      xmbNode = isBindable ? xmbNode : null
      padding = sh(0.5)

      children = {
        rendObj = ROBJ_BOX
        fillColor = selected ? Color(0,0,0,255)
                  : hovered ? Color(40, 40, 40, 80)
                  : Color(0, 0, 0, 40)
        borderWidth = selected ? hdpx(2) : 0
        borderColor = style.DEFAULT_TEXT_COLOR
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        clipChildren = true

        size = flex()
        children = bindedComp(list, group)
      }

      function onDoubleClick() {
        local actionType = dainput.get_action_type(ah)
        if (isActionDisabledToCustomize(ah))
          return showDisabledMsgBox()

        if ((actionType & dainput.TYPEGRP__MASK) == dainput.TYPEGRP_DIGITAL
          || cellData.singleBtn || cellData.tag == "modifiers" || cellData.tag == "axis")
          startRecording(cellData)
        else
          configuredAxis(cellData)
      }

      onClick = isGamepad.value ? null : isActionDisabledToCustomize(ah) ? showDisabledMsgBox : @() selection(cellData)
      onHover = isGamepad.value ? @(on) selection(on ? cellData : null) : null

      function onDetach() {
        if (isCellSelected(cellData, selection))
          selection(null)
      }
    }
  })
}

local colorTextHdr = Color(120,120,120)
local function bindingColHeader(typ){
  return {
    size = bindingColumnCellSize
    rendObj = ROBJ_DTEXT
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    text = ::loc("/".join(["controls/type", platform.id, typ]),typ)
    color = colorTextHdr
  }
}
local function mkBindingsHeader(colRange){
  local cols = colRange.map(@(v) bindingColHeader(isGamepadColumn(v) ? "gamepad":"keyboard"))
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    children = mkActionRowCells(mkActionRowLabel(null), cols)
    valign = ALIGN_CENTER
    gap = sh(2)
    rendObj = ROBJ_SOLID
    color = Color(0,0,0)
  }
}

local function bindingsPage(section_name) {
  local filteredActions = getActionsList().filter(@(ah) getActionTags(ah).indexof(section_name) != null)
  local nActions = filteredActions.len()
  local nTotalColumns = dainput.get_actions_binding_columns()
  local xmbRootNode = ::XmbContainer({wrap=true})
  local xmbRowNodes = ::array(nActions)
  local xmbCellNodes = ::array(nActions)
  for (local iRow=0; iRow<nActions; ++iRow) {
    xmbRowNodes[iRow] = ::XmbContainer()
    local row = iRow
    xmbCellNodes[iRow] = ::array(nTotalColumns)
    for (local iCol=0; iCol<nTotalColumns; ++iCol) {
      local col = iCol
      xmbCellNodes[iRow][iCol] = ::XmbNode({
        function onLeave(dir) {
          if (dir == DIR_UP)
            ::gui_scene.setXmbFocus(xmbCellNodes[(row-1+nActions)%nActions][col])
          else if (dir == DIR_DOWN)
            ::gui_scene.setXmbFocus(xmbCellNodes[(row+1)%nActions][col])
        }
      })
    }
  }


  return function() {
    local colRange = collectBindableColumns()
    local toggleBg = makeBgToggle()

    local actionRows = []
    local header = mkBindingsHeader(colRange)

    foreach (aidx, ah in filteredActions) {
      local actionName = dainput.get_action_name(ah)
      local actionType = dainput.get_action_type(ah)

      switch (actionType & dainput.TYPEGRP__MASK) {
        case dainput.TYPEGRP_DIGITAL: {
          local bindings = colRange.map(@(col) dainput.get_digital_action_binding(ah, col))
          local colTexts = bindings.map(buildDigitalBindingText)
          local colComps = colTexts.map(@(col_text, idx) bindingCell(ah, colRange[idx], null, col_text, null, selectedBindingCell, actionName, xmbCellNodes[aidx][idx]))
          actionRows.append(makeActionRow(ah, actionName, colComps, xmbRowNodes[aidx], toggleBg))
          break
        }
        case dainput.TYPEGRP_AXIS:
        case dainput.TYPEGRP_STICK: {
          local colTexts = colRange.map(@(col, _) textListFromAction(actionName, col))
          local colComps = colTexts.map(@(col_text, idx) bindingCell(ah, colRange[idx], null, col_text, null, selectedBindingCell, actionName, xmbCellNodes[aidx][idx]))
          actionRows.append(makeActionRow(ah, actionName, colComps, xmbRowNodes[aidx], toggleBg))
          break
        }
      }
    }

    local bindingsArea = scrollbar.makeVertScroll({
      xmbNode = xmbRootNode
      flow = FLOW_VERTICAL
      size = [flex(), SIZE_TO_CONTENT]
      clipChildren = true
      children = actionRows
    })

    return {
      size = flex()
      padding = [sh(1), 0]
      flow = FLOW_VERTICAL
      key = section_name
      animations = pageAnim
      children = [platform.is_pc ? header : null, bindingsArea]
    }
  }
}

local function optionRowContainer(children, isOdd, params) {
  return ::watchElemState(@(sf) params.__merge({
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    skipDirPadNav = true
    children = children
    rendObj = ROBJ_SOLID
    color = menuRowColor(sf, isOdd)
    gap = sh(2)
    padding = [0, sh(2)]
  }))
}

local function optionRow(labelText, comp, isOdd) {
  local label = {
    rendObj = ROBJ_DTEXT
    color = style.DEFAULT_TEXT_COLOR
    text = labelText
    font = Fonts.medium_text
    margin = sh(1)
    size = [flex(1), SIZE_TO_CONTENT]
    //halign = ALIGN_CENTER
    halign = ALIGN_RIGHT
  }

  local children = [
    label
    {
      size = [flex(), fontH(200)]
      //halign = ALIGN_CENTER
      halign = ALIGN_LEFT
      valign = ALIGN_CENTER
      children = comp
    }
  ]

  return optionRowContainer(children, isOdd, {key=labelText})
}

local invertFields = {
  [0] = "axisXinv",
  [1] = "axisYinv",
  [-1] = "invAxis",
}

local function invertCheckbox(action_names, column, axis) {
  if (type(action_names) != "array")
    action_names = [action_names]

  local bindings = action_names.map(function(aname) {
    local ah = dainput.get_action_handle(aname, 0xFFFF)
    return dainput.get_analog_stick_action_binding(ah, column)
        ?? dainput.get_analog_axis_action_binding(ah, column)
  }).filter(@(b) b!=null)

  if (!bindings.len())
    return null

  local curInverses = bindings.map(@(b) b[invertFields[axis]])

  local valAnd = curInverses.reduce(@(a,b) a && b, true)
  local valOr = curInverses.reduce(@(a,b) a || b, false)

  local val = ::Watched((valAnd == valOr) ? valAnd : null)

  local function setValue(new_val) {
    val(new_val)
    foreach (b in bindings)
      b[invertFields[axis]] = new_val
    haveChanges(true)
  }

  return checkbox(val, null, { setValue = setValue, override = { size = flex(), valign = ALIGN_CENTER } useHotkeys=true})
}
local mkRounded = @(val) round_by_value(val, 0.01)

local function axisSetupSlider(action_name, column, prop, params) {
  local ah = dainput.get_action_handle(action_name, 0xFFFF)
  local binding = dainput.get_analog_stick_action_binding(ah, column)
               ?? dainput.get_analog_axis_action_binding(ah, column)
  if (!binding)
    return null
  local val = ::Watched(binding[prop])
  return mkSliderWithText(val,
    slider.Horiz(val,
      {
        setValue = function(new_val) {
          val(new_val)
          binding[prop] = new_val
          haveChanges(true)
        }
      }.__merge(params)),
      params?.morphText ?? mkRounded
    )
}


local sensRanges = [
  {min = 0.2, max = 5.0, step = 0.05} // mouse
  {min = 0.2, max = 5.0, step = 0.05} // gamepad
  {min = 0.2, max = 5.0, step = 0.05} // mouse/kbd aux
]

local function sensitivitySlider(action_name, column) {
  local params = sensRanges[column].__merge({
//    scaling = slider.scales.logarithmic
  })
  return axisSetupSlider(action_name, column, "sensScale", params)
}


local function sensMulSlider(prop) {
  local sensScale = control.get_sens_scale()
  local val = ::Watched(sensScale[prop])
  return mkSliderWithText(val
    slider.Horiz(val, {
      min = 0.2
      max = 5.0
      step = 0.05
//      scaling = slider.scales.logarithmic
      function setValue(new_val) {
        val(new_val)
        sensScale[prop] = new_val
        //haveChanges(true)
      }
    }))
}


local function smoothMulSlider(action_name) {
  local act = get_action_handle(action_name, 0xFFFF)
  if (act == 0xFFFF)
    return null
  return mkSliderWithText(aim_smooth
    slider.Horiz(aim_smooth, {
      min = 0.0
      max = 0.5
      step = 0.05
      function setValue(new_val) {
        aim_smooth_set(new_val)
        dainput.set_analog_stick_action_smooth_value(act, new_val)
      }
    }))
}


local function showDeadZone(val){
  return "{0}%".subst(round_by_value(val*100, 0.5))
}

local showRelScale = @(val) "{0}%".subst(round_by_value(val*10, 0.5))

const minDZ = 0.0
const maxDZ = 0.4
const stepDZ = 0.01
local function deadZoneScaleSlider(val, setVal){
  return mkSliderWithText(val,
    slider.Horiz(val, { min = minDZ, max = maxDZ, step=stepDZ, scaling = slider.scales.linear, setValue = setVal }),
    showDeadZone
  )
}
local isUserConfigCustomized = Watched(false)
local function checkUserConfigCustomized(){
  isUserConfigCustomized(dainput.is_user_config_customized())
}
local function updateAll(...) { updateCurrentPreset(); checkUserConfigCustomized()}
generation.subscribe(updateAll)
haveChanges.subscribe(updateAll)
local showPresetsSelect = Computed(@() availablePresets.value.len()>0)

local onClickCtor = @(p, idx) @() p.preset!=selectedPreset.value.preset || isUserConfigCustomized.value ? resetToDefault(p) : null//fixme do not reset if it is current
local isCurrent = @(p, idx) p.preset==selectedPreset.value.preset
local textCtor = @(p, idx, stateFlags) p?.name!=null ? ::loc(p?.name) : null
local selectPreset = select({state=selectedPreset, options=availablePresets.value, onClickCtor=onClickCtor, isCurrent=isCurrent, textCtor=textCtor})

local currentControls = @(){
  size = flex()
  watch = [showPresetsSelect, isUserConfigCustomized]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = {size = [hdpx(10),0]}
  children = showPresetsSelect.value ? [selectPreset].append(
    isUserConfigCustomized.value ? dtext(::loc("controls/modifiedControls"), {color = style.DEFAULT_TEXT_COLOR}) : null
  ) : null
}
local function pollSettings() {
  if (isUserConfigCustomized.value)
    return
  updateAll()
}

local function options() {
  local onlyGamePad = controlsSettingOnlyForGamePad.value
  local toggleBg = makeBgToggle()
  local showGamepadOpts = wasGamepad.value
  return {
    key = "options"
    size = flex()
    flow = FLOW_VERTICAL
    onAttach = function() {
      ::gui_scene.clearTimer(pollSettings)
      ::gui_scene.setInterval(0.5, pollSettings) //not enough to listen to changes and generations!!
    }
    onDetach = @() ::gui_scene.clearTimer(pollSettings)
    watch = [controlsSettingOnlyForGamePad, wasGamepad]
    children = [
      [true, ::loc("controls/curControlPreset"), currentControls],
      [!onlyGamePad, ::loc("controls/mouseAimXInvert"), invertCheckbox(["Human.Aim", "Spectator.Aim", "Vehicle.Aim"], 0, 0)],
      [!onlyGamePad, ::loc("controls/mouseAimYInvert"), invertCheckbox(["Human.Aim", "Spectator.Aim", "Vehicle.Aim"], 0, 1)],
      [showGamepadOpts, ::loc("controls/joyAimXInvert"), invertCheckbox(["Human.Aim", "Spectator.Aim", "Vehicle.Aim"], 1, 0)],
      [showGamepadOpts, ::loc("controls/joyAimYInvert"), invertCheckbox(["Human.Aim", "Spectator.Aim", "Vehicle.Aim"], 1, 1)],
      [!onlyGamePad, ::loc("controls/mouseAimSensitivity"), sensitivitySlider("Human.Aim", 0)],
      [showGamepadOpts, ::loc("controls/joyAimSensitivity"), sensitivitySlider("Human.Aim", 1)],
      [true, ::loc("controls/sensScale/humanAiming"), sensMulSlider("humanAiming")],
      [true, ::loc("controls/sensScale/humanTpsCam"), sensMulSlider("humanTpsCam")],
      [true, ::loc("controls/sensScale/humanFpsCam"), sensMulSlider("humanFpsCam")],
      [true, ::loc("controls/sensScale/vehicleCam"), sensMulSlider("vehicleCam")],
      [true, ::loc("controls/sensScale/planeCam"), sensMulSlider("planeCam")],
      [showGamepadOpts, ::loc("gamepad/stick0_deadzone"), deadZoneScaleSlider(stick0_dz, set_stick0_dz)],
      [showGamepadOpts, ::loc("gamepad/stick1_deadzone"), deadZoneScaleSlider(stick1_dz, set_stick1_dz)],
      [showGamepadOpts && isAimAssistExists,
        ::loc("options/aimAssist"),
        checkbox(isAimAssistEnabled, null,
          { setValue = setAimAssist, useHotkeys = true, override={size=flex() valign = ALIGN_CENTER}})
      ],
      [showGamepadOpts, ::loc("controls/uiClickRumble"),
        checkbox(isUiClickRumbleEnabled, null,
          { setValue = setUiClickRumble, override = { size = flex(), valign = ALIGN_CENTER } useHotkeys=true})],
      [showGamepadOpts, ::loc("controls/inBattleRumble"),
        checkbox(isInBattleRumbleEnabled, null,
          { setValue = setInBattleRumble, override = { size = flex(), valign = ALIGN_CENTER } useHotkeys=true})],

      [true, ::loc("controls/aimSmooth"), smoothMulSlider("Human.Aim")],
    ].map(@(v) v[0] ? optionRow.call(null, v[1],v[2], toggleBg()) : null)
    animations = pageAnim
  }
}


local function sectionHeader(text) {
  return optionRowContainer({
    rendObj = ROBJ_STEXT
    text = text
    color = style.DEFAULT_TEXT_COLOR
    font = Fonts.big_text
    padding = [sh(3), sh(1), sh(1)]
  }, false, {
    halign = ALIGN_CENTER
  })
}


local function axisSetupWindow() {
  local cellData = configuredAxis.value
  local stickBinding = dainput.get_analog_stick_action_binding(cellData.ah, cellData.column)
  local axisBinding = dainput.get_analog_axis_action_binding(cellData.ah, cellData.column)
  local binding = stickBinding ?? axisBinding
  local actionTags = getActionTags(cellData.ah)

  local actionName = dainput.get_action_name(cellData.ah)
  local actionType = dainput.get_action_type(cellData.ah)

  local title = {
    rendObj = ROBJ_STEXT
    font = Fonts.big_text
    color = style.DEFAULT_TEXT_COLOR
    text = ::loc($"controls/{actionName}", actionName)
    margin = sh(2)
  }

  local function buttons() {
    local children = []
    if (selectedAxisCell.value)
      children.append(
        textButton(::loc("controls/bindBinding"),
          function() { startRecording(selectedAxisCell.value) },
          { hotkeys = [["^{0}".subst(JB.A), { description = ::loc("controls/bindBinding") }]] })
        textButton(::loc("controls/clearBinding"),
          function() {
            clearBinding(selectedAxisCell.value)
            generation(generation.value+1)
          },
          { hotkeys = [["^J:X"]] })
       )

    children.append(textButton(::loc("mainmenu/btnOk", "OK"),
      function() { configuredAxis(null) },
      { hotkeys = [["^{0} | J:Start | Esc".subst(JB.B), { description={skip=true} }]] }))

    return {
      watch = selectedAxisCell

      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      halign = ALIGN_RIGHT
      children = children
    }
  }

  local modifiersList = []
  for (local i=0, n=binding.modCnt; i<n; ++i) {
    local mod = binding.mod[i]
    modifiersList.append(format_ctrl_name(mod.devId, mod.btnId))
    if (i < n-1)
      modifiersList.append("+")
  }

  local toggleBg = makeBgToggle()
  local rows = [
    optionRow(::loc("Modifiers"), bindingCell(cellData.ah, cellData.column, null, modifiersList, "modifiers", selectedAxisCell), toggleBg())
  ]

  local axisBindingTextList
  if (stickBinding) {
    axisBindingTextList = getSticksText(stickBinding)
  } else if (axisBinding) {
    axisBindingTextList = format_ctrl_name(axisBinding.devId, axisBinding.axisId, false)
  }

  toggleBg = makeBgToggle()

  rows.append(
    sectionHeader(::loc("controls/analog-axis-section", "Analog axis"))

    optionRow(::loc("controls/analog/axis", "Axis"), bindingCell(cellData.ah, cellData.column, null, axisBindingTextList ? [axisBindingTextList] : [], "axis", selectedAxisCell), toggleBg())

    stickBinding != null
      ? optionRow(::loc("controls/analog/sensitivity", "Sensitivity"), sensitivitySlider(actionName, cellData.column), toggleBg())
      : null

    dainput.get_action_type(cellData.ah) != dainput.TYPE_STICK_DELTA
      ? optionRow(::loc("controls/analog/deadzoneThres", "Deadzone"), axisSetupSlider(actionName, cellData.column, "deadZoneThres", {min=0, max=0.4,step=0.01, morphText=showDeadZone}), toggleBg())
      : null
    dainput.is_action_stateful(cellData.ah)
      ? optionRow(::loc("controls/analog/relIncScale", "changeStep"), axisSetupSlider(actionName, cellData.column, "relIncScale", {min=0.1, max=10.0, step=0.1, morphText=showRelScale}), toggleBg())
      : null
    dainput.get_action_type(cellData.ah) != dainput.TYPE_STICK_DELTA
      ? optionRow(::loc("controls/analog/nonlinearity"), axisSetupSlider(actionName, cellData.column, "nonLin", {min=0, max=4, step=0.5}), toggleBg())
      : null

    dainput.get_action_type(cellData.ah) != dainput.TYPE_STICK_DELTA && stickBinding != null
      ? optionRow(::loc("controls/analog/axisSnapAngK", "Axis snap factor"), axisSetupSlider(actionName, cellData.column, "axisSnapAngK", {min=0, max=1, step=0.025, morphText=showDeadZone}), toggleBg())
      : null

    stickBinding ? optionRow(::loc("controls/analog/isInvertedX", "Invert X"), invertCheckbox(actionName, cellData.column, 0), toggleBg()) : null
    stickBinding ? optionRow(::loc("controls/analog/isInvertedY", "Invert Y"), invertCheckbox(actionName, cellData.column, 1), toggleBg()) : null
    axisBinding ? optionRow(::loc("controls/analog/isInverted"), invertCheckbox(actionName, cellData.column, -1), toggleBg()) : null
  )

//  if (!isGamepadColumn(cellData.column) || dainput.is_action_stateful(cellData.ah))
//  {
  toggleBg = makeBgToggle()

  if (!actionTags.contains("_noDigitalButtons_")){
    rows.append(sectionHeader(::loc("controls/digital-buttons-section", "Digital buttons")))

    if (axisBinding) {
      if (actionType == dainput.TYPE_STEERWHEEL || dainput.is_action_stateful(cellData.ah)) {
        local texts = null
        if (isValidDevice(axisBinding.minBtn.devId))
          texts = [format_ctrl_name(axisBinding.minBtn.devId, axisBinding.minBtn.btnId, true)]
        else
          texts = []
        local cell = bindingCell(cellData.ah, cellData.column, "minBtn", texts, null, selectedAxisCell)
        rows.append(optionRow(::loc($"controls/{actionName}/min", ::loc("controls/min")), cell, toggleBg()))
      }

      local texts = null
      if (isValidDevice(axisBinding.maxBtn.devId))
        texts = [format_ctrl_name(axisBinding.maxBtn.devId, axisBinding.maxBtn.btnId, true)]
      else
        texts = []
      local cell = bindingCell(cellData.ah, cellData.column, "maxBtn", texts, null, selectedAxisCell)
      rows.append(optionRow(::loc($"controls/{actionName}/max", ::loc("controls/max")), cell, toggleBg()))

      if (dainput.is_action_stateful(cellData.ah)){
        local textsAdd = isValidDevice(axisBinding.decBtn.devId)
          ? [format_ctrl_name(axisBinding.decBtn.devId, axisBinding.decBtn.btnId, true)]
          : []
        local cellAdd = bindingCell(cellData.ah, cellData.column, "decBtn", textsAdd, null, selectedAxisCell)
        rows.append(optionRow(::loc($"controls/{actionName}/dec", ::loc("controls/dec")), cellAdd, toggleBg()))
        textsAdd = isValidDevice(axisBinding.incBtn.devId)
          ? [format_ctrl_name(axisBinding.incBtn.devId, axisBinding.incBtn.btnId, true)]
          : []
        cellAdd = bindingCell(cellData.ah, cellData.column, "incBtn", textsAdd, null, selectedAxisCell)
        rows.append(optionRow(::loc($"controls/{actionName}/inc", ::loc("controls/inc")), cellAdd, toggleBg()))

      }
    }
    else if (stickBinding) {
      local directions = [
        {locSuffix="X/min", axisId="axisXId", dirBtn="minXBtn"}
        {locSuffix="X/max", axisId="axisXId", dirBtn="maxXBtn"}
        {locSuffix="Y/max", axisId="axisYId", dirBtn="maxYBtn"}
        {locSuffix="Y/min", axisId="axisYId", dirBtn="minYBtn"}
      ]
      foreach (dir in directions) {
        local btn = stickBinding[dir.dirBtn]
        local texts = isValidDevice(btn.devId) ? [format_ctrl_name(btn.devId, btn.btnId, true)] : []

        rows.append(optionRow(::loc($"controls/{actionName}{dir.locSuffix}", ::loc($"controls/{dir.locSuffix}")),
          bindingCell(cellData.ah, cellData.column, dir.dirBtn, texts, null, selectedAxisCell), toggleBg()))
      }
    }
  }
//  }

  local children = [
    title

    scrollbar.makeVertScroll({
      flow = FLOW_VERTICAL
      key = "axis"
      size = [flex(), SIZE_TO_CONTENT]
      padding = [sh(1), 0]
      clipChildren = true

      children = rows
    })

    buttons
  ]

  return {
    size = flex()
    behavior = Behaviors.Button
    stopMouse = true
    stopHotkeys = true
    skipDirPadNav = true
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = Color(190,190,190,255)

    function onClick() {
      configuredAxis(null)
    }

    children = {
      size = [sw(80), sh(80)]
      rendObj = ROBJ_WORLD_BLUR_PANEL
      color = Color(120,120,120,255)
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER

      stopMouse = true
      stopHotkeys = true

      children = children
    }
  }
}


local function actionTypeSelect(cell_data, watched, value) {
  return ::watchElemState(function(sf) {
    return {
      behavior = Behaviors.Button
      function onClick() {
        watched(value)
      }
      flow = FLOW_HORIZONTAL
      children = [
        {
          size = [fontH(150), fontH(150)]
          halign = ALIGN_CENTER
          rendObj = ROBJ_STEXT
          font = Fonts.fontawesome
          text = (watched.value == value) ? fa["circle"] : fa["circle-o"]
          color = (sf & S_HOVER) ? style.HIGHLIGHT_COLOR : style.DEFAULT_TEXT_COLOR
        }
        {
          rendObj = ROBJ_STEXT
          font = Fonts.medium_text
          color = (sf & S_HOVER) ? style.HIGHLIGHT_COLOR : style.DEFAULT_TEXT_COLOR
          text = ::loc(eventTypeLabels[value])
        }
      ]
    }
  })
}

local selectEventTypeHdr = {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_STEXT
  text = ::loc("controls/actionEventType", "Action on")
  color = style.DEFAULT_TEXT_COLOR
  font = Fonts.medium_text
  halign = ALIGN_RIGHT
}

local function buttonSetupWindow() {
  local cellData = configuredButton.value
  local binding = dainput.get_digital_action_binding(cellData.ah, cellData.column)
  local eventTypeValue = ::Watched(binding.eventType)
  local modifierType = Watched(binding.unordCombo)
  local needShowModType = Watched(binding.modCnt > 0)
  modifierType.subscribe(function(new_val) {
    binding.unordCombo = new_val
    haveChanges(true)
  })

  local currentBinding = {
    flow = FLOW_HORIZONTAL
    children = bindedComp(buildDigitalBindingText(binding))
  }
  eventTypeValue.subscribe(function(new_val) {
    binding.eventType = new_val
    haveChanges(true)
  })

  local actionName = dainput.get_action_name(cellData.ah)
  local title = {
    rendObj = ROBJ_STEXT
    font = Fonts.big_text
    color = style.DEFAULT_TEXT_COLOR
    text = ::loc($"controls/{actionName}", actionName)
    margin = sh(3)
  }


  local buttons = {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    halign = ALIGN_RIGHT
    children = [
      textButton(::loc("mainmenu/btnOk", "OK"), function() {
        configuredButton(null)
      }, {
          hotkeys = [
            ["^{0} | J:Start | Esc".subst(JB.B), { description={skip=true} }],
          ]
      })
    ]
  }

  local eventTypesChildren = getAllowedBindingsTypes(cellData.ah).map( @(eventType) actionTypeSelect(cellData, eventTypeValue, eventType))
  local selectEventType = @() {
    flow = FLOW_VERTICAL
    size = [flex(), SIZE_TO_CONTENT]
    watch = eventTypeValue
    children = eventTypesChildren
  }

  local triggerTypeArea = {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_TOP
    gap = sh(2)
    children = [
      selectEventTypeHdr
      selectEventType
    ]
  }

  local selectModifierType = @() {
    watch = needShowModType
    hplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = needShowModType.value ? [
      checkbox(modifierType, {text = ::loc("controls/unordCombo")})
    ] : null
  }
  local children = [
    title
    {
      halign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      children = [currentBinding, selectModifierType]
    }
    {
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = triggerTypeArea
    }
    {size = flex(10) }
    buttons
  ]

  return {
    size = flex()
    behavior = Behaviors.Button
    skipDirPadNav = true
    stopMouse = true
    stopHotkeys = true
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = Color(190,190,190,255)

    function onClick() {
      configuredAxis(null)
    }

    children = {
      size = [sw(80), sh(80)]
      rendObj = ROBJ_WORLD_BLUR_PANEL
      color = Color(120,120,120,255)
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = hdpx(70)

      children = children
    }
  }
}


local function controlsSetup() {
  local menu = {
    transform = {}
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    size = [::min(sw(90), safeAreaSize.value[0]), sh(85)]
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = Color(120,120,120,255)
    flow = FLOW_VERTICAL
    //stopHotkeys = true
    stopMouse = true

    children = [
      settingsHeaderTabs({sourceTabs = tabsList, currentTab = currentTab}),
      {
        size = flex()
        padding=[hdpx(5),hdpx(10)]
        children = currentTab.value == "Options" ? options : bindingsPage(currentTab.value)
      },
      mkWindowButtons()
    ]
  }

  local root = {
    key = "controls"
    size = [sw(100), sh(100)]
    cursor = cursors.normal
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    watch = [
      actionRecording, configuredAxis, configuredButton, currentTab,
      generation, controlsSettingOnlyForGamePad
    ]

    children = [
      {
        size = [sw(100), sh(100)]
        stopHotkeys = true
        stopMouse = true
        rendObj = ROBJ_WORLD_BLUR_PANEL
        color = Color(130,130,130)
      }
      actionRecording.value==null ? menu : null
      configuredAxis.value!=null ? axisSetupWindow : null
      configuredButton.value!=null ? buttonSetupWindow : null
      actionRecording.value!=null ? recordingWindow : null
    ]

    transform = {
      pivot = [0.5, 0.25]
    }
    animations = pageAnim
    sound = {
      attach="ui/menu_enter"
      detach="ui/menu_exit"
    }

    hooks = HOOK_ATTACH
    actionSet = "StopInput"
  }

  return root
}


return {
  controlsMenuUi = controlsSetup
  showControlsMenu = showControlsMenu
}
 