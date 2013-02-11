---
created_at: 2013-02-10
kind: article
title: "The Web Is Becoming SmallTalk"
---

The concept of a 'web page' is quickly becoming meaningless. I believe there's
a new way to look at the Web and the browser, and synthesizing it with old
technologies could result in a novel technique for Web development and content
editing.
{: .summary}

Just today I found out that [the Chrome JS editor can 'hot-swap' your
code][chrome-js]. It got me thinking of other systems I know of that allow you
to edit code on-the-fly, breaking out of the tedious write/compile/test/run
cycle.

  [chrome-js]: http://smotko.si/using-chrome-as-a-javascript-editor/

SmallTalk is an uncommon language these days, with the exception of its
half-descendant, Objective-C. But whilst message passing, dynamic typing and
object orientation are nice things, Objective-C missed the big, game-changing
aspect of SmallTalk: image-based persistence, and the modeless editing
environment which worked with it.

Traditionally, applications get loaded into memory, and the operating system
kicks off execution of the program starting with a well-known location (i.e.
the start of the `main()` function). At this point you have to instantiate and
initialize whatever objects you have manually, whether that's by accepting user
input or reading data from the network or disk, *et cetera*. Your program gets
into a fuzzy state between 'startup' and 'ready'.

SmallTalk applications don't do that. Instead, you start with an image, load
that directly into memory, and that already contains all the class definitions
and object instances you need. The clever part is that to *change* a program
you open this same image file in the VM and point-and-click through the
definitions of various methods. When you've made the changes you need to, or
perhaps just tweaked the appropriate objects, you save the image file back to
disk, and it's ready to run again. If you want to start an application from
scratch, you clone a blank image and fill it up with classes, methods and
objects.

Since this editing environment was typically part of the SmallTalk VM that ran
the image, you wouldn't even need to cycle between editing and running your
application: just open up the editor in the VM and live-edit the objects.

* * * * *

What does this mean for the Web? Well, the way I (and [Roy Fielding][rest]) see
it, the browser is a stateful agent that just renders HTML to a viewport, and
executes JavaScript. When you first load up your browser, it's a blank VM.
You direct it to a URL, and HTML, CSS and JavaScript are fetched, which
instruct the browser to render some kind of interface to the viewport. This
interface is linked to the JS interpreter and the server through DOM events,
with the most prominent and noticeable one being the default action of clicking
an `<a>` element.

  [rest]: https://www.ics.uci.edu/~fielding/pubs/dissertation/rest_arch_style.htm

Those of us who first grokked the internet before the advent of JS-heavy web
'apps' still have this concept of navigating through pages. Now that
conventions are moving towards 'single-page' web apps, the concept of a 'page'
is losing its special meaning. In New World terms, a page is an artifact of a
navigation event which completely trashes all but a small part of the VM (i.e.
the cookie jar), replacing it with a new object tree and code definitions. Make
sense?

In a way, browsers have been capable of running web apps since the advent of
`XMLHttpRequest`. The only difference is that today, the mean time between
complete obliterations of that VM state is much longer.

So if we're moving into a world of treating the browser as a VM, the manager of
a long-lived application state, we need the other parts of the SmallTalk model:
live-editing and persistence. The Chrome Web Inspector is great for modifying
CSS rules on-the-fly (it's a declarative language, DOM redraws are cheap on a
human timescale, go figure). Editing JS is trickier due to its functional,
callback-based nature; the average JS object tree is much more nested than that
of the average SmallTalk VM. But Chrome is again showing that it is possible.
So the final piece of the puzzle is persistence: this bundle of HTML,
JavaScript and CSS needs to be written *back* to the server.

I have a hunch that WebDAV combined with standard HTTP authentication could be
the answer. I'm not 100% sure on it, but I can easily envision a world where
you fix bugs in your website by opening it up in a browser, reading a stack
trace, fixing the JS in that same browser and persisting your changes
back to the server.

I dream of the days when the Web truly does resemble SmallTalk.

* * * * *

Voice your disagreement on [Hacker News](https://news.ycombinator.com/item?id=5198425).
