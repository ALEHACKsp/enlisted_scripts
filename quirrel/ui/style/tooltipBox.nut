return @(content) {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = Color(30, 30, 30, 160)
  size = SIZE_TO_CONTENT
  children = {
    rendObj = ROBJ_FRAME
    size = SIZE_TO_CONTENT
    color =  Color(50, 50, 50, 20)
    borderWidth = hdpx(1)
    padding = sh(1)
    children = content
  }
} 