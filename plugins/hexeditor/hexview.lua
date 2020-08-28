local common = require "core.common"
local core = require "core"
local config = require "core.config"
local encoding = require "plugins.hexeditor.encoding"
local style = require "core.style"
local View = require "core.view"

local RootView = core.root_view

local HexView = View:extend()

local blink_period = 0.8


local function is_even(n)
  return bit32.band(n, 0x1) == 0
end


local function build_header(self)
  local buffer = {}
  for i = 0, self.doc.bpr - 1 do
    table.insert(buffer, string.format("%02X", i))
  end
  self.header = table.concat(buffer, " ")
end


HexView.translate = {
  ["beginning_of_file"] = function(byte, nibble)
    return 0, 0
  end,

  ["end_of_file"] = function(byte, nibble, hd)
    return math.huge, 2
  end,

  ["beginning_of_row"] = function(byte, nibble, hd)
    byte = byte - (byte + hd.offset) % hd.bpr
    nibble = 0

    return byte, nibble
  end,

  ["end_of_row"] = function(byte, nibble, hd)
    byte = byte + (hd.bpr - 1 - (byte + hd.offset) % hd.bpr)
    nibble = 2

    return byte, nibble
  end,

  ["next_byte"] = function(byte, nibble, hd)
    byte = byte + 1
    nibble = byte ~= #hd.bytes and 0 or 2

    return byte, nibble
  end,

  ["next_nibble"] = function(byte, nibble, hd)
    byte = byte + math.ceil(nibble / 2)
    if byte ~= #hd.bytes then
      nibble = (nibble + 1) % 2
    else
      nibble = nibble ~= 0 and 2 or 1
    end

    return byte, nibble
  end,

  ["next_row"] = function(byte, nibble, hd)
    if #hd.bytes - byte > hd.bpr then
      byte = byte + hd.bpr
    end

    return byte, nibble
  end,

  ["previous_byte"] = function(byte, nibble)
    byte = byte - (nibble ~= 2 and 1 or 0)
    nibble = 0

    return byte, nibble
  end,

  ["previous_nibble"] = function(byte, nibble)
    if byte ~= 0 or nibble ~= 0 then
      byte = byte - (nibble == 0 and 1 or 0)
      nibble = (nibble - 1) % 2
    end

    return byte, nibble
  end,

  ["previous_row"] = function(byte, nibble, hd)
    if byte >= hd.bpr then
      byte = byte - hd.bpr
    end

    return byte, nibble
  end,
}


