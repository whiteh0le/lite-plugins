local common = require "core.common"
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
  self.selection = {
    a = { byte = 0, nibble = 0 },
    b = { byte = 0, nibble = 0 },
    mode = "normal"
  }
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
  return a.byte, a.nibble, b.byte, b.nibble
end


function HexDoc:set_selection(byte1, nibble1, byte2, nibble2)
  local a, b = self.selection.a, self.selection.b
  byte1, nibble1 = self:sanitize_position(byte1, nibble1)
  byte2, nibble2 = self:sanitize_position(byte2 or byte1, nibble2 or nibble1)

  a.byte, a.nibble, b.byte, b.nibble = byte1, nibble1, byte2, nibble2
end


function HexDoc:sanitize_position(byte, nibble)
  byte = common.clamp(byte, 0, #self.bytes - 1)
  nibble = common.clamp(nibble, 0, 2)

  return byte, nibble
end


function HexDoc:move_to(fn)
  local byte, nibble = self:get_selection()
  byte, nibble = fn(byte, nibble, self)
  self:set_selection(byte, nibble)
end

return HexDoc
