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
	
	-- count of how many bytes are claimed by each channel of this pattern. will never exceed bytes_avail
	pulse2_bytes_used = 0,
	tri_bytes_used    = 0,
	pulse1_bytes_used = 0,
	noise_bytes_used  = 0,
	
	-- count of how many bytes in total between the start of the channels data and the next, the available room for data
	pulse2_bytes_avail = 0,
	tri_bytes_avail    = 0,
	pulse1_bytes_avail = 0,
	noise_bytes_avail  = 0,
	
	starttime = 0,
	-- based on the sum of all note lengths of pulse2, the lead channel. 
	-- the unit of measure is game ticks 
	duration = 0,
	noiseduration = 0,
	
	-- more like a pointer into a set of eight note durations
	tempo    = nil,
	
	-- refers back to the main song index
	songindex = nil,
	patternindex = nil,
	
	hasNoise = true,
	hasPulse1 = true,
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

function Pattern:changeRhythm( tick, existingnote, channel )
	local relativedur = tick - existingnote.starttime;
	
	-- -- for now it's just finding the nearest tempo value in whatever direction specified (increasing or decreasing)
	local nearestdiff = 100000; local ind;
	
	for i = self.tempo, self.tempo+7 do
	
		local ctv = RHYTHM_TABLE[i]; -- current tempo value
		--local hyd = existingnote.starttime + ctv; -- hypothetical duration
		local diff = math.abs(ctv - relativedur);
		
		if (diff < nearestdiff) then
		
		--if (math.abs(existingnote.duration - ctv) < nearestdiff and ctv ~= existingnote.duration and ( ctv > existingnote.duration ) == increasing ) then
			nearestdiff = diff; ind = i;
		end
		
	end
	newdur = RHYTHM_TABLE[ind];
	if not newdur then return; end 
	
	--print("you tried: " .. relativedur .. " new dur: " .. newdur )
	
	local previous = rom:get(existingnote.rom_index - 1);
	if (previous >= 0x80 and previous <= 0x87) then
		rom:put(existingnote.rom_index - 1, 0x80 + ind - self.tempo);
	end
	
	parseAllSongs();
end

function Pattern:writePitch(midinote, existingnote, channel)
	--if (tick > ( existingnote.duration * 0.8 ) + existingnote.starttime) then return; end
	
	local newval;
	if (channel == "pulse2" or channel == "pulse1") then
		newval = PITCH_VALS[midinote];
	end
	if (channel == "tri") then
		newval = PITCH_VALS[midinote + 12];
	end
	
	-- clicking on the note removes it
	if (existingnote.pitch == midinote) then
		newval = 04;
	end
	
	if (not newval) then return; end
	
	local ind = existingnote.rom_index;
	
	-- retains the rhythm value of the original note if pulse1
	if (channel == "pulse1") then
		local rhythm = bitwise.band(rom:get(ind), 0xc1); -- 1100 0001 
		local pitch  = bitwise.band(newval,       0x3e); -- 0011 1110
		
		newval = rhythm + pitch;
	end
	
	rom:put(ind, newval);
	--existingnote.pitch = 80;
	parseAllSongs();
end

function Pattern:allocateUnusedBytes(chnl)
	-- finds the first unused byte in the music data section
	local ind = rom:findNextUnusedIndex();
	if not ind then return false; end
	print(string.format( "%02X", ind ));
	
	local strt = self:getStartIndex(chnl);
	-- last index, the index after which a new empty byte will be inserted
	local lastind = strt + self:getBytesAvailable(chnl); 
	local newbyte = Byte:new{ val = 0xff }

	table.insert( rom.data, lastind, newbyte )
	table.remove( rom.data, ind );
	
	for i = 0, SONG_COUNT - 1 do
		local s = songs[i];
		
		for j = 0, s.patternCount - 1 do
			local p = s.patterns[j];
			
			local hs  = p.header_start_index + 1;
			local p2s = p.pulse2_start_index;
			-- translated back into memory address from the ROM address
			local p2_out = p2s + 0x8000 - 0x10;
			
			-- the headers of every pattern that is past the point of insertion must be incremented by one
			if p2s > lastind then
				local out = rom:getWord(hs);
				--print( p:getName() .. " | " .. string.format("%04X", p2s) .. " | " .. string.format("%04X", p2_out) );
				rom:putWord(hs, out + 1);
			end
			-- -- the headers of every pattern past the point of removal must be decremented by one
			if p2s > ind then
				local out = rom:getWord(hs);
				--print( p:getName() .. " | " .. string.format("%04X", p2s) .. " | " .. string.format("%04X", p2_out) );
				rom:putWord(hs, out - 1);
			end
			-- special behavior for modifying the header of this very pattern in question (self)
			-- if p2s == strt then
			
			-- end
		end
	end
	
	-- local pulse2_lo = rom:get( hdr_strt_ind + 1 );
	-- local pulse2_hi = rom:get( hdr_strt_ind + 2 );
	-- -- 0x8000 is the start of PRG ROM as seen by the NES memory mapping.
	-- -- Also 0x10 is added on because thats the size of the iNES header (not seen by NES)
	-- self.pulse2_start_index = ( pulse2_hi * 0x100 ) + pulse2_lo - 0x8000 + 0x10;
	
	-- self.tri_start_index    = self.pulse2_start_index + rom:get( hdr_strt_ind + 3 );
	-- self.pulse1_start_index = self.pulse2_start_index + rom:get( hdr_strt_ind + 4 );
	
	-- if (self.hasNoise) then
		-- self.noise_start_index = self.pulse2_start_index + rom:get( hdr_strt_ind + 5 );
	-- end
	
	parseAllSongs();
