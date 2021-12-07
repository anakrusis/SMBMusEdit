require "song"
require "pattern"
require "rom"
require "bitwise"
require "playback"
require "render"
require "gui"

local utf8 = require("utf8")

function love.load()
	VERSION_NAME = "SMBMusEdit pre-0.1.0a test build #3"
	
	selectedChannel = "tri";
	selectedPattern = 0;
	selectedSong    = 0;
	
	love.graphics.setDefaultFilter("nearest");
	TEXTURE_PENCIL = love.graphics.newImage("assets/pencil.png");
	TEXTURE_SELECT = love.graphics.newImage("assets/select.png");
	CURSOR_PENCIL  = love.mouse.newCursor( "assets/pencil.png", 0, 15 )
	
	love.window.setTitle(VERSION_NAME);
	success = love.window.setMode( 800, 800, {resizable=true, minwidth=800, minheight=600} )
	love.window.setVSync( 1 );
	WINDOW_WIDTH = 800; WINDOW_HEIGHT = 800;
	font = love.graphics.newFont("assets/zeldadxt.ttf", 24)
	love.graphics.setFont(font)
	CURSOR_HORIZ = love.mouse.getSystemCursor( "sizewe" );
	CURSOR_VERT  = love.mouse.getSystemCursor( "sizens" );
	
	frameCount = 0; -- just how many ticks the window has been open
	
	rom = ROM:new();
	PlaybackHandler:initSources();
	initGUI();
	
	-- In the future this can be stored in files of presets for each game's songs
	SONG_COUNT = 0;
	songs = {};
	local s;
	s = Song:new{ name = "Mario Dies", 
	ptr_start_index = 0x791d, hasNoise = false, loop = false };
	s = Song:new{ name = "Game Over",
	ptr_start_index = 0x791e, hasNoise = false, loop = false };
	s = Song:new{ name = "Princess Rescued",
	ptr_start_index = 0x791f, hasNoise = false, loop = true, quarter_note_duration = 48 };
	s = Song:new{ name = "Toad Rescued",
	ptr_start_index = 0x7920, hasNoise = false, loop = false, quarter_note_duration = 48 };
	s = Song:new{ name = "Game Over (Alt.)",
	ptr_start_index = 0x7921, hasNoise = false, loop = false };	
	s = Song:new{ name = "Level Complete",
	ptr_start_index = 0x7922, hasNoise = false, loop = false, quarter_note_duration = 48 };
	s = Song:new{ name = "Hurry Up!",
	ptr_start_index = 0x7923, hasNoise = false, loop = false, quarter_note_duration = 48 };
	s = Song:new{ name = "Silence",
	ptr_start_index = 0x7924, hasNoise = false, loop = false };
	s = Song:new{ name = "(Unknown)",
	ptr_start_index = 0x7925, hasNoise = true, loop = false };
	s = Song:new{ name = "Underwater",
	ptr_start_index = 0x7926, hasNoise = true,  loop = true, quarter_note_duration = 48 };	
	s = Song:new{ name = "Underground",
	ptr_start_index = 0x7927, hasNoise = false, loop = true, hasPulse1 = false };	
	s = Song:new{ name = "Castle",
	ptr_start_index = 0x7928, hasNoise = false, loop = true, quarter_note_duration = 40 };	
	s = Song:new{ name = "Coin Heaven",
	ptr_start_index = 0x7929, hasNoise = true,  loop = true, quarter_note_duration = 48 };	
	s = Song:new{ name = "Pipe Cutscene",
	ptr_start_index = 0x792a, hasNoise = true,  loop = false };	
	s = Song:new{ name = "Starman",
	ptr_start_index = 0x792b, hasNoise = true,  loop = true, quarter_note_duration = 48 };
	s = Song:new{ name = "Lives Screen",
	ptr_start_index = 0x792c, hasNoise = false, loop = false };
	s = Song:new{ name = "Overworld",
	ptr_start_index = 0x792d, hasNoise = true,  loop = true, patternCount = 33 };
end

