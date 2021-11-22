require "song"
require "pattern"
require "rom"
require "bitwise"
require "playback"
require "render"
require "guielement"
require "gui"
local utf8 = require("utf8")

function love.load()
	
	SRC_PULSE2 = love.audio.newSource( "square.wav", "static" );
	SRC_PULSE2:setLooping(true); SRC_PULSE2:setVolume(0.6);
	SRC_PULSE1 = love.audio.newSource( "square.wav", "static" );
	SRC_PULSE1:setLooping(true); SRC_PULSE1:setVolume(0.6);
	SRC_TRI = love.audio.newSource( "tri.wav", "static" );
	SRC_TRI:setLooping(true);
	
	SRC_KICK = love.audio.newSource("kick.wav", "static");
	SRC_CH   = love.audio.newSource("ch.wav", "static");
	SRC_OH   = love.audio.newSource("oh.wav", "static");
	
	playing = false; playpos = 0; songpos = 0; -- current tick in pattern
	playingPattern = 0;
	preview_playing = false; previewtick = 0; previewpitch = 0; -- preview note when placing down
	
	selectedChannel = "tri";
	selectedPattern = 0;
	selectedSong    = 0;
	
	love.window.setTitle("SMBMusEdit 0.1.0a pre")
	success = love.window.setMode( 800, 800, {resizable=true, minwidth=800, minheight=600} )
	font = love.graphics.newFont("zeldadxt.ttf", 24)
	love.graphics.setFont(font)
	frameCount = 0; -- just how many ticks the window has been open
	
	rom = ROM:new(); --rom:import("smbmusedit-2/mario.nes");
	
	--initPitchTables();
	--initRhythmTables();
	initGUI();
	
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
	
	--parseAllSongs();
	
	--selectSong(16);
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

	-- then parses the songs all
	for i = 0, SONG_COUNT - 1 do
		local s = songs[i]; s:parse();
	end
	-- after parsing is done we count the used bytes
	for i = 0, SONG_COUNT - 1 do
		local s = songs[i]; s:countBytes();
	end
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
	parseAllSongs();
	selectSong(16);
	openGUIWindow(GROUP_TOPBAR);
end

function love.keypressed(key)
	if selectedTextEntry then
		if key == "return" then
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
			local ptrn = songs[selectedSong].patterns[selectedPattern];
			if not ptrn then return end
			
			playing = not playing;
			playpos = 0; songpos = ptrn.starttime;
			playingPattern = selectedPattern;
			if (not playing) then stop(); end
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
				if enddist < 16 then
					print("dragging end point");
					PTRN_END_DRAGGING = true;
				end
				
			-- clicking elsewhere in the piano roll:
			elseif love.mouse.getX() > SIDE_PIANO_WIDTH then
				local note = math.ceil(piano_roll_untray(y));
				local existingnote = ptrn:getNoteAtTick(math.floor(tick), selectedChannel);
				
				-- no note present in this space? must be past the edge of pattern. try appending a note
				if (not existingnote) then
					ptrn:appendNote(note, tick, selectedChannel);
					return;
				end
				
				-- clicking the right edge of a note: initates dragging for rhythm changing
				if (tick > ( existingnote.duration * 0.8 ) + existingnote.starttime) then
					DRAGGING_NOTE = existingnote.noteindex;
					
				-- otherwise places/removes notes where notes are present
				else
					ptrn:writePitch(note,existingnote,selectedChannel);
				end
			end
		end
	end
end

function love.mousereleased( x,y,button )
	DRAGGING_NOTE = nil;
	PTRN_END_DRAGGING = false;
end

