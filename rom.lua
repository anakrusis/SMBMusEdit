-- object for performing operations and analytics on rom data
ROM = {
	-- table of Byte objects (starting at 0)
	data = {}
}

function ROM:get(ind)
	return self.data[ind].val;
end

function ROM:put(ind,value)
	-- todo maybe return an error or something if inputted value exceeds 0xff
	self.data[ind].val = value;
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

function Byte:hasClaim(song,ptrn,chnl)
	for i = 1, #self.song_claims do
		if self.song_claims[i] == song and self.ptrn_claims[i] == ptrn and self.chnl_claims[i] == chnl then
			return true;
		end
	end
	return false;
end