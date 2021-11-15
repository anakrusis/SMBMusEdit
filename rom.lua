-- object for performing operations and analytics on rom data
ROM = {
	-- table of Byte objects (starting at 0)
	data = {}
}

-- bytes
function ROM:get(ind)
	return self.data[ind].val;
end
function ROM:put(ind,value)
	-- todo maybe return an error or something if inputted value exceeds 0xff
	self.data[ind].val = value;
end

-- little-endian words, index refers to first byte
function ROM:putWord(ind,value)
	self.data[ind].val     = value % 0x100;
	self.data[ind + 1].val = math.floor(value / 0x100);
end
function ROM:getWord(ind)
	return ( self.data[ind + 1].val * 0x100 ) + self.data[ind].val
end

function ROM:findNextUnusedIndex()
	local DATA_START = 0x79C8;
	local DATA_END   = 0x7F0F;
	
	for i = DATA_START, DATA_END do
		if #self.data[i].song_claims == 0 then
			return i;
		end
	end
	return false;
end

-- the first unused index not in queue to be for this particular song+ptrn+chnl
function ROM:findNextUnusedUnqueuedIndex(song,ptrn,chnl)
	local DATA_START = 0x79C8;
	local DATA_END   = 0x7F0F;
	
	for i = DATA_START, DATA_END do
		if #self.data[i].song_claims == 0 then
			
			-- iterating backwards to find the first used index.
			-- if this used index is NOT claimed by the song+ptrn+chnl, then return it!
			-- otherwise, stop iterating backwards and move onto the next unused byte
			for j = 0, 0xff, 1 do
				local ind = i - j;
				if #self.data[ind].song_claims > 0 then
					if not self.data[ind]:hasClaim(song,ptrn,chnl) then
						return i;
					end
					break;
				end
			end
		end
	end
	return false;
end

-- The following two functions provide markers for shifting bytes without having to worry about changing indices and stuff. 
-- actions dealing with shifting indices do not have to keep track; it will be kept track of here.

function ROM:clearMarkers()
	local DATA_START = 0x79C8;
	local DATA_END   = 0x7F0F;
	for i = DATA_START, DATA_END do
		local cb = self.data[i];
		cb.insert_before = nil;
		cb.insert_after  = nil;
		cb.delete        = false;
	end
end

function ROM:commitMarkers(startind, endind)
	local DATA_START; local DATA_END;
	if startind then DATA_START = startind; else DATA_START = 0x79C8; end
	if endind   then DATA_END   = endind;   else DATA_END   = 0x7F0F; end
	
	ind = DATA_START;
	while ind <= DATA_END do
		local cb = self.data[ind];
		if cb.insert_before then
			local newbyte = Byte:new{ val = cb.insert_before }
			table.insert( self.data, ind, newbyte )
			cb.insert_before = nil;
			ind = ind + 1;
		end
		if cb.insert_after then
			local newbyte = Byte:new{ val = cb.insert_after }
			table.insert( self.data, ind + 1, newbyte )
			cb.insert_after = nil;
		end
		if cb.change then
			self.data[ind].val = cb.change;
			cb.change = nil;
		end
		if cb.delete then
			cb.delete = false;
			table.remove( self.data, ind );
			ind = ind - 1;
		end
		ind = ind + 1;
	end
end

-- doesnt deep copy the claims tables (yet)(might not need to)
function ROM:deepcopy(oldrom, startind, endind)
	--self.data = {};
	
	if startind then DATA_START = startind; else DATA_START = 0; end
	if endind   then DATA_END   = endind;   else DATA_END   = table.getn(oldrom.data); end
	
	for i = DATA_START, DATA_END do
		local ob = oldrom.data[i];
		local cb = Byte:new{ 
			val           = ob.val,
			insert_after  = ob.insert_after,
			insert_before = ob.insert_before,
			delete        = ob.delete,
			change        = ob.change,
			
			song_claims   = ob.song_claims,
			ptrn_claims   = ob.ptrn_claims,
			chnl_claims   = ob.chnl_claims
		}
		self.data[i] = cb;
	end
end

function ROM:export(path)
	local output = ""
	local file = io.open(path, "wb")
	for i = 0, table.getn(self.data) do 
		output = output .. string.char(self.data[i].val)
	end
	file:write(output)
	file:close()
end

function ROM:import(path)
	local file = io.open(path, "rb")
	local content = file:read "*a" -- *a or *all reads the whole file
	file:close()
		
	self.data = {};	
	for i = 1, #content do
		local b = Byte:new();
		b.val = string.byte(string.sub(content,i,i));
		self.data[i - 1] = b;
	end
end

function ROM:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	
	o.data = {};
	return o
end

Byte = {
	val = 0x00,
	
	-- a byte can "belong" to multiple songs, multiple patterns, multiple channels...
	-- but more importantly, if it doesn't belong to any, it is considered "free" and can be used for any song
	song_claims = {},
	ptrn_claims = {},
	chnl_claims = {},
	
	-- These are temporary markers for editing which can be committed into effect, or cleared if the action is cancelled
	change        = nil,
	delete        = false,
	insert_before = nil,
	insert_after  = nil,
}

function Byte:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	
	o.song_claims = {};
	o.ptrn_claims = {};
	o.chnl_claims = {};
	return o
end

function Byte:commitMarkers()
end

-- if this byte is claimed by a specific song, pattern and channel
function Byte:hasClaim(song,ptrn,chnl)
	for i = 1, #self.song_claims do
		if self.song_claims[i] == song and self.ptrn_claims[i] == ptrn and self.chnl_claims[i] == chnl then
			return true;
		end
	end
	return false;
end
-- if this byte is claimed by a specific channel (pattern/song doesnt matter)
function Byte:hasChannelClaim(chnl)
	for i = 1, #self.song_claims do
		if self.chnl_claims[i] == chnl then
			return true;
		end
	end
	return false;
end

function Byte:hasSongPatternClaim(song,ptrn)
	for i = 1, #self.song_claims do
		if self.song_claims[i] == song and self.ptrn_claims[i] == ptrn then
			return true;
		end
	end
	return false;
end