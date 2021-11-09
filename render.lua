function pianoroll_trax(x)
	return PIANOROLL_ZOOMX * (x - PIANOROLL_SCROLLX) + (WINDOW_WIDTH / 2) + SIDE_PIANO_WIDTH; 
end
function pianoroll_tray(y)
	return PIANOROLL_ZOOMY * (60 - y - PIANOROLL_SCROLLY ) + DIVIDER_POS + ( ( WINDOW_HEIGHT - DIVIDER_POS ) / 2 );
end
function piano_roll_untrax(x)
	return ((x - SIDE_PIANO_WIDTH - (WINDOW_WIDTH / 2) ) / PIANOROLL_ZOOMX) + PIANOROLL_SCROLLX;
end
function piano_roll_untray(y)
	return -((( y - DIVIDER_POS - ( ( WINDOW_HEIGHT - DIVIDER_POS ) / 2 ) ) / PIANOROLL_ZOOMY ) + PIANOROLL_SCROLLY) + 60
end

-- maybe this could be renamed to pianoRollBackground or something, not sure
function renderAvailableNotes( channel ) 
	for i = 0, #NOTES do
		local ind = i;
		if ( channel == "pulse1" ) then
			ind = bitwise.band( ind, 0x3e ) -- 0011 1110
		end
		
		if NOTES[ind] ~= nil then
			local pitch = NOTES[ind];
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
	for i = 0, #notes do
		love.graphics.setColor( color );
		local note = notes[i];
		local rectx = pianoroll_trax( note.starttime );
		local recty = pianoroll_tray( note.pitch );
		local rectwidth = note.duration * PIANOROLL_ZOOMX;
		
		if ( note.val ~= 04) then
			love.graphics.rectangle( "fill", rectx, recty, rectwidth, PIANOROLL_ZOOMY )
			love.graphics.setColor( 0,0,0 );
			love.graphics.rectangle( "line", rectx, recty, rectwidth, PIANOROLL_ZOOMY )
		end
		
		--love.graphics.setColor( 0.5,0.5,0.5 );
		--love.graphics.line(rectx,DIVIDER_POS,rectx,WINDOW_HEIGHT);
	end
	
	local dur = songs[selectedSong].patterns[selectedPattern].duration;
	local endx = pianoroll_trax(dur);
	love.graphics.line(endx,DIVIDER_POS,endx,WINDOW_HEIGHT);
end

function renderSidePiano()
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