function initGUI()
	GUI_SCALE = 1; bypassGameClick = false;
	-- scroll values for the two editors, pattern editor and piano roll editor
	PATTERN_SCROLL = 0; PATTERN_ZOOMX = 1;
	PIANOROLL_SCROLLX = 0; PIANOROLL_SCROLLY = 0; PIANOROLL_ZOOMX = 4; PIANOROLL_ZOOMY = 20;
	PIANOROLL_TOPBAR_HEIGHT = 16;
	OPTIMIZE_SCROLL   = 0;
	DIVIDER_POS = 325; SIDE_PIANO_WIDTH = 128;
	
	-- text that shows up for errors and other info bits at the bottom
	popup_timer = 0; popup_color = {}; popup_text = ""; popup_start = 0;
	
	DRAGGING_NOTE = nil;
	PTRN_END_DRAGGING = false;
	
	-- string for editing
	selectedTextEntry = nil;
	selectedTextBox   = nil;
	
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
		if (rom.path) then
			--rom:export("smbmusedit-2/mario.nes");
			rom:export(rom.path);
			GROUP_FILE:hide(); openGUIWindow(GROUP_TOPBAR);
		end
	end
	function export:onUpdate()
		if (rom.path) then
			self.text_color = {1,1,1};
		else
			self.text_color = {0.5,0.5,0.5};
		end
	end
	
	GROUP_EDIT = GuiElement:new{x=97, y=55, width=500, height=3, name="edit_container", autopos = "top", autosize = true}; GROUP_EDIT:hide();
	local optimize = GuiElement:new{x=0,y=0,width=275,height=50,parent=GROUP_EDIT, name="optimize", text="Optimize..."};
	function optimize:onClick()
		if (rom.path) then
			openGUIWindow( GROUP_OPTIMIZE );
		end
	end
	function optimize:onUpdate()
		if (rom.path) then
			self.text_color = {1,1,1};
		else
			self.text_color = {0.5,0.5,0.5};
		end
	end
	local ptredit = GuiElement:new{x=0,y=0,width=275,height=50,parent=GROUP_EDIT, name="ptredit", text="Pointer Edit..."};
	function ptredit:onClick()
		if (rom.path) then
			openGUIWindow( GROUP_PNTR_EDIT );
		end
	end
	function ptredit:onUpdate()
		if (rom.path) then
			self.text_color = {1,1,1};
		else
			self.text_color = {0.5,0.5,0.5};
		end
	end
	
	GROUP_OPTIMIZE = GuiElement:new{x=55, y=55, width=600, height=3, autopos = "top", autosize = true, autocenterX = true, autocenterY = true}; GROUP_OPTIMIZE:hide();
	local optimize = GuiElement:new{x=0,y=0,width=800,height=600,parent=GROUP_OPTIMIZE, text=""};
	function optimize:onUpdate()
		local song = songs[selectedSong];
		local ptrn = song.patterns[selectedPattern];
		
		local cbinfo = "";
		local rw = 24; local rh = 16; local rxs = 400;
		local x = math.floor((love.mouse.getX() - rxs - self.dispx) / rw); 
		local y = math.floor((love.mouse.getY() + OPTIMIZE_SCROLL - self.dispy) / rh)
		local ind = 0x79c0 + ( 16 * y ) + x;
		local cb = rom.data[ind];
		
		if x >= 0 and x < 16 then
			cbinfo = cbinfo .. "Byte Addr.: $" .. string.format("%04X", ind)
			cbinfo = cbinfo .. "\nValue: " .. string.format("%02X", cb.val);
			
			for i = 1, #cb.song_claims do
				local song = songs[ cb.song_claims[i] ];
				local ptrn = song.patterns[ cb.ptrn_claims[i] ];
				local chnl = cb.chnl_claims[i];
				cbinfo = cbinfo .. "\n" .. ptrn:getName() .. " " .. chnl;
			end
			cbinfo = cbinfo .. "\n\n";
		end
		
		self.text = {
			{1,1,1}, 
			"Current Pattern:\n" ..  song.name .. " #" .. ptrn.patternindex .. "\n\n",
			CHANNEL_COLORS["pulse2"],
			"Pulse 2: $" ..  string.format("%02X", ptrn.pulse2_start_index ) .. "\n",
			CHANNEL_COLORS["pulse1"],
			"Pulse 1: $" ..  string.format("%02X", ptrn.pulse1_start_index ) .. "\n",
			CHANNEL_COLORS["tri"],
			"Tri:     $" ..  string.format("%02X", ptrn.tri_start_index ) .. "\n",
			{1,1,1},
			"\n" .. cbinfo,
			{1,1,1},
			"Scroll to view more\nof the byte viewer --->\n\nThe 'Allocate Unused\nBytes' button will\nallocate space to the\npattern and channel\ncurrently opened in the\npiano roll.",
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
			-- rectangle width, height, and x start
			local rw = 24; local rh = 16; local rxs = 400;
			
			local rectx = self.dispx + rxs + ( i % 16 ) * rw
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
	GROUP_OPTIMIZE.BTN_ALLOCATE = GuiElement:new{x=0,y=0,width=375,height=50,parent=GROUP_OPTIMIZE, text="Allocate Unused Byte"};
	function GROUP_OPTIMIZE.BTN_ALLOCATE:onClick()
		local song = songs[selectedSong];
		local ptrn = song.patterns[selectedPattern];
		ptrn:allocateUnusedBytes( selectedChannel );
	end
	
	GROUP_OPTIMIZE.BTN_BACK = GuiElement:new{x=0,y=0,width=100,height=50,parent=GROUP_OPTIMIZE, text="Back"};
	function GROUP_OPTIMIZE.BTN_BACK:onClick()
		GROUP_EDIT:hide(); GROUP_OPTIMIZE:hide(); openGUIWindow( GROUP_TOPBAR );
	end
	
	GROUP_PNTR_EDIT = GuiElement:new{x=55, y=55, width=600, height=3, autopos = "top", autosize = true, autocenterX = true, autocenterY = true}; GROUP_PNTR_EDIT:hide();
	local pointeredit = GuiElement:new{x=0,y=0,width=620,height=400,parent=GROUP_PNTR_EDIT, text=""};
	function pointeredit:onUpdate()
		local song = songs[selectedSong];
		local ptrn = song.patterns[selectedPattern];
		local infostr = "Current Pattern: ";
		infostr = infostr .. ptrn:getName();
		infostr = infostr .. "\n\n---\n\nPtr to Header:     + $791D = $" .. string.format("%04X", ptrn.header_start_index);
		self.text = infostr;
	end
	
	local pointer = GuiElement:new{x=0,y=0,width=65,height=50,parent=pointeredit, text="", staticposition = true, maxlen = 2};
	function pointer:onUpdate()
		local song = songs[selectedSong];
		local ptrn = song.patterns[selectedPattern];
		self.x = pointeredit.dispx + 250;
		self.y = pointeredit.dispy + 75;
		if selectedTextEntry and selectedTextBox == self then
			self.text = selectedTextEntry;
		else
			self.text = string.format("%02X", rom:get(ptrn.ptr_index));
		end
	end
	function pointer:onClick()
		selectedTextBox = self;
		selectedTextEntry = self.text;
	end
	function pointer:onCommit()
		local song = songs[selectedSong];
		local ptrn = song.patterns[selectedPattern];
		local hex = tonumber(self.text,16);
		rom:put( ptrn.ptr_index, hex )
		parseAllSongs();
	end
	
	GROUP_PNTR_EDIT.BTN_BACK = GuiElement:new{x=0,y=0,width=100,height=50,parent=GROUP_PNTR_EDIT, text="Back"};
	function GROUP_PNTR_EDIT.BTN_BACK:onClick()
		GROUP_EDIT:hide(); GROUP_PNTR_EDIT:hide(); openGUIWindow( GROUP_TOPBAR );
	end
	
	GROUP_PARSE_ERROR = GuiElement:new{x=55, y=55, width=600, height=3, autopos = "top", autosize = true, autocenterX = true, autocenterY = true}; GROUP_PARSE_ERROR:hide();
	GROUP_PARSE_ERROR.ELM_BODY = GuiElement:new{x=0,y=0,width=450,height=350,parent=GROUP_PARSE_ERROR, text=""};
	GROUP_PARSE_ERROR.BTN_BACK = GuiElement:new{x=0,y=0,width=100,height=50,parent=GROUP_PARSE_ERROR, text="OK"};
	function GROUP_PARSE_ERROR.BTN_BACK:onClick()
		GROUP_PARSE_ERROR:hide(); GROUP_PARSE_ERROR.active = false;
	end 
	
	openGUIWindow(GROUP_TOPBAR);
	GROUP_PTRN_EDIT:hide();
end

function openGUIWindow( element )
	selectedTextBox = nil;
	selectedTextEntry = nil;
	
	-- sets the previous outermost element to inactive
	for i = 1, #elements do
		local e = elements[i];
		if (e.active) then
			e.active = false;
		end
	end
	
	-- Special case where these elements are inseperable, TODO maybe put these into a bigger super-group
	if (element == GROUP_TOPBAR) then
		if rom.path then
			GROUP_PTRN_EDIT.active = true;  GROUP_PTRN_EDIT:show();
		end
		GROUP_TOPBAR2.active = true;  GROUP_TOPBAR2:show();
	end
	
	element.active = true;
	element:show();
end

function clickGUI(x,y)
	for i = #elements, 1, -1 do
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
	
	--GROUP_PTRN_EDIT:show();
end

function renderGUI()

	for i = 1, #elements do
		local e = elements[i];
		e:render();
	end
end