local colors = {
  MenuRowBgOdd   = Color(20, 20, 20, 20)
  MenuRowBgEven  = Color(0, 0, 0, 0)
  MenuRowBgHover = Color(40, 40, 40, 40)
}
colors.menuRowColor <- function(sf, isOdd) {
    return (sf & S_HOVER) ? colors.MenuRowBgHover
           : isOdd ? colors.MenuRowBgOdd
           : colors.MenuRowBgEven
}
return colors
 