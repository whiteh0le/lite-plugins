local command = require "core.command"
local common = require "core.common"
local core = require "core"
local StatusView = require "core.statusview"
local style = require "core.style"

local HexDoc = require "plugins.hexeditor.hexdoc"
local HexView = require "plugins.hexeditor.hexview"

local hex = {}
hex.docs = {}


local function hd()
  return core.active_view.doc
end


local function hv()
  return core.active_view
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
require "plugins.hexeditor.commands.hexview"
require "plugins.hexeditor.config"
require "plugins.hexeditor.keymap"
require "plugins.hexeditor.style"


local get_items = StatusView.get_items
function StatusView:get_items()
  local left, right = get_items(self)
  if (core.active_view:is(HexView)) then
    local doc = hd()
    local hView = hv()
    local dirty = doc:is_dirty()

    left, right = {
      dirty and style.accent or style.text, style.icon_font, "f",
      style.dim, style.font, StatusView.separator2,
      style.text, doc.filename,
      style.dim, StatusView.separator,
      style.text, "cursor: ", string.format("%X", doc:get_effective_position())
    }, {
      style.text, style.icon_font, "g",
      style.dim, style.font, StatusView.separator2,
      style.text, hView.encoding,
      style.dim, StatusView.separator,
      style.text, doc.bpr, " bpr",
      style.dim, StatusView.separator,
      style.text, string.format("%X", #doc.bytes), " bytes"
    }
  end

  return left, right
end
--[[local view = InspectView()
local node = core.root_view:get_active_node()
node:split("right", view, true)
--]]

command.add(nil, {
  ["hex:open-file"] = function()
    core.command_view:enter("Open File as Hex", function(filename)
      HexView:open_doc(hex.open_doc(filename))
    end, common.path_suggest)
  end,
})


return hex
