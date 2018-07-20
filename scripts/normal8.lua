local function filter(c, tp)
	return c:isLocation('damage') and c:isPlayable() and c:isElement('sky') and c:isSide(tp) and not c:isDisabled()
end

local function operation(c, rc)
	local tp = c:getSide()
	local tc = choose(tp, 'Play 1 card:', getCards(filter, tp), 1, 1)
	if tc then
		tc:play(c)
	end
end

return function(c)
	c:createEffect {
		operation = operation,
		event = 'fusion_sky',
		description = "Play 1 SKY from your damage zone.",
	}
end
