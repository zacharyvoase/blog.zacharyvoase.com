--- 
kind: article
timestamp: 2010-01-02
title: "A (Nicer) Redis Client for EventMachine"
---

[Redis][] is my favourite key/value store; it’s flexible, easy to set up and
insanely fast. [EventMachine][] is a popular Ruby library for doing
asynchronous I/O using an event loop. Bindings already [exist][em-redis] for
accessing a Redis server using EM’s async-I/O (courtesy of Jonathan Broad), but
unfortunately the resulting code has to use [Continuation-Passing Style][cps]
via Ruby blocks. A very basic example of what that looks like follows:

  [Redis]: http://redis.googlecode.com/
  [EventMachine]: http://rubyeventmachine.com/
  [em-redis]: http://github.com/madsimian/em-redis
  [cps]: http://en.wikipedia.org/wiki/Continuation-passing_style

    require 'em-redis'
    
    EventMachine.run do
      redis = EventMachine::Protocols::Redis.connect
      redis.set("foo", "bar") do |_|
        redis.get("foo") do |response|
          puts response
        end
      end
    end

Essentially, every single Redis operation incurs another level of indentation.
Aside from being aesthetically very unpleasing, there are certain limitations
this brings with it, due to the fact that most Ruby code is written in a non-CPS
style, and written to work with non-CPS programs. What we’d really like to do is
the following:

    require 'em-redis'
    
    EventMachine.run do
      redis = EventMachine::Protocols::Redis.connect
      redis.set("foo", "bar")
      puts redis.get("foo")
    end

It turns out this is possible, and relatively easy too.

## The Fix

I set about tacking this problem with a relatively old programming technique.
[`call-with-current-continuation`][callcc], commonly abbreviated as `call/cc`,
is a construct first invented in Scheme which allows you to use a CPS function
seamlessly from within imperative code.

  [callcc]: http://en.wikipedia.org/wiki/Call-with-current-continuation

<ins>
  <strong>N.B.</strong> If you’re familiar with continuations, you’ll know that
  what I’m about to show you wouldn’t at all qualify as <code>call/cc</code>;
  however, in this instance we are concerned with its behaviour as a mapping
  from CPS to imperative code styles.
</ins>

In RSpec, `call/cc` would pass the following test:
  
    def myfunc
      yield 3
    end
    
    callcc(method :myfunc).should == 3

So in a Ruby-specific context, it transforms a `yield` statement into `return`.
Here, `callcc()` takes a proc (the object representation of a block), and
*returns* whatever that proc *yields*. It would also accept any number of
arguments to pass along.

Applied to Redis + EventMachine, we should be able to translate the earlier
fubarity into something a little cleaner:

    require 'em-redis'
    
    EventMachine.run do
      redis = EventMachine::Protocols::Redis.connect
      callcc(redis.method(:set), "foo", "bar")
      puts callcc(redis.method(:get), "foo")
    end

So it’s a little cleaner, but not perfect. We don’t want to have to wrap every
Redis operation with a `callcc()` invocation. So a better idea is to
monkey-patch the `Redis` EventMachine protocol to use `callcc` at a lower level:

    module EventMachine::Protocols::Redis
      alias :cps_inline_command :inline_command
      def inline_command(*args)
        callcc(method(:cps_inline_command), *args)
      end
      
      alias :cps_multiline_command :multiline_command
      def multiline_command(command, *args)
        callcc(method(:cps_multiline_command), command, *args)
      end
    end

The `EventMachine::Protocols::Redis` protocol carries out most operations using
these methods, so by overriding them everything else should implicitly start
using `callcc()`.

Now the example code looks like this:

    require 'em-redis'
    
    EventMachine.run do
      redis = EventMachine::Protocols::Redis.connect
      redis.set("foo", "bar")
      puts redis.get("foo")
    end

That’s much more like it.

## Implementing `callcc()`

Now for the hard part. `callcc()` is not trivial to implement in a language
without first-class built-in continuations. Ruby 1.9 includes [Fibers][], a
coroutine implementation which does make it possible to write `callcc()`. Anyone
familiar with Lua’s coroutines will feel perfectly at home with Fibers, but for
the Rubyists who haven’t encountered them, I’ll begin with a quick intro.

  [fibers]: http://ruby-doc.org/ruby-1.9/classes/Fiber.html

### A short introduction to Fibers

We all know and love Ruby’s `yield` and blocks. But unfortunately, a block
passed to a method will not be available implicitly further down the stack. The
problem is demonstrated here:

    def a(&block)
      b(&block)
    end
    
    def b(&block)
      c(&block)
    end
    
    def c
      puts "ready to receive"
      val = yield
      puts "received: #{ val.inspect }"
    end
    
    a { "some_value" }

