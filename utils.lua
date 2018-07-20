function wait(duration)
	coroutine.yield(function(dt)
		duration = duration - dt
		return duration<=0
	end)
end

function checkParameters(command, parameters, types)
	local t
	local i = 1
	while parameters[i] or types[i] do
		local p = parameters[i]
		t = types[i] or t --keep previous type if inexistent (used for ... parameters)
		local pt = class(p)
		if class(t)=='table' then
			local correct = false
			for j,tt in ipairs(t) do
				if pt==tt then
					correct = true
					break
				end
			end
			if not correct then
				local errorMsg = 'bad argument #' .. i .. " to '" .. command .. "' ("
				for j,tt in ipairs(t) do
					if j==#t then --last
						errorMsg = errorMsg .. tostring(tt)
					elseif j==#t-1 then --last but one
						errorMsg = errorMsg .. tostring(tt) .. ' or '
					else --other
						errorMsg = errorMsg .. tostring(tt) .. ', '
					end
				end
				errorMsg = errorMsg .. ' expected, got ' .. tostring(pt) .. ')'
				error(errorMsg, 3)
			end
		else
			if pt~=t then
				error('bad argument #' .. i .. " to '" .. command .. "' (" .. tostring(t) .. ' expected, got ' .. tostring(pt) .. ')', 3)
			end
		end
		i = i + 1
	end
end

if love then
	local btnFlag = {}
	function love.mouse.btnpressed(btn)
		if love.mouse.isDown(btn) then
			if not btnFlag[btn] then
				btnFlag[btn] = true
				return true
			end
		else
			btnFlag[btn] = nil
		end
		return false
	end

	local keyFlag = {}
	function love.keyboard.keypressed(key)
		if love.keyboard.isDown(key) then
			if not keyFlag[key] then
				keyFlag[key] = true
				return true
			end
		else
			keyFlag[key] = nil
		end
		return false
	end
end

