local command = require "core.command"
local common = require "core.common"
local config = require "core.config"
local core = require "core"
local keymap = require "core.keymap"
local StatusView = require "core.statusview"
local style = require "core.style"
local View = require "core.view"

local encoding = require "plugins.hexeditor.encoding"
local HexDoc = require "plugins.hexeditor.hexdoc"
local HexView = require "plugins.hexeditor.hexview"

config.bytes_per_row = 16
config.encoding = "ASCII+ANSI"
config.hexinspector_size = 200 * SCALE

local hex = {}
hex.docs = {}


local function hv()
  return core.active_view
end


local function hd()
  return core.active_view.doc
end

-- Try to open the file with the given filename,
-- if the file is already open, return that instead
function hex.open_doc(filename)
  if filename then
    local abs_filename = system.absolute_path(filename)
    for _, doc in pairs(hex.docs) do
      if doc.filename
      and system.absolute_path(doc.filename) == abs_filename then
        return doc
      end
    end

    local doc = HexDoc(filename)
    table.insert(hex.docs, doc)
    core.log_quiet(filename and "Opened hex doc \"%s\"" or "Opened new hex doc", filename)
    return doc
  end
end

-- init
command.add(nil, {
  ["hex:open-file"] = function()
    core.command_view:enter("Open File as Hex", function(filename)
      HexView:open_doc(hex.open_doc(filename))
    end, common.path_suggest)
  end,
})


command.add("plugins.hexeditor.hexview", {
  ["hex:change-bytes-per-row"] = function()
    local hv = hv()
    local bpr = hd().bpr
    core.command_view:enter("Bytes per Row(" .. bpr .. ")", function(bytes)
      hv:set_bytes_per_row(tonumber(bytes) or 16)
    end)
  end,

  ["hex:change-encoding"] = function()
    local enc = core.active_view.encoding
    core.command_view:enter("Encoding(" .. enc .. ")", function(e)
      e = encoding.get(e) and e or config.encoding
      core.active_view.encoding = e
    end, encoding.list)
  end,

  ["hex:move-to-next_byte"] = function()
    local hd = hd()
    local a, b = hd.selection.a, hd.selection.b
    a.col = a.col + 2
    b.col = b.col + 2
  end,

  ["hex:move-to-next_row"] = function()
    local hd = hd()
    local a, b = hd.selection.a, hd.selection.b
    a.line = a.line + 1
    b.line = b.line + 1
  end,

  ["hex:move-to-previous_byte"] = function()
    local hd = hd()
    local a, b = hd.selection.a, hd.selection.b
    a.col = a.col - 2
    b.col = b.col - 2
  end,

  ["hex:move-to-previous_row"] = function()
    local hd = hd()
    local a, b = hd.selection.a, hd.selection.b
    a.line = a.line - 1
    b.line = b.line - 1
  end,
})


local get_items = StatusView.get_items
function StatusView:get_items()
  local left, right = get_items(self)
  if (core.active_view:is(HexView)) then
    local hv = core.active_view
    local hd = hv.doc
    local dirty = hd:is_dirty()

    left, right = {
      dirty and style.accent or style.text, style.icon_font, "f",
      style.dim, style.font, StatusView.separator2,
      style.text, hd.filename
    }, {
      style.text, style.icon_font, "g",
      style.dim, style.font, StatusView.separator2,
      style.text, hv.encoding,
      style.dim, StatusView.separator,
      style.text, hd.bpr, " bpr",
      style.dim, StatusView.separator,
      style.text, string.format("0x%X", #hd.bytes), " bytes"
    }
  end

  return left, right
end
--[[local view = InspectView()
local node = core.root_view:get_active_node()
node:split("right", view, true)
--]]


keymap.add {
  ["right"]  = "hex:move-to-next_byte",
  ["down"]   = "hex:move-to-next_row",
  ["left"]   = "hex:move-to-previous_byte",
  ["up"]     = "hex:move-to-previous_row",
  ["ctrl+right"]  = "hex:move-to-next_nibble",
  ["ctrl+left"]   = "hex:move-to-previous_nibble",
  ["ctrl+h"] = "hex:open-file",
  ["alt+e"]  = "hex:change-encoding",
  ["alt+b"]  = "hex:change-bytes-per-row",
}


return hex
