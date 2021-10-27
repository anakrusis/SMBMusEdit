require "song"
require "bitwise"
require "gui"
require "guielement"

function love.load()
	
	SRC_PULSE2 = love.audio.newSource( "square.flac", "static" );
	SRC_PULSE2:setLooping(true);
	SRC_PULSE1 = love.audio.newSource( "square.flac", "static" );
	SRC_PULSE1:setLooping(true);
	SRC_TRI = love.audio.newSource( "square.flac", "static" );
	SRC_TRI:setLooping(true);
	
	playing = false; playpos = 0; -- currenttick
	
	love.window.setTitle("SMBMusEdit 0.1.0a")
	success = love.window.setMode( 800, 600, {resizable=true} )
	
	local file = io.open("smbmusedit-2/mario.nes", "rb")
	local content = file:read "*a" -- *a or *all reads the whole file
	file:close()
		
	rom = {};	
	for i = 1, #content do
		rom[i - 1] = string.byte(string.sub(content,i,i))
	end
	
	initPitchTables();
	initRhythmTables();
	
	songs = {};
	sng_mariodies = Song:new{ name = "Mario Dies" };
	sng_mariodies:parse(0x7926, 1);
	
	init_gui();
	
end

function love.keypressed(key)

	if key == "return" then
		playing = not playing;
		playpos = 0;
		if (not playing) then stop(); end
	end
end

function love.mousepressed( x,y,button )
	click_gui(x,y);
	if (bypassGameClick) then bypassGameClick = false; return; end
end

function love.update(dt)
	if (playing) then
		play();
	end
	
	update_gui();
end

function play()
	local ptrn = sng_mariodies.patterns[0];
	playChannel( ptrn.pulse2_notes, SRC_PULSE2 );
	playChannel( ptrn.tri_notes,    SRC_TRI );
	playChannel( ptrn.pulse1_notes, SRC_PULSE1 );
	
	if (playpos > ptrn.duration) then stop() end
	
	playpos = playpos + 1;
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
	local ptrn = sng_mariodies.patterns[0];
	
	love.graphics.setColor(1,0,1);
	for i = 0, #ptrn.pulse2_notes do
		local note = ptrn.pulse2_notes[i];
		local rectx = note.starttime * 4; 
		local recty = 1000 - note.pitch * 10;
		local rectwidth = note.duration * 3.8;
		
		if ( note.val ~= 04) then
			love.graphics.rectangle( "fill", rectx, recty, rectwidth, 10 )
		end
	end
	love.graphics.setColor(0,0,1);
	for i = 0, #ptrn.tri_notes do
		local note = ptrn.tri_notes[i];
		local rectx = note.starttime * 4; 
		local recty = 1000 - note.pitch * 10;
		local rectwidth = note.duration * 3.8;
		
		if ( note.val ~= 04) then
			love.graphics.rectangle( "fill", rectx, recty, rectwidth, 10 )
		end
	end
	love.graphics.setColor(0.5,0,0.5);
	for i = 0, #ptrn.pulse1_notes do
		local note = ptrn.pulse1_notes[i];
		local rectx = note.starttime * 4; 
		local recty = 1000 - note.pitch * 10;
		local rectwidth = note.duration * 3.8;
		
		if ( note.val ~= 04) then
			love.graphics.rectangle( "fill", rectx, recty, rectwidth, 10 )
		end
	end
	
	render_gui();
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
		--print( noteval );
		NOTES[ i ] = noteval;
	end
end