local M = {}
M.__index = M
M.title = "New Instruction"

function M.new(editor)
  local instance = setmetatable({}, M)
  instance.editor = assert(editor)
  return instance
end

function M:redo()
  table.insert(self.editor.instructions, {
    operation = "union",
    blending = 0,

    position = {0, 0, 0},
    orientation = {0, 0, 0, 1},

    color = {0.5, 0.5, 0.5, 1},
    shape = {1, 1, 1, 1},
  })

  self.editor.selection = #self.editor.instructions
  self.editor:remesh()
end

function M:undo()
  table.remove(self.editor.instructions)
  self.editor.selection = nil -- TODO: Update selection
  self.editor:remesh()
end

return M
