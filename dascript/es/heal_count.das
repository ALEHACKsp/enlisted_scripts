require ecs

def calculateKits(itemContainer : EidList; var selfHeal : int&; var targetHeal : int&; var selfRevive : int&; var targetRevive : int&)
  selfHeal = 0
  targetHeal = 0
  selfRevive = 0
  targetRevive = 0
  for itemEid in itemContainer
    let heal = has(itemEid, "item.healAmount")
    let revive = has(itemEid, "item.reviveAmount")
    let self = has(itemEid, "item.useTime")
    let target = has(itemEid, "item.useTimeToTarget")
    selfHeal += heal && self ? 1 : 0
    targetHeal += heal && target ? 1 : 0
    selfRevive += revive && self ? 1 : 0
    targetRevive += revive && target ? 1 : 0

[es (track=itemContainer,on_event=(EventEntityCreated, EventComponentsAppear), tag=server)]
def item_es(evt:Event; itemContainer : EidList; var total_kits_dot_selfHeal:int&;
                                                var total_kits_dot_targetHeal:int&;
                                                var total_kits_dot_selfRevive:int&;
                                                var total_kits_dot_targetRevive:int&)
  calculateKits(itemContainer, total_kits_dot_selfHeal, total_kits_dot_targetHeal, total_kits_dot_selfRevive, total_kits_dot_targetRevive)

[es (on_event=EventEntityRecreated, REQUIRE=item_dot_mutableState, tag=server)]
def mutable_item_es(evt:Event; item_dot_ownerEid : EntityId)
  query(item_dot_ownerEid) <| $ [es] (itemContainer : EidList; var total_kits_dot_selfHeal:int&;
                                                               var total_kits_dot_targetHeal:int&;
                                                               var total_kits_dot_selfRevive:int&;
                                                               var total_kits_dot_targetRevive:int&)
    calculateKits(itemContainer, total_kits_dot_selfHeal, total_kits_dot_targetHeal, total_kits_dot_selfRevive, total_kits_dot_targetRevive)
