---
created_at: 2013-03-02
kind: article
title: "Compilers Are Way Smarter Than I Thought"
---

An attempt to optimize what I intuited as inefficient C code led me to discover
that my compiler had already done the hard work for me.
{: .summary}

At Heroku's [Waza conference](https://waza.heroku.com/2013/) on Thursday I went
to the Arduino booth and started playing around with some LEDs and buzzers.
Long story short, I wrote a [small sketch][morse-coder] to accept input over
the UART serial port and 'speak' it in Morse code over an output pin. I hooked
the pin up to either an LED or a buzzer (in series with a resistor) and, sure
enough, it worked.

  [morse-coder]: https://gist.github.com/zacharyvoase/5060886

However, one thing that I wasn't satisfied with was how I implemented the Morse
code itself in C. It looks like this:

    #!c
    switch (c) {
      case 'A':
      case 'a':
        writeMorse(".- "); break;
      case 'B':
      case 'b':
        writeMorse("-... "); break;
      case 'C':
      case 'c':
        writeMorse("-.-. "); break;
      # ...
      case '8':
        writeMorse("---.. "); break;
      case '9':
        writeMorse("----. "); break;
      case '0':
        writeMorse("----- "); break;
      default:
        break;
    }

As a coder who typically works in dynamic languages, I look at a large `switch`
statement like that and think "oh, that's going to take a while for the number
'0', because it'll check every other character first before finally arriving at
the last block". So I started looking at the object code produced from the
sketch.

* * * * *

### Aside: Disassembling Arduino Sketches

It's not hard to open up the assembly code produced from your Arduino sketch.
When you hit 'Verify' in the IDE, you'll see a bunch of output from the
compiler, but two of the last lines will look something like:

    /path/to/tmp/folder/sketch_name.cpp.elf
    /path/to/tmp/folder/sketch_name.cpp.hex

You're interested in the first of those files, the [ELF][] binary. Just copy
the path to that file and open it with `objdump` (which should be included
somewhere in your copy of the Arduino IDE). To find the `objdump` binary on OS
X:

  [elf]: https://en.wikipedia.org/wiki/Executable_and_Linkable_Format

    #!bash
    $ find /Applications/Arduino.app -name 'avr-objdump'
    /Applications/Arduino.app/Contents/Resources/Java/hardware/tools/avr/bin/avr-objdump

For convenience:

    #!bash
    $ alias avr-objdump=/Applications/Arduino.app/Contents/Resources/Java/hardware/tools/avr/bin/avr-objdump

Finally, dump the file itself:

    #!bash
    $ avr-objdump -Slr /path/to/tmp/folder/sketch_name.cpp.elf | pygmentize -l cpp-objdump | less -R

You don't have to tack on the `pygmentize` bit at the end, but I find syntax
highlighting can make a lot of difference when reading code.

* * * * *

