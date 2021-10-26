-- I will be using the word "index" to refer to the position in the rom table used internally by this software
-- and the word "pointer" to refer to absolute and relative positions as used by SMB's system

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

	local MUSIC_DATA_START = 0x791D + 1; -- Plus 1 because lua ahaha
	
	local ptr = rom[ptr_start_index]; print( string.format( "%02X", ptr ));
	local tempo = rom[ MUSIC_DATA_START + ptr ]; print( string.format( "%02X", tempo ));
	
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
	noise_notes  = {}
}

function Pattern:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Pattern:parse()

end