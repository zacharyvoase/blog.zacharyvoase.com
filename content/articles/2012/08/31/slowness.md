---
created_at: 2012-08-31
kind: article
title: "Slowness is a Side Effect"
---

Functional programmers use the term ‘side effect’ to refer to the impact a
function has on the world around it. Side effects are implicit—they are not
represented in the input arguments or output types of the function. It’s
considered good functional style to write programs without side effects, or at
least with a minimal and predictable number. In imperative programming, we
still try to keep side effects restricted to recognizable places: Ruby uses a
`!` suffix on ‘dangerous’ methods, Python’s core string and number types are
immutable, and the popularity of jQuery even demonstrates the appreciation for
fluent and functional interfaces in the JavaScript community.

However, it’s easy to fall into the trap of believing that the footprint of a
function begins and ends with its prototype. The question of whether a function
has side effects a simple one: **is the world you are in when the function
terminates equal to the one you were in when it started?** At the level of
fast, atomic operations, like `1 + 1`, this is obviously true. But as a
function gets slower, no matter whether it acts on its environment or not,
**the world you are in when it terminates will have changed significantly since
it started.**

What does this mean to those of us who don’t care so much about functional
purity? Well, consider the case of defining a capital-I *Interface*, and the
concomitant claim that you can swap out the implementation without changing any
properties of the system. This is often used as an argument for incurring
technical debt, with the promise that the details of an API, database or
service can be ‘abstracted away’.

The fallacy—or false hope—in this argument is exposed when one considers that
there’s more to an interface than its component function signatures. The
performance and implementation details of various methods have a direct impact
on the experience of their use, and this will, in turn, shape the software
written against them. When you design an interface, it designs back.

My sole recommendation—and it’s not a panacea—is to take a holistic approach to
implementation and interface. Recognize that performance characteristics *do*
have an effect on how you code. [Write opinionated software][opinionated],
because portable, generic software is usually slow, buggy software. Finally,
take pride in designing robust interfaces and schemas that stand the test of
time.

  [opinionated]: http://gettingreal.37signals.com/ch04_Make_Opinionated_Software.php
