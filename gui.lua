function initGUI()
	GUI_SCALE = 1; bypassGameClick = false;
	-- scroll values for the two editors, pattern editor and piano roll editor
	PATTERN_SCROLL = 0; PATTERN_ZOOMX = 1;
	PIANOROLL_SCROLLX = 0; PIANOROLL_SCROLLY = 0; PIANOROLL_ZOOMX = 4; PIANOROLL_ZOOMY = 1;
	DIVIDER_POS = 400;
	elements = {};
	
	GROUP_TOPBAR = GuiElement:new{x=0, y=0, width=500, height=3, name="topbar", autopos = "left", autosizey = true};
	function GROUP_TOPBAR:onUpdate()
		self.width = WINDOW_WIDTH;
	end
	
	local file = GuiElement:new{x=0,y=0,width=100,height=50,parent=GROUP_TOPBAR, name="file", text="File"};
	local edit = GuiElement:new{x=0,y=0,width=100,height=50,parent=GROUP_TOPBAR, name="edit", text="Edit"};
	
	GROUP_PTRN_EDIT = GuiElement:new{x=0, y=55, width=500, height=60, name="ptrneditor", autopos = "top", autosizey = true};
	function GROUP_PTRN_EDIT:onUpdate()
		self.width = WINDOW_WIDTH;
	end
	
	GROUP_PTRN_EDIT.ELM_PULSE2 = GuiElement:new{x=0,y=0,width=100,height=50,parent=GROUP_PTRN_EDIT, name="pulse2cntr", autopos = "left", autosizey = true};
	function GROUP_PTRN_EDIT.ELM_PULSE2:onUpdate()
		self.width = WINDOW_WIDTH;
	end
	--GROUP_PTRN_EDIT.ELM_PULSE1 = GuiElement:new{x=0,y=0,width=100,height=50,parent=GROUP_PTRN_EDIT, autopos = "top"};
	--function GROUP_PTRN_EDIT.ELM_PULSE1:onUpdate()
	--	self.width = WINDOW_WIDTH;
	--end
	--GROUP_PTRN_EDIT.ELM_TRI = GuiElement:new{x=0,y=0,width=100,height=50,parent=GROUP_PTRN_EDIT, autopos = "top"};
	--GROUP_PTRN_EDIT.ELM_NOISE = GuiElement:new{x=0,y=0,width=100,height=50,parent=GROUP_PTRN_EDIT, autopos = "top"};
end

function clickGUI(x,y)
	for i = 1, #elements do
		local e = elements[i];
		if ((e.active or e.bypassActiveForClicks) and not e.parent) then
			e:click(x,y);
		end
	end
end

function updateGUI()

	for i = 1, #elements do
		local e = elements[i];
		if (e.active) then
			e:update();
		end
	end
end

function updatePatternGUI( song )
	GROUP_PTRN_EDIT.ELM_PULSE2.children = {}
	--GROUP_PTRN_EDIT.ELM_TRI.children    = {}
	--GROUP_PTRN_EDIT.ELM_PULSE1.children = {}
	--GROUP_PTRN_EDIT.ELM_NOISE.children  = {}
	
	ElementPattern = GuiElement:new{
		pattern = nil, -- numerical index
		channel = nil, -- will be a key like "pulse1" etc.
		height = 75,
		bg_color = {1,0,1},
		text_color = {0,0,0}
	}
	table.remove(elements); -- it's a base class so dont let it go into the elements table lol
	
	function ElementPattern:onClick()
		selectedPattern = self.pattern;
		selectedChannel = self.channel;
	end
	function ElementPattern:onUpdate()
		local p = selectedSong;
		local ptrn = sng_mariodies.patterns[ self.pattern ];
		self.width = ptrn.duration * PATTERN_ZOOMX;
	end
	
	function ElementPattern:onRender()
		local p = selectedSong;
		local ptrn = sng_mariodies.patterns[ self.pattern ];
		local notes = ptrn:getNotes( self.channel );
		
		local hiindex = ptrn:getHighestNote( self.channel );
		local hinote  = notes[hiindex].pitch;
		local loindex = ptrn:getLowestNote( self.channel );
		local lonote  = notes[loindex].pitch;
		
		for i = 0, #notes do
			local note = notes[i];
			local x = note.starttime + self.dispx;
			
			local btm = (self.dispy + self.dispheight) - (2*self.padding);
			local top = (self.dispy + self.padding)
			local notey = ((note.pitch - lonote) * ( btm - top)) / ( hinote - lonote )
			local y = self.dispy + self.dispheight - ( 2* self.padding ) - notey;
			
			--self.dispy + self.dispheight/2;
			
			local width = (note.duration / ptrn.duration) * self.dispwidth;
			local height = (3);
			
			if (note.val ~= 04) then
				love.graphics.setColor( self.text_color );
				love.graphics.rectangle( "fill", x, y, width, height );
			end
		end
	end
	
	for i = 0, song.patternCount - 1 do
		local p = song.patterns[i];
		
		local p2 = ElementPattern:new{parent=GROUP_PTRN_EDIT.ELM_PULSE2, pattern = i, channel = "pulse2"};
	end
end

function renderGUI()

	for i = 1, #elements do
		local e = elements[i];
		e:render();
	end
end