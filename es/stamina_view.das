require ecs
require game.es.events
require HumanPhys
require EnlistedHuman
require math.base

[es (tag=(ui,render,gameClient), REQUIRE=watchedByPlr, after=after_net_phys_sync)]
def hero_stamina_es(info: UpdateStageInfoAct;
                    human_net_phys: HumanActor;
                    var view_lowStamina: bool&;
                    var view_stamina: int&)
  let canStartSprint = human_net_phys.phys.canStartSprint
  view_lowStamina = !canStartSprint

  view_stamina = int(human_net_phys.phys.currentState.stamina
    * safeinv(human_net_phys.phys.maxStamina / 100.f * human_net_phys.phys.currentState.maxStaminaMult
    * human_net_phys.phys.currentState.staminaBoostMult) + 1.f)