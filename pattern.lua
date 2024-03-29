Pattern = {
	-- access into the rom from these values
	ptr_index          = nil,
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
	duration = nil,
	noiseduration = 0,
	-- just for visual reference, thats all
	quarter_note_duration = 36,
	
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

-- clears all channel data of pattern except parts that overlap
function Pattern:clear()
	self:clearChannel("pulse2");
	self:clearChannel("pulse1");
	self:clearChannel("tri");
	self:clearChannel("noise");
end
function Pattern:clearChannel(channel)
	local si = self:getStartIndex(channel);
	local ei = si + self:getBytesAvailable(channel) - 1;
	for i = si, ei do
		rom.data[i].change = 0x04;
	end
	-- terminator at start of pattern
	if channel == "pulse2" or channel == "noise" then
		rom.data[si].change = 0x00;
	end
	-- triangle doesn't accept a terminating value but it needs a starting rhythm value in case the pattern is lengthened back, otherwise it will do weird things (and possibly crash?)
	if channel == "tri" then
		rom.data[si].change = 0x80;
	end
	rom:commitMarkers();
	parseAllSongs();
end

function Pattern:changeEndpoint(tick, channel)
	if channel ~= "pulse2" and channel ~= "noise" then return end
	local notes = self:getNotes(channel);
	if not notes[0] then return end
	
	local lastnotebefore = nil;
	local lastdurbefore = 0;
	for i = 0, #notes do
		local cn = notes[i];
	
		if lastdurbefore + cn.duration > tick then
			lastnotebefore = cn;
			break;
		end
		
		lastdurbefore = lastdurbefore + cn.duration;
	end
	if not lastnotebefore then return; end
	local lastnoteromind = lastnotebefore.rom_index;
	local insertindex;
	-- If this note is preceded by a rhythm byte, then insert before that too
	if rom:get(lastnoteromind - 1) >= 0x80 and rom:get(lastnoteromind - 1) <= 0x87 then
		insertindex = lastnoteromind - 1;
	else
		insertindex = lastnoteromind;
	end
	
	print( string.format( "%02X", insertindex ));
	
	rom.data[insertindex].insert_before = 0x00;
	rom:commitMarkers(insertindex,insertindex);
	
	local strt = self:getStartIndex(channel);
	local curind = strt + self:getBytesAvailable(channel) - 1
	local cb = rom.data[curind]
	local cv = cb.val;
	print(string.format( "%02X",cv) .. "removed at $" .. string.format( "%04X",curind) );
	
	cb.delete = true;
	rom:commitMarkers(curind,curind);
	parseAllSongs();
end

-- Appending a note is comparitively simple, it will always be a one-byte operation. 
-- The note appended will match the rhythm value of the preceding note by default
function Pattern:appendNote(midinote, tick, channel)

	local newval;
	if (channel == "pulse2" or channel == "noise") then
		newval = PITCH_VALS[midinote];
	else
		return;
	end
	if (not newval) then
		popupText("Can't append unavailable pitch!", {1,1,1});
		return; 
	end

	local bytecost = 1;
	local strt = self:getStartIndex(channel);
	local curind = strt + self:getBytesUsed(channel) - 1;
	-- This is because a note appended after the data terminator will not be seen
	if (rom.data[curind].val == 0x00) then curind = curind - 1; end
	
	local cb = rom.data[curind];
	local cv = cb.val;
	cb.insert_after = {}; -- trying out a new functionality for multiple-byte insertion
	
	-- pulse 2 requires a rhythm to be specified if this note is the first byte of the channel
	if (channel == "pulse2") and curind == strt - 1 then
		cb.insert_after = {0x80};
		print( "0x80 inserted after " .. string.format( "%02X",cv) .. " at $" .. string.format( "%04X",curind) );
		bytecost = bytecost + 1;
	end
	
	print( "byte inserted after " .. string.format( "%02X",cv) .. " at $" .. string.format( "%04X",curind) );
	
	if (channel == "noise") then
		local rhythm = bitwise.band(cv, 0xc1);     -- 1100 0001
		local pitch  = bitwise.band(newval, 0x3e); -- 0011 1110
		
		table.insert(cb.insert_after, rhythm + pitch);
	else
		table.insert(cb.insert_after, newval);
	end

	if bytecost > self:getBytesAvailable(channel) - self:getBytesUsed(channel) then
		popupText("Not enough free bytes in this channel to append note!\nEdit > Optimize to allocate unused bytes!", {1,1,1});
		
		-- Byte markers MUST be cleared if cancelling an action
		-- (otherwise they will unintentionally take effect next action)
		rom:clearMarkers();
		return;
	end
	
	PlaybackHandler:playPreview(newval);
	rom:commitMarkers();
	
	-- TODO this can be simplified due to multiple-byte insertions implemented, doesn't require looping here anymore
	for i = 0, math.abs(bytecost) - 1 do
		if bytecost == 0 then break; end
	
		local strt = self:getStartIndex(channel);
		local curind;
		
		-- positive bytecost: bytes will be removed from the end
		if bytecost > 0 then
			curind = strt + self:getBytesAvailable(channel) + (bytecost - 1) - i;
			local cb = rom.data[curind]
			local cv = cb.val;
			print(string.format( "%02X",cv) .. "removed at $" .. string.format( "%04X",curind) );
			
			cb.delete = true;
			rom:commitMarkers(curind,curind);
			
		-- negative bytecost: bytes will be appended at the end
		-- else
			-- curind = strt + self:getBytesUsed(channel) + bytecost - 1;
			-- local cb = temprom.data[curind]
			-- local cv = cb.val;
			-- print( "byte inserted after " .. string.format( "%02X",cv) .. " at $" .. string.format( "%04X",curind) );
			
			-- cb.insert_after = 0xff;
			-- temprom:commitMarkers(curind,curind);
		end
	end
	
	parseAllSongs();
end

-- Changing rhythms is difficult, so it is split into a multi-pass process below:
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
	if existingnote.duration == NEWDUR then return; end
	
	-- a temporary rom copy that will be edited
	local temprom = ROM:new(); 
	temprom:deepcopy(rom);

	-- how many bytes will this operation use up? (always 0 for the compressed channels pulse1+noise)
	local bytecost = 0;
	
	-- Pulse 1 ( and noise, when that gets going) have rhythm values on every byte, simpler to deal with
	if (channel == "pulse1" or channel == "noise") then
		local pitch = bitwise.band(rom:get( existingnote.rom_index ), 0x3e); -- 0011 1110
		local newrhythm = ind - self.tempo; 
		local fours_bit = bitwise.band( newrhythm, 0x04 );
		local two_one_b = bitwise.band( newrhythm, 0x03 );
		
		local rhythm = (fours_bit / 4) + (two_one_b * 0x40);
		--print(string.format( "%02X", temprom.data[noteindex].val ));
		temprom.data[ existingnote.rom_index ].change = pitch + rhythm;
		--table.insert(change_vals,   pitch + rhythm);
		--table.insert(change_addrss, existingnote.rom_index);
		
		-- TODO fix the invalid notes on pulse1
		
		temprom:commitMarkers( existingnote.rom_index, existingnote.rom_index );
		
	-- The other channels have more complex rhythm handling
	else
		-- I think there will be two passes for this:
		-- the first pass will simply insert rhythm bytes where needed, before and after.
		-- the second pass will look for redundant ones and splice them out
		-- this should simplify the logic a lot, i think...?
	
	-- PASS 1:
	
		local NEW_RHYTHM = 0x80 + ind - self.tempo;
		
		currbyte = temprom.data[ existingnote.rom_index ]; 
		
		local prevbyte = temprom.data[ existingnote.rom_index - 1 ];
		local prevval  = prevbyte.val;
		-- Rhythm byte before note:
		-- change it accordingly
		if (prevval >= 0x80 and prevval <= 0x87) then
			prevbyte.change = NEW_RHYTHM;
			
		-- Non-rhythm byte before note:
		-- insert a new rhythm byte before
		else
			bytecost = bytecost + 1;
			currbyte.insert_before = NEW_RHYTHM;
		end
		
		local nextbyte = temprom.data[ existingnote.rom_index + 1 ];
		local nextval  = nextbyte.val;
		local nextnote = self:getNotes(channel)[ existingnote.noteindex +  1 ];
		-- special handling for the last note of the pattern (ignore for now)
		if not nextnote then
			
		-- Rhythm byte after note: (no need to do anything)
		elseif (nextval >= 0x80 and nextval <= 0x87) then

		-- Non-rhythm byte after note:
		-- a rhythm byte will be inserted after.
		-- to figure out what rhythm value it will hold, we must assess the duration of the note
		else
			bytecost = bytecost + 1;
			
			local cr = nil; -- currentrhythm
			for q = self.tempo, self.tempo+7 do
				if RHYTHM_TABLE[q] == nextnote.duration then
					cr = q;
				end
			end
			local rhythmAfter = 0x80 + cr - self.tempo;
			
			currbyte.insert_after = rhythmAfter;
		end
		
		temprom:commitMarkers();
		
	-- PASS 2:
		-- this is a cleanup routine that passes through and removes redundant or unused rhythm values from the whole channel's data
		-- It also counts the length of the new used portion of notes
		local newptrnlen = 0;
		local lastrhythm = 0;
		local lastind = self:getLastIndex(channel) - 1;
		for i = self:getStartIndex(channel), lastind + bytecost do
			local cb = temprom.data[i];
			local cv = cb.val -- current val (of byte)
			if (cv >= 0x80 and cv <= 0x87) then
			
				-- redundancy detection: will prevent rhythm bytes from being inserted if they are already present before
				if lastrhythm == cv then
					--print("redundant rhythm removed " .. string.format( "%02X",cv));
					cb.delete = true;			
					bytecost = bytecost - 1;
				end
				lastrhythm = cv;
				
			elseif (cv == 0x00) then
			
			else
				--local newrhythm = RHYTHM_TABLE[ (0x80 - lastrhythm) + self.tempo ];
				--print( newrhythm );
				--newptrnlen = newptrnlen + newrhythm;
			end
		end
		
		--print ( "duration " .. self.duration .. "->" .. newptrnlen );
		
		temprom:commitMarkers();
		
		-- TODO: pattern length changing such that garbage data will be read: must be prevented lolol
		-- (Can be considered like overlap protection)
		
		-- TODO: adjust pointers for songs that point to a place in this channel
		-- I mention this because the "silence" tracks point all channels to the final #$00 of the pulse 2 channel of the overworlds second pattern.
		-- these tracks break when the position of that 00 is moved, and it also causes the byte to not be seen as unused
	end
	
	if bytecost > self:getBytesAvailable(channel) - self:getBytesUsed(channel) then
		popupText("Not enough free bytes in this channel to change rhythm!\nEdit > Optimize to allocate unused bytes!", {1,1,1});
		
		-- Byte markers MUST be cleared if cancelling an action
		-- (otherwise they will unintentionally take effect next action)
		rom:clearMarkers();
		return;
	end
	
	print("bytecost: " .. bytecost);
	
	-- This part appends on or removes unused bytes in queue for this channel, if needed
	-- this maintains the internal size of the pattern so other pointers dont have to be changed with every edit
	
	-- TODO now that rom objects can insert multiple bytes at once, this can be simplified to not require a for loop
	for i = 0, math.abs(bytecost) - 1 do
		if bytecost == 0 then break; end
	
		local strt = self:getStartIndex(channel);
		local lastind = self:getLastIndex(channel);
		local curind;
		
		-- positive bytecost: bytes will be removed from the end
		if bytecost > 0 then
			--curind = strt + self:getBytesAvailable(channel) + (bytecost - 1) - i;
			curind = lastind + (bytecost - 1) - i;
			local cb = temprom.data[curind]
			local cv = cb.val;
			print(string.format( "%02X",cv) .. "removed at $" .. string.format( "%04X",curind) );
			
			cb.delete = true;
			temprom:commitMarkers(curind,curind);
			
		-- negative bytecost: bytes will be appended at the end
		else
			--curind = strt + self:getBytesUsed(channel) + bytecost - 1;
			curind = lastind + (bytecost - 1);
			local cb = temprom.data[curind]
			local cv = cb.val;
			print( "byte inserted after " .. string.format( "%02X",cv) .. " at $" .. string.format( "%04X",curind) );
			
			cb.insert_after = 0x04;
			temprom:commitMarkers(curind,curind);
		end
	end

	rom = temprom;
	--rom:commitMarkers();
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
		popupText("Pitch not available!", {1,1,1});
		return; 
	end
	if newval ~= 04 then PlaybackHandler:playPreview(newval); end
	
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
	local lastind = self:getLastIndex(chnl);
	
	newbyte = Byte:new{ val = 0x04 }
	table.insert( rom.data, lastind, newbyte )
	
	if (lastind <= ind) then ind = ind + 1 end
	print(string.format("%02X", rom.data[ind].val) .. " removed");
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
				
				p:adjustInternalPointers(lastind, ind);
				
				seen_hdr_strts[hs] = true;
			end
		end
	end
	
	parseAllSongs();
end

-- Returns the last index of the pattern, whichever comes first:
-- the last non-overlapping byte that belongs to the pattern, or the last available byte of the pattern
function Pattern:getLastIndex(chnl)
	local strt = self:getStartIndex(chnl);
	-- last index, the index before which a new empty byte will be inserted
	local lastind = strt + self:getBytesAvailable(chnl);
	-- When calculating the last index, we will take into account any overlapping channels, so as to not disturb the data of another songs/patterns/channels in the allocation process. 
	-- Whichever comes first, the end of the available bytes, or the end of non-overlapping bytes, will become lastind
	local hasOverlap = false;
	for j = strt, strt + self:getBytesAvailable(chnl) - 1 do
		local currentbyte = rom.data[j];
		for q = 1, #currentbyte.song_claims do
			local csc = currentbyte.song_claims[q];
			local cpc = currentbyte.ptrn_claims[q];
			local ccc = currentbyte.chnl_claims[q];
			
			if (csc ~= self.songindex or cpc ~= self.patternindex or ccc ~= chnl) then
				local claimedsong = songs[csc];
				local claimedptrn = claimedsong.patterns[cpc];
				if claimedptrn:getStartIndex(ccc) > strt then 
					lastind = j;
					hasOverlap = true;
					print("has overlap at $" .. string.format("%04X", j));
					break;
				end
			end
		end
		
		if hasOverlap then break end
	end
	
	return lastind;
end

-- given an Insertion Point of a new byte and a Removal Point of another byte. doesnt matter which comes first in the rom
function Pattern:adjustInternalPointers(ip, rp)

	local greatest_start = math.max( self.pulse1_start_index, self.tri_start_index );
	if ( self.hasNoise ) then
		greatest_start = math.max( greatest_start, self.noise_start_index );
	end
	--print( self:getName() .. " " .. string.format( "%02X",greatest_start))
	
	local out;
	local tripos = self.header_start_index + 3;
	local p1pos = self.header_start_index + 4;
	local nopos = self.header_start_index + 5;
	
	-- checking that the changed indices are truly internal to this patterns data
	-- first at the insertion point:
	if self.pulse2_start_index < ip and ip <= greatest_start then
		print( self:getName() .. " " .. "contains insert point")
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
	if self.pulse2_start_index < rp and rp <= greatest_start then
		print( self:getName() .. " " .. "contains remove point")
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
		
		if self.duration ~= nil and duration >= self.duration then
			return duration;
		end
		
		local b = rom.data[ind]; -- byte object
		if not b then return false end
		
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
			return duration;
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
	
	return duration;
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
	if not self.duration then return false end
	
	self:parseNotes(self.tri_start_index, self.tri_notes);
	
	if (self.hasPulse1) then
		self:parseCompressedNotes(self.pulse1_start_index, self.pulse1_notes);
	end
	if (self.hasNoise) then
		self.noiseduration = self:parseCompressedNotes(self.noise_start_index, self.noise_notes);
	end
	
	--print(self:getName() .. " " .. self.quarter_note_duration);
	
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