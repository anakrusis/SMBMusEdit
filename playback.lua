-- initialises the preview
function previewNote(val)
	-- TODO make sources accessible from table of keys
	local source;
	if selectedChannel == "pulse2" then
		source = SRC_PULSE2;
	elseif selectedChannel == "pulse1" then
		source = SRC_PULSE1;
	elseif selectedChannel == "tri" then
		source = SRC_TRI;
	end
	if not source then return end
	local freq = FREQ_TABLE[ val ];
	if not freq then source:stop(); return end
	
	if (source == SRC_TRI) then
		freq = freq / 2;
	end
	source:setPitch( freq / 130.8128 ); -- <- the frequency of the square wave sample im using right now
	source:play();
	preview_playing = true; previewtick = 20;
end

function playPreview()
	if previewtick <= 1 then
		local source;
		if selectedChannel == "pulse2" then
			source = SRC_PULSE2;
		elseif selectedChannel == "pulse1" then
			source = SRC_PULSE1;
		elseif selectedChannel == "tri" then
			source = SRC_TRI;
		end
		if not source then return end
		source:stop(); preview_playing = false;
	end
	previewtick = previewtick - 1;
end

function play()
	local ptrn = songs[selectedSong].patterns[playingPattern];
	playChannel( ptrn.pulse2_notes, SRC_PULSE2 );
	playChannel( ptrn.tri_notes,    SRC_TRI );
	playChannel( ptrn.pulse1_notes, SRC_PULSE1 );
	playChannel( ptrn.noise_notes,  SRC_KICK );
	
	if (playpos >= ptrn.duration) then 
		if songs[selectedSong].loop then
			playingPattern = ( playingPattern + 1 ) % ( songs[selectedSong].patternCount );
			playpos = -1;
			songpos = songpos - 1;
			
			-- loop back to the beginning of song
			if playingPattern == 0 then
				songpos = -1;
			end
		else
			stop();
		end
	end
	
	playpos = playpos + 1;
	songpos = songpos + 1;
end

function playChannel( notes, source )
	local ptrn = songs[selectedSong].patterns[playingPattern];
	if not notes[0] then return end
	for i = 0, #notes do
		local note = notes[i];
		local pos = playpos;
		-- noise playback loops
		if source == SRC_KICK and ptrn.noiseduration < ptrn.duration then
			pos = pos % ptrn.noiseduration;
		end
		if note.starttime == pos then
			
			if ( note.val == 04) then
				source:stop();
			else
				-- special noise handling playback
				if source == SRC_KICK then
					if note.val == 0x10 then -- closed hat
						SRC_CH:play();
					elseif note.val == 0x20 then -- kick
						source:play();
					elseif note.val == 0x30 then -- open hat
						SRC_OH:play();
					else
						return;
					end
				else
					local freq = FREQ_TABLE[ note.val ];
					if not freq then source:stop(); return end
					
					if (source == SRC_TRI) then
						freq = freq / 2;
					end
					source:setPitch( freq / 130.8128 ); -- <- the frequency of the square wave sample im using right now
					source:play();
				end
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