local mt = {
	__call = function(_, t)
		--give group methods to table
		setmetatable(t, Group)
		return t
	end,
}
Group = {
	--static things
	__metatable = 'table', --tricks class()
}
Group.__index = Group
setmetatable(Group, mt)

--auto-create methods for tables
local exception = {'filter'} --don't create these methods
for name, method in pairs(table) do
	if type(method)=='function' and not exception[name] then
		Group[name] = function(t, ...)
			if class(t)~='table' then
				t = {t}
			end
			
			local success, res = pcall(method, t, ...)
			if success then
				return res
			else
				error(res, 2)
			end
		end
	end
end
--manually create filter
function Group:filter(...)
	return Group(table.filter(self, ...))
end

--auto-create methods for cards
exception = {'new', 'getPlayableCard'} --don't create these methods
for name, method in pairs(CardInterface) do
	if type(method)=='function' and not exception[name] then
		Group[name] = function(card, ...)
			if class(card)~='table' then
				card = {card}
			end
			local ret = true
			for i,c in ipairs(card) do
				if class(c)~=CardInterface then
					error('object ' .. i .. ' is not a card.', 2)
				end
				local success, res = pcall(method, c, ...)
				if success then
					ret = ret and res
				else
					error(res, 2)
				end
			end
			return ret
		end
	end
end
