local background = require("background.nut")
local {local_storage} = require("enlist.app")
local auth = require("auth")
local {get_time_msec} = require("dagor.time")
local urlText = require("enlist/components/urlText.nut")
local { save_settings, get_setting_by_blk_path, set_setting_by_blk_path } = require("settings")

local textInput = require("ui/components/textInput.nut")
local checkBox = require("ui/components/checkbox.nut")
local progressText = require("enlist/components/progressText.nut")
local textButton = require("enlist/components/textButton.nut")
local fontIconButton = require("enlist/components/fontIconButton.nut")
local {safeAreaBorders} = require("enlist/options/safeAreaState.nut")
local fa = require("daRg/components/fontawesome.map.nut")
local {exitGameMsgBox} = require("enlist/mainMsgBoxes.nut")
local msgbox = require("enlist/components/msgbox.nut")
local regInfo = require("reginfo.nut")
local supportLink = require("supportLink.nut")
local system = require("dagor.system")

local {isLoggedIn} = require("enlist/login/login_state.nut")
local {startLogin, currentStage} = require("enlist/login/login_chain.nut")
local loginDarkStripe = require("loginDarkStripe.nut")
local { loginBlockOverride, infoBlock } = require("loginUiParams.nut")


const forgotPasswordUrl = "https://login.gaijin.net/ru/sso/forgot"
local forgotPassword  = urlText(::loc("forgotPassword"), forgotPasswordUrl, {opacity=0.7, font=Fonts.small_text})

const autologinBlkPath = "autologin"
local doAutoLogin = persist("doAutoLogin", @() Watched(get_setting_by_blk_path(autologinBlkPath) ?? false))

const DUPLICATE_ACTION_DELAY_MSEC = 100 //actions can be pushed by loading or by long frame. In such case we do not want double login assert
local AFTER_ERROR_PROCESSED_ID = "after_go_login_error_processed"

local arg_login = system.get_arg_value_by_name("auth_login")
local arg_password = system.get_arg_value_by_name("auth_password")
local storedLogin = arg_login ? arg_login : local_storage.hidden.get_value("login")
local storedPassword = arg_password ? arg_password : local_storage.hidden.get_value("password")
local need2Step = persist("need2Step", @() Watched(false))
local lastLoginCalled = - DUPLICATE_ACTION_DELAY_MSEC

isLoggedIn.subscribe(@(v) need2Step(false))

local formStateLogin = Watched(storedLogin ?? "")
local formStatePassword = Watched(storedPassword ?? "")
local formStateTwoStepCode = Watched("")
local formStateSaveLogin = Watched(storedLogin != null)
local formStateSavePassword = Watched(storedPassword != null)
local formStateFocusedField = Watched(null)
local formStateAutoLogin = Watched(get_setting_by_blk_path(autologinBlkPath) ?? false)

formStateAutoLogin.subscribe(function(v) {
  set_setting_by_blk_path(autologinBlkPath, v)
  save_settings()
})
local function availableFields() {
  return [
    formStateLogin,
    formStatePassword,
    (need2Step.value ? formStateTwoStepCode : null),
    formStateSaveLogin,
    (formStateSaveLogin.value ? formStateSavePassword : null),
    formStateAutoLogin
  ].filter(@(val) val)
}


local function tabFocusTraverse(delta) {
  local tabOrder = availableFields()

  local curIdx = tabOrder.indexof(formStateFocusedField.value)
  if (curIdx==null)
    ::set_kb_focus(tabOrder[0])
  else {
    local newIdx = (curIdx + tabOrder.len() + delta) % tabOrder.len()
    ::set_kb_focus(tabOrder[newIdx])
  }
}
local persistActions = persist("persistActions", @() {})

persistActions[AFTER_ERROR_PROCESSED_ID] <- function(processState) {
  local status = processState?.status
  if (status == auth.YU2_2STEP_AUTH) {
    need2Step(true)
    formStateTwoStepCode("")
    ::set_kb_focus(formStateTwoStepCode)
  }
  else if (status == auth.YU2_WRONG_LOGIN) {
    ::set_kb_focus(formStateLogin)
    ::anim_start(formStateLogin)
  }
}

local function doPasswordLogin() {
  if (currentStage.value!=null) {
    log($"Ignore start login due current loginStage is {currentStage.value}")
    return
  }
  local curTime = get_time_msec()
  if (curTime < lastLoginCalled + DUPLICATE_ACTION_DELAY_MSEC) {
    log("Ignore start login due duplicate action called")
    return
  }

  lastLoginCalled = curTime
  local isValid = true
  foreach (f in availableFields()) {
    if (typeof(f.value)=="string" && !f.value.len()) {
      ::anim_start(f)
      isValid = false
    }
  }
  if (isValid) {
    local twoStepCode = need2Step.value ? formStateTwoStepCode.value : null
    startLogin({
      login_id = formStateLogin.value,
      password = formStatePassword.value,
      saveLogin = formStateSaveLogin.value,
      savePassword = formStateSavePassword.value && formStateSaveLogin.value,
      two_step_code = twoStepCode
      needShowError = @(processState) processState?.status != auth.YU2_2STEP_AUTH
      afterErrorProcessed = @(processState) persistActions[AFTER_ERROR_PROCESSED_ID](processState)
    })
  }
}

