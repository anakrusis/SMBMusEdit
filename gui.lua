function initGUI()
	GUI_SCALE = 1; bypassGameClick = false;
	-- scroll values for the two editors, pattern editor and piano roll editor
	PATTERN_SCROLL = 0; PATTERN_ZOOMX = 1;
	PIANOROLL_SCROLLX = 0; PIANOROLL_SCROLLY = 0; PIANOROLL_ZOOMX = 4; PIANOROLL_ZOOMY = 20;
	OPTIMIZE_SCROLL   = 0;
	DIVIDER_POS = 300; SIDE_PIANO_WIDTH = 128;
	
	-- text that shows up for errors and other info bits at the bottom
	popup_timer = 0; popup_color = {}; popup_text = ""; popup_start = 0;
	
	NOTE_DRAGGING = nil;
	
	elements = {};
	
	CHANNEL_COLORS = {};
	CHANNEL_COLORS["pulse2"] = { 1,   0, 0.75 }
	CHANNEL_COLORS["pulse1"] = { 0.5, 0, 0.75 }
	CHANNEL_COLORS["tri"]    = { 0,   0, 1 }
	CHANNEL_COLORS["noise"]  = { 0, 0.5, 0.5 }
	
	GROUP_TOPBAR = GuiElement:new{x=0, y=0, width=500, height=3, name="topbar", autopos = "left", autosizey = true};
	function GROUP_TOPBAR:onUpdate()
		self.width = WINDOW_WIDTH;
	end
	GROUP_TOPBAR2 = GuiElement:new{x=0, y=60, width=500, height=3, name="topbar2", autopos = "left", autosizey = true};
	function GROUP_TOPBAR2:onUpdate()
		self.width = WINDOW_WIDTH;
	end
	local prevsong = GuiElement:new{x=0,y=0,width=50,height=50,parent=GROUP_TOPBAR2, name="prevsong", text="<"};
	function prevsong:onClick()
		selectSong((selectedSong - 1) % SONG_COUNT);	
	end
	local currsong = GuiElement:new{x=0,y=0,width=300,height=50,parent=GROUP_TOPBAR2, name="currsong", text="<"};
	function currsong:onUpdate()
		self.text = songs[selectedSong].name;
	end
	local nextsong = GuiElement:new{x=0,y=0,width=50,height=50,parent=GROUP_TOPBAR2, name="nextsong", text=">"};
	function nextsong:onClick()
		selectSong((selectedSong + 1) % SONG_COUNT);
	end
	
	local file = GuiElement:new{x=0,y=0,width=100,height=50,parent=GROUP_TOPBAR, name="file", text="File"};
	function file:onClick()
		openGUIWindow( GROUP_FILE );
	end
	local edit = GuiElement:new{x=0,y=0,width=100,height=50,parent=GROUP_TOPBAR, name="edit", text="Edit"};
	function edit:onClick()
		openGUIWindow( GROUP_EDIT );
	end
	
	GROUP_PTRN_EDIT = GuiElement:new{x=-50, y=120, width=500, height=60, name="ptrneditor", autopos = "top", autosizey = true, padding = 0};
	function GROUP_PTRN_EDIT:onUpdate()
		self.width = 2000;
		self.x = ((0 - PATTERN_SCROLL) * PATTERN_ZOOMX)
	end
	
	GROUP_PTRN_EDIT.ELM_PULSE2 = GuiElement:new{x=0,y=0,width=100,height=50,parent=GROUP_PTRN_EDIT, name="pulse2cntr", autopos = "left", autosizey = true, padding = 0};
	function GROUP_PTRN_EDIT.ELM_PULSE2:onUpdate()
		self.width = 2000;
	end
	GROUP_PTRN_EDIT.ELM_PULSE1 = GuiElement:new{x=0,y=0,width=100,height=50,parent=GROUP_PTRN_EDIT, name="pulse1cntr", autopos = "left", autosizey = true, padding = 0};
	function GROUP_PTRN_EDIT.ELM_PULSE1:onUpdate()
		self.width = 2000;
	end
	GROUP_PTRN_EDIT.ELM_TRI = GuiElement:new{x=0,y=0,width=100,height=50,parent=GROUP_PTRN_EDIT, name="tricntr", autopos = "left", autosizey = true, padding = 0};
	function GROUP_PTRN_EDIT.ELM_TRI:onUpdate()
		self.width = 2000;
	end
	GROUP_PTRN_EDIT.ELM_NOISE = GuiElement:new{x=0,y=0,width=100,height=50,parent=GROUP_PTRN_EDIT, name="noisecntr", autopos = "left", autosizey = true, padding = 0};
	function GROUP_PTRN_EDIT.ELM_NOISE:onUpdate()
		self.width = 2000;
		if (songs[selectedSong].hasNoise) then self:show() else self:hide() end
	end
	
	GROUP_FILE = GuiElement:new{x=0, y=55, width=500, height=3, name="file_container", autopos = "left", autosize = true};
	GROUP_FILE:hide();
	local export = GuiElement:new{x=0,y=0,width=200,height=50,parent=GROUP_FILE, name="export", text="Export ROM"};
	function export:onClick()
		GROUP_FILE:hide(); openGUIWindow(GROUP_TOPBAR);
		rom:export("smbmusedit-2/mario.nes");
	end
	
	GROUP_EDIT = GuiElement:new{x=97, y=55, width=500, height=3, name="edit_container", autopos = "left", autosize = true}; GROUP_EDIT:hide();
	local optimize = GuiElement:new{x=0,y=0,width=200,height=50,parent=GROUP_EDIT, name="optimize", text="Optimize..."};
	function optimize:onClick()
		openGUIWindow( GROUP_OPTIMIZE );
	end
	
	GROUP_OPTIMIZE = GuiElement:new{x=55, y=55, width=600, height=3, autopos = "top", autosize = true, autocenterX = true, autocenterY = true}; GROUP_OPTIMIZE:hide();
	local optimize = GuiElement:new{x=0,y=0,width=800,height=600,parent=GROUP_OPTIMIZE, text=""};
	function optimize:onUpdate()
		local song = songs[selectedSong];
		local ptrn = song.patterns[selectedPattern];
		
		local cbinfo = "Byte Addr.: $";
		local rw = 32; local rh = 16;
		local x = math.floor((love.mouse.getX() - 320 - self.dispx) / rw); 
		local y = math.floor((love.mouse.getY() + OPTIMIZE_SCROLL - self.dispy) / rh)
		local ind = 0x79c0 + ( 16 * y ) + x;
		local cb = rom.data[ind];
		
		cbinfo = cbinfo .. string.format("%04X", ind)
		cbinfo = cbinfo .. "\nValue: " .. string.format("%02X", cb.val);
		
		for i = 1, #cb.song_claims do
			local song = songs[ cb.song_claims[i] ];
			local ptrn = song.patterns[ cb.ptrn_claims[i] ];
			local chnl = cb.chnl_claims[i];
			cbinfo = cbinfo .. "\n" .. ptrn:getName() .. " " .. chnl;
		end
		
		cbinfo = cbinfo .. "\n\n";
		self.text = {
			{1,1,1}, 
			"Current Pattern:\n" ..  song.name .. " #" .. ptrn.patternindex .. "\n\n",
			CHANNEL_COLORS["pulse2"],
			"Pulse 2: $" ..  string.format("%02X", ptrn.pulse2_start_index ) .. "\n",
			CHANNEL_COLORS["pulse1"],
			"Pulse 1: $" ..  string.format("%02X", ptrn.pulse1_start_index ) .. "\n",
			CHANNEL_COLORS["tri"],
			"Tri:     $" ..  string.format("%02X", ptrn.tri_start_index ) .. "\n\n",
			{1,1,1},
			cbinfo,
			{1,1,1},
			"The 'Allocate\nUnused Bytes' button\nwill allocate space\nto the pattern and \nchannel currently\nopened in the piano\nroll.",
		}
		if (ptrn.hasNoise) then
			table.insert(self.text, 9, CHANNEL_COLORS["noise"]);
			table.insert(self.text, 10, "Noise:   $" ..  string.format("%02X", ptrn.noise_start_index ) .. "\n");
		end
	end
	function optimize:onRender()
		
		local song = songs[selectedSong];
		local ptrn = song.patterns[selectedPattern];
		
		local DATA_START = 0x79C8;
		local DATA_END   = 0x7F0F;
		
		for i = DATA_START, DATA_END do
			
			local rw = 32; local rh = 16;
			
			local rectx = self.dispx + 320 + ( i % 16 ) * rw
			local recty = self.dispy + (math.floor( (i - 0x79c0) / 16 ) * rh) - OPTIMIZE_SCROLL; 
			local b = rom.data[i] -- byte
			if (b:hasChannelClaim("pulse2")) then
				love.graphics.setColor(CHANNEL_COLORS["pulse2"]);
			
			elseif (b:hasChannelClaim("tri")) then
				love.graphics.setColor(CHANNEL_COLORS["tri"]);
			
			elseif (b:hasChannelClaim("pulse1")) then
				love.graphics.setColor(CHANNEL_COLORS["pulse1"]);
			
			elseif (b:hasChannelClaim("noise")) then
				love.graphics.setColor(CHANNEL_COLORS["noise"]);
			
			-- used byte
			elseif (#b.song_claims > 0) then
				love.graphics.setColor(1,0,0);
				
			-- unused byte
			else
				love.graphics.setColor(0,1,0);
			end
			if (recty >= self.dispy and recty <= self.dispy + self.dispheight) then
				love.graphics.rectangle("fill",rectx,recty,rw * 0.75,rh * 0.75);
				
				if (b:hasSongPatternClaim(selectedSong,selectedPattern)) then
					love.graphics.setColor(1,1,0);
					love.graphics.rectangle("line",rectx,recty,rw * 0.75,rh * 0.75);
				end
			end
		end			
	end
	GROUP_OPTIMIZE.BTN_ALLOCATE = GuiElement:new{x=0,y=0,width=375,height=50,parent=GROUP_OPTIMIZE, text="Allocate Unused Bytes"};
	function GROUP_OPTIMIZE.BTN_ALLOCATE:onClick()
		local song = songs[selectedSong];
		local ptrn = song.patterns[selectedPattern];
		ptrn:allocateUnusedBytes( selectedChannel );
	end
	
	GROUP_OPTIMIZE.BTN_BACK = GuiElement:new{x=0,y=0,width=100,height=50,parent=GROUP_OPTIMIZE, text="Back"};
	function GROUP_OPTIMIZE.BTN_BACK:onClick()
		GROUP_EDIT:hide(); GROUP_OPTIMIZE:hide(); openGUIWindow( GROUP_TOPBAR );
	end
	
	openGUIWindow(GROUP_TOPBAR);
end

function openGUIWindow( element )
	-- sets the previous outermost element to inactive
	for i = 1, #elements do
		local e = elements[i];
		if (e.active) then
			e.active = false;
		end
	end
	
	-- Special case where these elements are inseperable, TODO maybe put these into a bigger super-group
	if (element == GROUP_TOPBAR) then
		GROUP_PTRN_EDIT.active = true;  GROUP_PTRN_EDIT:show();
		GROUP_TOPBAR2.active = true;  GROUP_TOPBAR2:show();
	end
	
	element.active = true;
	element:show();
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
	GROUP_PTRN_EDIT.ELM_TRI.children    = {}
	GROUP_PTRN_EDIT.ELM_PULSE1.children = {}
	GROUP_PTRN_EDIT.ELM_NOISE.children  = {}
	
	ElementPattern = GuiElement:new{
		pattern = nil, -- numerical index
		song    = nil, -- ditto
		channel = nil, -- will be a key like "pulse1" etc.
		height = 50,
		bg_color = {1,1,1},
		text_color = {0,0,0},
		padding = 0,
	}
	table.remove(elements); -- it's a base class so dont let it go into the elements table lol
	
	function ElementPattern:onClick()
		selectedPattern = self.pattern;
		selectedChannel = self.channel;
	end
	function ElementPattern:onUpdate()
		local ptrn = songs[self.song].patterns[self.pattern];
		self.width = ptrn.duration * PATTERN_ZOOMX;
		self.bg_color = CHANNEL_COLORS[ self.channel ];
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
				love.graphics.setColor( self.text_color );
				love.graphics.rectangle( "fill", x, y, width, height );
			end
			
			x = x + note.duration * PATTERN_ZOOMX
		end
	end
	
	for i = 0, song.patternCount - 1 do
		local p = song.patterns[i];
		
		local p2 = ElementPattern:new{parent=GROUP_PTRN_EDIT.ELM_PULSE2, song = song.songindex, pattern = i, channel = "pulse2"};
		local p1 = ElementPattern:new{parent=GROUP_PTRN_EDIT.ELM_PULSE1, song = song.songindex, pattern = i, channel = "pulse1"};
		local tr = ElementPattern:new{parent=GROUP_PTRN_EDIT.ELM_TRI,    song = song.songindex, pattern = i, channel = "tri"};
		if song.hasNoise then
			local no = ElementPattern:new{parent=GROUP_PTRN_EDIT.ELM_NOISE,  song = song.songindex, pattern = i, channel = "noise"};
		end
	end
end

function renderGUI()

	for i = 1, #elements do
		local e = elements[i];
		e:render();
	end
end