In order for `c` to be able to call the block, it must be explicitly passed down
by each function in the stack. With Fibers, the code becomes:

    def a
      b
    end
    
    def b
      c
    end
    
    def c
      puts "ready to receive"
      val = Fiber.yield
      puts "received: #{ val.inspect }"
    end
    
    f = Fiber.new &(method :a)
    f.resume # get the fiber to the first `Fiber.yield` call.
    f.resume "some_value"

A few things to note here:

*   `c()` calls `Fiber.yield` instead of `yield`. This is a non-local `yield`
    which will propagate up to whatever called the current fiber’s `resume()`
    method.
    
*   The code which does the calling becomes a little more complex, but none of
    the application code in `a()` or `b()` need be aware that `c()` will yield.
    Nevertheless, the pattern shown here can be abstracted away, so that
    eventually we may only need:
    
            fiblock(method :a) { "some_value" }
    
*   We must explicitly run `a()` in a Fiber; this is a trade-off against having
    to explicitly acknowledge the presence of a block throughout the stack (as
    in the previous code).

### `call/cc`, already.

`call/cc` can be implemented relatively simply with Fibers, but there are two
distinct forms:

    def callcc_inner(proc, *args)
      Fiber.new do
        proc.call(*args) { |*yargs| Fiber.yield(*yargs) }
      end.resume
    end
    
    def callcc_outer(proc, *args)
      curr_fiber = Fiber.current
      proc.call(*args) { |*rargs| curr_fiber.resume(*rargs) }
      Fiber.yield
    end

The difference between the two is subtle, but very important:

*   `callcc_inner()` creates a new Fiber in which the proc is run. The proc is
    passed a block which calls `Fiber.yield`, causing the wrapping Fiber to
    immediately pass control back to whatever started it. Since this fiber is
    resumed immediately after creation, we get whatever was yielded by the proc.

*   `callcc_outer()` operates almost exactly opposite. The proc is called with a
    block that will immediately resume the *current* Fiber. Then `Fiber.yield()`
    is called from the top-level. This suspends the current Fiber until proc
    eventually calls the block with some values; these values are output as the
    result of the call to `Fiber.yield()`, and therefore the result of the call
    to `callcc_outer()`.

Because of their different behaviours, `callcc_inner()` will *only* work when
the proc it is called with yields *during* its execution (i.e. yields before it
returns). Conversely, `callcc_outer()` will *only* work when the proc it is
called with returns *before* it yields.

## Patching EventMachine and `em-redis`

To revisit the CPS employed in the Redis bindings:

    redis.set("foo", "bar") do |_|
      redis.get("foo") do |value|
        puts value
      end
    end

The call to `redis.set()` returns *before* it executes the given block (since it
adds the block to a list of event loop callbacks); as such, we should use
`callcc_outer()` throughout the modified `EventMachine::Protocols::Redis`. The
entirety of the code needed to patch `em-redis` is:

    # File: redis-fiber.rb
    require 'fiber'
    require 'em-redis'


    def callcc(proc, *args)
      curr_fiber = Fiber.current
      proc.call(*args, &curr_fiber.method(:resume))
      return Fiber.yield
    end


    module EventMachine
      def self.run_fiber(*args, &blk)
        f = Fiber.new(&blk)
        run(*args) { f.resume }
      end

      module Protocols::RedisFiber
        include Protocols::Redis

        # Classmethods don't get mixed in.
        def self.connect(host = 'localhost', port = 6379)
          EventMachine.connect(host, port, self, host, port)
        end

        alias :cps_inline_command :inline_command
        def inline_command(*args)
          callcc((method :cps_inline_command), *args)
        end

        alias :cps_multiline_command :multiline_command
        def multiline_command(command, *args)
          callcc((method :cps_multiline_command), command, *args)
        end
      end
    end

And the code I use to test it in a very quick-n-dirty way:

    # file: redis-fiber-test.rb
    require 'redis-fiber'

    EventMachine.run_fiber do
      redis = EventMachine::Protocols::RedisFiber.connect
      puts "set foo = \"bar\""
      redis.set("foo", "bar")
      print "foo => "
      puts redis.get("foo").inspect
      EventMachine.stop_event_loop
    end

The additional `EventMachine.run_fiber()` method is required for
`callcc_outer()` to work; since it uses `Fiber.yield()` from the top-level, and
the root Fiber cannot yield (since there’s nothing for it to yield to), we need
to run the event loop within its own Fiber. I’ve also created a new `RedisFiber`
protocol, instead of patching the old one, in case existing code uses the old
one.

## Bye For Now, or The Road Ahead

The thing to take away from this blog post is:

*   Fibers can be used to implement `call/cc` (or something like it).
*   `call/cc` allows you to use EventMachine async-I/O without the CPS.
*   It’s pretty easy to monkey-patch existing libraries to use `call/cc`.

I’m very interested in building on what I’ve done here, but due to time
constraints I might not be able to put much work in right now. If anyone out
there chooses to do so, please let me know.
