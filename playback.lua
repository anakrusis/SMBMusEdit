PlaybackHandler = {
	sources = {},
	muted   = {
		pulse2 = false,
		pulse1 = false,
		tri    = false,
		noise  = false
	},
	solo    = {
		pulse2 = false,
		pulse1 = false,
		tri    = false,
		noise  = false
	},
	
	playing = false,
	-- these are in ticks: ticks relative to the start of the current pattern
	playpos = 0,
	-- ticks relative to the start of the whole song
	songpos = 0,
	-- this is a position which can be set upon clicking on a point in the editors
	setsongpos = 0,
	setplaypos = 0,
	setPattern = 0,
	
	playingPattern = 0,
	-- the sounds that play when placing down notes
	preview_playing = false, 
	previewtick = 0, 
	previewpitch = 0,
}

function PlaybackHandler:initSources()
	local p2 = love.audio.newSource( "assets/square.wav", "static" ); p2:setLooping(true); p2:setVolume(0.6);
	self.sources["pulse2"] = p2;
	local p1 = love.audio.newSource( "assets/square.wav", "static" ); p1:setLooping(true); p1:setVolume(0.6);
	self.sources["pulse1"] = p1;
	local tri = love.audio.newSource( "assets/tri.wav", "static" ); tri:setLooping(true);
	self.sources["tri"] = tri;
	
	-- noise sources
	self.sources["kick"] = love.audio.newSource("assets/kick.wav", "static");
	self.sources["ch"]   = love.audio.newSource("assets/ch.wav", "static");
	self.sources["oh"]   = love.audio.newSource("assets/oh.wav", "static");
end

-- toggles between playing and stopping based on the current status
function PlaybackHandler:togglePlaying()
	local ptrn = songs[selectedSong].patterns[self.setPattern];
	if not ptrn then return end
	
	self.playing = not self.playing;
	self.playpos = self.setplaypos; self.songpos = self.setsongpos;
	self.playingPattern = self.setPattern;
	if (not self.playing) then self:stop(); end
end

-- returns an audio source given a channel and noteval (the noteval is used to decide the sources for noise)
function PlaybackHandler:getSource(channel, noteval)
	-- todo (this is probably bitmasked in some way)
	if channel == "noise" then
		if noteval == 0x10 then -- closed hat
			return self.sources["ch"];
		elseif noteval == 0x20 then -- kick
			return self.sources["kick"];
		elseif noteval == 0x30 then -- open hat
			return self.sources["oh"];
		else
			return false;
		end
	else
		return self.sources[channel];
	end
end

-- called every tick, updates the playback of the song if it is currently ongoing
function PlaybackHandler:update()
	if not self.playing then return end
	local ptrn = songs[selectedSong].patterns[self.playingPattern];
	if not ptrn then return end
	
	self:updateChannel("pulse2");
	self:updateChannel("pulse1");
	self:updateChannel("tri");
	self:updateChannel("noise");
	
	if (self.playpos >= ptrn.duration) then 
		if songs[selectedSong].loop then
		-- TODO make this skip over all patterns of zero duration
			self.playingPattern = ( self.playingPattern + 1 ) % ( songs[selectedSong].patternCount );
			self.playpos = -1;
			self.songpos = self.songpos - 1;
			
			-- loop back to the beginning of song
			if self.playingPattern == 0 then
				self.songpos = -1;
			end
		else
			stop();
		end
	end
	
	self.playpos = self.playpos + 1;
	self.songpos = self.songpos + 1;
end

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

function PlaybackHandler:updateChannel( chnl )
	local ptrn = songs[selectedSong].patterns[self.playingPattern];
	if not ptrn then return end
	local notes = ptrn:getNotes(chnl);
	if not notes[0] then return end
	for i = 0, #notes do
		local note = notes[i];
		local pos = self.playpos;
		-- noise playback loops if shorter than the main pattern duration
		if chnl == "noise" and ptrn.noiseduration < ptrn.duration then
			pos = pos % ptrn.noiseduration;
		end
		
		if note.starttime == pos then
			local source = self:getSource(chnl, note.val);
			if not source then return end
			
			-- rest
			if ( note.val == 04) then
				source:stop(); 
				return;
			-- note
			else
				-- Noise can't be repitched like the other channels
				if chnl ~= "noise" then
					local freq = FREQ_TABLE[ note.val ];
					if not freq then source:stop(); return end
					
					if (chnl == "tri") then
						freq = freq / 2;
					end
					source:setPitch( freq / 130.8128 ); -- <- the frequency of the square wave sample im using right now
				end
				
				source:play();
			end
		end
	end
end

function PlaybackHandler:stop()
	for key, value in pairs(self.sources) do
		--print(key)
		self.sources[key]:stop();
	end
	self.playing = false;
end