<ins>
**N.B.:** In order to understand most of the object code which follows, without
blindly trusting my analysis, you might want to read a copy of the [Atmel AVR
Datasheet](http://www.atmel.com/Images/doc8161.pdf) (PDF link). The particular
chipset I'm talking about here is the ATmega328P, which powers the Arduino UNO.
</ins>

I went looking through the object code for the particular function in which the
Morse code is implemented, `serialEvent()`, and found it under a C++-mangled
label:

    #!cpp-objdump
    0000025e <_Z11serialEventv>:

What you're about to see is kind of hardcore, so I'm going to walk through the
disassembly piece by piece. First, we just call `Serial.read()` to get the
character (storing it in register `r24`):

    #!cpp-objdump
    25e:        81 e7           ldi     r24, 0x71       ; 113
    260:        92 e0           ldi     r25, 0x02       ; 2
    262:        0e 94 86 04     call    0x90c   ; 0x90c <_ZN14HardwareSerial4readEv>

Now we're into the `switch` statement. It would seem most of the character
operations are done on pairs of 8-bit registers. Here, we zero out `r25`, but
then take its complement if the most significant bit of `r24` is set. I reckon
this is to handle the case that `Serial.read()` returns `-1` (indicating that
the read failed).

    #!cpp-objdump
    266:        99 27           eor     r25, r25
    268:        87 fd           sbrc    r24, 7
    26a:        90 95           com     r25

`r25` is copied into `r26` and `r27`, for reasons I can't quite fathom at this
point (those registers are never used again inside this function).

    #!cpp-objdump
    26c:        a9 2f           mov     r26, r25
    26e:        b9 2f           mov     r27, r25

`movw` will copy the pair of registers `r25:r24` (representing a 16-bit
integer) into `r31:r30` (which can be addressed as the single 16-bit register
`Z`).

    #!cpp-objdump
    270:        fc 01           movw    r30, r24

Then, we do a quick check to see if `r30` is in the range `[32, 123)`.  Why?
Because in the ASCII code table, the space character is number 32 and
lowercase-'z' is 122; all the characters in this Morse code lie between those
values. So the compiler has effectively added a range check to the value based
on looking at the ASCII constants in this large `switch` statement. Cool.

    #!cpp-objdump
    272:        b0 97           sbiw    r30, 0x20       ; 32
    274:        eb 35           cpi     r30, 0x5B       ; 91
    276:        f1 05           cpc     r31, r1
    278:        08 f0           brcs    .+2             ; 0x27c <_Z11serialEventv+0x1e>
    27a:        7a c0           rjmp    .+244           ; 0x370 <_Z11serialEventv+0x112>

The next bit of code seems almost 'magical' (at least, quite opaque).

    #!cpp-objdump
    27c:        ec 5c           subi    r30, 0xCC       ; 204
    27e:        ff 4f           sbci    r31, 0xFF       ; 255
    280:        ee 0f           add     r30, r30
    282:        ff 1f           adc     r31, r31
    284:        05 90           lpm     r0, Z+
    286:        f4 91           lpm     r31, Z+
    288:        e0 2d           mov     r30, r0
    28a:        09 94           ijmp

Values get subtracted from the `Z` register, and parts of it get doubled and
incremented, and some weird stuff happens which I don't fully understand.
Finally, we call `ijmp`, which jumps to whatever `Z` is pointing to (remember
that `Z` is just a 16-bit alias for `r31:r30`).  This might seem weird, but
when you see what comes next it'll make sense:

    #!cpp-objdump
    28c:        80 e0           ldi     r24, 0x00       ; 0
    28e:        91 e0           ldi     r25, 0x01       ; 1
    290:        68 c0           rjmp    .+208           ; 0x362 <_Z11serialEventv+0x104>
    292:        84 e0           ldi     r24, 0x04       ; 4
    294:        91 e0           ldi     r25, 0x01       ; 1
    296:        65 c0           rjmp    .+202           ; 0x362 <_Z11serialEventv+0x104>
    298:        8a e0           ldi     r24, 0x0A       ; 10
    29a:        91 e0           ldi     r25, 0x01       ; 1
    29c:        62 c0           rjmp    .+196           ; 0x362 <_Z11serialEventv+0x104>
    ...
    356:        05 c0           rjmp    .+10            ; 0x362 <_Z11serialEventv+0x104>
    358:        89 eb           ldi     r24, 0xB9       ; 185
    35a:        91 e0           ldi     r25, 0x01       ; 1
    35c:        02 c0           rjmp    .+4             ; 0x362 <_Z11serialEventv+0x104>
    35e:        80 ec           ldi     r24, 0xC0       ; 192
    360:        91 e0           ldi     r25, 0x01       ; 1
    362:        0e 94 e8 00     call    0x1d0   ; 0x1d0 <_Z10writeMorsePc>
    366:        08 95           ret
    368:        87 ec           ldi     r24, 0xC7       ; 199
    36a:        91 e0           ldi     r25, 0x01       ; 1
    36c:        0e 94 e8 00     call    0x1d0   ; 0x1d0 <_Z10writeMorsePc>
    370:        08 95           ret

For every single character of the Morse code, the compiler has created a little
chunk of code which sets up a memory location in `r25:r24` and then jumps
straight to the call to `writeMorse()`. Those memory locations are just the
locations of the Morse code string literals in the object file.

## What This Means

The compiler has taken a large `switch` statement (which one might expect to
take `O(len(code))` in the worst case) and condensed it into a *constant-time*
arithmetic operation and indirect jump. I thought I'd have to put in some
serious effort to optimize the implementation of the Morse code table, only to
discover that `gcc` had done it for me.

Happy Happy Joy Joy.
