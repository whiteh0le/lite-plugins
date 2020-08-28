local core = require "core"
local command = require "core.command"
local config = require "core.config"
local encoding = require "plugins.hexeditor.encoding"
local HexView = require "plugins.hexeditor.hexview"

local function doc()
  return core.active_view.doc
end


local function hv()
  return core.active_view
end


local commands = {}
local translations = {
  ["beginning-of-file"] = HexView.translate.beginning_of_file,
  ["beginning-of-row"]  = HexView.translate.beginning_of_row,
  ["end-of-file"]       = HexView.translate.end_of_file,
  ["end-of-row"]        = HexView.translate.end_of_row,
  ["next-byte"]         = HexView.translate.next_byte,
  ["next-nibble"]       = HexView.translate.next_nibble,
  ["next-row"]          = HexView.translate.next_row,
  ["previous-byte"]     = HexView.translate.previous_byte,
  ["previous-nibble"]   = HexView.translate.previous_nibble,
  ["previous-row"]      = HexView.translate.previous_row,
}


for name, fn in pairs(translations) do
  commands["hex:move-to-" .. name] = function() doc():move_to(fn) end
end


commands["hex:change-bytes-per-row"] = function()
  core.command_view:enter("Bytes per Row(" .. doc().bpr .. ")", function(bytes)
    hv():set_bytes_per_row(tonumber(bytes) or 16)
    doc().offset = doc().offset % doc().bpr
  end)
end


commands["hex:change-encoding"] = function()
  core.command_view:enter("Encoding(" .. hv().encoding .. ")", function(enc)
    enc = encoding.get(enc) and enc or config.encoding
    hv().encoding = enc
  end, encoding.list)
end


commands["hex:reset-doc-offset"] = function()
  doc().offset = 0
end


commands["hex:shift-doc-left"] = function()
  command.perform("hex:move-to-previous-byte")
  local hd = doc()
  local view = hv()
  if hd:get_effective_position() > 0 or hd.offset > 0 then
    hd.offset = (hd.offset + 1) % hd.bpr
    if hd.offset == 0 then
      local new_scroll_y = view.scroll.to.y - view:get_line_height()
      view.scroll.y = new_scroll_y
      view.scroll.to.y = new_scroll_y
    end
  end
end


commands["hex:shift-doc-right"] = function()
  command.perform("hex:move-to-next-byte")
  local hd = doc()
  local view = hv()
  if hd:get_effective_position() < #hd.bytes or hd.offset > 0 then
    if hd.offset == 0 then
      local new_scroll_y = view.scroll.to.y + view:get_line_height()
      view.scroll.y = new_scroll_y
      view.scroll.to.y = new_scroll_y
    end
    hd.offset = (hd.offset - 1) % hd.bpr
  end
end


command.add("plugins.hexeditor.hexview", commands)
