local test = {}
local stream = require 'stream'

function test.new()
	local x = 0
	local function tail()
		x = x + 1
		return stream.new(x, tail)
	end
	local s0 = stream.new(x, tail)
	local s1 = s0.tail
	local s2 = s1.tail
	assert(s0.head == 0)
	assert(s1.head == 1)
	assert(s2.head == 2)
	assert(s2 == s0.tail.tail)
end

function test.cons()
	local s = stream.cons('X', 'STREAM')
	assert(s.head == 'X')
	assert(s.tail == 'STREAM')
end

function test.make()
	local s = stream.make(ipairs{'A', 'B', 'C'})
	assert(s.head[1] == 1 and s.head[2] == 'A')
	assert(s.tail.head[1] == 2 and s.tail.head[2] == 'B')
	assert(s.tail.tail.head[1] == 3 and s.tail.tail.head[2] == 'C')
end

function test.zip()
	local s1 = stream.sequence(0)
	local s2 = stream.cons('A', stream.cons('B', stream.cons('C')))
	local s3 = stream.duplicate('*')
	local s = stream.zip(s1, s2, s3)

	local h0 = s.head
	local h1 = s.tail.head
	local h2 = s.tail.tail.head

	assert(s.tail.tail.tail == nil)
	assert(h0[1] == 0)
	assert(h0[2] == 'A')
	assert(h0[3] == '*')

	assert(h1[1] == 1)
	assert(h1[2] == 'B')
	assert(h1[3] == '*')

	assert(h2[1] == 2)
	assert(h2[2] == 'C')
	assert(h2[3] == '*')
end

function test.duplicate()
	local s = stream.duplicate('X')
	assert(s.head == 'X')
	assert(s.tail.head == 'X')
	assert(s.tail.tail.head == 'X')
end

function test.sequence()
	local s = stream.sequence(0)
	assert(s.head == 0)
	assert(s.tail.head == 1)
	assert(s.tail.tail.head == 2)
end

function test.all()
	assert(stream.make(ipairs{1, 2, 3, 4, 5}):all(function(x)
		return x[2] > 0
	end))
	assert(not stream.make(ipairs{0, 2, 3, 4, 5}):all(function(x)
		return x[2] > 0
	end))
	assert(not stream.make(ipairs{1, 2, 0, 4, 5}):all(function(x)
		return x[2] > 0
	end))
	assert(not stream.make(ipairs{1, 2, 3, 4, 0}):all(function(x)
		return x[2] > 0
	end))
end

function test.any()
	assert(not stream.make(ipairs{1, 2, 3, 4, 5}):any(function(x)
		return x[2] == 0
	end))
	assert(stream.make(ipairs{0, 2, 3, 4, 5}):any(function(x)
		return x[2] == 0
	end))
	assert(stream.make(ipairs{1, 2, 0, 4, 5}):any(function(x)
		return x[2] == 0
	end))
	assert(stream.make(ipairs{1, 2, 3, 4, 0}):any(function(x)
		return x[2] == 0
	end))
end

function test.fold()
	local s = stream.make(ipairs{3, 1, 7, 4, 9}):fold(0, function(a, x)
		return a + x[2]
	end)
	assert(s == 24)
end

function test.force()
	local l = {'A', 'B', 'C'}
	local s0 = stream.make(ipairs(l))
	local s1 = s0:force()
	l[1], l[2], l[3] = 'X', 'Y', 'Z'
	assert(s0 == s1)
	assert(s0.head[2] == 'A')
	assert(s0.tail.head[2] == 'B')
	assert(s0.tail.tail.head[2] == 'C')
end

function test.walk()
	local xs = ''
	local s0 = stream.make(ipairs{'A', 'B', 'C'})
	local s1 = s0:walk(function(x)
		xs = xs .. x[2]
	end)
	assert(s0 == s1)
	assert(xs == 'ABC')
end

function test.map()
	local s = stream.sequence(0):map(function(x)
		return 2 * x
	end)
	assert(s.head == 0)
	assert(s.tail.head == 2)
	assert(s.tail.tail.head == 4)
end

function test.filter()
	local s0 = stream.sequence(0):filter(function(x)
		return x % 2 == 0
	end)
	assert(s0.head == 0)
	assert(s0.tail.head == 2)
	assert(s0.tail.tail.head == 4)

	local s1 = stream.sequence(0):filter(function(x)
		return x % 2 == 1
	end)
	assert(s1.head == 1)
	assert(s1.tail.head == 3)
	assert(s1.tail.tail.head == 5)
end

function test.take()
	assert(stream.sequence(0):take(1000):fold(0, function(a, x)
		return a + x
	end) == 499500)
	assert(stream.sequence(0):take(function(x)
		return x < 1000
	end):fold(0, function(a, x)
		return a + x
	end) == 499500)
end

function test.drop()
	assert(stream.sequence(0):drop(1000).head == 1000)
	assert(stream.sequence(0):drop(function(x)
		return x < 1000
	end).head == 1000)
end

function test.cut()
	assert(stream.sequence(0):take(1000):cut(500):fold(0, function(a, x)
		return a + x
	end) == 124750)
	assert(stream.sequence(0):take(1000):cut(function(x)
		return x >= 500
	end):fold(0, function(a, x)
		return a + x
	end) == 124750)
end

function test.concat()
	local s1 = stream.cons('A', stream.cons('B'))
	local s2 = stream.duplicate('*'):take(2)
	local s3 = stream.sequence(0)
	local s = nil .. s1 .. nil .. s2 .. nil .. s3 .. nil
	assert(s.head == 'A')
	assert(s.tail.head == 'B')
	assert(s.tail.tail.head == '*')
	assert(s.tail.tail.tail.head == '*')
	assert(s.tail.tail.tail.tail.head == 0)
	assert(s.tail.tail.tail.tail.tail.head == 1)
	assert(s.tail.tail.tail.tail.tail.tail.head == 2)
end

return test
