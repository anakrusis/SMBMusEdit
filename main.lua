require "song"

function love.load()
	
	local file = io.open("smbmusedit-2/mario.nes", "rb")
	local content = file:read "*a" -- *a or *all reads the whole file
	file:close()
		
	rom = {};	
	for i = 1, #content do
		rom[i - 1] = string.byte(string.sub(content,i,i))
	end 
	
	songs = {};
	local sng_mariodies = Song:new{ name = "Mario Dies" };
	sng_mariodies:parse(0x791E, 1);
	
end

function love.update(dt)

end

function love.draw()

	--string.format("%02X",
	
	--for i = 1, #rom do
		--love.graphics.print( string.format("%02X", rom[i] ), 0, i*16 );
	--end 
end