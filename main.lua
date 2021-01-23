require "run"
require "grid"

io.stdout:setvbuf("no")

local CHARS = 8
local CHAR_WIDTH = 8
local CHAR_HEIGHT = 16

function setFont(name)
  local hinting = "mono"
  local size = viewGrid.rows
  while true do
    if name == nil or name == "default" then
      font = love.graphics.newFont(size, hinting)
    else
      font = love.graphics.newFont("fonts/"..name, size, hinting)
    end

    -- Font may be a little too big; strangely the size is just a "request"
    if font:getHeight() > viewGrid.rows and size > 1 then
      size = size - 1
    else
      break
    end
  end
end

function currentAction()
  return actions[action]
end

function actionCommand(a)
  a = a or currentAction()
  return a.command
end

function actionText(a)
  a = a or currentAction()
  return a.text
end

function invisibleAction(a)
  local cmd = actionCommand(a)
  return cmd == "C" or cmd == "F" or cmd == "LC" or cmd == "DC" or cmd == "OC" or cmd == "FPS"
end

function handleInvisibleAction()
  local cmd = actionCommand()
  local text = actionText()

  if cmd == "C" then
    viewGrid.dark_color = dark_color
    viewGrid.outline_color = outline_color
    viewGrid:clear()
  elseif cmd == "F" then
    setFont(text)
  elseif cmd == "LC" then
    light_color = Grid.stringToColor(text)
  elseif cmd == "DC" then
    dark_color = Grid.stringToColor(text)
  elseif cmd == "OC" then
    outline_color = Grid.stringToColor(text)
  elseif cmd == "FPS" then
    fps = tonumber(text)
  end
end

function addAction(command, text)
  actions[actions.size] = { command = command, text = text }
  actions.size = actions.size + 1
end

function addActionLine(line)
  if line:match("^#") then return end
  if line:match("^%s*$") then return end

  local command = line
  local text = ""
  local pos = line:find(" ")
  if pos ~= nil then
    command = line:sub(1, pos - 1)
    text = line:sub(pos + 1, -1)
  end
  addAction(command, text)
end

-- Ensure there is at least one visible action; otherwise, the program will hang.
function ensureOneVisibleAction()
  local haveVisibleActions = false
  for i = 0, actions.size - 1 do
    if not invisibleAction(actions[i]) then haveVisibleActions = true end
  end
  if not haveVisibleActions then addAction("S", "") end
end

function loadActions(filename)
  actions = { size = 0 }
  addAction("FPS", "40")
  addAction("F", "default")
  addAction("LC", Grid.colorToString(light_color))
  addAction("DC", Grid.colorToString(dark_color))
  addAction("OC", Grid.colorToString(outline_color))

  local lines
  if filename then
    lines = io.lines(filename)
  else
    lines = love.filesystem.lines("messages/example.txt")
  end
  for line in lines do
    addActionLine(line)
  end
  ensureOneVisibleAction()

  action = -1
  step = 0
  steps = 1
  substep = 0
  substeps = 1
end

function initViewGrid()
  viewGrid = Grid:new(CHARS * CHAR_WIDTH, CHAR_HEIGHT, light_color, dark_color, outline_color)
  viewGrid:clear()
end

function love.load(arg)
  showfps = true

  light_color = { 0.85, 0, 0 }
  dark_color = { 0, 0, 0 }
  outline_color = { 1, 0.5, 0.5 }

  initViewGrid()
  setFont()
  loadActions(arg[1])
end

function love.keypressed(key, scancode, isrepeat)
  if key == "escape" then
    love.event.quit()
  elseif key == "f" then
    love.window.setFullscreen(not love.window.getFullscreen())
  elseif key == "f1" then
    showfps = not showfps
  end
end

function calculateActionSteps()
  steps = 1
  substeps = 1

  local cmd = actionCommand()
  local text = actionText()

  if cmd == "W" then
    steps = math.floor(fps * tonumber(text))
    if steps < 1 then steps = 1 end
  elseif cmd == "S" then
    steps = 1
  elseif cmd == "SL" or cmd == "SR" then
    steps = sourceGrid.cols
  elseif cmd == "SU" or cmd == "SD" then
    steps = sourceGrid.rows
  end

  -- TODO
end

function updateSourceGrid()
  -- Create text drawing object with the text of the current action.
  local text = love.graphics.newText(font, actionText())

  -- Create canvas to hold text.
  local width = text:getWidth()
  local height = viewGrid.rows -- should match text:getHeight()
  if width < 1 then width = 1 end
  local canvas = love.graphics.newCanvas(width, height)

  -- Print text on canvas.
  canvas:renderTo(function()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(text)
  end);

  -- Copy canvas to source grid.
  local imageData = canvas:newImageData()
  sourceGrid = Grid:new(width, height, light_color, dark_color, outline_color)
  for row = 0, sourceGrid.rows - 1 do
    for col = 0, sourceGrid.cols - 1 do
      local r, g, b = imageData:getPixel(col, row)
      if r == 1 and g == 1 and b == 1 then
        sourceGrid:setLightDot(col, row)
      else
        sourceGrid:setDarkDot(col, row)
      end
    end
  end
