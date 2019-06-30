--[[
Copyright 2019 by ofunc

This software is provided 'as-is', without any express or implied warranty. In
no event will the authors be held liable for any damages arising from the use of
this software.

Permission is granted to anyone to use this software for any purpose, including
commercial applications, and to alter it and redistribute it freely, subject to
the following restrictions:

1. The origin of this software must not be misrepresented; you must not claim
that you wrote the original software. If you use this software in a product, an
acknowledgment in the product documentation would be appreciated but is not
required.

2. Altered source versions must be plainly marked as such, and must not be
misrepresented as being the original software.

3. This notice may not be removed or altered from any source distribution.
]]

local type = type
local rawset = rawset
local setmetatable = setmetatable
local table = require 'table'
local unpack = table.unpack
local pack = table.pack

local new
local metatable = {}

local function concat(s1, s2)
	if s1 == nil then
		return s2
	elseif s2 == nil then
		return s1
	end
	return new(s1.head, function()
		return s1.tail .. s2
	end)
end

function new(head, tail)
	return setmetatable({head = head}, {
		__index = function(self, key)
			if key == 'tail' then
				local t = tail()
				rawset(self, key, t)
				return t
			else
				return metatable[key]
			end
		end;
		__concat = concat;
	})
end

local function make(f, x, i)
	local h = {f(x, i)}
	i = h[1]
	if i == nil then
		return nil
	else
		return new(h, function()
			return make(f, x, i)
		end)
	end
end

local function cons(x, s)
	return new(x, function()
		return s
	end)
end

local function zip(...)
	local hs, ts = pack(...), pack(...)
	local n = hs.n
	for i = 1, n do
		local s = hs[i]
		if s == nil then
			return nil
		end
		hs[i] = s.head
	end
	return new(hs, function()
		for i = 1, n do
			ts[i] = ts[i].tail
		end
		return zip(unpack(ts, 1, n))
	end)
end

local function duplicate(x)
	return new(x, function()
		return duplicate(x)
	end)
end

local function sequence(i)
	return new(i, function()
		return sequence(i+1)
	end)
end

local function taken(s, n)
	if s == nil or n <= 0 then
		return nil
	end
	return new(s.head, function()
		return taken(s.tail, n-1)
	end)
end

local function takef(s, f)
	if s == nil then
		return nil
	end
	local h = s.head
	if f(h) then
		return new(h, function()
			return takef(s.tail, f)
		end)
	end
end

local function dropn(s, n)
	while s ~= nil and n > 0 do
		s, n = s.tail, n-1
	end
	return s
end

local function dropf(s, f)
	while s ~= nil and f(s.head) do
		s = s.tail
	end
	return s
end

local function cutn(s1, s2)
	if s2 == nil then
		return nil
	end
	return new(s1.head, function()
		return cutn(s1.tail, s2.tail)
	end)
end

local function cutf(s1, s2, f)
	if s1 == s2 then
		s2 = dropf(s2, f)
	end
	if s2 == nil then
		return nil
	end
	return new(s1.head, function()
		if s1 == s2 then
			s2 = s2.tail
		end
		return cutf(s1.tail, s2, f)
	end)
end

function metatable:all(f)
	while self ~= nil do
		if not f(self.head) then
			return false
		end
		self = self.tail
	end
	return true
end

function metatable:any(f)
	while self ~= nil do
		if f(self.head) then
			return true
		end
		self = self.tail
	end
	return false
end

function metatable:fold(a, f)
	while self ~= nil do
		a = f(a, self.head)
		self = self.tail
	end
	return a
end

function metatable:force()
	local s = self
	while s ~= nil do
		s = s.tail
	end
	return self
end

function metatable:walk(f)
	local s = self
	while s ~= nil do
		f(s.head)
		s = s.tail
	end
	return self
end

function metatable:map(f)
	return new(f(self.head), function()
		local t = self.tail
		if t ~= nil then
			return t:map(f)
		end
	end)
end

function metatable:filter(f)
	local h, t = self.head, self.tail
	local g = function()
		if t ~= nil then
			return t:filter(f)
		end
	end
	if f(h) then
		return new(h, g)
	else
		return g()
	end
end

function metatable:take(x)
	if type(x) == 'number' then
		return taken(self, x)
	else
		return takef(self, x)
	end
end

function metatable:drop(x)
	if type(x) == 'number' then
		return dropn(self, x)
	else
		return dropf(self, x)
	end
end

function metatable:cut(x)
	if type(x) == 'number' then
		return cutn(self, dropn(self, x))
	else
		return cutf(self, self, x)
	end
end

return {
	version = '1.0.1';
	new = new;
	cons = cons;
	make = make;
	zip = zip;
	duplicate = duplicate;
	sequence = sequence;
}
