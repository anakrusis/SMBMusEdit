-- -- Element used to contain the ElementPatterns as defined below
ElementPatternContainer = {}; ElementPatternContainer.__index = ElementPatternContainer;
function ElementPatternContainer.new(channel)
	local self = setmetatable(GuiElement.new(0, 0, 100, 50, GROUP_PTRN_EDIT), ElementPatternContainer);

	self.autopos = "left"; self.autosizey = true; 
	self.padding = 0;
	self.children = {};
	self.channel = channel;
	
	return self;
end
setmetatable(ElementPatternContainer, {__index = GuiElement});

-- ElementPatternContainer = GuiElement:new{
	-- channel = nil,
	-- x=0,y=0,width=100,height=50,
	-- autopos = "left", autosizey = true, padding = 0,
-- }

-- table.remove(elements); 

function ElementPatternContainer:onUpdate()
	self.width = 2000;
	if self.channel == "noise" then 
		if songs[selectedSong].hasNoise then self:show() else self:hide() end
	else
		self:show()
	end
	
	--print("updating " .. self.channel);
end

-- -- -- Element used to display and select a specific pattern when clicked
-- -- ElementPattern = GuiElement:new{
	-- -- pattern = nil, -- numerical index
	-- -- song    = nil, -- ditto
	-- -- channel = nil, -- will be a key like "pulse1" etc.
	-- -- height = 50,
	-- -- bg_color = {1,1,1},
	-- -- enable_color = {0,0,0},
	-- -- text_color = {0,0,0},
	-- -- padding = 0,
-- -- }

ElementPattern = {}; ElementPattern.__index = ElementPattern;
function ElementPattern.new(parent, song, pattern, channel)
	local self = setmetatable( GuiElement.new(0,0,0,50,parent ), ElementPattern);

	self.pattern = pattern; self.song = song; self.channel = channel;
	--self.height = 50;
	self.bg_color = {1,1,1};
	self.enable_color = {0,0,0};
	self.padding = 0;
	self.name = "p";
	
	print(self.text_color[1]);
	
	-- if (self.parent) then
		-- --print(self.parent.name);
		-- --print( o.name .. " added to " .. o.parent.name);
		-- self.parent:appendElement( self );
	-- else
		-- --elements.push(this);
		-- --print( o.name .. " added to elements " );
		-- table.insert(elements, self);
	-- end
	
	return self;
end
setmetatable(ElementPattern, {__index = GuiElement});

function ElementPattern:onClick()
	selectedPattern = self.pattern;
	selectedChannel = self.channel;
	print(self.name .. " clicked");
end
function ElementPattern:onUpdate()
	local ptrn = songs[self.song].patterns[self.pattern];
	self.width = ptrn.duration * PATTERN_ZOOMX;
	self.bg_color = CHANNEL_COLORS[ self.channel ];
	
	--print("updating " .. ptrn:getName() .. " " .. self.channel);
end

function ElementPattern:onRender()
	local ptrn = songs[self.song].patterns[self.pattern];
	local notes = ptrn:getNotes( self.channel );
	
	local hiindex = ptrn:getHighestNote( self.channel );
	local hinote  = notes[hiindex];
	local loindex = ptrn:getLowestNote( self.channel );
	local lonote  = notes[loindex];
	
	if (not hinote or not lonote) then return; end
	
	local amount;
	if (self.channel == "noise" and ptrn.noiseduration ~= 0) then
		amount = (1+#notes * ( ptrn.duration / ptrn.noiseduration ))
	else
		amount = 1+#notes;
	end
	local x = self.dispx;
	for i = 0, amount do
		local note = notes[i % (#notes+1)];
		
		local padding = 5;
		
		local btm = (self.dispy + self.dispheight) - (2*padding);
		local top = (self.dispy + padding)
		local notey = ((note.pitch - lonote.pitch) * ( btm - top)) / ( hinote.pitch - lonote.pitch )
		local y = self.dispy + self.dispheight - ( 2* padding ) - notey;
		
		--self.dispy + self.dispheight/2;
		
		local width = (note.duration / ptrn.duration) * self.dispwidth;
		local height = (3);
		
		if (note.val ~= 04) then
			love.graphics.setColor( self.enable_color );
			love.graphics.rectangle( "fill", x, y, width, height );
		end
		
		x = x + note.duration * PATTERN_ZOOMX
	end
end

function updatePatternGUI( song )
	GROUP_PTRN_EDIT.ELM_PULSE2.children = {}
	GROUP_PTRN_EDIT.ELM_TRI.children    = {}
	GROUP_PTRN_EDIT.ELM_PULSE1.children = {}
	GROUP_PTRN_EDIT.ELM_NOISE.children  = {}
	
	for i = 0, song.patternCount - 1 do
		local p = song.patterns[i];
		
		local p2 = ElementPattern.new(GROUP_PTRN_EDIT.ELM_PULSE2, song.songindex, i, "pulse2" );
		local p1 = ElementPattern.new(GROUP_PTRN_EDIT.ELM_PULSE1, song.songindex, i, "pulse1" );
		local tr = ElementPattern.new(GROUP_PTRN_EDIT.ELM_TRI,    song.songindex, i, "tri" );
		
		--local p2 = ElementPattern:new{parent=GROUP_PTRN_EDIT.ELM_PULSE2, song = song.songindex, pattern = i, channel = "pulse2"};
		--local p1 = ElementPattern:new{parent=GROUP_PTRN_EDIT.ELM_PULSE1, song = song.songindex, pattern = i, channel = "pulse1"};
		--local tr = ElementPattern:new{parent=GROUP_PTRN_EDIT.ELM_TRI,    song = song.songindex, pattern = i, channel = "tri"};
		if song.hasNoise then
			local no = ElementPattern.new(GROUP_PTRN_EDIT.ELM_NOISE, song.songindex, i, "noise" );
			--local no = ElementPattern:new{parent=GROUP_PTRN_EDIT.ELM_NOISE,  song = song.songindex, pattern = i, channel = "noise"};
		end
	end
	
	GROUP_PTRN_EDIT:show();
end