end

function moveToNextStep()
  substep = substep + 1
  if substep >= substeps then
    substep = 0
    step = step + 1
    if step >= steps then
      step = 0
      action = action + 1
      if action >= actions.size then action = 0 end
      if invisibleAction() then
        handleInvisibleAction()
      else
        updateSourceGrid()
      end
      calculateActionSteps()
    end
  end
end

-- returns padLeft, columns
function centerSource()
  if sourceGrid.cols > viewGrid.cols then
    return 0, viewGrid.cols
  else
    return math.floor((viewGrid.cols - sourceGrid.cols) / 2), sourceGrid.cols
  end
end

function updateViewGrid_Show()
  local padLeft, cols = centerSource()

  for row = 0, viewGrid.rows - 1 do
    for col = 0, cols - 1 do
      local dot = sourceGrid:getDot(col, row)
      viewGrid:setDot(padLeft + col, row, dot)
    end
  end
end

function updateViewGrid_ScrollLeft()
  viewGrid:scrollLeft()

  local col = viewGrid.cols - 1
  for row = 0, viewGrid.rows - 1 do
    local dot = sourceGrid:getDot(step, row)
    viewGrid:setDot(col, row, dot)
  end
end

function updateViewGrid_ScrollRight()
  viewGrid:scrollRight()

  local col = 0
  for row = 0, viewGrid.rows - 1 do
    local dot = sourceGrid:getDot(sourceGrid.cols - 1 - step, row)
    viewGrid:setDot(col, row, dot)
  end
end

function updateViewGrid_ScrollUp()
  viewGrid:scrollUp()

  local padLeft, cols = centerSource()
  local row = viewGrid.rows - 1
  for col = 0, padLeft - 1 do
    viewGrid:setDarkDot(col, row)
  end
  for col = 0, cols - 1 do
    local dot = sourceGrid:getDot(col, step)
    viewGrid:setDot(padLeft + col, row, dot)
  end
  for col = padLeft + cols, viewGrid.cols - 1 do
    viewGrid:setDarkDot(col, row)
  end
end

function updateViewGrid_ScrollDown()
  viewGrid:scrollDown()

  local padLeft, cols = centerSource()
  local row = 0
  for col = 0, padLeft - 1 do
    viewGrid:setDarkDot(col, row)
  end
  for col = 0, cols - 1 do
    local dot = sourceGrid:getDot(col, sourceGrid.rows - 1 - step)
    viewGrid:setDot(padLeft + col, row, dot)
  end
  for col = padLeft + cols, viewGrid.cols - 1 do
    viewGrid:setDarkDot(col, row)
  end
end

function updateViewGrid()
  local cmd = actionCommand()
  local text = actionText()

  if cmd == "W" then
    -- do nothing to grid
  elseif cmd == "S" then
    updateViewGrid_Show()
  elseif cmd == "SL" then
    updateViewGrid_ScrollLeft()
  elseif cmd == "SR" then
    updateViewGrid_ScrollRight()
  elseif cmd == "SU" then
    updateViewGrid_ScrollUp()
  elseif cmd == "SD" then
    updateViewGrid_ScrollDown()
  end
  -- TODO
end

function love.update(dt)
  repeat
    moveToNextStep()
  until not invisibleAction()
  updateViewGrid()
end

function drawViewGrid()
  local hdiameter = (love.graphics.getWidth() - 1) / viewGrid.cols
  local vdiameter = (love.graphics.getHeight() - 1) / viewGrid.rows
  local diameter = math.min(hdiameter, vdiameter)
  local radius = 0.82 * diameter / 2
  local padTop = (love.graphics.getHeight() - viewGrid.rows * diameter) / 2
  if padTop < 0 then padTop = 0 end

  for row = 0, viewGrid.rows - 1 do
    for col = 0, viewGrid.cols - 1 do
      local x = 1 + col * diameter + radius
      local y = 1 + row * diameter + radius + padTop
      local dot = viewGrid:getDot(col, row)
      love.graphics.setColor(dot.fill_color)
      love.graphics.circle("fill", x, y, radius)
      love.graphics.setColor(dot.outline_color)
      love.graphics.circle("line", x, y, radius)
    end
  end
end

function drawFps()
  local text = tostring(love.timer.getFPS())
  local font = love.graphics.getFont()
  local width = font:getWidth(text)
  local x = love.graphics.getWidth() - width
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(text, x, 0)
end

function love.draw()
  drawViewGrid()
  if showfps then drawFps() end
end

