function initGUI()
	GUI_SCALE = 1; bypassGameClick = false;
	-- scroll values for the two editors, pattern editor and piano roll editor
	PATTERN_SCROLL = 0; PIANOROLL_SCROLLX = 0; PIANOROLL_SCROLLY = 0; PIANOROLL_ZOOMX = 4; PIANOROLL_ZOOMY = 1;
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
		pattern = nil,
		height = 75,
	}
	table.remove(elements);
	
	for i = 0, song.patternCount - 1 do
		local p = song.patterns[i];
		
		local p2 = ElementPattern:new{parent=GROUP_PTRN_EDIT.ELM_PULSE2, pattern = p};
	end
end

function renderGUI()

	for i = 1, #elements do
		local e = elements[i];
		e:render();
	end
end