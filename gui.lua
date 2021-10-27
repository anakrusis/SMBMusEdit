function init_gui()
	GUI_SCALE = 1; bypassGameClick = false;
	elements = {};
end

function click_gui(x,y)
	for i = 1, #elements do
		local e = elements[i];
		if ((e.active or e.bypassActiveForClicks) and not e.parent) then
			e:click(x,y);
		end
	end
end

function update_gui()

	for i = 1, #elements do
		local e = elements[i];
		if (e.active) then
			e:update();
		end
	end
end

function render_gui()

	for i = 1, #elements do
		local e = elements[i];
		e:render();
	end
end