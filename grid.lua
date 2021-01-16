Grid = {}
Grid.__index = Grid

function Grid:new(cols, rows, light_color, dark_color, outline_color)
  local g = {
    cols = cols,
    rows = rows,
    light_color = light_color,
    dark_color = dark_color,
    outline_color = outline_color,
    dots = {}
  }
  setmetatable(g, self)
  return g
end

function Grid.colorToString(color)
  return color[1] .. "," .. color[2] .. "," .. color[3]
end

function Grid.stringToColor(str)
  red, green, blue = str:match("([^,]+),%s*([^,]+),%s*([^,]+)")
  return { tonumber(red), tonumber(green), tonumber(blue) }
end

function Grid.dot(fill_color, outline_color)
  return { fill_color = fill_color, outline_color = outline_color }
end

function Grid:getDot(col, row)
  return self.dots[col..":"..row] -- or self:getDarkDot()
end

function Grid:getDarkDot()
  return Grid.dot(self.dark_color, self.outline_color)
end

function Grid:getLightDot()
  return Grid.dot(self.light_color, self.outline_color)
end

function Grid:setDot(col, row, dot)
  self.dots[col..":"..row] = dot
end

function Grid:setDarkDot(col, row)
  self:setDot(col, row, self:getDarkDot())
end

function Grid:setLightDot(col, row)
  self:setDot(col, row, self:getLightDot())
end

function Grid:copyDot(fromCol, fromRow, toCol, toRow)
  dot = self:getDot(fromCol, fromRow)
  self:setDot(toCol, toRow, dot)
end

function Grid:clear()
  for row = 0, self.rows - 1 do
    for col = 0, self.cols - 1 do
      self:setDarkDot(col, row)
    end
  end
end

function Grid:scrollLeft()
  for row = 0, self.rows - 1 do
    for col = 1, self.cols - 1 do
      self:copyDot(col, row, col - 1, row)
    end
  end
end

function Grid:scrollRight()
  for row = 0, self.rows - 1 do
    for col = self.cols - 2, 0, -1 do
      self:copyDot(col, row, col + 1, row)
    end
  end
end

function Grid:scrollUp()
  for row = 1, self.rows - 1 do
    for col = 0, self.cols - 1 do
      self:copyDot(col, row, col, row - 1)
    end
  end
end

function Grid:scrollDown()
  for row = self.rows - 2, 0, -1 do
    for col = 0, self.cols - 1 do
      self:copyDot(col, row, col, row + 1)
    end
  end
end
