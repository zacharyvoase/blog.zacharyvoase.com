---
created_at: 2013-03-24
kind: article
title: "Programming the Propeller with PropGCC"
---

It's clear that the future of programming is in multi- and pluri-core systems.
This is the story of how, over the last three days, I approached a brand new
hardware platform built for parallel microcomputing, and managed to put
together a toolchain that fit better with my 'UNIX hacker' mindset.
{: .summary}

The [Parallax Propeller][] is a nice little 32-bit 8-core microcontroller with
a completely custom (or, perhaps, 'proprietary') reduced instruction set
architecture. The cores are each identical, and each core (referred to as a
'cog') has 2K of its own memory, plus there's 32K of shared 'hub' memory
(access to which is granted in a round-robin time-sliced fashion to each core).
32 general purpose I/O pins are available for use by all cores, and the
[Quickstart][] board I picked up at Radio Shack had touch sensors rigged up on
pins 0-7 and blue LEDs on pins 16-23.

  [parallax propeller]: http://www.parallaxsemiconductor.com/products/propellerchips
  [quickstart]: http://www.parallaxsemiconductor.com/quickstart

The Propeller is the first low-power multi-core microcontroller and prototyping
platform I've found, but I reckon it's only a matter of time before there's a
comparable offering from the Arduino project. What I *really* want to see is a
microcontroller running a Cell processor, but that's another story!

A drawback of the Propeller platform is that the *entire* stack is proprietary,
from instruction set to high-level programming environment. Plus, the stock IDE
only works on Windows. This doesn't fly with me. Fortunately, the [PropGCC][]
project has written a Propeller backend for GCC, enabling first-class
applications to be written in pure C. Om nom nom.

  [propgcc]: https://code.google.com/p/propgcc/

<ins>Instructions follow for OS X 10.8. YMMV.</ins>

Installation is half the battle. First, head to [this page][ftdi-driver] to get
the FTDI driver for your Mac. No restart is needed, but you need the driver to
recognize and talk to the board from your computer. Next, install the PropGCC
build for OS X:

  [ftdi-driver]: http://www.ftdichip.com/Drivers/VCP.htm

    #!bash
    $ mkdir -p /tmp/prop
    $ cd /tmp/prop
    $ curl -sO 'https://propgcc.googlecode.com/files/propgcc-2013-03-16-mac.zip'
    $ openssl sha1 propgcc-2013-03-16-mac.zip
    SHA1(propgcc-2013-03-16-mac.zip)= 75e0d44f05793d7dafaccdf5f855c4c556c5d644
    $ unzip propgcc-2013-03-16-mac.zip
    ...

Fortunately those binaries unzip straight there, and the next step is to set up
a project workspace where you can write and compile code. One of the benefits
of working on such a restricted platform is that you don't have the overhead of
managing a whole source tree---you'll typically just have one or two original
source files, potentially a couple of libraries. For this reason I like to
write makefiles for compilation and deployment.

    #!bash
    $ mkdir -p /tmp/project
    $ cd /tmp/project
    $ vim Makefile

Here's a barebones makefile which uses make's implicit rules for producing
object files from source files:

    #!make
    PROPGCC=/tmp/prop
    CC=${PROPGCC}/bin/propeller-elf-gcc
    CFLAGS=-Os -mlmm -m32bit-doubles -fno-exceptions

By default, running `make foo` will execute `$CC $CFLAGS -o foo foo.c`.  Let's
put together a basic C file and test this out (btw, I use [Linux kernel
style][] for C code):

  [linux kernel style]: https://www.kernel.org/doc/Documentation/CodingStyle

    #!c
    /* main.c */
    #include <cog.h>
    #include <propeller.h>

    int main(void)
    {
            return 1;
    }

Now back in the shell:

    #!bash
    $ make main
    /tmp/prop/bin/propeller-elf-gcc -Os -mlmm -m32bit-doubles -fno-exceptions main.c -o main

No errors! Now that this bit is working, let's put together a fake target to
load it onto the device. I've beefed up the makefile a little in the process:

    #!make
    PROPGCC=/tmp/prop
    CC=${PROPGCC}/bin/propeller-elf-gcc
    LOAD=${PROPGCC}/bin/propeller-load
    CFLAGS=-Os -mlmm -m32bit-doubles -fno-exceptions
    BOARD=QUICKSTART
    PORT=/dev/cu.usbserial-AH00OHHX

    .PHONY: all clean load

    all: main

    clean:
            rm main *.o

    load: main
            ${LOAD} -b ${BOARD} -p ${PORT} -I ${PROPGCC}/propeller-load -r $<

