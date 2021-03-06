local sessionId =  require("ui/hud/state/session_id.nut")

return function(){
  return {
    text = sessionId.value
    rendObj = ROBJ_DTEXT
    opacity = 0.5
    color = Color(120,120,120, 100)
    font = Fonts.tiny_text
    watch = sessionId
  }
} 