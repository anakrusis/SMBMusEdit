ElementTextEntry = {}; ElementTextEntry.__index = ElementTextEntry;
function ElementTextEntry.new(width,height,parent,maxlen)
	local self = setmetatable(GuiElement.new(0, 0, width, height, parent), ElementTextEntry);
	
	self.maxlen = maxlen;
	
	return self;
end
setmetatable(ElementTextEntry, {__index = GuiElement});

function ElementTextEntry:onClick()
	selectedTextBox = self;
	selectedTextEntry = self.text;
end

function ElementTextEntry:onCommit()

end

function ElementTextEntry:onRender()
	local FONTSIZE = 24 / (3/2);
	if selectedTextBox == self and frameCount % 16 > 8 then
		local linex = (FONTSIZE * #self.text) + self.dispx + self.padding;
		love.graphics.line( linex, self.dispy + self.padding, linex, self.dispy + self.dispheight - self.padding );
	end
end

-- function ElementTextEntry:read()

-- end

-- function ElementTextEntry:write()

-- end

-- ElementByteEntry = {}; ElementByteEntry.__index = ElementByteEntry;
-- function ElementByteEntry.new(relx, rely, height,parent)
	-- local self = setmetatable(ElementTextEntry.new(65,height,parent,2), ElementByteEntry);
	
	-- -- IF staticposition is enabled, determine relatives index from the parents position, otherwise unused
	-- self.relx = relx; self.rely = rely;
	
	-- return self;
-- end
-- setmetatable(ElementByteEntry, {__index = GuiElement});

-- function ElementByteEntry:read()

-- end