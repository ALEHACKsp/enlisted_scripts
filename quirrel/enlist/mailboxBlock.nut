local fa = require("daRg/components/fontawesome.map.nut")
local colors = require("ui/style/colors.nut")
local {bigGap, gap} = require("enlist/viewConst.nut")
local scrollbar = require("ui/components/scrollbar.nut")
local fontIconButton = require("components/fontIconButton.nut")
local textButton = require("enlist/components/textButton.nut")
local mailboxState = require("mailboxState.nut")
local modalPopupWnd = require("enlist/components/modalPopupWnd.nut")

local MAILBOX_MODAL_UID = "mailbox_modal_wnd"
local wndWidth = ::hdpx(450)
local maxListHeight = ::hdpx(300)
local padding = gap

/*
  this layout looks ugly cause we have no valid autolayout for objects that should be in scrollbox and in the same time scrollbox can depend on it's content (min\maxHeight and min\maxWidth)
  TODO:
    introduce timestamp for notifications
    show timestamsp
    show new notifications different way from old one
    auto 'markread' new notifications if visible for long enough time
*/

local mkRemoveBtn = @(notify) {
  size = SIZE_TO_CONTENT
  children = fontIconButton(fa["trash-o"],
    { onClick = @() notify.remove(),
      color = Color(200,200,200)
    })
}

local btnParams = textButton.smallStyle.__merge({ margin = 0, size = [flex(), ::hdpx(30)], halign = ALIGN_LEFT })
local defaultStyle = btnParams
local buttonStyles = {
  toBattle = textButton.onlinePurchaseStyle.__merge(btnParams)
  primary = textButton.primaryButtonStyle.__merge(btnParams)
}

local item = @(notify) @() {
  watch = notify.text
  size = [flex(), SIZE_TO_CONTENT]
  flow  = FLOW_HORIZONTAL
  gap = ::hdpx(2)
  children = [
    textButton(notify.text.value, notify.show, buttonStyles?[notify.styleId] ?? defaultStyle)
    mkRemoveBtn(notify)
  ]
}

local mailsPlaceHolder = {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_SOLID
  padding = padding
  color = colors.ControlBg
  children = {
    rendObj = ROBJ_DTEXT
    color = colors.TextHighlight
    text = ::loc("no notifications")
  }
}

local mkHeader = @(total) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER

  children = [
    {
      rendObj = ROBJ_DTEXT
      text="{0} {1}".subst(::loc("Notifications:"), total > 0 ? total : "")
      color =colors.Inactive
      margin = [0, 0, 0, gap]
    }
    {size=[flex(),0]}
    {
      vplace = ALIGN_CENTER
      children = fontIconButton(fa["times"],
        {
          function onClick() {
            modalPopupWnd.remove(MAILBOX_MODAL_UID)
          }
        })
    }
  ]
}

//local textHgt = ::calc_comp_size({rendObj = ROBJ_DTEXT, text= "clear"})[1]
//local clearAllBtn = textButton("trash-o", mailboxState.clearAll, {font = Fonts.small_text, margin = 0, hplace=ALIGN_RIGHT, padding = 0, textMargin=[textHgt/3, textHgt]})
local clearAllBtn = textButton.FAButton("trash-o", mailboxState.clearAll, {hplace=ALIGN_RIGHT, font = Fonts.fontawesome})

local function mailboxBlock() {
  local elems = mailboxState.inbox.value.map(item)
  if (elems.len() == 0)
    elems.append(mailsPlaceHolder)
  elems.reverse()

  return {
    size = [wndWidth, SIZE_TO_CONTENT]
    watch = [mailboxState.hasUnread, mailboxState.inbox]
    flow = FLOW_VERTICAL
    gap = bigGap

    children = [
      mkHeader(mailboxState.inbox.value.len())
      scrollbar.makeVertScroll({
        size = [flex(), SIZE_TO_CONTENT]
        gap = gap
        flow = FLOW_VERTICAL
        children = elems
      },
      {
        size = [flex(), SIZE_TO_CONTENT]
        maxHeight = maxListHeight
        needReservePlace = false
      })
      clearAllBtn
    ]
  }
}

mailboxState.inbox.subscribe(@(v) !v.len() && modalPopupWnd.remove(MAILBOX_MODAL_UID))

return @(event) modalPopupWnd.add(event.targetRect,
  {
    watch = mailboxState.inbox //!!FIX ME: This watch need only because of bug with incorrect recalc parent on child size change
    uid = MAILBOX_MODAL_UID
    onAttach = function() {
      mailboxState.markReadAll()
      mailboxState.isMailboxVisible(true)
    }
    onDetach = function() {
      mailboxState.markReadAll()
      mailboxState.isMailboxVisible(false)
    }

    rendObj = ROBJ_BOX
    fillColor = colors.WindowBlurredColor
    popupBg = { rendObj = ROBJ_WORLD_BLUR_PANEL, fillColor = colors.ModalBgTint }

    children = mailboxBlock
  }) 