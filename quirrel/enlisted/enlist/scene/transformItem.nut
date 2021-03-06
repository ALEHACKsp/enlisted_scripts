local math = require("std/math_ex.nut")
local Point3 = math.Point3
local quat_to_matrix = math.quat_to_matrix
local euler_to_quat = math.euler_to_quat
local degToRad = math.degToRad

local function transformItem(transform, templateName){
  if (templateName != null) {
    local template = ::ecs.g_entity_mgr.getTemplateDB().getTemplateByName(templateName)
    if (template == null)
      return transform
    local ypr = ["Yaw", "Pitch", "Roll"].map(pipe(@(v) $"item.icon{v}", @(v) template.getCompValNullable(v) ?? 0, degToRad))
    local pos = transform.getcol(3)
    local trYaw =   quat_to_matrix(euler_to_quat(Point3(-ypr[0], 0, 0))).inverse()
    local trPitch = quat_to_matrix(euler_to_quat(Point3(0, ypr[2], 0))).inverse()
    local trRoll =  quat_to_matrix(euler_to_quat(Point3(0, 0, ypr[1]))).inverse()
    transform = trPitch * trRoll * trYaw
    transform.setcol(3, pos)
  }
  return transform
}

return transformItem 