function table.random(t)
	if #t==0 then
		return nil
	end
	local r = math.random(1, #t)
	return t[r]
end

function table.merge(t1, t2)
	for i,e in ipairs(t2) do
		t1[#t1+1] = e
	end
end

function table.shuffle(t)
	for i=1,#t do
		local j = math.random(i, #t)
		t[i],t[j] = t[j],t[i]
	end
end

function table.update(t, update, ...)
	for i,e in ipairs(t) do
		t[i] = update(e, ...)
	end
end

function table.select(t, better, ...)
	local best = nil
	for i,e in ipairs(t) do
		if best==nil or better(e, best, ...) then
			best = e
		end
	end
	return best
end

function table.filter(t, filter, ...)
	local t2 = {}
	for i,e in ipairs(t) do
		if filter(e, ...) then
			t2[#t2+1] = e
		end
	end
	return t2
end

function table.exists(t, condition, ...)
	for i,e in ipairs(t) do
		if condition(e, ...) then
			return true
		end
	end
	return false
end

function class(object)
	local t = type(object) 
	if t~='table' then
		return t
	end
	
	local mt = getmetatable(object)
	return mt or t
end

function createClass(class, constructor, name)
	--object metatable
	class.__index = class
	class.new = function(_, ...)
		local self = {}
		setmetatable(self, class)
		self = constructor(self, ...) or self
		return self
	end
	
	--class metatable
	setmetatable(class, {
		__tostring = function()
			return name
		end,
	})
	
	return class
end

function screenshot(path)
	if os.rename(path, path) then
		os.remove(path)
	end
	local name = 'temp.png'
	local screenshot = love.graphics.newScreenshot()
	screenshot:encode('png', name)
	--os.execute('convert "' .. love.filesystem.getAppdataDirectory() .. '/LOVE/' .. love.filesystem.getIdentity() .. '/' .. name .. '" "' .. path .. '"')
	os.rename(love.filesystem.getAppdataDirectory() .. '/LOVE/' .. love.filesystem.getIdentity() .. '/' .. name, path)
end

function string.readF(s, ...)
	local t = {...}
	local pattern = ''
	for i,p in ipairs(t) do
		pattern = pattern .. '(' .. p .. ') '
	end
	pattern = pattern:gsub(' $', '')
	local ret = {s:find(pattern)}
	table.remove(ret, 1)
	table.remove(ret, 1)
	return unpack(ret)
end

function os.copy(source, dest)
	local sf = io.open(source, 'rb')
	local df = io.open(dest, 'wb')
	df:write(sf:read('*a'))
	sf:close()
	df:close()
end

function tableInsertC(t, callback, elem)
	local a = 0
	local b = #t+1
	while b ~= a+1 do
		local m = math.floor((a+b)/2)
		if callback(elem, t[m]) then
			b = m
		else
			a = m
		end
	end
	table.insert(t, b, elem)
end

function tostring2(elem)
	if type(elem)=='string' then
		return "'" .. elem .. "'"
	else
		return tostring(elem)
	end
end

function printR(elem, hist, tabs)
	hist = hist or {}
	tabs = tabs or 0
	if type(elem)~='table' then
		print(tostring2(elem))
	else
		if not hist[elem] then
			hist[elem] = true
			print(tostring2(elem) .. ' {')
			tabs = tabs + 1
			for i,e in pairs(elem) do
				io.write(string.rep('\t', tabs) .. '[' .. tostring2(i) .. '] ')
				printR(e, hist, tabs)
			end
			tabs = tabs - 1
			print(string.rep('\t', tabs) .. '}')
		else
			print(tostring2(elem) .. ' {...}')
		end
	end
end

function printRToFile(file, elem, hist, tabs)
	hist = hist or {}
	tabs = tabs or 0
	if type(elem)~='table' then
		file:write(tostring2(elem) .. '\n')
	else
		if not hist[elem] then
			hist[elem] = true
			file:write(tostring2(elem) .. ' {\n')
			tabs = tabs + 1
			for i,e in pairs(elem) do
				file:write(string.rep('\t', tabs) .. '[' .. tostring2(i) .. '] ')
				printRToFile(file, e, hist, tabs)
			end
			tabs = tabs - 1
			file:write(string.rep('\t', tabs) .. '}\n')
		else
			file:write(tostring2(elem) .. ' {...}\n')
		end
	end
end

function copyR(t, hist)
	hist = hist or {}
	if type(t)~='table' then
		return t
	end
	if hist[t] then
		return hist[t]
	end
	local c = {}
	setmetatable(c, getmetatable(t))
	hist[t] = c
	for i,value in pairs(t) do
		c[i] = copyR(value, hist)
	end
	return c
end

function compareR(elem1, elem2, hist)
	hist = hist or {}
	if type(elem1)~=type(elem2) then
		return false
	end
	if type(elem1)~='table' then
		return elem1==elem2
	end
	hist[elem1] = hist[elem1] or {}
	if not hist[elem1][elem2] then
		hist[elem1][elem2] = true
		for i, e1 in pairs(elem1) do
			local e2 = elem2[i]
			if not compareR(e1, e2, hist) then
				return false
			end
		end
		for i, e2 in pairs(elem2) do
			local e1 = elem1[i]
			if not compareR(e1, e2, hist) then
				return false
			end
		end
	end
	return true
end

function makeBackup(t, hist)
	hist = hist or {}
	if type(t)~='table' then
		return t
	end
	if hist[t] then
		return hist[t]
	end
	local c = {
		address = t,
		data = {},
	}
	setmetatable(c.data, getmetatable(t))
	hist[t] = c
	for i,value in pairs(t) do
		c.data[i] = makeBackup(value, hist)
	end
	return c
end

function restoreBackup(t, hist)
	hist = hist or {}
	if type(t)~='table' then
		return t
	end
	if hist[t] then
		return hist[t]
	end
	local c = t.address
	hist[t] = c
	for i in pairs(c) do
		c[i] = nil
	end
	for i,value in pairs(t.data) do
		c[i] = restoreBackup(value, hist)
	end
	return c
end

function concatTable(t1, t2)
	local count = 0
	for i,v in ipairs(t2) do
		table.insert(t1, v)
		count = count + 1
	end
	return count
end

function concatSet(t1, t2)
	local count = 0
	for i,v in pairs(t2) do
		if not t1[i] then
			t1[i] = v
			count = count + 1
		end
	end
	return count
end

function isNan(n)
	return n~=n
end

function getNearest(self, target)
	local nearestTarget
	local nearestDist = math.huge
	for i,t in ipairs(target) do
		local dist = math.abs(t.x-self.x) + math.abs(t.y-self.y)
		if dist<nearestDist then
			nearestDist = dist
			nearestTarget = t
		end
	end
	return nearestTarget, nearestDist
end

function scandir(directory, arg)
	arg = arg or {}
    local i = 0
    local t = {}
    local tmp = io.popen('dir /B ' .. (arg.dirOnly and '/ad ' or '')  .. '"' .. directory .. '"')
    for filename in tmp:lines() do
		if not arg.format then
			filename = filename:gsub('%..*', '')
		end
        i = i + 1
        t[i] = filename
    end
    tmp:close()
    return t
end

function random(...)
	local t = {...}
	return t[math.random(1, #t)]
end







































