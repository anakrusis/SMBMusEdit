require "guielement"
require "guipattern"
require "guitextentry"

function initGUI()
	GUI_SCALE = 1; bypassGameClick = false;
	-- scroll values for the two editors, pattern editor and piano roll editor
	PATTERN_SCROLL = 0; PATTERN_ZOOMX = 1;
	PIANOROLL_SCROLLX = 0; PIANOROLL_SCROLLY = 0; PIANOROLL_ZOOMX = 4; PIANOROLL_ZOOMY = 20;
	PIANOROLL_TOPBAR_HEIGHT = 16;
	OPTIMIZE_SCROLL   = 0;
	DIVIDER_POS = 325; SIDE_PIANO_WIDTH = 128; PTRN_SIDE_WIDTH = 250; SIDE_NOISE_WIDTH = 165;
	
	-- text that shows up for errors and other info bits at the bottom
	popup_timer = 0; popup_color = {}; popup_text = ""; popup_start = 0;
	
	PENCIL_MODE = true;
	DRAGGING_NOTE = nil; PLACING_NOTE = false; REMOVING_NOTE = false;
	PTRN_END_DRAGGING = false;
	-- eelection rectangle (not the notes, just the position on the screen)
	SELECTION_P1X = nil; SELECTION_P1Y = nil; SELECTION_P2X = nil; SELECTION_P2Y = nil;
	-- the indices to the notes themselves
	selectedNotes = {};
	
	-- string for editing
	selectedTextEntry = nil;
	selectedTextBox   = nil;
	
	elements = {};
	
	CHANNEL_COLORS = {};
	CHANNEL_COLORS["pulse2"] = { 1,   0, 0.75 }
	CHANNEL_COLORS["pulse1"] = { 0.5, 0, 0.75 }
	CHANNEL_COLORS["tri"]    = { 0,   0, 1 }
	CHANNEL_COLORS["noise"]  = { 0, 0.5, 0.5 }
	
	-- TOPBAR 2: Furthest back, it contains the pattern and song selection buttons
	-- Soon it will have different tools as well, like pencil, selection, etc... (see sekaiju, ableton, etc)
	GROUP_TOPBAR2 = GuiElement.new(0,60,500,3); GROUP_TOPBAR2.autopos = "left"; GROUP_TOPBAR2.autosizey = true;
	function GROUP_TOPBAR2:onUpdate()
		self.width = WINDOW_WIDTH;
	end
	local prevsong = GuiElement.new(0,0,50,50,GROUP_TOPBAR2);
	function prevsong:onClick()
		selectSong((selectedSong - 1) % SONG_COUNT);	
	end
	function prevsong:onRender()
		love.graphics.draw(IMG_PREVSONG, self.dispx + self.padding, self.dispy + self.padding, 0, 2, 2);
	end
	local currsong = GuiElement.new(0,0,300,50,GROUP_TOPBAR2);
	function currsong:onUpdate()
		self.text = songs[selectedSong].name;
	end
	local nextsong = GuiElement.new(0,0,50,50,GROUP_TOPBAR2);
	function nextsong:onClick()
		selectSong((selectedSong + 1) % SONG_COUNT);
	end
	function nextsong:onRender()
		love.graphics.draw(IMG_NEXTSONG, self.dispx + self.padding, self.dispy + self.padding, 0, 2, 2);
	end
	
	local prevptrn = GuiElement.new(0,0,50,50,GROUP_TOPBAR2);
	function prevptrn:onClick()
		local song = songs[selectedSong];
		selectedPattern = ((selectedPattern - 1) % song.patternCount);	
	end
	function prevptrn:onRender()
		love.graphics.draw(IMG_PREVPTRN, self.dispx + self.padding, self.dispy + self.padding, 0, 2, 2);
	end
	local currptrn = GuiElement.new(0,0,120,50,GROUP_TOPBAR2);
	function currptrn:onUpdate()
		local song = songs[selectedSong];
		self.text = "#" .. selectedPattern .. "/" .. song.patternCount-1;
	end
	function currptrn:onClick()
		openGUIWindow( GROUP_PNTR_EDIT );
	end
	function currptrn:getEnabledCondition()
		return rom.path ~= nil
	end
	local nextptrn = GuiElement.new(0,0,50,50,GROUP_TOPBAR2);
	function nextptrn:onClick()
		local song = songs[selectedSong];
		selectedPattern = ((selectedPattern + 1) % song.patternCount);	
	end 
	function nextptrn:onRender()
		love.graphics.draw(IMG_NEXTPTRN, self.dispx + self.padding, self.dispy + self.padding, 0, 2, 2);
	end
	
	local play = GuiElement.new(0,0,50,50,GROUP_TOPBAR2);
	function play:onClick()
		PlaybackHandler:togglePlaying();
		if not PlaybackHandler.playing then PlaybackHandler:togglePlaying(); end
	end 
	function play:onRender()
		local padx = (self.width - 32) / 4;
		love.graphics.draw(IMG_PLAY, self.dispx + padx, self.dispy + padx, 0, 2, 2);
	end
	local stop = GuiElement.new(0,0,50,50,GROUP_TOPBAR2);
	function stop:onClick()
		PlaybackHandler:togglePlaying();
		if PlaybackHandler.playing then PlaybackHandler:togglePlaying(); end
	end 
	function stop:onRender()
		local padx = (self.width - 32) / 4;
		love.graphics.draw(IMG_STOP, self.dispx + padx, self.dispy + padx, 0, 2, 2);
	end

	-- TOPBAR 1: The main bar with the main functions File, Edit
	GROUP_TOPBAR = GuiElement.new(0,0,500,3); GROUP_TOPBAR.autopos = "left"; GROUP_TOPBAR.autosizey = true;
	function GROUP_TOPBAR:onUpdate()
		self.width = WINDOW_WIDTH;
	end	
	local file = GuiElement.new(0,0,100,50,GROUP_TOPBAR,"File");
	function file:onClick()
		openGUIWindow( GROUP_FILE );
	end
	local edit = GuiElement.new(0,0,100,50,GROUP_TOPBAR,"Edit");
	function edit:onClick()
		openGUIWindow( GROUP_EDIT );
	end
	
	GROUP_PIANOROLL_EDIT = GuiElement.new(-50,120,500,60); GROUP_PIANOROLL_EDIT.autopos = "right";
	GROUP_PIANOROLL_EDIT.autosize = true; GROUP_PIANOROLL_EDIT.name = "pnorolledit";
	function GROUP_PIANOROLL_EDIT:onUpdate()
		local pad = 32;
		self.x = WINDOW_WIDTH - self.dispwidth - pad * 2;
		self.y = DIVIDER_POS  + PIANOROLL_TOPBAR_HEIGHT + pad; 
	end
	local pcl = GuiElement.new(0,0,50,50,GROUP_PIANOROLL_EDIT,"");
	function pcl:onClick()
		PENCIL_MODE = true;
	end
	function pcl:onUpdate()
		if PENCIL_MODE then self.bg_color = {0,0,0.5} else self.bg_color = {0,0,0} end
	end
	function pcl:onRender()
		local padx = (self.width - 32) / 4;
		love.graphics.draw(IMG_PENCIL, self.dispx + padx, self.dispy + padx, 0, 2, 2);
	end
	local slc = GuiElement.new(0,0,50,50,GROUP_PIANOROLL_EDIT,"");
	function slc:onClick()
		PENCIL_MODE = false;
	end
	function slc:onUpdate()
		if not PENCIL_MODE then self.bg_color = {0,0,0.5} else self.bg_color = {0,0,0} end
	end
	function slc:onRender()
		local padx = (self.width - 32) / 4;
		love.graphics.draw(IMG_SELECT, self.dispx + padx, self.dispy + padx, 0, 2, 2);
	end
	local bytesavail = GuiElement.new(0,0,140,50,GROUP_PIANOROLL_EDIT,"");
	function bytesavail:onUpdate()
		local song = songs[selectedSong];
		local ptrn = song.patterns[selectedPattern];
		if not ptrn then return end
		-- Bytes free out of bytes total enqueued
		local bytes_str = ptrn:getBytesUsed(selectedChannel) .. "/" .. ptrn:getBytesAvailable(selectedChannel);
		self.text = bytes_str;
	end
	function bytesavail:onClick()
		openGUIWindow( GROUP_OPTIMIZE );
	end
	function bytesavail:getEnabledCondition()
		return rom.path ~= nil
	end
	
	-- PTRN EDIT: The main pattern editor container and its four tracks, these are dynamically filled elsewhere
	GROUP_PTRN_EDIT = GuiElement.new(-50,120,500,60); GROUP_PTRN_EDIT.autopos = "top";
	GROUP_PTRN_EDIT.autosizey = true; GROUP_PTRN_EDIT.padding = 0; GROUP_PTRN_EDIT.name = "ptrnedit";
	function GROUP_PTRN_EDIT:onUpdate()
		self.width = 2000;
		self.x = ((0 - PATTERN_SCROLL) * PATTERN_ZOOMX) + PTRN_SIDE_WIDTH;
	end
	GROUP_PTRN_EDIT.ELM_PULSE2 = ElementPatternContainer.new("pulse2");
	GROUP_PTRN_EDIT.ELM_PULSE1 = ElementPatternContainer.new("pulse1");
	GROUP_PTRN_EDIT.ELM_TRI    = ElementPatternContainer.new("tri");
	GROUP_PTRN_EDIT.ELM_NOISE  = ElementPatternContainer.new("noise");
	
	-- PTRN SIDE: The sidebar displaying the names of the channels, also [Mute][Solo}
	GROUP_PTRN_SIDE = GuiElement.new(0,120,100,100); GROUP_PTRN_SIDE.autosize = true; GROUP_PTRN_SIDE.padding = 0;
	GROUP_PTRN_SIDE.ELM_PULSE2 = ElementPatternSide.new("pulse2","Pulse 2");
	GROUP_PTRN_SIDE.ELM_PULSE1 = ElementPatternSide.new("pulse1","Pulse 1");
	GROUP_PTRN_SIDE.ELM_TRI    = ElementPatternSide.new("tri","Tri");
	GROUP_PTRN_SIDE.ELM_NOISE  = ElementPatternSide.new("noise","Noise");
	function GROUP_PTRN_SIDE.ELM_PULSE2:onClick()
		print(self.dispheight);
	end
	
	GROUP_FILE = GuiElement.new(0,55,500,3); GROUP_FILE.autopos = "left"; GROUP_FILE.autosize = true;
	GROUP_FILE:hide();
	local export = GuiElement.new(0,0,200,50,GROUP_FILE,"Export ROM");
	function export:onClick()
		rom:export(rom.path);
		GROUP_FILE:hide(); openGUIWindow( GROUP_EXPORT_SUCCESS );
	end
	function export:getEnabledCondition()
		return rom.path ~= nil
	end
	
	GROUP_EDIT = GuiElement.new(97,55,500,3); GROUP_EDIT.autopos = "top"; GROUP_EDIT.autosize = true;
	GROUP_EDIT:hide();
	local optimize = GuiElement.new(0,0,275,50,GROUP_EDIT,"Optimize...");
	function optimize:onClick()
		openGUIWindow( GROUP_OPTIMIZE );
	end
	function optimize:getEnabledCondition()
		return rom.path ~= nil
	end
	local ptredit = GuiElement.new(0,0,275,50,GROUP_EDIT,"Pointer Edit...");
	function ptredit:onClick()
		openGUIWindow( GROUP_PNTR_EDIT );
	end
	function ptredit:getEnabledCondition()
		return rom.path ~= nil
	end
	local ptredit = GuiElement.new(0,0,275,50,GROUP_EDIT,"Clear Pattern");
	function ptredit:onClick()
		local song = songs[selectedSong];
		local ptrn = song.patterns[selectedPattern];
		ptrn:clear();
	end
	function ptredit:getEnabledCondition()
		return rom.path ~= nil
	end
	
	GROUP_OPTIMIZE = GuiElement.new(55,55,600,3); GROUP_OPTIMIZE.autosize = true; 
	GROUP_OPTIMIZE.autocenterX = true; GROUP_OPTIMIZE.autocenterY = true; 
	GROUP_OPTIMIZE:hide();
	local optimize = GuiElement.new(0,0,800,600,GROUP_OPTIMIZE);
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
				
				-- bytes belonging to the selected song
				if (b:hasSongPatternClaim(selectedSong,selectedPattern)) then
					love.graphics.setColor(1,1,0);
					love.graphics.rectangle("line",rectx,recty,rw * 0.75,rh * 0.75);
				end
			end
		end			
	end
	GROUP_OPTIMIZE.BTN_ALLOCATE = GuiElement.new(0,0,375,50,GROUP_OPTIMIZE, "Allocate Unused Byte");
	function GROUP_OPTIMIZE.BTN_ALLOCATE:onClick()
		local song = songs[selectedSong];
		local ptrn = song.patterns[selectedPattern];
		ptrn:allocateUnusedBytes( selectedChannel );
	end
	
	GROUP_OPTIMIZE.BTN_BACK = GuiElement.new(0,0,100,50,GROUP_OPTIMIZE,"Back");
	function GROUP_OPTIMIZE.BTN_BACK:onClick()
		GROUP_EDIT:hide(); GROUP_OPTIMIZE:hide(); openGUIWindow( GROUP_TOPBAR );
	end
	
	GROUP_PNTR_EDIT = GuiElement.new(55,55,600,3);
	GROUP_PNTR_EDIT.autopos = "top"; GROUP_PNTR_EDIT.autosize = true;
	GROUP_PNTR_EDIT.autocenterX = true; GROUP_PNTR_EDIT.autocenterY = true;
	GROUP_PNTR_EDIT:hide();
	--{x=55, y=55, width=600, height=3, autopos = "top", autosize = true, autocenterX = true, autocenterY = true}; 
	GROUP_PNTR_EDIT.ELM_BODY = GuiElement.new(0,0,620,400,GROUP_PNTR_EDIT);
	--{x=0,y=0,width=620,height=400,parent=GROUP_PNTR_EDIT, text=""};
	function GROUP_PNTR_EDIT.ELM_BODY:onUpdate()
		local song = songs[selectedSong];
		local ptrn = song.patterns[selectedPattern];
		local infostr = "Current Pattern: ";
		infostr = infostr .. ptrn:getName();
		infostr = infostr .. "\n\n---\n\nPtr to Header:     + $791D = $" .. string.format("%04X", ptrn.header_start_index);
		infostr = infostr .. "\n\nPtr to Pulse 2: $      ";
		infostr = infostr .. "\n\nPtr to Pulse 1: $" .. string.format("%04X", ptrn.pulse2_start_index) .. 
		" +    = $" .. string.format("%04X", ptrn.pulse1_start_index);
		infostr = infostr .. "\n\nPtr to Tri:     $" .. string.format("%04X", ptrn.pulse2_start_index) .. 
		" +    = $" .. string.format("%04X", ptrn.tri_start_index);
		
		if ptrn.hasNoise then
			infostr = infostr .. "\n\nPtr to Noise:   $" .. string.format("%04X", ptrn.pulse2_start_index) .. 
			" +    = $" .. string.format("%04X", ptrn.noise_start_index);
		end
		
		self.text = infostr;
	end
	
	local noiseptr = ElementTextEntry.new(65,40,GROUP_PNTR_EDIT.ELM_BODY,2); noiseptr.staticposition = true;
	--{x=0,y=0,width=65,height=40,parent=pointeredit, text="", staticposition = true, maxlen = 2};
	function noiseptr:onUpdate()
		local song = songs[selectedSong];
		local ptrn = song.patterns[selectedPattern];
		if ptrn.hasNoise then self:show(); else self:hide(); return; end
		self.x = self.parent.dispx + 385;
		self.y = self.parent.dispy + 242;
		if selectedTextEntry and selectedTextBox == self then
			self.text = selectedTextEntry;
		else
			self.text = string.format("%02X", rom:get(ptrn.header_start_index + 5));
		end
	end
	function noiseptr:onCommit()
		local song = songs[selectedSong];
		local ptrn = song.patterns[selectedPattern];
		local hex = tonumber(self.text,16);
		rom:put( ptrn.header_start_index + 5, hex )
		parseAllSongs();
	end
	
	local triptr = ElementTextEntry.new(65,40,GROUP_PNTR_EDIT.ELM_BODY,2); triptr.staticposition = true;
	--{x=0,y=0,width=65,height=40,parent=pointeredit, text="", staticposition = true, maxlen = 2};
	function triptr:onUpdate()
		local song = songs[selectedSong];
		local ptrn = song.patterns[selectedPattern];
		self.x = self.parent.dispx + 385;
		self.y = self.parent.dispy + 200;
		if selectedTextEntry and selectedTextBox == self then
			self.text = selectedTextEntry;
		else
			self.text = string.format("%02X", rom:get(ptrn.header_start_index + 3));
		end
	end
	function triptr:onCommit()
		local song = songs[selectedSong];
		local ptrn = song.patterns[selectedPattern];
		local hex = tonumber(self.text,16);
		rom:put( ptrn.header_start_index + 3, hex )
		parseAllSongs();
	end
	
	local p1ptr = ElementTextEntry.new(65,40,GROUP_PNTR_EDIT.ELM_BODY,2); p1ptr.staticposition = true;
	--{x=0,y=0,width=65,height=40,parent=pointeredit, text="", staticposition = true, maxlen = 2};
	function p1ptr:onUpdate()
		local song = songs[selectedSong];
		local ptrn = song.patterns[selectedPattern];
		self.x = self.parent.dispx + 385;
		self.y = self.parent.dispy + 158;
		if selectedTextEntry and selectedTextBox == self then
			self.text = selectedTextEntry;
		else
			self.text = string.format("%02X", rom:get(ptrn.header_start_index + 4));
		end
	end
	function p1ptr:onCommit()
		local song = songs[selectedSong];
		local ptrn = song.patterns[selectedPattern];
		local hex = tonumber(self.text,16);
		rom:put( ptrn.header_start_index + 4, hex )
		parseAllSongs();
	end
	
	local p2ptr = ElementTextEntry.new(100,40,GROUP_PNTR_EDIT.ELM_BODY,4); p2ptr.staticposition = true;
	--{x=0,y=0,width=100,height=40,parent=pointeredit, text="", staticposition = true, maxlen = 4};
	function p2ptr:onUpdate()
		local song = songs[selectedSong];
		local ptrn = song.patterns[selectedPattern];
		self.x = self.parent.dispx + 285;
		self.y = self.parent.dispy + 115;
		if selectedTextEntry and selectedTextBox == self then
			self.text = selectedTextEntry;
		else
			self.text = string.format("%04X", ptrn.pulse2_start_index);
		end
	end
	function p2ptr:onCommit()
		local song = songs[selectedSong];
		local ptrn = song.patterns[selectedPattern];
		local hex = tonumber(self.text,16);
		rom:putWord(ptrn.header_start_index + 1, (0x8000 + hex) - 0x10);
		parseAllSongs();
	end
	
	local pointer = ElementTextEntry.new(65,40,GROUP_PNTR_EDIT.ELM_BODY,2); pointer.staticposition = true;
	--{x=0,y=0,width=65,height=40,parent=pointeredit, text="", staticposition = true, maxlen = 2};
	function pointer:onUpdate()
		local song = songs[selectedSong];
		local ptrn = song.patterns[selectedPattern];
		self.x = self.parent.dispx + 250;
		self.y = self.parent.dispy + 75;
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
	
	GROUP_PNTR_EDIT.BTN_BACK = GuiElement.new(0,0,100,50,GROUP_PNTR_EDIT,"Back");
	--{x=0,y=0,width=100,height=50,parent=GROUP_PNTR_EDIT, text="Back"};
	function GROUP_PNTR_EDIT.BTN_BACK:onClick()
		GROUP_EDIT:hide(); GROUP_PNTR_EDIT:hide(); openGUIWindow( GROUP_TOPBAR );
	end
	
	-- PARSE ERROR: Shows up when an error happens in parsing song data and it can't continue
	GROUP_PARSE_ERROR = GuiElement.new(55,55,600,3);
	GROUP_PARSE_ERROR.autopos = "top"; GROUP_PARSE_ERROR.autosize = true;
	GROUP_PARSE_ERROR.autocenterX = true; GROUP_PARSE_ERROR.autocenterY = true;
	--{x=55, y=55, width=600, height=3, autopos = "top", autosize = true, autocenterX = true, autocenterY = true}; 
	GROUP_PARSE_ERROR:hide();
	GROUP_PARSE_ERROR.ELM_BODY = GuiElement.new(0,0,450,350,GROUP_PARSE_ERROR);
	--{x=0,y=0,width=450,height=350,parent=GROUP_PARSE_ERROR, text=""};
	GROUP_PARSE_ERROR.BTN_BACK = GuiElement.new(0,0,100,50,GROUP_PARSE_ERROR,"OK");
	--{x=0,y=0,width=100,height=50,parent=GROUP_PARSE_ERROR, text="OK"};
	function GROUP_PARSE_ERROR.BTN_BACK:onClick()
		GROUP_PARSE_ERROR:hide(); GROUP_PARSE_ERROR.active = false;
	end
	
	GROUP_EXPORT_SUCCESS = GuiElement.new(55,55,600,3);
	GROUP_EXPORT_SUCCESS.autopos = "top"; GROUP_EXPORT_SUCCESS.autosize = true;
	GROUP_EXPORT_SUCCESS.autocenterX = true; GROUP_EXPORT_SUCCESS.autocenterY = true;
	--{x=55, y=55, width=600, height=3, autopos = "top", autosize = true, autocenterX = true, autocenterY = true};
	GROUP_EXPORT_SUCCESS:hide();
	GROUP_EXPORT_SUCCESS.ELM_BODY = GuiElement.new(0,0,450,130,GROUP_EXPORT_SUCCESS,"Successfully exported!\n\nRemember to back up your work frequently. This program is very unstable!");
	--{x=0,y=0,width=450,height=130,parent=GROUP_EXPORT_SUCCESS, text="Successfully exported!\n\nRemember to back up your work frequently. This program is very unstable!"};
	GROUP_EXPORT_SUCCESS.BTN_BACK = GuiElement.new(0,0,100,50,GROUP_EXPORT_SUCCESS,"OK");
	--{x=0,y=0,width=100,height=50,parent=GROUP_EXPORT_SUCCESS, text="OK"};
	function GROUP_EXPORT_SUCCESS.BTN_BACK:onClick()
		GROUP_EXPORT_SUCCESS:hide(); openGUIWindow( GROUP_TOPBAR );
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
		GROUP_PTRN_SIDE.active = true; GROUP_PTRN_SIDE:show();
		GROUP_PIANOROLL_EDIT.active = true; GROUP_PIANOROLL_EDIT:show();
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

function renderGUI()

	for i = 1, #elements do
		local e = elements[i];
		e:render();
	end
end