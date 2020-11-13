require ecs
require math
require DagorShaders
require DagorMath

[es (tag=render, on_event=(EventEntityCreated, EventComponentsAppear), REQUIRE = (snow_whitening_dot_speed, snow_whitening_dot_amount))]
def snow_whitening_appear(evt:Event)
  DagorShaders::set_real(get_shader_variable_id("envi_cover_normal_mask_threshold", true), 0.)

[es(no_order, tag=render)]
def snow_whitening_update(info:UpdateStageInfoAct; snow_whitening_dot_speed:float; var snow_whitening_dot_amount:float&)
  snow_whitening_dot_amount = clamp(snow_whitening_dot_amount + snow_whitening_dot_speed*info.dt, 0., 0.5)
  if snow_whitening_dot_amount < 0.001
    DagorShaders::set_int(get_shader_variable_id("envi_cover", true), 0)
  else
    DagorShaders::set_int(get_shader_variable_id("envi_cover", true), 1)
    DagorShaders::set_real(get_shader_variable_id("envi_cover_normal_mask_threshold", true), snow_whitening_dot_amount)

