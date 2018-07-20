local function filter1(c, tp)
	return c:isLocation('hand') and c:isSide(tp) and not c:isDisabled()
end

local function filter2(c, tp)
	return c:isElement('sky') and not c:isSpirit() and c:isSide(tp) and c:isLocation('discard') and not c:isDisabled()
end

local function operation(c, rc)
	local tp = c:getSide()
	local tc = choose(tp, 'Discard 1 card from your hand:', getCards(filter1, tp), 1, 1)
	if tc and tc:discard(c) then
		local tc2 = choose(tp, 'Add 1 card to your hand:', getCards(filter2, tp), 1, 1)
		if tc2 then
			tc2:add(c)
		end
	end
end

return function(c)
	c:createEffect {
		operation = operation,
		event = 'fusion_sky',
		description = "Discard 1 card from your hand, add 1 non-spirit SKY from your discard pile to your hand.",
	}
end