function HexView:new(hexdoc)
  HexView.super.new(self)
  self.blink_timer = 0
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
  return math.max(0, math.ceil((#self.doc.bytes + self.doc.offset) / self.doc.bpr) - 1)
end


-- Calculate the width of the space occupied by the numbers
function HexView:get_line_margin_width()
  local ln_hex = string.format("%X", get_last_line_number(self) * self.doc.bpr)
  return self:get_font():get_width(ln_hex) + style.padding.x * 2
end


function HexView:get_scrollable_size()
  local lh = self:get_line_height()
  return lh * (get_last_line_number(self) + (self.size.y / lh))
end


function HexView:get_visible_line_range()
  local _, y, _, y2 = self:get_content_bounds()
  local lh = self:get_line_height()
  local minline = math.floor(y / lh)
  local maxline = math.min(get_last_line_number(self), math.floor(y2 / lh))

  return minline, maxline
end


function HexView:get_caret_x_offset_hex(x, byte, nibble)
  byte = (byte + self.doc.offset) % self.doc.bpr
  local cw = get_char_width(self)
  return x + (byte * cw * 2) + (byte * cw) + (nibble * cw)
end


function HexView:get_caret_x_offset_text(x, byte, nibble)
  local cw = get_char_width(self)
  return x + ((byte + self.doc.offset) % self.doc.bpr + math.floor(nibble / 2)) * cw
end


function HexView:scroll_to_line()
  -- TODO
end


function HexView:set_bytes_per_row(bpr)
  self.doc.bpr = common.clamp(bpr, 1, 255)
  build_header(self)
end


function HexView:update()
  local byte, nibble = self.doc:get_selection()
  if (byte ~= self.last_byte or nibble ~= self.last_nibble) and self.size.x > 0 then
    if core.active_view == self then
      --self:scroll_to_make_visible(byte, nibble)
    end
    self.blink_timer = 0
    self.last_byte, self.last_nibble = byte, nibble
  end

  if self == core.active_view then
    local n = blink_period / 2
    local prev = self.blink_timer
    self.blink_timer = (self.blink_timer + 1 / config.fps) % blink_period
    if (self.blink_timer > n) ~= (prev > n) then
      core.redraw = true
    end
  end

  self.super.update(self)
end


function HexView:draw_header_margin(x, y)
  local color = style.line_number
  local font = self:get_font()
  x = x + self:get_line_margin_width()
  y = y + style.padding.y

  local hx = renderer.draw_text(font, self.header, x, y, color)
  renderer.draw_text(font, "Text", hx + style.padding.x, y, color)
end


function HexView:draw_adress_margin(idx, x, y)
  local doc = self.doc
  local color = style.line_number
  local byte1, _, byte2, _ = doc:get_selection()
  local row1, row2 = math.floor((byte1 + doc.offset) / doc.bpr), math.floor((byte2 + doc.offset) / doc.bpr)
  if idx >= row1 and idx <= row2 then
    color = style.line_number2
  end

  x = x + style.padding.x
  local maxline_hex = string.format("%X", get_last_line_number(self) * doc.bpr)
  local fmt = "%0" .. #maxline_hex .. "X"
  renderer.draw_text(self:get_font(), string.format(fmt, math.max(0, idx * doc.bpr - doc.offset)), x, y, color)
end


-- Gets the row with its values converted into hex
-- and separated between even an odd columns
local function get_row(self, line)
  local doc = self.doc
  local byte_offset = line * doc.bpr
  local i = 0
  local res = {}
  res.even, res.odd = {}, {}

  -- If the first line is not complete, that is,
  -- if it's length is not equal to the bytes per row of the file,
  -- grab only the bytes that we want to draw.
  doc.bytes
    :sub(byte_offset + 1 - (line ~= 0 and doc.offset or 0), byte_offset + doc.bpr - doc.offset)
    :gsub(".", function(byte)
      -- Separate the bytes into two tables depending on whether
      -- they are in an odd or even column
      table.insert(is_even(i) and res.even or res.odd, string.format("%02X", byte:byte()))
      i = i + 1
    end)

  return res
end


local function prepare_col(col)
  return table.concat(col, "    ")
end


local function draw_row(self, line, row, x, y)
  local doc = self.doc
  local font = self:get_font()
  local odd_offset = font:get_width("   ") -- Separation between even and odd items
  local row_displacement = (line == 0) and odd_offset * doc.offset or 0 -- Align the first row to the right

  local color_even = style.hex_col_even
  local color_odd = style.hex_col_odd
  -- line zero is a special case, because is aligned to the rigth,
  -- the different types of columns will always get the same color without
  -- cheking if they are even or odd
  if line == 0 then
    color_even = is_even(doc.offset) and style.hex_col_even or style.hex_col_odd
    color_odd = is_even(doc.offset) and style.hex_col_odd or style.hex_col_even
  end

  renderer.draw_text(font, prepare_col(row.even), x + row_displacement, y, color_even)
  renderer.draw_text(font, prepare_col(row.odd), x + odd_offset + row_displacement, y, color_odd)
end


function HexView:draw_hex_area(line, x, y)
  local doc = self.doc

  x = x + self:get_line_margin_width()

  local row = get_row(self, line)
  draw_row(self, line, row, x, y)

  -- Draw caret
  local byte1, nibble1 = doc:get_selection()
  local caret_row = math.floor((byte1 + doc.offset) / doc.bpr)
  if line == caret_row
  and self.blink_timer < blink_period / 2
  and system.window_has_focus() then
    local lh = self:get_line_height()
    local x1 = self:get_caret_x_offset_hex(x, byte1, nibble1)
    renderer.draw_rect(x1, y, style.caret_width, lh, style.caret)
  end
end


function HexView:draw_text_area(line, x, y)
  local doc = self.doc
  local byte_offset = line * doc.bpr
  local color = style.hex_normal
  local font = self:get_font()
  local text_row = doc.bytes:sub(byte_offset + 1 - (line ~= 0 and doc.offset or 0), byte_offset + doc.bpr - doc.offset)
  local header_width = font:get_width(self.header)
  x = x + self:get_line_margin_width() + header_width + style.padding.x

  local hex_row = {}
  text_row:gsub(".", function(byte)
    table.insert(hex_row, encoding.get(self.encoding)[byte:byte() + 1])
  end)

  local row_displacement = line == 0 and (doc.bpr - #hex_row) * get_char_width(self) or 0
  renderer.draw_text(font, table.concat(hex_row), x + row_displacement, y, color)

  -- Draw caret
  local byte1, nibble1 = doc:get_selection()
  local caret_row = math.floor((byte1 + doc.offset) / doc.bpr)
  if line == caret_row
  and self.blink_timer < blink_period / 2
  and system.window_has_focus() then
    local lh = self:get_line_height()
    local x1 = self:get_caret_x_offset_text(x, byte1 % doc.bpr, nibble1)
    renderer.draw_rect(x1, y, style.caret_width, lh, style.caret)
  end
end


function HexView:draw()
  self:draw_background(style.background)

  local hmh = self:get_header_margin_height()
  local lh = self:get_line_height()
  local minline, maxline = self:get_visible_line_range()
  local pos, size = self.position, self.size
  local x, y = pos.x, pos.y

  -- Draw header
  self:draw_header_margin(x, y)

  y = y + hmh
  core.push_clip_rect(x, y, size.x, size.y - hmh)
  for i = minline, maxline do
    self:draw_adress_margin(i, x, y)
    self:draw_hex_area(i, x, y)
    self:draw_text_area(i, x, y)

    y = y + lh
  end
  core.pop_clip_rect()

  self:draw_scrollbar()
end


return HexView
