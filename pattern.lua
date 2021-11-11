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

function Pattern:changeRhythm( tick, noteindex, channel )
	local existingnote = self:getNotes(channel)[ noteindex ];
	local relativedur = tick - existingnote.starttime;
	
	-- for now it's just finding the nearest tempo value in whatever direction specified (increasing or decreasing)
	local nearestdiff = 100000; local ind;
	for i = self.tempo, self.tempo+7 do
	
		local ctv = RHYTHM_TABLE[i]; -- current tempo value
		local diff = math.abs(ctv - relativedur);
		
		if (diff < nearestdiff) then
			nearestdiff = diff; ind = i;
		end
		
	end
	local NEWDUR = RHYTHM_TABLE[ind];
	if not NEWDUR then return; end
	
	-- (trying out a bit of a system here, not sure if it'll be good or not.)
	-- The intent is that, if the logic should find a reason to cancel this action, no bytes will be changed yet
	-- Only at the end when everything is confirmed to be ok'd will the bytes be written/inserted/removed
	
	-- prospective byte changes...
	local addrs   = {}; local vals   = {};
	-- prospective byte insertions...
	local i_addrs = {}; local i_vals = {}; 
	local removals = {};
	
	-- Pulse 1 ( and noise, when that gets going) have rhythm values on every byte, simpler to deal with
	if (channel == "pulse1") then
		local pitch = bitwise.band(rom:get( existingnote.rom_index ), 0x3e); -- 0011 1110
		local newrhythm = ind - self.tempo; print(string.format( "%02X", newrhythm ));
		local fours_bit = bitwise.band( newrhythm, 0x04 );
		local two_one_b = bitwise.band( newrhythm, 0x03 );
		
		local rhythm = (fours_bit / 4) + (two_one_b * 0x40);
		rom:put(existingnote.rom_index, pitch + rhythm);
		
	-- The other channels have more complex rhythm handling
	else
		local NEW_RHYTHM = 0x80 + ind - self.tempo;
		
		-- If a rhythm byte is immediately before this byte:
		local previous = rom:get(existingnote.rom_index - 1); --print(string.format( "%02X", previous ));
		if (previous >= 0x80 and previous <= 0x87) then
		
			--print ("has rhythm byte");
			local previousnote = self:getNotes(channel)[ existingnote.noteindex - 1 ];
			-- If there is a previous note and its duration will be equal to the prospective duration, we will remove the rhythm byte from the latter note
			-- and we will add an empty, unused byte at the end of this channels data
			if (previousnote) then
				if previousnote.duration == NEWDUR then
					strt = self:getStartIndex(channel);
					lastind = strt + self:getBytesAvailable(channel);
					newbyte = Byte:new{ val = 0xff }
					
					table.insert( removals, existingnote.rom_index - 1 );
					table.insert( i_addrs , lastind - 1 );
					table.insert( i_vals  , 0xff );
				else	
					rom:put(existingnote.rom_index - 1, NEW_RHYTHM);
				end
			else
				rom:put(existingnote.rom_index - 1, NEW_RHYTHM);
			end
			
		-- If there is no rhythm byte preceding this byte:
		else
			--print ("no rhythm byte");
			-- If there is a previous note and its duration will be equal to the prospective duration, do nothing
			local previousnote = self:getNotes(channel)[ existingnote.noteindex - 1 ];
			if (previousnote) then
				if previousnote.duration == NEWDUR then
					--print("already equal");
					return;
				end
			end
			-- Otherwise, we will need a free byte to make a new rhythm byte.
			-- Inserting a rhythm byte before the note, and removing the unused byte from the end of the channel data
			if self:getBytesAvailable(channel) > self:getBytesUsed(channel) then
				strt = self:getStartIndex(channel);
				lastind = strt + self:getBytesAvailable(channel); 
				
				table.insert( removals, lastind - 1 );
				table.insert( i_addrs , existingnote.rom_index );
				table.insert( i_vals  , NEW_RHYTHM );
			else
				popupText("Not enough free bytes in this channel to change rhythm!\nEdit > Optimize to allocate unused bytes!", {1,1,1}); return;
			end
		end
		
		parseAllSongs();
		--songs[self.songindex]:parse();
		local notes = self:getNotes(channel);
		local existingnote = notes[ noteindex ];
		
		-- now it must iterate through the notes after this one that was just changed:
		-- a note that comes after without a rhythm byte, if its duration is different, a rhythm byte must be inserted
		-- rhythm bytes that will be the same as this prospective rhythm can be removed (they are redundant)
		-- and if we find a rhythm byte that is different than the prospective rhythm than we can stop iterating
		
		
		local note = notes[ existingnote.noteindex + 1 ];
		local previousbyte = rom.data[note.rom_index - 1].val; print(string.format( "%02X", previousbyte ));
		
		-- The note has a rhythm byte before it, ignore it
		if (previousbyte >= 0x80 and previousbyte <= 0x87) then
			print("has rhythm byte");
			
		-- The note lacks a rhythm byte before it: 
		-- if the duration is different, we will need to place an extra byte before it
		else
			if note.duration == NEWDUR then
				print("already same");
			else
				if self:getBytesAvailable(channel) > self:getBytesUsed(channel) then
					print("adding rhythm byte");
					strt = self:getStartIndex(channel);
					lastind = strt + self:getBytesAvailable(channel); 
					
					table.insert( removals, lastind - 1 );
					table.insert( i_addrs , note.rom_index );
					table.insert( i_vals  , 0x80 );
				else
					popupText("Not enough free bytes in this channel to change rhythm!\nEdit > Optimize to allocate unused bytes!", {1,1,1}); return;
				end
			end
		end	
		
		-- local ni = existingnote.noteindex;
		-- for i = existingnote.rom_index + 1, existingnote.rom_index + 0xff do
			-- local cb = rom.data[i];
			-- -- we mustnt go outside our range
			-- if not cb:hasClaim(self.songindex, self.patternindex, channel) then break end
			
			-- local cv = cb.val -- current val (of byte)
			-- -- Rhythm bytes:
			-- if (cv >= 0x80 and cv <= 0x87) then
				-- -- When we find a rhythm byte different from the one before it then we are done iterating
				-- if (cv ~= NEW_RHYTHM) then
					-- break;
				-- -- Otherwise we are looking at a redundant byte of the same rhythm, which is to be removed
				-- else
					-- print("ahead value removed");
					-- strt = self:getStartIndex(channel);
					-- lastind = strt + self:getBytesAvailable(channel); 
					-- table.insert( removals, i );
					-- table.insert( i_addrs , lastind - 1 );
					-- table.insert( i_vals  , 0xff );
				-- end
			-- -- Non rhythm bytes:
			-- else
				-- -- we get the duration of this later note from the parsed data.
				-- -- if it is the same as the note before then we do nothing
				-- ni = ni + 1;
				-- local note = self:getNotes(channel)[ ni ];
				-- if note.duration == NEWDUR then
				
				-- -- otherwise a rhythm byte will need to be placed
				-- else
					-- if self:getBytesAvailable(channel) > self:getBytesUsed(channel) then
						-- strt = self:getStartIndex(channel);
						-- lastind = strt + self:getBytesAvailable(channel); 
						
						-- table.insert( removals, lastind - 1 );
						-- table.insert( i_addrs , note.rom_index );
						-- table.insert( i_vals  , 0x80 );
					-- else
						-- popupText("Not enough free bytes in this channel to change rhythm!\nEdit > Optimize to allocate unused bytes!", {1,1,1}); return;
					-- end
				-- end
			-- end
		-- end
		
		-- finally, if it made it this far, all the prospective byte changes will be put into action
		for i = 1, #addrs do
			rom:put(addrs[i],vals[i]);
		end
		for i = 1, #removals do
			table.remove( rom.data, removals[i] );
		end
		for i = 1, #i_addrs do
			newbyte = Byte:new{ val = i_vals[i] }
			table.insert( rom.data, i_addrs[i], newbyte )
		end
		
		-- TODO: adjust pointers for songs that point to a place in this channel
		-- I mention this because the "silence" tracks point all channels to the final #$00 of the pulse 2 channel of the overworlds second pattern.
		-- these tracks break when the position of that 00 is moved, and it also causes the byte to not be seen as unused
	end
	
	parseAllSongs();
end

function Pattern:writePitch(midinote, existingnote, channel)
	local newval;
	if (channel == "pulse2" or channel == "pulse1" or channel == "noise") then
		newval = PITCH_VALS[midinote];
	end
	if (channel == "tri") then
		newval = PITCH_VALS[midinote + 12];
	end
	
	-- clicking on the note removes it
	if (existingnote.pitch == midinote) then
		newval = 04;
	end
	
	if (not newval) then
		popupText("Note not available!", {1,0,0});
		return; 
	end
	if newval ~= 04 then previewNote(newval); end
	
	local ind = existingnote.rom_index;
	
	-- retains the rhythm value of the original note if pulse1 or noise
	if channel == "pulse1" or channel == "noise" then
		local rhythm = bitwise.band(rom:get(ind), 0xc1); -- 1100 0001 
		local pitch  = bitwise.band(newval,       0x3e); -- 0011 1110
		
		newval = rhythm + pitch;
	end

	rom:put(ind, newval);
	parseAllSongs();
end

function Pattern:allocateUnusedBytes(chnl)
	local ind, lastind, strt, newbyte;

	ind = rom:findNextUnusedUnqueuedIndex(self.songindex, self.patternindex, chnl);
	if not ind then 
		popupText("No more unused bytes to queue up!\nYou can shorten patterns to free up bytes.", {1,1,1});
		return false; 
	end
	
	local oldsongind; local oldptrnind;
	-- need to know what song "ind" is queued up after... (technically doesn't matter which, if multiple songs/patterns share the byte)
	for j = 0, 0xff, 1 do
		local ci = ind - j;
		if #rom.data[ci].song_claims > 0 then
			oldsongind = rom.data[ci].song_claims[1];
			oldptrnind = rom.data[ci].ptrn_claims[1];
			break;
		end
	end
		
	strt = self:getStartIndex(chnl);
	-- last index, the index after which a new empty byte will be inserted
	lastind = strt + self:getBytesAvailable(chnl); 

	newbyte = Byte:new{ val = 0xff }
	table.insert( rom.data, lastind, newbyte )
	table.remove( rom.data, ind );
	
	-- now we must traverse all the headers and modify the ones between the insertion site and removal site.
	-- because multiple patterns can share the same header, and we only want to modify each one once, 
	-- we have to check for the ones that we already have seen
	seen_hdr_strts = {};
	for i = 0, SONG_COUNT - 1 do
		local s = songs[i];
		
		for j = 0, s.patternCount - 1 do
			local p = s.patterns[j];
			
			local hs  = p.header_start_index + 1;
			local p2s = p.pulse2_start_index;
			
			if not seen_hdr_strts[hs] then
				-- the headers of every pattern that is past the point of insertion must be incremented by one
				if p2s >= lastind then
					local out = rom:getWord(hs);
					rom:putWord(hs, out + 1);
				end
				-- the headers of every pattern past the point of removal must be decremented by one
				if p2s >= ind then
					local out = rom:getWord(hs);
					rom:putWord(hs, out - 1);
				end
				
				seen_hdr_strts[hs] = true;
			end
		end
	end
	
	self:adjustInternalPointers(lastind, ind);
	
	-- if transferring within the same ptrn, the pointers are only done on that one ptrn once.
	-- otherwise, the internal pointers of boths ptrn must be fixed
	if (oldsongind ~= self.songindex and oldptrnind ~= self.patternindex) then
		local oldsong = songs[oldsongind];
		local oldptrn = oldsong.patterns[oldptrnind];
		oldptrn:adjustInternalPointers(lastind, ind);
	end
	
	parseAllSongs();
end

-- given an Insertion Point of a new byte and a Removal Point of another byte. doesnt matter which comes first in the rom
function Pattern:adjustInternalPointers(ip, rp)

	local greatest_start = math.max( self.pulse1_start_index, self.tri_start_index );
	if ( self.hasNoise ) then
		greatest_start = math.max( greatest_start, self.noise_start_index );
	end
	
	local out;
	local tripos = self.header_start_index + 3;
	local p1pos = self.header_start_index + 4;
	local nopos = self.header_start_index + 5;
	
	-- checking that the changed indices are truly internal to this patterns data
	-- first at the insertion point:
	if self.pulse2_start_index <= ip and ip <= greatest_start then
		
		if self.tri_start_index >= ip then
			out = rom:get( tripos );
			rom:put( tripos, out + 1 );
		end
		if self.pulse1_start_index >= ip then
			out = rom:get( p1pos );
			rom:put( p1pos, out + 1 );
		end
		if (self.hasNoise) then
			if self.noise_start_index >= ip then
				out = rom:get( nopos );
				rom:put( nopos, out + 1 );
			end
		end
	end
	-- and at the removal point:
	if self.pulse2_start_index <= rp and rp <= greatest_start then
		
		if self.tri_start_index >= rp then
			out = rom:get( tripos );
			rom:put( tripos, out - 1 );
		end
		if self.pulse1_start_index >= rp then
			out = rom:get( p1pos );
			rom:put( p1pos, out - 1 );
		end
		if (self.hasNoise) then
			if self.noise_start_index >= rp then
				out = rom:get( nopos );
				rom:put( nopos, out - 1 );
			end
		end
	end
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
		if val >= 0x80 and val <= 0x87 then
			current_rhythm_val = val;
			local rhythm_ind = ( val - 0x80 ) + self.tempo;
			current_note_length = RHYTHM_TABLE[ rhythm_ind ];
			
		-- Notes proper
		else
			local n = Note:new{ rom_index = ind, noteindex = notecount }
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
		
		if self.duration ~= nil and duration >= self.duration then
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
			
			local n = Note:new{ rom_index = ind, noteindex = notecount }
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

	self.duration = nil;
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