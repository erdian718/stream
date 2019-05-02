# stream

A simple lazy list module for [Lua](https://github.com/ofunc/lua).

## Usage

```lua
local stream = require 'stream'

-- Define a Fibonacci sequence.
local fibs
fibs = stream.cons(0, stream.new(1, function()
	return stream.zip(fibs, fibs.tail):map(function(x)
		return x[1] + x[2]
	end)
end))
-- Take the first 32 elements and print them.
fibs:take(32):walk(print)
```

More examples refer to tests.

## Dependencies

* [ofunc/lua](https://github.com/ofunc/lua)

## Documentation

### stream.new(head, tail)

Creates a stream with `head` and `tail`.
`tail` must be a function that generates the tail of this stream.

### stream.cons(x, s)

Prepends the element `x` to the head of the stream `s`.

### stream.make(f, x, i)

Creates a stream using the iteration function `f`. `x` and `i` is the arguments of `f`.

### stream.zip(...)

Returns a stream of tables, where the i-th table contains the i-th element from each of the argument streams.
The returned stream is truncated in length to the length of the shortest argument stream.

### stream.duplicate(x)

Creates an infinite stream with all its elements are `x`.

### stream.sequence(i)

Creates an infinite incremental sequence starting with `i`.

### stream:all(f)

Returns whether all elements of the stream match the given `f` function.

### stream:any(f)

Returns whether any element of the stream matches the given `f` function.

### stream:fold(a, f)

Applies the `f` function to each element of the stream, threading an accumulator argument `a` through the computation. 

### stream:force()

Calculates the elements of the stream immediately, no lazy.

### stream:walk(f)

Applies the given `f` function to each element of the stream.

### stream:map(f)

Applies the given `f` function to each element of the stream and returns the stream.

### stream:filter(f)

Filters the elements of the stream to match the given `f` function and returns the stream.

### stream:take(x)

If `x` is a integer, then takes the first `x` elements.
If `x` is a function, then takes all elements of the stream as long as `x` is true.

### stream:drop(x)

If `x` is a integer, then rejects the first `x` elements.
If `x` is a function, then rejects all elements of the stream as long as `x` is true.

### stream:cut(x)

If `x` is a integer, then rejects the last `x` elements.
If `x` is a function, then rejects all elements of the stream (start with the last one) as long as `x` is true.
