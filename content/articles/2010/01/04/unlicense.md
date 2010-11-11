--- 
kind: article
timestamp: 2010-01-04
title: "Why I’m Going Public"
---

I just made the decision to unlicense my Markdown-based wiki management software
[Markdoc][], and re-release it into the public domain. I’m about to start the
lengthy but valuable process of unlicensing [all of my software][], and I felt
it would be a good idea to explain my actions, and perhaps convince others to
follow suit.

  [markdoc]: http://markdoc.org/
  [all of my software]: http://bitbucket.org/zacharyvoase/

The trail that led me here began several years ago, when I wrote my first
complete program in Python. I licensed it under the GNU GPL, because as far as I
could tell that was *the* open-source software license (I just wasn’t aware of
any others). I read the full text of the GPL, and it seemed reasonable enough to
me. I did always have a nagging in the back of my head at the time, that the
‘viral’ nature of the license might be harmful in the long term, but I went with
it anyway. Nothing I had written at that stage was worthy of being redistributed
by anyone else, so I had little to worry about.

My encounter with Django convinced me to start using MIT/X11 as my license of
choice. It turns out a lot of other people shared my opinion on the GPL, and
that the choice of license really *did* have real-world consequences. Like Mac
OS X coming with a sucky readline library, or stupidly long installations
because a developer couldn’t include a required library with their software for
fear of being sued. As I saw it, GPL was a different kind of free software — it
was freedom **whether you like it or not**.

By this point I was just a step away from public domain. Not being a lawyer, I
had neither the incentive nor the ability to draft a comprehensive ‘unlicense’
that would declare my code as public domain. The MIT license was suiting me
fine, and I didn’t expect anyone to even want to redistribute my software. After all, this is the era of the dynamic language, and it’s relatively simple to just declare an external dependency and call it a day. But then came the revelation.


## Software Freedom

The word ‘free’ is bandied about a lot today. Sometimes it’s written as ‘Free’,
because with capitalization it is no longer a word, but a platonic ideal. The
FSF describes free software as “free as in speech, not as in beer” (although
it’s usually both). I, however, like to consider the *spirit* of freedom. And,
[unlike the FSF][fsd], I’m not going to waste over 12,000 bytes telling you what
it is.

  [fsd]: http://www.gnu.org/philosophy/free-sw.html


### The Spirit of Freedom

So I’ve written a piece of software.

*   I’m not making any promises about this piece of software.
*   You are free to do **whatever the fuck** you want *with* this piece of software.
*   You are free to do **whatever the fuck** you want *to* this piece of software.

And isn’t *that* what being free is all about? Not having to worry that you
might be breaking a rule? Even though I think the MIT license is relatively loose, it still forces requirements on the users:

    Permission is hereby granted ...snip... subject to the following
    conditions:
    
    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

OK, so it’s a small requirement, but even this turns out to be a big issue when
you’re dealing with mixing and redistributing multiple pieces of software with
various licenses.

The way public domain works is as follows:

*   You see my code.

*   You like my code.

*   You copy-and-paste my code into your application, and if you’re gracious
    enough, you send me a tweet or an e-mail to let me know. Perhaps you even
    acknowledge my contribution in an AUTHORS file somewhere.
    
    But you don’t have to.

Now that’s what I call freedom.


## The Unlicense

[The Unlicense][] has recently been published, and it’s provided the impetus I needed to start putting my software into the public domain (henceforth known as ‘pubdomming’). I can now `cp`-and-go as I could with the GPL and MIT licenses. The text of the license is short and sweet, and remains perfectly aligned with the spirit of freedom. So why don’t you unlicense *your* code?

  [the unlicense]: http://unlicense.org/
