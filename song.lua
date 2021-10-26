-- I will be using the word "index" to refer to the position in the rom table used internally by this software
-- and the word "pointer" to refer to absolute and relative positions as used by SMB's system

local currentsong; -- song being parsed at the moment 

Song = {
	name = "Song",
	
	-- this value will be the length of the headerpointers and patterns tables
	patternCount = 0, 
	
	headerPointers = {}, -- not sure what this will be for yet
	patterns = {},
	
	-- i think only underground and castle don't have noise...
	hasNoise = true,
}

function Song:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- begins traversal with the address to a pointer (will be around $791D and afterwards) and reads pointers sequentally
-- pointerscount will always be 1 except for the overworld theme which takes like a ton of pointers
function Song:parse( ptr_start_index, pointerscount )
	currentsong = self;
	local MUSIC_DATA_START = 0x791D;

	for i = 0, pointerscount - 1 do
	
		local p = Pattern:new();
	
		local ptr = rom[ ptr_start_index + i ]; --print( string.format( "%02X", ptr ));
		local header_start_index = MUSIC_DATA_START + ptr;
		p:parse( header_start_index );
		
		self.patterns[i] = p;
		
		--local tempo = rom[ MUSIC_DATA_START + ptr ]; print( string.format( "%02X", tempo ));
	end
end

Pattern = {
	-- access into the rom from these values
	pulse2_start_index = nil,
	tri_start_index    = nil,
	pulse1_start_index = nil,
	noise_start_index  = nil,
	
	-- notes
	pulse2_notes = {},
	tri_notes    = {},
	pulse1_notes = {},
	noise_notes  = {},
	
	-- based on the sum of all note lengths of pulse2, the lead channel. 
	-- the unit of measure is game ticks 
	duration = 0,
	
	-- more like a pointer into a set of eight note durations
	tempo    = nil,
}

function Pattern:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- Parses pattern, given a header start index ( hdr_strt_ind ) as an entry point
function Pattern:parse( hdr_strt_ind )
	self.tempo = rom[ hdr_strt_ind ];
	
	local pulse2_lo = rom[ hdr_strt_ind + 1 ];
	local pulse2_hi = rom[ hdr_strt_ind + 2 ];
	-- 0x8000 is the start of PRG ROM as seen by the NES memory mapping.
	-- Also 0x10 is added on because thats the size of the iNES header (not seen by NES)
	self.pulse2_start_index = ( pulse2_hi * 0x100 ) + pulse2_lo - 0x8000 + 0x10;
	
	self.tri_start_index    = self.pulse2_start_index + rom[ hdr_strt_ind + 3 ];
	self.pulse1_start_index = self.pulse2_start_index + rom[ hdr_strt_ind + 4 ];
	
	-- SQUARE 2 PARSING
	-- (The index register won't ever exceed 0xff in the games code internally, so i am putting that limit here as well)
	-- (...in particular if the terminating 0x00 is accidently left absent from the pattern, it won't keep going forever here in this program)
	
	local currentrhythm = nil;
	
	for i = 0x00, 0xff do
		local ind = self.pulse2_start_index + i;
		local val = rom[ind];
		print( string.format( "%02X", val ));
		
		if val == 0x00 then
			break;
		end
		
		-- Rhythm modifiers
		if val >= 0x80 and val <= 0x88 then
		
		end
	end
end

Note = {
	pitch = nil,
	rhythm = nil,
}

function Note:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end