require ecs
require DagorSystem

[es (on_event=(EventEntityCreated, EventComponentsAppear))]
def init_recoil_mult_es(evt:Event; var platformRecoilControlMult : float&)
  if get_console_model() != ConsoleModel UNKNOWN
    platformRecoilControlMult = 0.5

