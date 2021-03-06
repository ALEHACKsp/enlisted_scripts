local {contactBlockExtensionCtr} = require("enlist/contacts/contactsState.nut")
local { enabledSquad, squadMembers, squadId } = require("enlist/squad/squadState.nut")
local { mkIcon } = require("enlisted/enlist/soldiers/components/armyPackage.nut")
local { curArmies_list } = require("enlisted/enlist/soldiers/model/state.nut")

local iconHgt = hdpx(32).tointeger()
local diceIcon = {
  rendObj = ROBJ_IMAGE
  image = ::Picture("!ui/skin#dice_solid.svg:{0}:{0}:K".subst((iconHgt*3/4).tointeger()))
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_CENTER
  pos = [hdpx(1), hdpx(2)]
}

local armyImage = @(armyId) mkIcon(armyId, iconHgt)

local memberAvatar = @(uid) function() {
  local watch = [enabledSquad, squadMembers, squadId]
  local res = { watch = watch }
  local squadLeader = enabledSquad.value && squadId.value == uid ? squadMembers.value?[uid] : null
  if (squadLeader == null)
    return res
  watch.append(squadLeader.state)
  local randomTeam = squadLeader.state.value?.isTeamRandom ?? false
  local curArmy = squadLeader.state.value?.curArmy
  return res.__update({
    padding = [hdpx(4),0,0,0],
    children = !randomTeam
      ? curArmy ? mkIcon(curArmy, iconHgt*4/3) : null
      : curArmies_list.value.map(@(army, idx) {children = armyImage(army), pos = [iconHgt*3.0/4*(idx - 1/2.0), -iconHgt/5]})
        .reverse()
        .append(diceIcon)
  })
}

contactBlockExtensionCtr({
//  bottomLineChild = bottomLineChild
//  namePrefixCtr = namePrefixCtr
  memberAvatar = memberAvatar
})
 