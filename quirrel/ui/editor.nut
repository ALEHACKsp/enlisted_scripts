local editor = null
local editorState = null
local showUIinEditor = Watched(false)
local editorIsActive = Watched(false)
local daEditor4 = require_optional("daEditor4")
if (daEditor4 != null) {
  editor = require_optional("ui/editor/editor.nut")
  editorState = require_optional("ui/editor/state.nut")
  editorState.extraPropPanelCtors.update(@(v) v.append(require("editorCustomView.nut")))
  showUIinEditor = editorState.showUI
  editorIsActive = editorState.editorIsActive
}

return {
  editor, showUIinEditor, editorIsActive
} 