return {
  broadcastEvents = {
    EventSquadMembersStats = { list = [/*squadEid, guid, eid, stat, amount*/] }
    CmdUpdateSquadPOI = null,
    EventOnSquadStats = {stats = {guid = {}}}
  },
  unicastEvents = {
    CmdSquadsData = {} //deprecated will be delete after update profileServer and client
    CmdProfileJwtData = {} //here is table of anything
    CmdSquadSoldiersInfoChange = { soldiers = "", army = "", section = "" },
    CmdGetBattleResult = {},
    AFKShowWarning = null,
    AFKShowDisconnectWarning = null,
    CmdOpenArtilleryMap = null,
    CmdCloseArtilleryMap = null,
    CmdShowArtilleryCooldownHint = null,
    RequestCloseArtilleryMap = null,
    EventArtilleryMapPosSelected = { pos = null },
    CmdArtillerySelfOrder = null,
    CmdSelectBuildingType = { index = 0 },
    CmdCreateRespawner = null,
  }
}
 