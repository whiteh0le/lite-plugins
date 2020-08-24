local common = require "core.common"
local core = require "core"
local config = require "core.config"
local encoding = require "plugins.hexeditor.encoding"
local style = require "core.style"
local View = require "core.view"

local RootView = core.root_view

local HexView = View:extend()


local function build_header(self)
  local buffer = {}
  for i = 0, self.doc.bpr - 1 do
    table.insert(buffer, string.format("%02X", i))
  end
  self.header = table.concat(buffer, " ")
end


function HexView:new(hexdoc)
  HexView.super.new(self)
  self.cursor = "ibeam"
  self.doc = assert(hexdoc)
  self.encoding = config.encoding
  self.font = "code_font"
  self.scrollable = true
  build_header(self)
end


function HexView:open_doc(hexdoc)
  local node = RootView:get_active_node()
  if node.locked and core.last_active_view then
    core.set_active_view(core.last_active_view)
    node = RootView:get_active_node()
  end
  assert(not node.locked, "Cannot open doc on locked node")
  for i, view in ipairs(node.views) do
    if view.doc == hexdoc then
      node:set_active_view(node.views[i])
      return view
    end
  end

  local hView = HexView(hexdoc)
  node:add_view(hView)
  RootView.root_node:update_layout()
  hView:scroll_to_line(hView.doc:get_selection(), true, true)
  return hView
end


function HexView:get_name()
  local post = self.doc:is_dirty() and "*" or ""
  local name = self.doc:get_name()

  return name:match("[^/%\\]*$") .. post
end


function HexView:get_font()
  return style[self.font]
end


local function get_char_width(self)
  return self:get_font():get_width(' ')
end


-- Calculate the height of the space occupied by the header
function HexView:get_header_margin_height()
  return self:get_line_height() + style.padding.y * 2
end


function HexView:get_line_height()
  return math.floor(self:get_font():get_height() * config.line_height)
end


local function get_last_line_number(self)
  return math.max(0, math.ceil(#self.doc.bytes / self.doc.bpr) - 1)
end


-- Calculate the width of the space occupied by the numbers
function HexView:get_line_margin_width()
  local ln_hex = string.format("%X", get_last_line_number(self) * self.doc.bpr)
  return self:get_font():get_width(ln_hex) + style.padding.x * 2
end


function HexView:get_scrollable_size()
  local minline, maxline = self:get_visible_line_range()
  local lh = self:get_line_height()
  return lh * (get_last_line_number(self) + (self.size.y / lh))
end


function HexView:get_visible_line_range()
  local _, y, _, y2 = self:get_content_bounds()
  local lh = self:get_line_height()
  local minline = math.max(0, math.floor(y / lh))
  local maxline = math.min(get_last_line_number(self), math.floor(y2 / lh))

  return minline, maxline
end


function HexView:get_x_offset_hex(x, col)
  local cw = get_char_width(self)
  return x + (col * cw) + (math.floor(col / 2) * cw)
end


function HexView:get_x_offset_text(x, col)
  local cw = get_char_width(self)
  return x + (math.floor(col / 2) * cw)
end


function HexView:scroll_to_line()
  -- TODO
end


function HexView:set_bytes_per_row(bpr)
  self.doc.bpr = common.clamp(bpr, 1, 255)
  build_header(self)
end


function HexView:draw_header_margin(x, y)
  local color = style.line_number
  local font = self:get_font()
  local header_width = font:get_width(self.header) + style.padding.x

  renderer.draw_text(font, self.header, x, y, color)
  renderer.draw_text(font, "Text", x + header_width, y, color)
end


function HexView:draw_line_margin(idx, x, y)
  local color = style.line_number
  local line1, _, line2, _ = self.doc:get_selection(true)
  if idx >= line1 and idx <= line2 then
    color = style.line_number2
  end

  -- TODO cache the results
  x = x + style.padding.x
  local maxline_hex = string.format("%X", get_last_line_number(self) * self.doc.bpr)
  local fmt = "%0" .. #maxline_hex .. "X"
  renderer.draw_text(self:get_font(), string.format(fmt, idx * self.doc.bpr), x, y, color)
end


function HexView:draw_hex(line, x, y)
  local byte_offset = line * self.doc.bpr
  local color = style.syntax["normal"]
  local font = self:get_font()
  local text_row = self.doc.bytes:sub(byte_offset + 1, byte_offset + self.doc.bpr)

  -- TODO cache the results
  local hex_row = {}
  text_row:gsub(".", function(byte)
    table.insert(hex_row, string.format("%02X", byte:byte()))
  end)

  renderer.draw_text(font, table.concat(hex_row, " "), x, y, color)

  -- Draw caret
  local line1, col1, line2, col2 = self.doc:get_selection()
  if (line == line1) then
    local lh = self:get_line_height()
    local x1 = self:get_x_offset_hex(x, col1)
    renderer.draw_rect(x1, y, style.caret_width, lh, style.caret)
  end
end


function HexView:draw_text(line, x, y)
  local byte_offset = line * self.doc.bpr
  local color = style.syntax["normal"]
  local font = self:get_font()
  local text_row = self.doc.bytes:sub(byte_offset + 1, byte_offset + self.doc.bpr)

  -- TODO cache the results
  local hex_row = {}
  text_row:gsub(".", function(byte)
    table.insert(hex_row, encoding.get(self.encoding)[byte:byte() + 1])
  end)

  renderer.draw_text(font, table.concat(hex_row), x, y, color)

  -- Draw caret
  local line1, col1, line2, col2 = self.doc:get_selection()
  if (line == line1) then
    local lh = self:get_line_height()
    local x1 = self:get_x_offset_text(x, col1)
    renderer.draw_rect(x1, y, style.caret_width, lh, style.caret)
  end
end


function HexView:draw()
  self:draw_background(style.background)

  local font = self:get_font()
  local hmh = self:get_header_margin_height()
  local lh = self:get_line_height()
  local lmw = self:get_line_margin_width()
  local minline, maxline = self:get_visible_line_range()
  local pos = self.position
  local size = self.size

  -- Draw header
  local x = pos.x + lmw
  local y = pos.y + style.padding.y
  self:draw_header_margin(x, y)

  local header_width = font:get_width(self.header)
  x = pos.x + lmw + header_width + style.padding.x
  y = pos.y + hmh
  core.push_clip_rect(pos.x, pos.y + hmh, size.x, size.y - hmh)
  for i = minline, maxline do
    self:draw_line_margin(i, pos.x, y)
    self:draw_hex(i, pos.x + lmw, y)
    self:draw_text(i, x, y)

    y = y + lh
  end
  core.pop_clip_rect()

  self:draw_scrollbar()
end


return HexView