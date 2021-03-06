local gutterMath = require("gutter.math")
local RotateCommand = require("gutter.editor.commands.RotateCommand")
local quaternion = require("gutter.quaternion")

local atan2 = math.atan2
local normalize3 = gutterMath.normalize3
local setRotation3 = gutterMath.setRotation3
local transformPoint3 = gutterMath.transformPoint3
local transformVector3 = gutterMath.transformVector3

local M = {}
M.__index = M

function M.new(editor)
  local instance = setmetatable({}, M)
  instance.editor = assert(editor)
  instance.editor.controller = instance

  instance.startScreenX, instance.startScreenY = love.mouse.getPosition()

  local selection = assert(editor.selection)
  local entity = assert(editor.model.children[selection])

  instance.oldOrientation = {unpack(entity.components.orientation)}
  instance.newOrientation = {unpack(entity.components.orientation)}

  return instance
end

function M:destroy()
  self.editor.controller = nil
end

function M:mousemoved(x, y, dx, dy, istouch)
  if self.editor.selection then
    -- TODO: Use camera and viewport transforms kept in sync elsewhere

    local width, height = love.graphics.getDimensions()
    local scale = 0.25

    local viewportTransform = love.math.newTransform():translate(0.5 * width, 0.5 * height):scale(height)

    local cameraTransform = setRotation3(love.math.newTransform(), 0, 1, 0, self.editor.angle):apply(love.math.newTransform():setMatrix(
      scale, 0, 0, 0,
      0, scale, 0, 0,
      0, 0, scale, 0,
      0, 0, 0, 1))

    local worldToScreenTransform = love.math.newTransform():apply(viewportTransform):apply(cameraTransform)
    local screenToWorldTransform = worldToScreenTransform:inverse()

    local axisX, axisY, axisZ = normalize3(transformVector3(screenToWorldTransform, 0, 0, 1))

    local entity = self.editor.model.children[self.editor.selection]

    -- TODO: Use pivot based on selection or camera
    local pivotX, pivotY = transformPoint3(worldToScreenTransform, unpack(entity.components.position))
    local angle1 = atan2(self.startScreenY - pivotY, self.startScreenX - pivotX)
    local angle2 = atan2(y - pivotY, x - pivotX)
    local angle = angle2 - angle1

    local qx1, qy1, qz1, qw1 = unpack(self.oldOrientation)

    local qx2, qy2, qz2, qw2 = quaternion.fromAxisAngle(axisX, axisY, axisZ, angle)

    entity.components.orientation = {quaternion.product(qx2, qy2, qz2, qw2, qx1, qy1, qz1, qw1)}
    self.newOrientation = {unpack(entity.components.orientation)}
    self.editor:remesh()
  end
end

function M:mousereleased(x, y, button, istouch, presses)
  self.editor:doCommand(RotateCommand.new(self.editor, self.oldOrientation, self.newOrientation))
  self:destroy()
end

return M