function parseAllSongs()

	-- resets all claims within the range of the music data section
	local DATA_START = 0x79C8;
	local DATA_END   = 0x7F0F;
	for i = DATA_START, DATA_END do
		local byt = rom.data[i];
		byt.song_claims = {};
		byt.ptrn_claims = {};
		byt.chnl_claims = {};
	end
	
	local errorcaught = false;
	local errortext = "Errors occurred during the parsing of these songs:\n\n";
	
	-- then parses the songs all
	for i = 0, SONG_COUNT - 1 do
		local s = songs[i]; 
		local success = s:parse();
		
		if not success then
			errortext = errortext .. s.name .. "\n"
			errorcaught = true;
		end
	end
	if errorcaught then
		errortext = errortext .. "\nPlease ensure that all pointers are properly placed, and that this is a functioning game file."
		GROUP_PARSE_ERROR.ELM_BODY.text = errortext;
		GROUP_PARSE_ERROR:show();
		GROUP_PARSE_ERROR.active = true;
		return;
	end
	
	-- after parsing is done we count the used bytes
	for i = 0, SONG_COUNT - 1 do
		local s = songs[i]; s:countBytes();
	end
	-- and the number of used patterns of overworld music will be counted as well:
	-- (The overworld theme is always the last one)
	local overworld = songs[#songs];
	
	local last_nonempty_ptrn_ind = 0;
	for i = 0, overworld.patternCount - 1 do
		local p = overworld.patterns[i];
		if p.duration > 0 then
			last_nonempty_ptrn_ind = i;
		end
	end
	-- Plus one because it is counting the total number of patterns, plus 0x11 because (I don't know why)
	rom:put(0x76f6, last_nonempty_ptrn_ind + 0x11 + 1)
end

function love.textinput(t)
    if selectedTextBox then
		if selectedTextBox.maxlen > #selectedTextEntry then
			selectedTextEntry = selectedTextEntry .. t;
		end
	end
end

function love.filedropped(file)
	rom = ROM:new();
	rom:import(file);
	initPitchTables();
	initRhythmTables();
	selectSong(16);
	openGUIWindow(GROUP_TOPBAR);
end

function love.keypressed(key)
	if selectedTextEntry then
		if key == "return" then
			if not tonumber(selectedTextBox.text,16) then return end
			selectedTextBox:onCommit();
			selectedTextBox = nil;
			selectedTextEntry = nil;
		end
		if key == "backspace" then
        -- get the byte offset to the last UTF-8 character in the string.
			local byteoffset = utf8.offset(selectedTextEntry, -1)

			if byteoffset then
				-- remove the last UTF-8 character.
				-- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
				selectedTextEntry = string.sub(selectedTextEntry, 1, byteoffset - 1)
			end
		end
	else
		if key == "space" or key == "return" then
			PlaybackHandler:togglePlaying();
		end
		if key == "escape" then
			for i = #elements, 1, -1 do
				local e = elements[i];
				if (e.active and not e.parent and e.BTN_BACK) then
					e.BTN_BACK:onClick();
					break;
				end
			end
		end
		if key == "b" then
			PENCIL_MODE = not PENCIL_MODE;
		end
	end
end

function love.mousepressed( x,y,button )
	if (button ~= 3) then
		clickGUI(x,y);
	end
	if (bypassGameClick) then bypassGameClick = false; return; end
	
	if GROUP_FILE.active or GROUP_EDIT.active then
		GROUP_FILE:hide(); GROUP_EDIT:hide();
		openGUIWindow(GROUP_TOPBAR);
	end
	
	local ptrn = songs[selectedSong].patterns[selectedPattern];
	if not ptrn then return end
	
	-- left clicking on the piano roll has several functions:
	if (button == 1) then
		if love.mouse.getY() > DIVIDER_POS then
			local tick = (piano_roll_untrax(x));
			
			-- clicking the bar at the very top of the piano roll:
			-- initiates dragging for pattern endpoint changing
			if love.mouse.getY() < DIVIDER_POS + PIANOROLL_TOPBAR_HEIGHT then
				local enddist = math.abs( tick - ptrn.duration );
				if enddist < 16 and ( selectedChannel == "pulse2") then
					PTRN_END_DRAGGING = true;
				end
				enddist = math.abs( tick - ptrn.noiseduration );
				if enddist < 16 and ( selectedChannel == "noise") then
					PTRN_END_DRAGGING = true;
				end
				
			-- clicking elsewhere in the piano roll:
			elseif love.mouse.getX() > SIDE_PIANO_WIDTH then
				local pitch = math.ceil(piano_roll_untray(y));
				local existingnote = ptrn:getNoteAtTick(math.floor(tick), selectedChannel);
				
				-- clicking the right edge of a note: initates dragging for rhythm changing
				-- (This will happen regardless of the pencil mode stuff below)
				if existingnote then
				if (tick > ( existingnote.duration * 0.85 ) + existingnote.starttime) then
					DRAGGING_NOTE = existingnote.noteindex;
					return;
				end
				end
				
				-- pencil tool: all the direct note placement/removal actions
				-- (can also drag the edge of notes too)
				if PENCIL_MODE then
					-- no note present in this space? must be past the edge of pattern. try appending a note
					if (not existingnote) then
						ptrn:appendNote(pitch, tick, selectedChannel);
						return;
					end
					
					-- click within bounds: deciding to initiate either multiple note removing or placing...
					-- if a rest, or the note value differs, then place a new note here.
					if existingnote.pitch ~= pitch or existingnote.val == 0x04 then
						ptrn:writePitch(pitch,existingnote,selectedChannel);
						PLACING_NOTE = true;
					
					-- if a note, and the note value is the same, then remove the current note here
					else
						ptrn:writePitch(existingnote.pitch,existingnote,selectedChannel);
						REMOVING_NOTE = true;
					end
					
				-- not pencil tool: (todo)note selection, dragging of notes
				-- it will also set the playhead if clicked somewhere
				else
					SELECTION_P1X = love.mouse.getX(); SELECTION_P1Y = love.mouse.getY()
				end
			end
		end
	end
end

function love.mousereleased( x,y,button )
	DRAGGING_NOTE = nil;
	PTRN_END_DRAGGING = false;
	PLACING_NOTE = false;
	REMOVING_NOTE = false;
	SELECTION_P1X = nil; SELECTION_P1Y = nil; SELECTION_P2X = nil; SELECTION_P2Y = nil;
end

function love.mousemoved( x, y, dx, dy, istouch )
	love.mouse.setCursor()

	-- middle click and dragging: pans the view
	if love.mouse.isDown( 3 ) then
		if love.mouse.getY() > DIVIDER_POS then
			PIANOROLL_SCROLLX = PIANOROLL_SCROLLX - (dx / PIANOROLL_ZOOMX);
			PIANOROLL_SCROLLY = PIANOROLL_SCROLLY - (dy / PIANOROLL_ZOOMY);
		else 
			PATTERN_SCROLL = PATTERN_SCROLL - (dx / PATTERN_ZOOMX);
		end
	end
	
	local ptrn = songs[selectedSong].patterns[selectedPattern];
	if not ptrn then return end
	
	-- left click and dragging: various functions
	if love.mouse.isDown( 1 ) then	
		if love.mouse.getY() > DIVIDER_POS then
			local tick = math.floor(piano_roll_untrax(x));
			-- dragging left and right on a note: edits the rhythm
			if (DRAGGING_NOTE) then
				ptrn:changeRhythm( tick, DRAGGING_NOTE, selectedChannel );
			
			-- dragging on the top bar of the piano roll: edits the pattern end point
			elseif (PTRN_END_DRAGGING) then
				ptrn:changeEndpoint( tick, selectedChannel );
				
			-- dragging over existing notes: overwrites their note values
			elseif PLACING_NOTE then 
				local pitch = math.ceil(piano_roll_untray(y));
				local existingnote = ptrn:getNoteAtTick(math.floor(tick), selectedChannel);
				
				if existingnote and existingnote.pitch ~= pitch then
					ptrn:writePitch(pitch,existingnote,selectedChannel);
				end
			-- ditto but also can remove them
			elseif REMOVING_NOTE then
				local pitch = math.ceil(piano_roll_untray(y));
				local existingnote = ptrn:getNoteAtTick(math.floor(tick), selectedChannel);
				
				if existingnote and existingnote.pitch == pitch then
					ptrn:writePitch(existingnote.pitch,existingnote,selectedChannel);
				end
			elseif SELECTION_P1X then
				SELECTION_P2X = love.mouse.getX(); SELECTION_P2Y = love.mouse.getY();
				-- TODO select notes
			
			-- dragging left and right in the side piano: zooms in and out the y axis of the piano roll
			elseif love.mouse.getX() < SIDE_PIANO_WIDTH then
				PIANOROLL_ZOOMY = PIANOROLL_ZOOMY + (dx / 2);
				PIANOROLL_ZOOMY = math.max(10, PIANOROLL_ZOOMY);
			
			end
		end
	end
	
	-- Cursors for different mouse usages
	
	if DRAGGING_NOTE or PTRN_END_DRAGGING then love.mouse.setCursor( CURSOR_HORIZ ) end
	
	if love.mouse.getY() > DIVIDER_POS and GROUP_TOPBAR.active then
		local tick = (piano_roll_untrax(x));
		
		-- Dragging pattern length 
		if love.mouse.getY() < DIVIDER_POS + PIANOROLL_TOPBAR_HEIGHT then
			local enddist = math.abs( tick - ptrn.duration );
			if enddist < 16 and ( selectedChannel == "pulse2") then
				love.mouse.setCursor( CURSOR_HORIZ )
			end
			enddist = math.abs( tick - ptrn.noiseduration );
			if enddist < 16 and ( selectedChannel == "noise") then
				love.mouse.setCursor( CURSOR_HORIZ )
			end
			
		-- regular note editing
		elseif love.mouse.getX() > SIDE_PIANO_WIDTH then
			-- if pencil mode, use pencil cursor by default
			if PENCIL_MODE then love.mouse.setCursor(CURSOR_PENCIL) end
			
			local note = math.ceil(piano_roll_untray(y));
			local existingnote = ptrn:getNoteAtTick(math.floor(tick), selectedChannel);
			if (not existingnote) then
				return;
			end
			if (tick > ( existingnote.duration * 0.85 ) + existingnote.starttime) then
				love.mouse.setCursor( CURSOR_HORIZ )
			end
		end
	end
end

function love.wheelmoved( x, y )
	if GROUP_OPTIMIZE.active then
		OPTIMIZE_SCROLL = OPTIMIZE_SCROLL - ((y * 50));
	else
		-- mouse wheel on the piano roll: scrolls vertically
		if love.mouse.getY() > DIVIDER_POS then
			if love.keyboard.isDown( "lctrl" ) then
				if love.mouse.getY() > DIVIDER_POS then
					PIANOROLL_ZOOMX = PIANOROLL_ZOOMX + (y / 2);
					PIANOROLL_ZOOMX = math.max(1, PIANOROLL_ZOOMX);
				else
					PATTERN_ZOOMX = PATTERN_ZOOMX + (y / 2);
					PATTERN_ZOOMX = math.max(0.5, PATTERN_ZOOMX);
				end
			else
				PIANOROLL_SCROLLY = PIANOROLL_SCROLLY - ((y * 50) / PIANOROLL_ZOOMY);
			end
		else	
			
		end
	end
end

function love.update(dt)
	WINDOW_WIDTH, WINDOW_HEIGHT, flags = love.window.getMode();
	
	-- pianoroll left-side limit
	local zeromark = ((WINDOW_WIDTH / 2) / PIANOROLL_ZOOMX)
	PIANOROLL_SCROLLX = math.max( PIANOROLL_SCROLLX, zeromark )
	PIANOROLL_ZOOMX = math.max(1, PIANOROLL_ZOOMX);
	-- pattern editor left-side limit
	--zeromark = ((WINDOW_WIDTH / 2) / PATTERN_SCROLL)
	PATTERN_SCROLL = math.max( PATTERN_SCROLL, 0 )
	
	updateGUI();
	frameCount = frameCount + 1;
	PlaybackHandler:update();
end

function popupText(text,color)
	-- this is to prevent the animation from continuing to retrigger
	if (text ~= popup_text or popup_timer <= 0) then
		popup_start = -30;
	end
	popup_timer = 9 * #text; 
	popup_text = text; 
	popup_color = color;
end

function selectSong(index)
	PlaybackHandler:stop(); PlaybackHandler:reset();
	selectedSong = index; selectedPattern = 0; selectedChannel = "pulse2";
	
	if rom.path then
		parseAllSongs();
		updatePatternGUI( songs[index] );
		
		love.window.setTitle(rom.filename .. " [" .. songs[index].name .. "] - " .. VERSION_NAME)
	end
	PATTERN_SCROLL = 0;
	PIANOROLL_SCROLLX = 0; PIANOROLL_SCROLLY = 0;
end

function selectPattern(song, index, chnl)
	local ptrn = songs[song].patterns[index];
	selectedPattern = index;
	selectedChannel = chnl;
	
	-- sets the position of the playhead relative to wherever you clicked in this button
	--local relx = x - self.dispx;
	--local tick = (relx / self.dispwidth) * ptrn.duration;
	
	PlaybackHandler.setsongpos = ptrn.starttime; --+ tick;
	PlaybackHandler.setplaypos = 0;
	PlaybackHandler.setPattern = index;
	
	PIANOROLL_SCROLLX = 0; PIANOROLL_SCROLLY = 0;
end

function love.draw()
	-- Piano roll rendering
	local ptrn = songs[selectedSong].patterns[ selectedPattern ];
	
	-- background of the piano roll (red)
	love.graphics.setColor( 0.40,0.10,0.10 );
	love.graphics.rectangle("fill",0,DIVIDER_POS,WINDOW_WIDTH,WINDOW_HEIGHT);
	renderAvailableNotes( selectedChannel );
	
	if (ptrn) then
		renderChannel( ptrn:getNotes(selectedChannel), CHANNEL_COLORS[selectedChannel]);
		
		renderOverlap()
	end
	
	-- play line
	if (PlaybackHandler.playingPattern == selectedPattern) then
		local linepos = PlaybackHandler.playpos;
		if selectedChannel == "noise" then
			linepos = linepos % ptrn.noiseduration;
		end
		love.graphics.setColor( 1,1,1 );
		local linex = pianoroll_trax(linepos);
		love.graphics.line(linex,DIVIDER_POS,linex,WINDOW_HEIGHT);
	end
	
	-- top bar (pattern length indicator)
	if selectedChannel == "pulse2" and ptrn then
		love.graphics.setColor( CHANNEL_COLORS[selectedChannel] );
		love.graphics.rectangle("fill",pianoroll_trax(0),DIVIDER_POS,pianoroll_trax(ptrn.duration)-pianoroll_trax(0),PIANOROLL_TOPBAR_HEIGHT);
	end
	if selectedChannel == "noise" and ptrn then
		love.graphics.setColor( CHANNEL_COLORS[selectedChannel] );
		love.graphics.rectangle("fill",pianoroll_trax(0),DIVIDER_POS,pianoroll_trax(ptrn.noiseduration)-pianoroll_trax(0),PIANOROLL_TOPBAR_HEIGHT);
	end
	renderSidePiano();
	
	-- masks out anything of the piano roll rendered above the divider
	love.graphics.setColor( 0,0,0 );
	love.graphics.rectangle("fill",0,0,WINDOW_WIDTH,DIVIDER_POS);
	love.graphics.setColor( 1,1,1 );
	love.graphics.line(0,DIVIDER_POS,WINDOW_WIDTH,DIVIDER_POS);
	
	-- Pattern editor rendering
	--love.graphics.rectangle("fill",0,0,ptrn.duration,50);
	
	-- Overlaid text not part of a gui element
	if (ptrn) then
		if SELECTION_P1X and SELECTION_P2X then
			love.graphics.setColor( 1,1,1 );
			love.graphics.rectangle("line",SELECTION_P1X,SELECTION_P1Y,SELECTION_P2X-SELECTION_P1X,SELECTION_P2Y-SELECTION_P1Y);
		end
	else
		-- Text when you have nothing loaded in
		love.graphics.setColor( 1,1,1 );
		local txt_noload = "Drop your ROM here to get started!";
		love.graphics.printf(txt_noload, SIDE_PIANO_WIDTH, DIVIDER_POS + (( WINDOW_HEIGHT - DIVIDER_POS ) / 2), WINDOW_WIDTH - SIDE_PIANO_WIDTH, "center" );
	end
	
	-- All the buttons and menus and stuff
	renderGUI();
	
	-- pattern editor play line
	love.graphics.setColor( 1,1,1 );
	local linex = ((PlaybackHandler.songpos - PATTERN_SCROLL) * PATTERN_ZOOMX) + PTRN_SIDE_WIDTH;
	love.graphics.line(linex,120,linex,DIVIDER_POS - 5);
	
	-- set play line
	love.graphics.setColor( 0,1,1 );
	local linex = ((PlaybackHandler.setsongpos - PATTERN_SCROLL) * PATTERN_ZOOMX) + PTRN_SIDE_WIDTH;
	love.graphics.line(linex,120,linex,DIVIDER_POS - 5);
	
	-- popup text
	if popup_timer > 0 then
		local py = WINDOW_HEIGHT - 72 - 2*popup_start;
		if (popup_timer < 30) then py = py + 2*( 30 - popup_timer ) end
		
		love.graphics.setColor( 0,0,0 );
		love.graphics.rectangle("fill",0,py,WINDOW_WIDTH,py);
		love.graphics.setColor( popup_color );
		love.graphics.printf( popup_text, 0, py + 8, WINDOW_WIDTH, "center" );
	
		popup_timer = popup_timer - 1;
		popup_start = math.min(0, popup_start + 1);
	end
end

function initRhythmTables()
	RHYTHM_TABLE = {}; 
	RHYTHM_STRT_INDEX = 0x7F76;
	
	for i = 0, 0x2f do
		RHYTHM_TABLE[i] = rom:get( RHYTHM_STRT_INDEX + i );
	end
end

-- converts apu timer values to frequency values which can be used in playback
-- ( consulted here for info https://wiki.nesdev.org/w/index.php?title=APU_Pulse )

function initPitchTables()
	-- Timer values are the divider values that are fed to the apu from this table. They are inversely proportional to frequency
	TIMER_TABLE = {};
	-- Frequency values, are what it will really sound like in playback
	FREQ_TABLE  = {};
	-- Corresponding midi notes
	NOTES       = {};
	-- list of valid "val" values (internal note index) indexed with the midi note (this is a reverse index of NOTES)
	PITCH_VALS  = {};
	
	TIMER_STRT_INDEX = 0x7f10;
	for i = 0, 0x65, 2 do
		local ind = ( i + TIMER_STRT_INDEX );
		TIMER_TABLE[ i ] = rom:get( ind );
		
		local timer = (0x100 * rom:get( ind )) + rom:get( ind + 1 );
		--print( string.format( "%02X", timer) );
		local freq = 1789773 / ( 16 * ( timer + 1 ) );
		--print( freq .. "Hz" );
		
		FREQ_TABLE[ i ] = freq;
		
		local pitchlog = math.log( freq/440 ) / math.log(2);
		local noteval = math.floor((12 * pitchlog) + 69 + 0.5);
		--print( noteval )
		
		if (i ~= 04) then
			NOTES[ i ] = noteval;
			PITCH_VALS[ noteval ] = i
		end
	end
end