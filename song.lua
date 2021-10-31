-- I will be using the word "index" to refer to the position in the rom table used internally by this software
-- (or other tables)
-- and the word "pointer" to refer to absolute and relative positions as used by SMB's system

Song = {
	name = "Song",
	songindex = 0,
	
	-- this value will be the length of the headerpointers and patterns tables
	patternCount = 0, 
	
	headerPointers = {}, -- not sure what this will be for yet
	patterns = {},
	
	-- i think only underground and castle don't have noise...
	hasNoise = true,
	loop     = true, -- some songs will be best looped and others not
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
function Song:parse( ptr_start_index, pointerscount )
	local MUSIC_STRT_INDEX = 0x791D;
	
	local duration = 0;	
	for i = 0, pointerscount - 1 do
	
		local p = Pattern:new();
		p.starttime = duration;
		p.songindex = self.songindex;
	
		local ptr = rom:get( ptr_start_index + i ); --print( string.format( "%02X", ptr ));
		local header_start_index = MUSIC_STRT_INDEX + ptr;
		duration = duration + p:parse( header_start_index );
		
		self.patterns[i] = p;
	end
	self.patternCount = pointerscount;
	
	updatePatternGUI( self );
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