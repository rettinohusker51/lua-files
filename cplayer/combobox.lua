local player = require'cairo_player'

function player:combobox(t)
	local id = assert(t.id, 'id missing')
	local x, y, w, h = self:getbox(t)
	local items, selected = t.items, t.selected
	local text = selected or 'pick...'
	local font_size = t.font_size or h / 2

	local menu_h = 100

	local down = self.lbutton
	local hot = self:hotbox(x, y, w, h)

	if not self.active and hot and down then
		self.active = id
	elseif self.active == id then
		if hot and self.click then
			if not self.cmenu then
				local menu_id = id .. '_menu'
				self.cmenu = {id = menu_id, x = x, y = y + h, w = w, h = menu_h, items = items}
				self.active = nil
			else
				self.cmenu = nil
			end
		elseif not hot then
			self.active = nil
			self.cmenu = nil
		end
	end

	--drawing
	self:rect(x, y, w, h, 'faint_bg')
	self:text(text, font_size, 'normal_fg', 'left', 'middle', x, y, w, h)

	return self.cmenu
end

if not ... then require'cairo_player_demo' end
