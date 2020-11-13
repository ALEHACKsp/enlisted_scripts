require ecs
require ecs.common
require game.es.events

[es(tag=gameClient, track=(human_dot_lockPersonView, isAlive, isDowned, human_weap_dot_mortarMode), REQUIRE=hero)]
def human_lock_person_view_es(evt : Event; possessedByPlr : EntityId; isAlive, isDowned, human_weap_dot_mortarMode : bool; camNames : Array; var human_dot_lockSwitchCamera : bool&; human_dot_lockPersonView : int = 0)
  if human_dot_lockPersonView > 0
    for i in iter_range(camNames)

      let cameraTemplateName = get_string(camNames[i], "")
      if cameraTemplateName == ""
        continue

      let templ = getTemplateByName(cameraTemplateName)
      if templ == null
        continue

      let component = getTemplateComponent(templ, "isTpsView")
      if component == null
        continue
      let tpsCamera = get_bool(component) ?? false

      if human_dot_lockPersonView == (tpsCamera ? 3 : 1)
        human_dot_lockSwitchCamera = false
        sendEventImmediate(possessedByPlr, [[CmdSwitchCameraByIndex index=i]])
        break
  human_dot_lockSwitchCamera = human_dot_lockPersonView != 0 || isDowned || !isAlive || human_weap_dot_mortarMode
