                                                     
                                                                                                         
                                                                                                                  
                                                                                                                                

local function panel(elem_, ...) {
  local children = elem_?.children ?? []
  local add_children = []
  foreach (v in vargv) {
    if (::type(v) != "array")
      add_children.append(v)
    else
      add_children.extend(v)
  }
  if (::type(children) in ["table","class","function"] )
    children = [children]

  children.extend(add_children)

  return elem_.__merge({children=children})
}

return panel 