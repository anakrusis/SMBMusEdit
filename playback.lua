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
	volumes = {
		pulse2 = 0.6,
		pulse1 = 0.6,
		tri    = 1,
		noise  = 1
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
	local p2 = love.audio.newSource( "assets/square.wav", "static" ); p2:setLooping(true);
	self.sources["pulse2"] = p2;
	local p1 = love.audio.newSource( "assets/square.wav", "static" ); p1:setLooping(true);
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

function PlaybackHandler:toggleMute(channel)
	self.muted[channel] = not self.muted[channel];
	if self.muted[channel] then 
		-- without a specific note we dont know what source noise is
		if channel == "noise" then
			self.sources["kick"]:stop();
			self.sources[ "ch" ]:stop();
			self.sources[ "oh" ]:stop();
		else
			self.sources[channel]:stop();
		end
	end
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
	if self.preview_playing then self:updatePreview() end

	if not self.playing then return end
	local ptrn = songs[selectedSong].patterns[self.playingPattern];
	if not ptrn then return end
	
	self:updateChannel("pulse2");
	self:updateChannel("pulse1");
	self:updateChannel("tri");
	self:updateChannel("noise");
	
	if (self.playpos >= ptrn.duration - 1) then 
		if songs[selectedSong].loop then
			-- This will step through every subsequent pattern until it finds one with greater than zero duration
			-- If it reaches the end of the song, it will loop back to the beginning (hence the modulo)
			local next_nonzero_ptrn;
			for i = 0, 0xff do
				self.playingPattern = ( self.playingPattern + 1 ) % ( songs[selectedSong].patternCount );
				next_nonzero_ptrn = songs[selectedSong].patterns[self.playingPattern];
				if next_nonzero_ptrn.duration > 0 then
					break;
				end
			end
			-- Minus one because it will be stepped back up to zero at the end of this function
			self.playpos = -1;
			self.songpos = next_nonzero_ptrn.starttime - 1;
		else
			self:stop();
		end
	end
	
	self.playpos = self.playpos + 1;
	self.songpos = self.songpos + 1;
end

-- initialises the preview
function PlaybackHandler:playPreview(val)
	-- TODO make sources accessible from table of keys
	local source = self:getSource(selectedChannel, val)
	if not source then return end
	
	if selectedChannel ~= "noise" then
		local freq = FREQ_TABLE[ val ];
		if not freq then source:stop(); return end
		if (selectedChannel == "tri") then
			freq = freq / 2;
		end
		source:setPitch( freq / 130.8128 ); -- <- the frequency of the square wave sample im using right now
	end
	source:play();
	self.preview_playing = true; self.previewtick = 20;
	self.previewpitch = val;
end

function PlaybackHandler:updatePreview()
	if self.previewtick <= 1 then
		local source = self:getSource(selectedChannel, self.previewpitch)
		if not source then return end
		source:stop(); self.preview_playing = false;
	end
	self.previewtick = self.previewtick - 1;
end

function PlaybackHandler:updateChannel( chnl )
	if self.muted[chnl] then return end

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
				--source:setVolume(0); -- <- this doesnt really have a smooth cutoff, it ramps down weirdly
				return;
			-- note
			else
				source:setVolume( self.volumes[ chnl ] );
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

function PlaybackHandler:reset()
	self.playpos = 0; self.songpos = 0;
	self.setsongpos = 0;
	self.setplaypos = 0;
	self.setPattern = 0;
	self.playingPattern = 0;
end