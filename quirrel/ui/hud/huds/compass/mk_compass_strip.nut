local {DEFAULT_TEXT_COLOR} = require("ui/hud/style.nut")
local userPoints = require("ui/hud/huds/compass/compass_user_point.nut")

local lookDirection = {
  data = {
    relativeAngle = 0 // or 'angle' or 'eid'
  }

  transform = {}
  halign = ALIGN_CENTER
  valign = ALIGN_TOP

  rendObj = ROBJ_VECTOR_CANVAS
  size = [hdpx(4), hdpx(8)]
  lineWidth = 2.0
  color = DEFAULT_TEXT_COLOR
  commands = [
    [VECTOR_LINE, 0, -100, 50,  20],
    [VECTOR_LINE, 50, 20, 100, -100],
  ]
}


local function compassElem(text, angle, scale, lineHeight=::hdpx(10)) {

  local res = {
    data = {
      angle = angle // or 'relativeAngle' or 'eid'
    }

    transform = {}
    halign = ALIGN_CENTER
    valign = ALIGN_TOP
    flow = FLOW_VERTICAL

    children = [
      {
        rendObj = ROBJ_VECTOR_CANVAS
        size = [lineHeight, lineHeight]
        lineWidth = max(hdpx(2.8 * scale), 1.1)
        color = DEFAULT_TEXT_COLOR
        commands = [
          [VECTOR_LINE, 50, 0, 50, 100 * scale],
        ]
      }
    ]
  }

  if (text)
    res.children.append(
      {
        rendObj = ROBJ_STEXT
        font = Fonts.big_text
        fontSize = hdpx(22 * scale)
        color = DEFAULT_TEXT_COLOR
        opacity = (scale + 1.0) * 0.5
        text = text
      }
    )

  return res
}

local compassFovSettings = {
        fov = 140         // degrees
        fadeOutZone = 30  // degrees
      }

const bigCharScaleDef = 0.85
const medCharScaleDef = 0.7
const smallCharScaleDef = 0.5

local defaultsCompassObject = [
  {watch = userPoints, childrenCtor = @() userPoints.value}
]

local defaultSize = [hdpx(400), hdpx(30)]
local defaultPos = [0, sh(4)]
local mkCompassStrip = ::kwarg(function mkCompassStripImlp(size = defaultSize,
      pos = defaultPos, compassObjects=[], globalScale = 1.0,
      bigCharScale=bigCharScaleDef, medCharScale = medCharScaleDef, smallCharScale = smallCharScaleDef, hplace = ALIGN_CENTER,
      showCompass = null
  ) {
  bigCharScale = bigCharScale*globalScale
  medCharScale = medCharScale*globalScale
  showCompass = showCompass ?? Watched(true)
  smallCharScale = smallCharScale*globalScale
  local children = ((clone defaultsCompassObject).extend(compassObjects)).map(@(v) @(){
        size = flex()
        data = compassFovSettings
        behavior = Behaviors.PlaceOnCompassStrip
        watch = v.watch
        halign = ALIGN_CENTER
        children = v.childrenCtor()
      }
    )
  return @(){
    pos = pos
    size = size
    hplace = hplace
    watch = showCompass
    children = !showCompass.value? null : [
      {
        size = flex()
        data = compassFovSettings
        behavior = Behaviors.PlaceOnCompassStrip
        halign = ALIGN_CENTER

        children = [
          compassElem("N",  15 * 0,  bigCharScale)
          compassElem((15 * 1).tostring(), 15 * 1,  smallCharScale)
          compassElem((15 * 2).tostring(), 15 * 2,  smallCharScale)
          compassElem("NE", 15 * 3,  medCharScale)
          compassElem((15 * 4).tostring(), 15 * 4,  smallCharScale)
          compassElem((15 * 5).tostring(), 15 * 5,  smallCharScale)
          compassElem("E",  15 * 6,  bigCharScale)
          compassElem((15 * 7).tostring(), 15 * 7,  smallCharScale)
          compassElem((15 * 8).tostring(), 15 * 8,  smallCharScale)
          compassElem("SE", 15 * 9,  medCharScale)
          compassElem((15 * 10).tostring(), 15 * 10, smallCharScale)
          compassElem((15 * 11).tostring(), 15 * 11, smallCharScale)
          compassElem("S",  15 * 12, bigCharScale)
          compassElem((15 * 13).tostring(), 15 * 13, smallCharScale)
          compassElem((15 * 14).tostring(), 15 * 14, smallCharScale)
          compassElem("SW", 15 * 15, medCharScale)
          compassElem((15 * 16).tostring(), 15 * 16, smallCharScale)
          compassElem((15 * 17).tostring(), 15 * 17, smallCharScale)
          compassElem("W",  15 * 18, bigCharScale)
          compassElem((15 * 19).tostring(), 15 * 19, smallCharScale)
          compassElem((15 * 20).tostring(), 15 * 20, smallCharScale)
          compassElem("NW", 15 * 21, medCharScale)
          compassElem((15 * 22).tostring(), 15 * 22, smallCharScale)
          compassElem((15 * 23).tostring(), 15 * 23, smallCharScale)
          lookDirection
        ]
      }
    ].extend(children)
  }
})


return mkCompassStrip
 