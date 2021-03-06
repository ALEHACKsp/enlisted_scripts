  
                                                                                                                                         
                                                                           

                                                                                                               
                                                               
                                                                                                                                                             
                                                                                                               

                                                                                                                                                                   
                      
                                                  
                                           

          
              
                                             
                                        
                      
                          
      
                     
                 
                 
     
                      
                                                           
             
                      
                  
                                                       
                      
      
                                         
    

  
local unknownTag = @(...) {rendObj=ROBJ_SOLID opacity=0.2 size=[flex(), hdpx(2)], margin=[0, hdpx(5)], color = Color(255,120,120)}
local function defTextArea(params, formatAstFunc, style={}){
  return {
    rendObj = ROBJ_TEXTAREA
    text = params?.v
    behavior = Behaviors.TextArea
    color = style?.defTextColor
    size = [flex(), SIZE_TO_CONTENT]
  }.__update(params)
}

local defFormatters = {
  string = @(text, formatAstFunc, style={}) defTextArea({v=text}, formatAstFunc, style)
  def = defTextArea
}

local defStyle = {
  lineGaps = hdpx(5)
}

local mkFormatAst = ::kwarg(function mkFormatAstImpl(formatters = defFormatters, filter = @(obj) false, style = defStyle){
  if (formatters != defFormatters)
    formatters=defFormatters.__merge(formatters)
  if (style != defStyle)
    style = defStyle.__merge(style)

  return function formatAst(object, params={}){
    local formatAstFunc = ::callee()
    if (::type(object) == "string")
      return formatters["string"](object, formatAstFunc, style)
    if (object==null)
      return null

    if (::type(object) == "table") {
      if (filter(object))
        return null

      local tag = object?.t ?? object?.tag
      if (!("v" in object))
        object = object.__merge({v=null})

      if (tag==null)
        return formatters["def"](object, formatAstFunc, style)
      if (tag in formatters)
        return formatters[tag](object, formatAstFunc, style)
      return unknownTag(object)
    }
    local ret = []
    if (::type(object) == "array") {
      foreach (t in object)
        ret.append(formatAstFunc(t))
    }
    return {
      children = ret
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = style?.lineGaps
    }.__update(params ?? {})
  }
})

return mkFormatAst
 