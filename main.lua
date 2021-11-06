require "song"
require "pattern"
require "rom"
require "bitwise"
require "render"
require "guielement"
require "gui"

function love.load()
	
	SRC_PULSE2 = love.audio.newSource( "square.wav", "static" );
	SRC_PULSE2:setLooping(true);
	SRC_PULSE1 = love.audio.newSource( "square.wav", "static" );
	SRC_PULSE1:setLooping(true);
	SRC_TRI = love.audio.newSource( "tri.wav", "static" );
	SRC_TRI:setLooping(true);
	
	playing = false; playpos = 0; songpos = 0; -- current tick in pattern
	playingPattern = 0;
	
	selectedChannel = "tri";
	selectedPattern = 0;
	selectedSong    = 0;
	
	love.window.setTitle("SMBMusEdit 0.1.0a")
	success = love.window.setMode( 800, 600, {resizable=true, minwidth=800, minheight=600} )
	font = love.graphics.newFont("zeldadxt.ttf", 24)
	love.graphics.setFont(font)
	
	rom = ROM:new(); rom:import("smbmusedit-2/mario.nes");
	
	initPitchTables();
	initRhythmTables();
	initGUI();
	
	SONG_COUNT = 0;
	songs = {};
	local s;
	s = Song:new{ name = "Mario Dies", 
	ptr_start_index = 0x791d, hasNoise = false, loop = false };
	s = Song:new{ name = "Game Over",
	ptr_start_index = 0x791e, hasNoise = false, loop = false };
	s = Song:new{ name = "Princess Rescued",
	ptr_start_index = 0x791f, hasNoise = false, loop = true };
	s = Song:new{ name = "Toad Rescued",
	ptr_start_index = 0x7920, hasNoise = false, loop = false };
	s = Song:new{ name = "Game Over (Alt.)",
	ptr_start_index = 0x7921, hasNoise = false, loop = false };	
	s = Song:new{ name = "Level Complete",
	ptr_start_index = 0x7922, hasNoise = false, loop = false };
	s = Song:new{ name = "Hurry Up!",
	ptr_start_index = 0x7923, hasNoise = false, loop = false };
	s = Song:new{ name = "Silence",
	ptr_start_index = 0x7924, hasNoise = false, loop = false };
	s = Song:new{ name = "(Unknown)",
	ptr_start_index = 0x7925, hasNoise = false, loop = false };
	s = Song:new{ name = "Underwater",
	ptr_start_index = 0x7926, hasNoise = true,  loop = true };	
	s = Song:new{ name = "Underground",
	ptr_start_index = 0x7927, hasNoise = false, loop = true, hasPulse1 = false };	
	s = Song:new{ name = "Castle",
	ptr_start_index = 0x7928, hasNoise = false, loop = true };	
	s = Song:new{ name = "Coin Heaven",
	ptr_start_index = 0x7929, hasNoise = true,  loop = true };	
	s = Song:new{ name = "Pipe Cutscene",
	ptr_start_index = 0x792a, hasNoise = true,  loop = false };	
	s = Song:new{ name = "Starman",
	ptr_start_index = 0x792b, hasNoise = true,  loop = true };
	s = Song:new{ name = "Lives Screen",
	ptr_start_index = 0x792c, hasNoise = false, loop = false };
	s = Song:new{ name = "Overworld",
	ptr_start_index = 0x792d, hasNoise = true,  loop = true, patternCount = 33 };
	
	parseAllSongs();
	
	selectSong(1);
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

	-- and then parses the songs all
	for i = 0, SONG_COUNT - 1 do
		local s = songs[i]; s:parse();
	end
end

function love.keypressed(key)
	if key == "return" then
		playing = not playing;
		playpos = 0; songpos = songs[selectedSong].patterns[selectedPattern].starttime;
		playingPattern = selectedPattern;
		if (not playing) then stop(); end
	end
end

function love.mousepressed( x,y,button )
	if (button ~= 3) then
		clickGUI(x,y);
	end
	if (bypassGameClick) then bypassGameClick = false; return; end
	
	-- left clicking on the piano roll has several functions:
	if (button == 1) then
		if love.mouse.getY() > DIVIDER_POS and love.mouse.getX() > SIDE_PIANO_WIDTH then
		
			local note = math.ceil(piano_roll_untray(y));
			local tick = math.floor(piano_roll_untrax(x));
			local ptrn = songs[selectedSong].patterns[selectedPattern];
			local existingnote = ptrn:getNoteAtTick(tick, selectedChannel);
			
			if (not existingnote) then return end
			-- clicking the right edge of the note: initates dragging for rhythm changing
			if (tick > ( existingnote.duration * 0.8 ) + existingnote.starttime) then
				DRAGGING_NOTE = existingnote;
				
			-- otherwise places/removes notes
			else
				ptrn:writePitch(note,existingnote,selectedChannel);
			end
		end
	end
end

function love.mousereleased( x,y,button )
	DRAGGING_NOTE = nil;
end

