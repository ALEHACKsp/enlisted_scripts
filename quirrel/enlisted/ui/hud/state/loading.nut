local loadingImages = Watched()

::ecs.register_es("loading_images_ui_es",{
    function onInit(eid, comp){
      local images = comp.loading_images?.getAll()
      loadingImages((images?.len() ?? 0) > 0 ? images : null)
    }
    function onDestroy(eid, comp){
      loadingImages(null)
    }
  },
  {comps_ro = [["loading_images", ::ecs.TYPE_STRING_LIST]]}
)

return {loadingImages} 