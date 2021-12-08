function pianoroll_trax(x)
	local side; if selectedChannel == "noise" then side = SIDE_NOISE_WIDTH else side = SIDE_PIANO_WIDTH end
	return PIANOROLL_ZOOMX * (x - PIANOROLL_SCROLLX) + (WINDOW_WIDTH / 2) + side; 
end
function pianoroll_tray(y)
	return PIANOROLL_ZOOMY * (60 - y - PIANOROLL_SCROLLY ) + DIVIDER_POS + ( ( WINDOW_HEIGHT - DIVIDER_POS ) / 2 );
end
function piano_roll_untrax(x)
	local side; if selectedChannel == "noise" then side = SIDE_NOISE_WIDTH else side = SIDE_PIANO_WIDTH end
	return ((x - side - (WINDOW_WIDTH / 2) ) / PIANOROLL_ZOOMX) + PIANOROLL_SCROLLX;
end
function piano_roll_untray(y)
	return -((( y - DIVIDER_POS - ( ( WINDOW_HEIGHT - DIVIDER_POS ) / 2 ) ) / PIANOROLL_ZOOMY ) + PIANOROLL_SCROLLY) + 60
end

-- maybe this could be renamed to pianoRollBackground or something, not sure
function renderAvailableNotes( channel )
	if not NOTES then return end
	local notesarray;
	-- noise will display a much more limited set of pitches available (despite others working too, i think)
	if channel == "noise" then
		notesarray = { NOTES[0x10], NOTES[0x20], NOTES[0x30] }
	else
		notesarray = NOTES;
	end
	
	for i = 0, #notesarray do
		local ind = i;
		if ( channel == "pulse1" ) then
			ind = bitwise.band( ind, 0x3e ) -- 0011 1110
		end
		
		if notesarray[ind] ~= nil then
			local pitch = notesarray[ind];
			if ( channel == "tri" ) then
				pitch = pitch - 12;
			end
			
			local recty = pianoroll_tray( pitch );
			local m = (pitch) % 12;
			if ( m == 1 or m == 3 or m == 6 or m == 8 or m == 10 ) then
				love.graphics.setColor( 0.25,0.25,0.25 );
				--love.graphics.setColor( 0.00,0.00,0.00 );
			else 
				love.graphics.setColor( 0.33,0.33,0.33 );
				--love.graphics.setColor( 0.06,0.06,0.06 );
			end
			love.graphics.rectangle( "fill", 0, recty, WINDOW_WIDTH, PIANOROLL_ZOOMY )
			
			--love.graphics.setLineWidth(3);
			love.graphics.setColor( 0.00,0.00,0.00,1 );
			love.graphics.line(0,recty+1,WINDOW_WIDTH,recty+1);
			--love.graphics.setLineWidth(1);
		end
	end
end

function renderChannel( notes, color )
	if not notes[0] then return end
	
	-- rhythmic bars for reference: first tries to find the longest rhythm of the group divisible by 12... 
	-- (was trying to find the quarter note value but i dont think its possible to get this right always)
	-- love.graphics.setColor( 0.0,0.0,0.0 );
	-- local ptrn = songs[selectedSong].patterns[selectedPattern];
	-- local longestval = 0; local ind;
	-- for i = ptrn.tempo, ptrn.tempo+7 do
		-- local ctv = RHYTHM_TABLE[i]; -- current tempo value
		-- if (ctv > longestval and (ctv / 12) % 1 == 0) then
			-- longestval = ctv; ind = i;
		-- end
	-- end
	local ptrn = songs[selectedSong].patterns[selectedPattern];
	local qnd = ptrn.quarter_note_duration;
	local dur;
	if selectedChannel == "noise" then dur = ptrn.noiseduration else dur = ptrn.duration end
	
	-- ...and draws them here
	if qnd ~= 0 then
		for i = 0, (dur / (qnd/4)) do
			if i % 4 == 0 then
				love.graphics.setColor(0,0,0,1);
			else
				love.graphics.setColor(0,0,0,0.5);
			end
			
			local x = pianoroll_trax( (qnd/4) * i );
			love.graphics.line(x,DIVIDER_POS,x,WINDOW_HEIGHT);
		end
	end
	
	-- the notes themselves
	for i = 0, #notes do
		love.graphics.setColor( color );
		local note = notes[i];
		local rectx = pianoroll_trax( note.starttime );
		local recty = pianoroll_tray( note.pitch );
		local rectwidth = note.duration * PIANOROLL_ZOOMX;
		
		if ( note.val ~= 04) then
			love.graphics.rectangle( "fill", rectx, recty, rectwidth, PIANOROLL_ZOOMY )
			-- selected notes have a white outline
			if (selectedNotes[i]) then
				love.graphics.setColor( 1,1,1 );
			-- otherwise black outline
			else
				love.graphics.setColor( 0,0,0 );
			end
			love.graphics.rectangle( "line", rectx, recty, rectwidth, PIANOROLL_ZOOMY )
		end
		
		--love.graphics.setColor( 0.5,0.5,0.5 );
		--love.graphics.line(rectx,DIVIDER_POS,rectx,WINDOW_HEIGHT);
	end
	
	-- end of pattern line
	love.graphics.setColor( 0.0,0.0,0.0 );
	local endx = pianoroll_trax(dur);
	love.graphics.line(endx,DIVIDER_POS,endx,WINDOW_HEIGHT);
