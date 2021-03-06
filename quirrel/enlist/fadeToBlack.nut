local fadeState = persist("fadeState", @() Watched([]))
local black = Color(0,0,0)
local counter = 0
local doFade = kwarg(function(fadein, fadeout=null, color = black, cb = null, id = null){
  counter++
  fadeState(@(value) value.append({fadein=fadein, fadeout=fadeout ?? fadein, color=color, cb=cb, id=id ?? counter}))
})
/*
todo:
this is very dirty implementation. It doesnt work well with several fadeouts started
what we really need is on addFade combine all actions in one and perfrom them on first black time
like:
'first': toBlack = 0.5, out = 0.5, cb = @() do1()
'second': toBlack = 0.7, out = 0.7, cb = @() do2()
result:
  toBlack = 0.5 inBlack=0.2 out =0.7, onBlack = do1();do2()
add onFullBlack, onBlackExit and onTime callbacks types (to do exactly onTime, onFullBlack and on startBlackOut)
probably the best way to do it is to do everything on poll (which we can start only if not empty fades)
*/
local function removeFade(id){
  local fs = fadeState.value
  local idx = fs.findindex(@(v) v.id==id)
  if (idx!=null){
    fs.remove(idx)
    fadeState.trigger()
  }
}
local function mkFs(fs){
  return {
    size = flex()
    key = fs.id
    color = fs?.color ?? black
    rendObj = ROBJ_SOLID
    onDetach = @() fs?.cb?()
    animations = [
      { prop=AnimProp.opacity, from=0, to=1, duration=fs?.fadein ?? 0.5, play=true, loop=false, onFinish = function() {removeFade(fs.id)}}
      { prop=AnimProp.opacity, from=1, to=0, duration=fs?.fadeout ?? 0.5, playFadeOut=true, loop=false }
    ]
  }
}
local function ui(){
  return {
    watch = fadeState
    children = fadeState.value.map(mkFs)
    size = flex()
  }
}
return {
  fade = doFade
  ui = ui
} 