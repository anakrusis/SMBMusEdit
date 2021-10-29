Pattern = {
	-- access into the rom from these values
	header_start_index = nil,
	pulse2_start_index = nil,
	tri_start_index    = nil,
	pulse1_start_index = nil,
	noise_start_index  = nil,
	
	-- notes
	pulse2_notes = {},
	tri_notes    = {},
	pulse1_notes = {},
	noise_notes  = {},
	
	starttime = 0,
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
	
	o.pulse2_notes = {};
	o.tri_notes    = {};
	o.pulse1_notes = {};
	o.noise_notes  = {};
	
	return o
end

function Pattern:write(midinote, tick, channel)
	local notes = self:getNotes(channel);
	local existingnote;
	for i = 0, #notes do
		local note = notes[i];
		if ( note.starttime + note.duration > tick ) then
			existingnote = note;
			break;
		end
	end
	if (not existingnote) then return; end
	
	local newval;
	if (channel == "pulse2") then
		newval = PITCH_VALS[midinote];
	end
	
	local ind = existingnote.rom_index;
	rom[ind] = newval;
	--existingnote.pitch = 80;
	self:parse(self.header_start_index);
end

-- just a simple map. valid keys: "pulse1", "pulse2", "tri", "noise"
function Pattern:getNotes(key)
	if key == "pulse1" then
		return self.pulse1_notes
	elseif key == "pulse2" then
		return self.pulse2_notes
	elseif key == "tri" then
		return self.tri_notes
	elseif key == "noise" then
		return self.noise_notes
	end
end

-- returns the index of the lowest note in the notes table
function Pattern:getLowestNote(key)
	local notes = self:getNotes(key);
	
	local lowestpitch = 10000; local lowestpitchindex = -1;
	for i = 0, #notes do
		local note = notes[i];

		if (note.pitch < lowestpitch and note.val ~= 04) then
			lowestpitch = note.pitch;
			lowestpitchindex = i;
		end
	end
	return lowestpitchindex;
end

-- returns the index of the highest note in the notes table
function Pattern:getHighestNote(key)
	local notes = self:getNotes(key);
	
	local highestpitch = -10000; local hipitchindex = -1;
	for i = 0, #notes do
		local note = notes[i];

		if (note.pitch > highestpitch and note.val ~= 04) then
			highestpitch = note.pitch;
			hipitchindex = i;
		end
	end
	return hipitchindex;
end

-- This is the pulse 2 and triangle style note parsing
-- (pulse 1 and noise parsing are done in their own respective functions)
function Pattern:parseNotes(start_index, target_table)
	local duration = 0;
	local current_rhythm_val = nil;
	local current_note_length = nil;
	local notecount = 0;
	
	-- (The index register won't ever exceed 0xff in the games code internally, so i am putting that limit here as well)
	-- (...in particular if the terminating 0x00 is accidently left absent from the pattern, it won't keep going forever here in this program)
	for i = 0x00, 0xff do
		local ind = start_index + i;
		local val = rom[ind];
		--print( string.format( "%02X", val ));
		
		if self.duration > 0 and duration >= self.duration then
			return duration;
		end
		
		-- Pattern terminator
		if val == 0x00 then
			return duration;
		end
		
		-- Rhythm modifiers
		if val >= 0x80 and val <= 0x88 then
			current_rhythm_val = val;
			local rhythm_ind = ( val - 0x80 ) + self.tempo;
			current_note_length = RHYTHM_TABLE[ rhythm_ind ];
			--print(current_note_length);
			
		-- Notes proper
		else
			local n = Note:new{ rom_index = ind }
			n.duration = current_note_length;
			n.starttime = duration;
			n.val = val;
			
			n.pitch = NOTES[val];
			if (target_table == self.tri_notes) then
				n.pitch = n.pitch - 12;
			end
			
			target_table[ notecount ] = n;
			duration = duration + n.duration;
			notecount = notecount + 1;
		end
	end
	
	return duration;
end

function Pattern:parsePulse1Notes( start_index, target_table )
	local duration = 0;
	local current_rhythm_val = nil;
	local current_note_length = nil;
	local notecount = 0;
	
	for i = 0x00, 0xff do
		local ind = start_index + i;
		local val = rom[ind];
		
		if self.duration > 0 and duration >= self.duration then
			return;
		end
		
		--print( "Val: " .. string.format( "%02X", val ));
		
		-- Rhythm data for pulse 1 is obtained with a bitmask like this: 1100 0001
		local less_sig_bits = bitwise.band( val, 0xc0 );
		local more_sig_bit  = val % 2;
		current_rhythm_val  = 0x80 + ( more_sig_bit * 4 ) + ( less_sig_bits / 0x40 );
		
		--print( "Rhythm: " .. string.format( "%02X", current_rhythm_val ));
		
		local rhythm_ind = ( current_rhythm_val - 0x80 ) + self.tempo;
		current_note_length = RHYTHM_TABLE[ rhythm_ind ];
		
		--print( "Length: " .. string.format( "%02X", current_note_length ));
		
		local n = Note:new{ rom_index = ind }
		n.duration = current_note_length;
		n.starttime = duration;
		
		-- Bitmask of 0011 1110 provides the pitch data for pulse 1
		local pval = bitwise.band( val, 0x3e );
		n.val = pval;
		n.pitch = NOTES[pval];
		--print( "Pitch: " .. string.format( "%02X", pval ));
		
		target_table[ notecount ] = n;
		duration = duration + n.duration;
		notecount = notecount + 1;
	end
end

-- Parses pattern, given a header start index ( hdr_strt_ind ) as an entry point
function Pattern:parse( hdr_strt_ind )
	self.header_start_index = hdr_strt_ind;
	self.tempo = rom[ hdr_strt_ind ];
	
	local pulse2_lo = rom[ hdr_strt_ind + 1 ];
	local pulse2_hi = rom[ hdr_strt_ind + 2 ];
	-- 0x8000 is the start of PRG ROM as seen by the NES memory mapping.
	-- Also 0x10 is added on because thats the size of the iNES header (not seen by NES)
	self.pulse2_start_index = ( pulse2_hi * 0x100 ) + pulse2_lo - 0x8000 + 0x10;
	
	self.tri_start_index    = self.pulse2_start_index + rom[ hdr_strt_ind + 3 ];
	self.pulse1_start_index = self.pulse2_start_index + rom[ hdr_strt_ind + 4 ];
	
	-- Duration of pattern is decided by the length of the pulse 2 channel
	self.duration = self:parseNotes(self.pulse2_start_index, self.pulse2_notes);
	self:parseNotes(self.tri_start_index, self.tri_notes);
	self:parsePulse1Notes(self.pulse1_start_index, self.pulse1_notes);
	
	--print("Lowest note: " .. self:getLowestNote("pulse2"));
	return self.duration;
end