Plug the device in, and we'll do a quick test:

    #!bash
    $ make load
    /tmp/prop/bin/propeller-load -b QUICKSTART -p /dev/cu.usbserial-AH00OHHX -I /tmp/prop/propeller-load -r main
    Propeller Version 1 on /dev/cu.usbserial-AH00OHHX
    Loading main to hub memory
    2172 bytes sent
    Verifying RAM ... OK

Still no errors! Well that's all very well and good, but the program doesn't do
anything. If, like me, you bought the quickstart board, you'll have access to
several touch sensors and LEDs. So let's write something which monitors the
state of the first touch sensor (pin 0), and turns on the first blue LED (pin
16) if it's being touched.

    #!c
    /* main.c */
    #include <cog.h>
    #include <propeller.h>

    int main(void)
    {
            /* Set direction of pin 16 to OUTPUT */
            DIRA |= 1 << 16;
            while (1) {
                    /* Provided by propeller.h */
                    setpin(16, getpin(0));
            }
    }

Install and run it:

    #!bash
    $ make load
    /tmp/prop/bin/propeller-load -b QUICKSTART -p /dev/cu.usbserial-AH00OHHX -I /tmp/prop/propeller-load -r main
    Propeller Version 1 on /dev/cu.usbserial-AH00OHHX
    Loading main to hub memory
    2240 bytes sent
    Verifying RAM ... OK

If you touch the rightmost touch sensor, you should see the corresponding blue
LED turning on and off, like this:

<iframe class="center" src="http://player.vimeo.com/video/62597032" width="640"
height="360" frameborder="0" webkitAllowFullScreen mozallowfullscreen
allowFullScreen></iframe>

That's great, but can we make it work for all 8 sensors and LEDs? Yes!

## Pthreads

Amazingly, you can use the [pthreads][] library with PropGCC to write code
which will execute in parallel on each of the cogs. Here's a basic prototype of
the standard `setpin(..., getpin(...))` loop for each of the 8 sensor/LED
pairs:

  [pthreads]: https://computing.llnl.gov/tutorials/pthreads/

    #!c
    #include <cog.h>
    #include <propeller.h>
    #include <pthread.h>

    /* The thread loop which reads/sets the pin values. */
    void *monitor(void *arg)
    {
            const int pin = *(int *)arg;
            while (1) {
                    setpin(pin + 16, getpin(pin));
            }
    }

    int main(void)
    {
            /* Set direction of pins 16:23 to OUTPUT */
            DIRA |= 0xff << 16;
            pthread_t threads[8];
            /*
             * We can't just pass &i in; the value of i changes for every loop
             * iteration, so all the threads would end up holding a reference
             * to the same number. An alternative is to malloc() or alloca()
             * and then memcpy() for every loop iteration, but that would be
             * slow and shit.
             */
            int i;
            int pins[] = {0, 1, 2, 3, 4, 5, 6, 7};
            for (i = 0; i < 8; i++) {
                    pthread_create(&threads[i], NULL, monitor, &pins[i]);
            }
            for (i = 0; i < 8; i++) {
                    pthread_join(threads[i], NULL);
            }
    }

Do the `make load` dance again. You should get something like this (excuse my
fat hands):

<iframe src="http://player.vimeo.com/video/62597406" width="640" height="360"
frameborder="0" webkitAllowFullScreen mozallowfullscreen
allowFullScreen></iframe>

## Conclusion

One can put together a basic but very functional compilation and loading
toolchain based on standard UNIX tools: GCC, make and a text editor. There's no
need for fancy IDEs or brand new high-level languages.

  [kernel-style]: https://www.kernel.org/doc/Documentation/CodingStyle

## Follow-up

There's so much more to explore with PropGCC and the Propeller. One of the
most nuanced and interesting aspects of the toolchain is the memory model
selection; we just wrote a program using LMM, whereby the main process resides
in the 32K of hub memory and tasks are dispatched to a small kernel running on
each cog. But you can also program in a cog-centric model, whereby your process
runs directly in the 2K of cog memory and the 32K of hub memory is used for
sharing and streaming data between the cogs.

There's also a large number of things you can do with I/O, especially when you
can have one cog working on serial output, for example, and another working on
gyroscope-based stabilization, or temperature sensing, or a host of other
things. I'm inclined to do a whole other blog post exploring some of those
things, but it's 2:30 AM and I'm tired. Good night!
