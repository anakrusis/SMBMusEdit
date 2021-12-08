-- I will be using the word "index" to refer to the position in the rom table used internally by this software
-- (or other tables)
-- and the word "pointer" to refer to absolute and relative positions as used by SMB's system

Song = {
	name = "Song",
	songindex = 0,
	-- index to the first pointer in rom which will point to the first header of the first pattern
	ptr_start_index = nil,
	-- number of pointers, including the first one, to sequentially parse. (for all except overworld theme, will be 1)
	patternCount = 1, 
	
	patterns = {},
	
	quarter_note_duration = 36,
	
	-- underground, castle, and all the event music have no noise
	hasNoise  = true,
	-- I think only underground has no pulse1
	hasPulse1 = true,
	loop      = true, -- some songs will be best looped and others not
}

function Song:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	
	o.patterns = {};
	o.songindex = SONG_COUNT;
	songs[SONG_COUNT] = o;
	SONG_COUNT = SONG_COUNT + 1;
	return o
end

-- begins traversal with the address to a pointer (starting at $791D and afterwards) and reads pointers sequentally
-- pointerscount will always be 1 except for the overworld theme which takes like a ton of pointers
function Song:parse()
	local MUSIC_STRT_INDEX = 0x791D;
	
	-- todo parsing a song should... reset its claims on bytes?
	-- (but what if multiple songs claim the same set of bytes? should all their claims be reset?)
	
	local duration = 0;	
	for i = 0, self.patternCount - 1 do
	
		local p = Pattern:new();
		p.starttime = duration;
		p.quarter_note_duration = self.quarter_note_duration;
		p.songindex = self.songindex;
		p.patternindex = i;
		p.hasNoise  = self.hasNoise;
		p.hasPulse1 = self.hasPulse1;
		p.ptr_index = self.ptr_start_index + i;
	
		local ptr = rom:get( self.ptr_start_index + i ); --print( string.format( "%02X", ptr ));
		local header_start_index = MUSIC_STRT_INDEX + ptr;
		local cpd = p:parse( header_start_index ); -- current pattern duration
		if not cpd then return false end
		
		duration = duration + cpd;
		
		self.patterns[i] = p;
	end
	return true;
end

-- this step must be done after all parsing is complete
function Song:countBytes()
	for i = 0, self.patternCount - 1 do
		local p = self.patterns[i];
		
		p:countBytes("pulse2");
		p:countBytes("tri");
		if (p.hasPulse1) then
			p:countBytes("pulse1");
		end
		if (p.hasNoise) then
			p:countBytes("noise");
		end
	end
end

function Song:getLowestNote(key)
	-- local lowestpitch = 10000; local lowestpitchindex = -1;
	-- for i = 0, pointerscount - 1 do
		-- local p = self.patterns[i];
		
		-- local currentlow = p.getLowestNote(key);
		-- if (currentlow < lowestpitch) then
			-- lowestpitch = currentlow;
			-- lowestpitchindex = i;
		-- end
	-- end
	
end

Note = {
	-- location in rom
	rom_index = nil,
	-- location in notes array of pattern
	noteindex = nil,
	starttime = 0,
	duration = 0,
	-- used to get the frequency from the timer table
	-- this value will be obtained slightly differently by pulse 1, i think... (will see when we get there)
	val = 0,
	pitch = 0,
}

function Note:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end