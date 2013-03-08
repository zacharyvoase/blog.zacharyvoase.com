---
created_at: 2013-03-06
kind: article
title: "QR Codify: The Most Useful Snippet I've Ever Written"
---

**tl;dr**: I wrote a Mac OS X Service which allows you to display the
currently-selected text as an on-screen QR code. Download it
[here](/qr-codify.workflow.tar.bz2).
{: .summary}

It really annoys me when there's some text on my computer that I need to be
available immediately on my Android phone. Especially when that text is a phone
number or a URL. Fortunately, OS X now has
[Services](https://en.wikipedia.org/wiki/Services_menu#Mac_OS_X), which are
scriptable actions that can be performed on GUI elements by right-clicking.

I opened up Automator and created the following:

![The QR Codify service in Automator](automator.png)

<ins>
Here's a [Gist](https://gist.github.com/zacharyvoase/5102470) for those who
want the raw source code.
</ins>

The service simply reads the selected text from stdin, generates a [Google
Image Chart][] URL for a QR code with that text, downloads it to a temporary
local file and displays it via QuickLook (using the `qlmanage` CLI). It looks
something like this:

  [google image chart]: https://developers.google.com/chart/image/docs/making_charts?hl=en

![Demo 1](demo-1.png)

![Demo 2](demo-2.png)

When I'm done with it, I hit the space bar and it goes away.

If this is something that'd be useful to you, you can grab it
[here](/qr-codify.workflow.tar.bz2).