function love.mousemoved( x, y, dx, dy, istouch )
	-- middle click and dragging: pans the piano roll
	if love.mouse.isDown( 3 ) then
		if love.mouse.getY() > DIVIDER_POS then
			PIANOROLL_SCROLLX = PIANOROLL_SCROLLX - (dx / PIANOROLL_ZOOMX);
			PIANOROLL_SCROLLY = PIANOROLL_SCROLLY - (dy / PIANOROLL_ZOOMY);
		else 
			PATTERN_SCROLL = PATTERN_SCROLL - (dx / PATTERN_ZOOMX);
		end
	end
	-- dragging left and right in the side piano: zooms in and out the y axis of the piano roll
	if love.mouse.isDown( 1 ) then
		if love.mouse.getY() > DIVIDER_POS and love.mouse.getX() < SIDE_PIANO_WIDTH then
			PIANOROLL_ZOOMY = PIANOROLL_ZOOMY + (dx / 2);
			PIANOROLL_ZOOMY = math.max(10, PIANOROLL_ZOOMY);
		
	-- dragging left and right on a note: edits the rhythm
		elseif love.mouse.getY() > DIVIDER_POS then
			if (DRAGGING_NOTE) then
				local tick = math.floor(piano_roll_untrax(x));
				songs[selectedSong].patterns[selectedPattern]:changeRhythm( tick, DRAGGING_NOTE, selectedChannel )
			end
		end
	end
end

function love.wheelmoved( x, y )
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

function love.update(dt)

	if (playing) then
		play();
	end
	
	WINDOW_WIDTH, WINDOW_HEIGHT, flags = love.window.getMode();
	
	--local zeromark = ((0 - PIANOROLL_SCROLLX) * PIANOROLL_ZOOMX) + WINDOW_WIDTH / 2;
	local zeromark = ((WINDOW_WIDTH / 2) / PIANOROLL_ZOOMX)
	PIANOROLL_SCROLLX = math.max( PIANOROLL_SCROLLX, zeromark )
	
	PIANOROLL_ZOOMX = math.max(1, PIANOROLL_ZOOMX);
	
	updateGUI();
end

function errorText(text)

end

function selectSong(index)
	stop(); playpos = 0; songpos = 0; selectedSong = index;
	selectedPattern = 0; selectedChannel = "pulse2";
	parseAllSongs();
	updatePatternGUI( songs[index] );
end

function play()
	local ptrn = songs[selectedSong].patterns[playingPattern];
	playChannel( ptrn.pulse2_notes, SRC_PULSE2 );
	playChannel( ptrn.tri_notes,    SRC_TRI );
	playChannel( ptrn.pulse1_notes, SRC_PULSE1 );
	
	if (playpos >= ptrn.duration) then 
		if songs[selectedSong].loop then
			playingPattern = ( playingPattern + 1 ) % ( songs[selectedSong].patternCount );
			playpos = -1;
			songpos = songpos - 1;
			
			-- loop back to the beginning of song
			if playingPattern == 0 then
				songpos = -1;
			end
		else
			stop();
		end
	end
	
	playpos = playpos + 1;
	songpos = songpos + 1;
end

function playChannel( notes, source )
	if not notes[0] then return end
	for i = 0, #notes do
		local note = notes[i];
		if note.starttime == playpos then
			
			if ( note.val == 04) then
				source:stop();
			else
				local freq = FREQ_TABLE[ note.val ];
				if (source == SRC_TRI) then
					freq = freq / 2;
				end
				source:setPitch( freq / 130.8128 ); -- <- the frequency of the square wave sample im using right now
				source:play();
			end
		end
	end
end

function stop()
	SRC_PULSE2:stop();
	SRC_PULSE1:stop();
	SRC_TRI:stop();
	playing = false;
end

function love.draw()
	-- Piano roll rendering
	local ptrn = songs[selectedSong].patterns[ selectedPattern ];
	
	-- background of the piano roll (red)
	love.graphics.setColor( 0.12,0,0 );
	love.graphics.rectangle("fill",0,DIVIDER_POS,WINDOW_WIDTH,WINDOW_HEIGHT);
	renderAvailableNotes( selectedChannel );
	
	renderChannel( ptrn:getNotes(selectedChannel), CHANNEL_COLORS[selectedChannel]);
	
	-- play line
	if (playingPattern == selectedPattern) then
		love.graphics.setColor( 1,0,0 );
		local linex = pianoroll_trax(playpos);
		love.graphics.line(linex,DIVIDER_POS,linex,WINDOW_HEIGHT);
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
	
	love.graphics.setColor( 1,1,1 );
	local bytes_str = ptrn:getBytesUsed(selectedChannel) .. "/" .. ptrn:getBytesAvailable(selectedChannel);
	love.graphics.print( bytes_str, WINDOW_WIDTH - 100, DIVIDER_POS + 8 )
	
	-- pattern editor play line
	love.graphics.setColor( 1,0,0 );
	local linex = ((songpos - PATTERN_SCROLL) * PATTERN_ZOOMX) --+ WINDOW_WIDTH / 2;
	love.graphics.line(linex,60,linex,DIVIDER_POS);
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