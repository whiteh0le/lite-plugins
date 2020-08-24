local config = require "core.config"
local core = require "core"
local Object = require "core.object"
local DocView = require "core.docview"

local HexDoc = Object:extend()


function HexDoc:new(filename)
  self:reset()
  if filename then
    self:load(filename)
  end
end


function HexDoc:load(filename)
  local fh = assert(io.open(filename, "rb"))
  self.filename = filename
  self.bytes = fh:read("*a")
  fh:close()
end


function HexDoc:reset()
  self.bpr = config.bytes_per_row
  self.bytes = ""
  self.selection = { a = { line = 0, col = 0 }, b = { line = 0, col = 0 } }
end


function HexDoc:is_dirty()
  --TODO
  return false
end


function HexDoc:get_name()
  return self.filename or "unsaved"
end


function HexDoc:get_selection()
  local a, b = self.selection.a, self.selection.b
  return a.line, a.col, b.line, b.col
end


function HexDoc:sanitize_position(line, col)
  line = common.clamp(line, 0, math.ceil(#self.bytes / self.bpr) - 1)
  col = common.clamp(col, 0, (#self.bytes % self.bpr) * 2)

  return line, col
end


return HexDoc