end

function renderOverlap()
	local ptrn = songs[selectedSong].patterns[selectedPattern];
	local notes = ptrn:getNotes(selectedChannel);
	if not notes[0] then return end
	
	seen_songs = {}
	seen_ptrns = {}
	seen_chnls = {}
	
	for i = 0, #notes do
		local note = notes[i];
		local currentbyte = rom.data[note.rom_index];
		local hasOverlap = false;
		local txt = "--Overlap-->\n\n"
		
		for q = 1, #currentbyte.song_claims do
			local csc = currentbyte.song_claims[q];
			local cpc = currentbyte.ptrn_claims[q];
			local ccc = currentbyte.chnl_claims[q];
			
			-- The overlap display will only appear on the first note that is overlapping
			-- so it won't show up if its already been put on
			local alreadyseen = false;
			local alreadyseenSong = false;
			for r = 1, #seen_songs do
				if seen_songs[r] == csc and seen_ptrns[r] == cpc and seen_chnls[r] == ccc then 
					alreadyseen = true;
					break;
				elseif seen_songs[r] == csc then
					alreadyseenSong = true;
				end
			end
			
			if (csc ~= selectedSong or cpc ~= selectedPattern or ccc ~= selectedChannel) and (not alreadyseen) then
				local claimedsong = songs[csc];
				local claimedptrn = claimedsong.patterns[cpc];
				
				if claimedptrn:getStartIndex(ccc) > ptrn:getStartIndex(selectedChannel) then
					local r = 0.50 + CHANNEL_COLORS[ccc][1];
					local g = 0.50 + CHANNEL_COLORS[ccc][2];
					local b = 0.50 + CHANNEL_COLORS[ccc][3];
					love.graphics.setColor(r,g,b);
					
					if not alreadyseenSong then
						txt = txt .. claimedsong.name .. "\n" .. ccc .. "\n\n"
					end
					hasOverlap = true;
					table.insert(seen_songs, csc); table.insert(seen_ptrns, cpc); table.insert(seen_chnls, ccc);
				end
			end
		end
		
		if hasOverlap then
			local linex = pianoroll_trax( note.starttime );
			dashLine({x=linex,y=DIVIDER_POS},{x=linex,y=WINDOW_HEIGHT},8,8);
			love.graphics.print(txt, linex + 4, DIVIDER_POS + 24);
		end
	end
end

function renderSidePiano()
	-- noise has a totally different side element
	if selectedChannel == "noise" then
		--love.graphics.setColor( 0.10,0.10,0.10 );
		love.graphics.setColor( 0,0,0 );
		love.graphics.rectangle("fill",0,DIVIDER_POS,SIDE_NOISE_WIDTH,WINDOW_HEIGHT);
		
		love.graphics.setColor( 1,1,1 );
		love.graphics.print("Kick -----",0,pianoroll_tray(NOTES[0x20]))
		love.graphics.print("Closed Hat",0,pianoroll_tray(NOTES[0x10]))
		love.graphics.print("Open Hat--",0,pianoroll_tray(NOTES[0x30]))
		return
	end

	for i = 31, 103 do
		local keyy = pianoroll_tray( i );
		
		local m = (i) % 12;
		if ( m == 1 or m == 3 or m == 6 or m == 8 or m == 10 ) then
			love.graphics.setColor( 0.10,0.10,0.10 );
			--love.graphics.setColor( 0.25,0.25,0.25 );
		else
			love.graphics.setColor( 1,1,1 );
		end
		love.graphics.rectangle( "fill", 0, keyy, SIDE_PIANO_WIDTH, PIANOROLL_ZOOMY )
	end
end

-- This function was written by Ref on the love2d forums:
-- https://love2d.org/forums/viewtopic.php?t=83295
function dashLine( p1, p2, dash, gap )
	local gr = love.graphics;
   local dy, dx = p2.y - p1.y, p2.x - p1.x
   local an, st = math.atan2( dy, dx ), dash + gap
   local len	 = math.sqrt( dx*dx + dy*dy )
   local nm	 = ( len - dash ) / st
   gr.push()
      gr.translate( p1.x, p1.y )
      gr.rotate( an )
      for i = 0, nm do
         gr.line( i * st, 0, i * st + dash, 0 )
      end
      gr.line( nm * st, 0, nm * st + dash,0 )
   gr.pop()
end