end

function Pattern:getNoteAtTick(tick, channel)
	local notes = self:getNotes(channel);
	local existingnote;
	if not notes[0] then return end
	for i = 0, #notes do
		local note = notes[i];
		if ( note.starttime + note.duration > tick ) then
			existingnote = note;
			break;
		end
	end
	return existingnote;
end

-- counts both the bytes that are being used for music data (bytes_used) and unused bytes immediately after (bytes_avail)
function Pattern:countBytes( chnl )
	self:setBytesUsed(      chnl, 0 );
	self:setBytesAvailable( chnl, 0 );
	
	local DATA_START = 0x79C8;
	local DATA_END   = 0x7F0F;
	
	local start = self:getStartIndex( chnl )
	for i = start, start + 0xff do 
		local byt = rom.data[i];
		
		if i > DATA_END then break; end
		
		-- bytes which are claimed by this pattern+channel are counted towards the bytes used number.
		if byt:hasClaim(self.songindex, self.patternindex, chnl ) then
			-- current bytes used
			local cbu = self:getBytesUsed( chnl );
			self:setBytesUsed( chnl, cbu + 1 );
			
		-- when a byte is found which is claimed, but not by this pattern+channel, it tells us we are no longer in our available space.
		elseif #byt.song_claims > 0 then
			break;
		end
		-- otherwise, we will continue counting adjacent unused bytes towards the available space.
		local cba = self:getBytesAvailable( chnl );
		self:setBytesAvailable( chnl, cba + 1 );
	end
end

-- returns the index of the lowest note in the notes table
function Pattern:getLowestNote(key)
	local notes = self:getNotes(key);
	
	local lowestpitch = 10000; local lowestpitchindex = -1;
	for i = 0, #notes do
		local note = notes[i];
		if (note) then
			if (note.pitch < lowestpitch and note.val ~= 04) then
				lowestpitch = note.pitch;
				lowestpitchindex = i;
			end
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
		if (note) then
			if (note.pitch > highestpitch and note.val ~= 04) then
				highestpitch = note.pitch;
				hipitchindex = i;
			end
		end
	end
	return hipitchindex;
end

