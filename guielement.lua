GuiElement = {
	--constructor(x,y,width,height,parent){
	
	-- core properties
	x = 0,
	y = 0,
	width = 100,
	height = 100,
	padding = 5,
	
	dispx = 0,
	dispy = 0,
	dispwidth = 100,
	dispheight = 100,
	
	text_color = {1,1,1},
	bg_color   = {0,0,0},
	
	active = true,
	bypassActiveForClicks = false, -- a few elements bypass the parents activity for click elements, such as the zoom buttons
	visible = true,
	transparent = false,
	ticksShown = 0,
	holdclick = false, -- If true, it will trigger the click event every tick that it is held, instead of just once at the beginning
	
	autopos = "top", -- float property
	autosize = false, -- will fill up to the size of its children elements
	autosizex = false,
	autosizey = false,
	
	staticposition = false, -- will not affect the size of autosize parent
	
	autocenterX = false, -- will center to middle of screen (best for popup windows, or also some HUD stuff)
	autocenterY = false,
	
	name = "",
	text = "",
	disptext = "",
	
	-- referential properties
	parent = nil,
	children = {},
}

function GuiElement:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	
	o.children = {};
	
	if (o.parent) then
		--print( o.name .. " added to " .. o.parent.name);
		o.parent:appendElement( o );
	else
		--elements.push(this);
		--print( o.name .. " added to elements " );
		table.insert(elements, o);
	end
	
	return o
end
	
	-- update() contains most of the auto positioning of text boxes and things, it is an outer layer to the 
	-- inner layer function onUpdate() which has more personal properties of individual GUI elements
function GuiElement:update()
		
	--print("update");	
	
	if self.onUpdate then
		self:onUpdate();
	end
	
	for i = 1, #self.children do
		local e  = self.children[i];
		e:update();
	end
	
	if not self.staticposition then
		local p = self.parent;
		if p then
			
			-- Float left, each element after is right of the one before it
			if p.autopos == "left" then
				
				self.dispx = p.dispx + p.padding;
				self.dispy = p.dispy + p.padding;
				
				for i = 1, #p.children do
					
					if (p.children[i].visible) then
						if p.children[i] == self then
							break;
						else
							self.dispx = self.dispx + p.children[i].dispwidth + p.padding;
						end
					end
				end
			end 
			if p.autopos == "top" then
				
				self.dispx = p.dispx + p.padding;
				self.dispy = p.dispy + p.padding;
				
				for i = 1, #p.children do
					
					if (p.children[i].visible) then
						if (p.children[i] == self) then
							break;
						else
							self.dispy = self.dispy + p.children[i].dispheight + p.padding;
						end
					end
				end
			end
		else
			
			if (self.autocenterX) then
				self.x = width/GUI_SCALE/2 - self.width/2;
			end
			if (self.autocenterY) then
				self.y = height/GUI_SCALE/2 - self.height/2;
			end
			
			self.dispx = self.x + self.padding; self.dispy = self.y + self.padding;
		end
	end
	
	-- This fills up an element based on the size of the children elements inside it:
	-- it gets the extremes for X and Y and then pads them out afterwards
	if (self.autosize or self.autosizex or self.autosizey) then
		
		--print("Yea autosize");
	
		local minx = 100000; local miny = 100000;
		local maxx = 0; local maxy = 0;
		for i = 1, #self.children do
			
			local c = self.children[i];
			if (c.visible and not c.staticposition) then
				if (c.dispx + c.dispwidth > maxx) then
					maxx = c.dispx + c.dispwidth;
				end
				if (c.dispx < minx) then
					minx = c.dispx;
				end
				if (c.dispy + c.dispheight > maxy) then
					maxy = c.dispy + c.dispheight;
				end
				if (c.dispy < miny) then
					miny = c.dispy;
				end
			end
		end
		-- This padding is compensating for the two lines immediately after
		if (self.autosize or self.autosizex) then
			self.width = maxx - minx + (self.padding*4);
		end
		if (self.autosize or self.autosizey) then
			self.height = maxy - miny + (self.padding*4);
		end

	end
	
	self.dispwidth = self.width - (self.padding*2);
	self.dispheight = self.height - (self.padding*2);
	
	--this.disptext = this.text;

	-- if (!FANCY_TEXT){
		-- var lines = 0;
		-- var linepos = 0;
		-- for (var i = 0; i < this.text.length; i++){
			
			-- --console.log(this.text.slice(i,i+2));
			-- if (this.text.slice(i, i+1) == "\n"){
				-- lines++;
				-- linepos = 0;
			-- }
			
			-- if ((linepos+1) % (this.dispwidth/10) == 0){
				
				-- lines++;
				-- linepos = 0;
				-- --var txt2 = txt1.slice(0, 3) + "\n" + txt1.slice(3);
			-- }
			-- linepos++;
		-- }
		-- this.lines = lines;
	-- }
	
	-- if (FANCY_TEXT){
		-- var h = (16 * this.lines) + this.padding*6;
	-- }else{
		-- var h = 22 * this.lines + this.padding*5;
	-- }
	-- this.dispheight = Math.max(this.dispheight, h);
	
	-- if (this.visible){
		-- this.ticksShown++;
	-- }else{
		-- this.ticksShown = 0;
	-- }
end

-- This is blank by default so each GUI element can have unique per-tick behaviors
function GuiElement:onUpdate()
	
end
	
-- This one also acts as a skeleton function for the real behavior which is onClick()
function GuiElement:click(x,y)
	for i = 1, #self.children do
		local e  = self.children[i];
		e:click(x,y);
	end
	
	if (bypassGameClick) then return end
	
	if (self.visible and (self.active or self.bypassActiveForClicks)) then
		if (x > self.dispx*GUI_SCALE and x < (self.dispx + self.dispwidth) * GUI_SCALE
		and y > self.dispy*GUI_SCALE and y < (self.dispy + self.dispheight)* GUI_SCALE ) then
		
			self:onClick(); 
			bypassGameClick = true;
		end
	end
end
	
-- This one is empty and left to be defined individually
function GuiElement:onClick()
	--print (self.name .. " clicked")
end
	
-- Wow this is going back to lua unchanged, truly full circle
function GuiElement:appendElement(e)
	--print( e.name .. " added to " .. self.name )
	e.parent = self;
	table.insert(self.children, e);
end
	
-- This is recursive, and it goes from a top parent element through all the children of the tree
function GuiElement:render()
	-- if (!this.visible || this.ticksShown < 3) { return; }
	
	-- if (!this.transparent){ fill(0); } else { noFill(); blendMode(DIFFERENCE); }
	-- stroke(255);
	
	love.graphics.setColor( self.bg_color );
	love.graphics.rectangle( "fill", self.dispx, self.dispy, self.dispwidth, self.dispheight );
		
	love.graphics.setColor( self.text_color );
	love.graphics.rectangle( "line", self.dispx, self.dispy, self.dispwidth, self.dispheight );
	love.graphics.printf( self.text, self.dispx + self.padding, self.dispy + self.padding, self.dispwidth - (self.padding*2));
	
	-- if (this.transparent){ blendMode(BLEND); }
	-- noStroke();
	-- fill(255);
	
	-- if (this.text != ""){
		-- //this.text = this.text.toUpperCase();
		-- //textWrap(LINE)
		-- //
		-- if (!FANCY_TEXT){
			-- text( this.text, this.dispx + this.padding, this.dispy + this.padding, this.dispwidth - (this.padding*2));
			
		-- }else{
			-- this.lines = 0;
			-- var dx = this.dispx + this.padding; var dy = this.dispy + this.padding;
			
			-- var SOURCE_SIZE = 8;
			-- var DEST_SIZE = 16;
			-- var i = 0; var column = 0; this.maxcolumns = Math.floor ( this.dispwidth / DEST_SIZE ) ;
			
			-- while ( i < this.text.length ){


				-- var c = this.text.charCodeAt(i); var cy = Math.floor( c / 16 ); var cx = c % 16;
				
				-- if ( c != 32 ){
				-- //image(img, dx, dy, dWidth, dHeight, sx, sy, [sWidth], [sHeight])
					-- image(FONT, dx, dy, DEST_SIZE, DEST_SIZE, cx * SOURCE_SIZE, cy * SOURCE_SIZE, SOURCE_SIZE, SOURCE_SIZE);
				-- }
				
				-- dx += Math.ceil( DEST_SIZE * 1 ); column++;
				
				-- if (c == 32){
					-- var f = this.text.substring(i+1); var tospace = f.split(" "); var tonl = f.split("\n");
					
					-- var f2 = ( tospace[0].length < tonl[0].length ) ? tospace : tonl;
					
					-- if ( column + (f2[0].length) > this.maxcolumns ){ 
						-- dy += ( DEST_SIZE ); dx = this.dispx + this.padding;
						-- column = 0; this.lines++;
					-- }
				-- }else if (this.text.substring(i,i+1) == "\n"){
					-- dy += ( DEST_SIZE ); dx = this.dispx + this.padding;
					-- column = 0; this.lines++;
				-- }
				-- i++;
			-- }
		-- }
	-- }else{
		-- this.lines = 0;
	-- }
	if (self.onRender) then
		self:onRender();
	end
	
	for i = 1, #self.children do
		local e  = self.children[i];
		e:render();
	end

end
	
-- Same deal, this is empty so each element can have custom rendering stuff
function GuiElement:onRender()
	
end

-- Likewise for the following methods
function GuiElement:show()
	-- this.visible = true;
	-- for (var i = 0; i < this.children.length; i++){
		-- var e  = this.children[i];
		-- e.show();
	-- }
	-- --this.onUpdate();
	-- this.onShow();
end

function GuiElement:onShow()
	
end

function GuiElement:hide()
	-- this.visible = false;
	-- for (var i = 0; i < this.children.length; i++){
		-- var e  = this.children[i];
		-- e.hide();
	-- }
end