function love.mousemoved( x, y, dx, dy, istouch )
	-- middle click and dragging: pans the view
	if love.mouse.isDown( 3 ) then
		if love.mouse.getY() > DIVIDER_POS then
			PIANOROLL_SCROLLX = PIANOROLL_SCROLLX - (dx / PIANOROLL_ZOOMX);
			PIANOROLL_SCROLLY = PIANOROLL_SCROLLY - (dy / PIANOROLL_ZOOMY);
		else 
			PATTERN_SCROLL = PATTERN_SCROLL - (dx / PATTERN_ZOOMX);
		end
	end
	
	-- left click and dragging: various functions
	if love.mouse.isDown( 1 ) then	
		if love.mouse.getY() > DIVIDER_POS then
			local tick = math.floor(piano_roll_untrax(x));
			-- dragging left and right on a note: edits the rhythm
			if (DRAGGING_NOTE) then
				songs[selectedSong].patterns[selectedPattern]:changeRhythm( tick, DRAGGING_NOTE, selectedChannel );
			
			-- dragging on the top bar of the piano roll: edits the pattern end point
			elseif (PTRN_END_DRAGGING) then
				songs[selectedSong].patterns[selectedPattern]:changeEndpoint( tick, selectedChannel );
			
			-- dragging left and right in the side piano: zooms in and out the y axis of the piano roll
			elseif love.mouse.getX() < SIDE_PIANO_WIDTH then
				PIANOROLL_ZOOMY = PIANOROLL_ZOOMY + (dx / 2);
				PIANOROLL_ZOOMY = math.max(10, PIANOROLL_ZOOMY);
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
	
	--local zeromark = ((0 - PIANOROLL_SCROLLX) * PIANOROLL_ZOOMX) + WINDOW_WIDTH / 2;
	local zeromark = ((WINDOW_WIDTH / 2) / PIANOROLL_ZOOMX)
	PIANOROLL_SCROLLX = math.max( PIANOROLL_SCROLLX, zeromark )
	
	PIANOROLL_ZOOMX = math.max(1, PIANOROLL_ZOOMX);
	
	updateGUI();
	frameCount = frameCount + 1;
	
	if (playing) then
		play();
	end
	if (preview_playing) then
		playPreview();
	end
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
	stop(); playpos = 0; songpos = 0; selectedSong = index;
	selectedPattern = 0; selectedChannel = "pulse2";
	if rom.path then
		parseAllSongs();
		updatePatternGUI( songs[index] );
	end
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
	end
	
	-- play line
	if (playingPattern == selectedPattern) then
		love.graphics.setColor( 1,0,0 );
		local linex = pianoroll_trax(playpos);
		love.graphics.line(linex,DIVIDER_POS,linex,WINDOW_HEIGHT);
	end
	
	if selectedChannel == "pulse2" and ptrn then
		love.graphics.setColor( CHANNEL_COLORS[selectedChannel] );
		love.graphics.rectangle("fill",pianoroll_trax(0),DIVIDER_POS,pianoroll_trax(ptrn.duration)-pianoroll_trax(0),PIANOROLL_TOPBAR_HEIGHT);
	end
	renderSidePiano();
	
	-- masks out anything of the piano roll rendered above the divider
	love.graphics.setColor( 0,0,0 );
	love.graphics.rectangle("fill",0,0,WINDOW_WIDTH,DIVIDER_POS);
	love.graphics.setColor( 1,1,1 );
	love.graphics.line(0,DIVIDER_POS,WINDOW_WIDTH,DIVIDER_POS);
	
	-- Pattern editor rendering
	--love.graphics.rectangle("fill",0,0,ptrn.duration,50);
	
	-- All the buttons and menus and stuff
	renderGUI();
	
	-- Overlaid text not part of a gui element
	if (ptrn) then
		-- Bytes free out of bytes total enqueued
		love.graphics.setColor( 1,1,1 );
		local bytes_str = ptrn:getBytesUsed(selectedChannel) .. "/" .. ptrn:getBytesAvailable(selectedChannel);
		love.graphics.print( bytes_str, WINDOW_WIDTH - 135, DIVIDER_POS + 32 )
	
	else
		-- Text when you have nothing loaded in
		love.graphics.setColor( 1,1,1 );
		local txt_noload = "Drop a ROM here to get started!";
		love.graphics.printf(txt_noload, SIDE_PIANO_WIDTH, DIVIDER_POS + (( WINDOW_HEIGHT - DIVIDER_POS ) / 2), WINDOW_WIDTH - SIDE_PIANO_WIDTH, "center" );
	end
	
	-- pattern editor play line
	love.graphics.setColor( 1,0,0 );
	local linex = ((songpos - PATTERN_SCROLL) * PATTERN_ZOOMX) --+ WINDOW_WIDTH / 2;
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