-- This is the pulse 2 and triangle style note parsing
-- (Rhythms and note pitches are in seperate bytes)
function Pattern:parseNotes(start_index, target_table)
	local duration = 0;
	local current_rhythm_val = nil;
	local current_note_length = nil;
	local notecount = 0;
	
	-- (The index register won't ever exceed 0xff in the games code internally, so i am putting that limit here as well)
	-- (...in particular if the terminating 0x00 is accidently left absent from the pattern, it won't keep going forever here in this program)
	for i = 0x00, 0xff do
		local ind = start_index + i;
		local val = rom:get(ind);
		--print( string.format( "%02X", val ));
		
		if self.duration > 0 and duration >= self.duration then
			return duration;
		end
		
		local b = rom.data[ind]; -- byte object
		table.insert(b.song_claims, self.songindex);
		table.insert(b.ptrn_claims, self.patternindex);
		if target_table == self.tri_notes then
			table.insert(b.chnl_claims, "tri");
		else
			table.insert(b.chnl_claims, "pulse2");
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

-- This is the pulse 1 and noise style parsing
-- (Rhythms and note pitches are both contained in each byte)
function Pattern:parseCompressedNotes( start_index, target_table )
	local duration = 0;
	local current_rhythm_val = nil;
	local current_note_length = nil;
	local notecount = 0;
	
	for i = 0x00, 0xff do
		local ind = start_index + i;
		local val = rom:get(ind);
		
		if self.duration > 0 and duration >= self.duration then
			return;
		end
		
		-- Registering the byte for counting purposes
		local b = rom.data[ind];
		table.insert(b.song_claims, self.songindex);
		table.insert(b.ptrn_claims, self.patternindex);
		if target_table == self.noise_notes then
			table.insert(b.chnl_claims, "noise");
		else
			table.insert(b.chnl_claims, "pulse1");
		end
		
		-- 00 is special case value. in the noise channel it acts as a premature terminator..
		-- in the pulse 1 channel it seems to trigger the hardware sweeps on the death music?
		if (val == 0x00) then
			if target_table == self.noise_notes then
				return duration;
			end
		else
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
end

-- Parses pattern, given a header start index ( hdr_strt_ind ) as an entry point
function Pattern:parse( hdr_strt_ind )

	self.duration = 0;
	self.noiseduration = 0; -- noise pattern usually has a different length
	
	self.pulse2_notes = {};
	self.tri_notes    = {};
	self.pulse1_notes = {};
	self.noise_notes  = {};

	self.header_start_index = hdr_strt_ind;
	self.tempo = rom:get( hdr_strt_ind );
	
	-- 0x8000 is the start of PRG ROM as seen by the NES memory mapping.
	-- Also 0x10 is added on because thats the size of the iNES header (not seen by NES)
	self.pulse2_start_index = rom:getWord( hdr_strt_ind + 1 ) - 0x8000 + 0x10;
	
	self.tri_start_index    = self.pulse2_start_index + rom:get( hdr_strt_ind + 3 );
	self.pulse1_start_index = self.pulse2_start_index + rom:get( hdr_strt_ind + 4 );
	
	if (self.hasNoise) then
		self.noise_start_index = self.pulse2_start_index + rom:get( hdr_strt_ind + 5 );
	end
	
	-- Duration of pattern is decided by the length of the pulse 2 channel
	self.duration = self:parseNotes(self.pulse2_start_index, self.pulse2_notes);
	self:parseNotes(self.tri_start_index, self.tri_notes);
	
	if (self.hasPulse1) then
		self:parseCompressedNotes(self.pulse1_start_index, self.pulse1_notes);
	end
	if (self.hasNoise) then
		self.noiseduration = self:parseCompressedNotes(self.noise_start_index, self.noise_notes);
	end
	
	return self.duration;
end

function Pattern:getName()
	local song = songs[ self.songindex ];
	return song.name .. " #" .. self.patternindex;
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

-- likewise for the following functions
function Pattern:getStartIndex(key)
	if key == "pulse1" then
		return self.pulse1_start_index
	elseif key == "pulse2" then
		return self.pulse2_start_index
	elseif key == "tri" then
		return self.tri_start_index
	elseif key == "noise" then
		return self.noise_start_index
	end
end

function Pattern:getBytesAvailable(key)
	if key == "pulse1" then
		return self.pulse1_bytes_avail
	elseif key == "pulse2" then
		return self.pulse2_bytes_avail
	elseif key == "tri" then
		return self.tri_bytes_avail
	elseif key == "noise" then
		return self.noise_bytes_avail
	end
end

function Pattern:getBytesUsed(key)
	if key == "pulse1" then
		return self.pulse1_bytes_used
	elseif key == "pulse2" then
		return self.pulse2_bytes_used
	elseif key == "tri" then
		return self.tri_bytes_used
	elseif key == "noise" then
		return self.noise_bytes_used
	end
end

function Pattern:setBytesUsed(key, value)
	if key == "pulse1" then
		self.pulse1_bytes_used = value;
	elseif key == "pulse2" then
		self.pulse2_bytes_used = value;
	elseif key == "tri" then
		self.tri_bytes_used    = value;
	elseif key == "noise" then
		self.noise_bytes_used  = value;
	end
end

function Pattern:setBytesAvailable(key, value)
	if key == "pulse1" then
		self.pulse1_bytes_avail = value;
	elseif key == "pulse2" then
		self.pulse2_bytes_avail = value;
	elseif key == "tri" then
		self.tri_bytes_avail    = value;
	elseif key == "noise" then
		self.noise_bytes_avail  = value;
	end
end