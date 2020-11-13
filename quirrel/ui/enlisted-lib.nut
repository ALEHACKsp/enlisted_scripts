                                                     

local globals = [
  //consider: enumerate all scripts in globals with dagor.scan_files()
  //and require all of them.
  //Con: order can be important; it is bad to have lots of globals
  //Pro: easier to keep them in sync with game scripts
  "globals/ui_library.nut"
  "globals/ecs.nut"
]
foreach (g in globals)
  require(g)

 