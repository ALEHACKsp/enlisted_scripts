local dbgData = ::Watched(null)
local dbgShow = ::Watched(false)
dbgShow.subscribe(function(v) {
  if (!v)
    dbgData(null)
})

return {
  dbgData = dbgData
  dbgShow = dbgShow
} 