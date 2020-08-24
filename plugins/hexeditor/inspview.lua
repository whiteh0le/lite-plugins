--
-- Data inspector view
local InspectView = View:extend()

function InspectView:new()
  InspectView.super.new(self)
  self.scrollable = false
  self.visible = true
  self.init_size = true
  self.cache = {}
end

function InspectView:get_name()
  return "Data Inspector"
end

function InspectView:update()
  -- update width
  local dest = self.visible and config.hexinspector_size or 0
  if self.init_size then
    self.size.x = dest
    self.init_size = false
  else
    self:move_towards(self.size, "x", dest)
  end

  InspectView.super.update(self)
end


function InspectView:draw()
  self:draw_background(style.background2)

  local icon_width = style.icon_font:get_width("D")
  local spacing = style.font:get_width(" ") * 2

  local doc = core.active_view.doc
  local active_filename = doc and system.absolute_path(doc.filename or "")
end