local function makeFormItemHandlers(field, debugKey=null) {
  return {
    onFocus = @() formStateFocusedField.update(field)
    onBlur = @() formStateFocusedField.update(null)
    onAttach = function(elem) {
      if (msgbox.widgets.value.len())
        return
      local focusOn = need2Step.value ? formStateTwoStepCode
            : ((formStatePassword.value=="" && formStateLogin.value!="") ? formStatePassword : formStateLogin)
      if (field == focusOn)
        ::set_kb_focus(elem)
    }

    onReturn = function() { log("Start Login from text field", debugKey); doPasswordLogin() }
  }
}


local function formText(field, options={}) {
  return textInput.Underlined(field, options, makeFormItemHandlers(field, options?.title))
}

local capslockText = {rendObj = ROBJ_DTEXT text="Caps Lock" color = Color(50,200,255)}
local capsDummy = {rendObj = ROBJ_DTEXT text=null}
local function capsLock() {
  local children = (::gui_scene.keyboardLocks.value & KBD_BIT_CAPS_LOCK) ? capslockText : capsDummy
  return {
    watch = ::gui_scene.keyboardLocks
    size = SIZE_TO_CONTENT
    hplace = ALIGN_CENTER
    children = children
  }
}

local keyboardLangColor = Color(100,100,100)
local function keyboardLang(){
  local text = ::gui_scene.keyboardLayout.value
  if (::type(text)=="string")
    text = text.slice(0,5)
  else
    text = ""
  return {
    watch = ::gui_scene.keyboardLayout
    rendObj = ROBJ_DTEXT text=text color=keyboardLangColor  hplace=ALIGN_RIGHT vplace=ALIGN_CENTER padding=[0,hdpx(5),0,0]
  }
}

local function formPwd(field, options={}) {
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = [
      {size=[flex(), SIZE_TO_CONTENT] children = [textInput.Underlined(field, options, makeFormItemHandlers(field, options?.debugKey)), keyboardLang]}
      capsLock
    ]
  }
}

local formCheckbox = @(field, options={}) checkBox(field,
  options.title, makeFormItemHandlers(field, options?.title))

local loginBtn = textButton.Purchase(::loc("Login"),
  function() { log("Start Login by login btn"); doPasswordLogin() },
  { size = [flex(), hdpx(70)], font = Fonts.big_text, halign = ALIGN_CENTER, margin = 0
    hotkeys = [["^J:Y", { description = { skip = true }}]]
  }
)

local hotkeysRootChild = {hotkeys = [["^Tab", @() tabFocusTraverse(1)], ["^L.Shift Tab | R.Shift Tab", @() tabFocusTraverse(-1)]]}

local function createLoginForm() {
  local loginOptions = [
    formText(formStateLogin,{placeholder=::loc("login (e-mail)"), inputType="mail", title="login"}),
    formPwd(formStatePassword,{placeholder=::loc("password"), password="*", title="password"})
  ]
  if (need2Step.value)
    loginOptions.append(formText(formStateTwoStepCode, { placeholder=::loc("2 step code"), title="twoStepCode"}))
  loginOptions.append(
    formCheckbox(formStateSaveLogin, {title=::loc("Store login (e-mail)")}),
    (formStateSaveLogin.value ? formCheckbox(formStateSavePassword,{title=::loc("Store password (this is unsecure!)")}) : null),
//    (formStateSaveLogin.value ? formCheckbox(formStateAutoLogin, {title=::loc("Autologin")}) : null), //- disable it cause there is no way to switch off autologin now
    forgotPassword
  )
  return [
    @()
    {
      flow = FLOW_VERTICAL
      size = flex()
      children = loginOptions
      watch = formStateSaveLogin
    }
    {
      vplace = ALIGN_BOTTOM
      halign = ALIGN_CENTER
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = hdpx(10)
      children = [
        currentStage.value == null ? loginBtn : null
      ]
    }
    regInfo
    hotkeysRootChild
  ]
}

local function loginRoot() {
  local watch = [currentStage, need2Step, formStateSaveLogin,
    isLoggedIn, loginBlockOverride]
  local children = (currentStage.value || isLoggedIn.value)
    ? [progressText(::loc("loggingInProcess"))]
    : createLoginForm()
  return {
    watch = watch
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    function onAttach() {
      if (doAutoLogin.value) {
        doAutoLogin(false)
        doPasswordLogin()
      }
    }
    children = children
  }.__update(loginBlockOverride.value)
}

local headerHeight = calc_comp_size({size=SIZE_TO_CONTENT children={font=Fonts.big_text margin = [sh(1), 0] size=[0, fontH(100)] rendObj=ROBJ_DTEXT}})[1]*0.75
local enterHandler = @(){
  hotkeys = [["^Enter", function() {
  if ((formStateLogin.value ?? "").len()>1 && (formStatePassword.value ?? "").len()>1)
    doPasswordLogin()
  }]]
}
return @() {
  watch = infoBlock
  size = flex()
  children = [
    background
    loginDarkStripe
    infoBlock.value
    enterHandler
    loginRoot
    supportLink
    {
      size = [headerHeight, headerHeight]
      hplace = ALIGN_RIGHT
      margin = safeAreaBorders.value[1]
      children = fontIconButton(fa["power-off"], { onClick = exitGameMsgBox })
    }
  ]
}

 