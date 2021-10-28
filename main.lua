require "song"
require "pattern"
require "bitwise"
require "guielement"
require "gui"

function love.load()
	
	SRC_PULSE2 = love.audio.newSource( "square.flac", "static" );
	SRC_PULSE2:setLooping(true);
	SRC_PULSE1 = love.audio.newSource( "square.flac", "static" );
	SRC_PULSE1:setLooping(true);
	SRC_TRI = love.audio.newSource( "square.flac", "static" );
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
	
	local file = io.open("smbmusedit-2/mario.nes", "rb")
	local content = file:read "*a" -- *a or *all reads the whole file
	file:close()
		
	rom = {};	
	for i = 1, #content do
		rom[i - 1] = string.byte(string.sub(content,i,i))
	end
	
	initPitchTables();
	initRhythmTables();
	initGUI();
	
	songs = {};
	sng_mariodies = Song:new{ name = "Mario Dies" };
	sng_mariodies:parse(0x792D, 33);
end

function love.keypressed(key)

	if key == "return" then
		playing = not playing;
		playpos = 0; songpos = sng_mariodies.patterns[selectedPattern].starttime;
		playingPattern = selectedPattern;
		if (not playing) then stop(); end
	end
end

function love.mousepressed( x,y,button )
	if (button ~= 3) then
		clickGUI(x,y);
	end
	if (bypassGameClick) then bypassGameClick = false; return; end
	
	-- left clicking in the piano roll places notes
	if (button == 1) then
		if love.mouse.getY() > DIVIDER_POS and love.mouse.getX() > SIDE_PIANO_WIDTH then
		
			local note = math.ceil(piano_roll_untray(y));
			local tick = math.floor(piano_roll_untrax(x));
			sng_mariodies.patterns[selectedPattern]:write(note,tick,selectedChannel);
			
			print(note .. " " .. tick);
		end
	end
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
		end
	end
end

function love.wheelmoved( x, y )
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

function play()
	local ptrn = sng_mariodies.patterns[playingPattern];
	playChannel( ptrn.pulse2_notes, SRC_PULSE2 );
	playChannel( ptrn.tri_notes,    SRC_TRI );
	playChannel( ptrn.pulse1_notes, SRC_PULSE1 );
	
	if (playpos >= ptrn.duration) then 
		if sng_mariodies.loop then
			playingPattern = ( playingPattern + 1 ) % ( sng_mariodies.patternCount );
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
	local ptrn = sng_mariodies.patterns[ selectedPattern ];
	
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
	
	-- pattern editor play line
	love.graphics.setColor( 1,0,0 );
	local linex = ((songpos - PATTERN_SCROLL) * PATTERN_ZOOMX) --+ WINDOW_WIDTH / 2;
	love.graphics.line(linex,0,linex,DIVIDER_POS);
end

function pianoroll_trax(x)
	return PIANOROLL_ZOOMX * (x - PIANOROLL_SCROLLX) + (WINDOW_WIDTH / 2) + SIDE_PIANO_WIDTH; 
end
function pianoroll_tray(y)
	return PIANOROLL_ZOOMY * (60 - y - PIANOROLL_SCROLLY ) + DIVIDER_POS + ( ( WINDOW_HEIGHT - DIVIDER_POS ) / 2 );
end
function piano_roll_untrax(x)
	return ((x - SIDE_PIANO_WIDTH - (WINDOW_WIDTH / 2) ) / PIANOROLL_ZOOMX) + PIANOROLL_SCROLLX;
end
function piano_roll_untray(y)
	return -((( y - DIVIDER_POS - ( ( WINDOW_HEIGHT - DIVIDER_POS ) / 2 ) ) / PIANOROLL_ZOOMY ) + PIANOROLL_SCROLLY) + 60
end

function renderChannel( notes, color )
	for i = 0, #notes do
		love.graphics.setColor( color );
		local note = notes[i];
		local rectx = pianoroll_trax( note.starttime );
		local recty = pianoroll_tray( note.pitch );
		local rectwidth = note.duration * PIANOROLL_ZOOMX;
		
		if ( note.val ~= 04) then
			love.graphics.rectangle( "fill", rectx, recty, rectwidth, PIANOROLL_ZOOMY )
		end
		
		love.graphics.setColor( 1,1,1,0.5 );
		love.graphics.line(rectx,DIVIDER_POS,rectx,WINDOW_HEIGHT);
	end
	
	local dur = sng_mariodies.patterns[selectedPattern].duration;
	local endx = pianoroll_trax(dur);
	love.graphics.line(endx,DIVIDER_POS,endx,WINDOW_HEIGHT);
end

function renderSidePiano()
	for i = 40, 90 do
		local keyy = pianoroll_tray( i );
		
		local m = (i) % 12;
		if ( m == 1 or m == 3 or m == 6 or m == 8 or m == 10 ) then
			love.graphics.setColor( 0.25,0.25,0.25 );
		else
			love.graphics.setColor( 1,1,1 );
		end
		love.graphics.rectangle( "fill", 0, keyy, SIDE_PIANO_WIDTH, PIANOROLL_ZOOMY )
	end
end

function initRhythmTables()
	RHYTHM_TABLE = {};
	RHYTHM_STRT_INDEX = 0x7F76;
	
	for i = 0, 0x2f do
		RHYTHM_TABLE[i] = rom[ RHYTHM_STRT_INDEX + i ];
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
		TIMER_TABLE[ i ] = rom[ ind ];
		
		local timer = (0x100 * rom [ ind ]) + rom[ ind + 1 ];
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