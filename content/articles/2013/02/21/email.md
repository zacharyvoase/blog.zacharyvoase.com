---
created_at: 2013-02-21
kind: article
title: "Improving Email, Realistically"
---

Every day it seems there's more hype about a new startup that's setting out to
destrominate email as we know it. The thing is, email has been around longer
than even the Web, and I reckon that it'll still be around in its current form
for a long time to come. Rather than trying to revolutionize the way we
communicate, what are some small, incremental, backwards-compatible
improvements we can make to the protocol and the UX of email clients?

A real problem for me is dealing with a backlog of personal emails over brief
periods of time when I'm busy, traveling, in a different timezone or just plain
tired. So what I really need is not a new interface to my email, but rather
a way of *managing expectations* for people who send me emails. This
expectation management could have the effect of preventing someone from sending
the email in the first place, or perhaps reaching out to me through a different
medium (like telephone, Skype or IM).

One way of solving this problem would be to build a client which works in
exactly the same way as modern ones, but recognizes patterns in my behavior and
publishes a metric based on info like:

* my calendar;
* my current timezone;
* the average time I take to respond to other emails;
* the length of the email I need to respond to; etc.

When someone is drafting an email to me, they should be able to see an
*estimated time to response* live-updating as they write, based on information
published by my email client:

![](ettr.jpg)

The 'information' published would effectively have to be some kind of function
over the length of the e-mail, its sender, my calendar, plus some indication of
my present 'business' (including whether or not I'm likely to be asleep). So
the obvious strategy is to build an API that works at Layer 7 (either DNS
TXT/SRV records, or just HTTP [à la Gravatar][gravatar]) where you can post a
bunch of information in a JSON object and receive a best-guess estimate of the
time I would take to respond.

  [gravatar]: http://en.gravatar.com/site/implement/

Such a system has several benefits:

* It's 100% non-intrusive. You don't need to change your current email client,
  or join a waiting list behind 56,000 other people to use it.
* It's decentralized: you can point to your 'response expectation management
  provider' from your DNS records, enabling a competitive market of such
  providers; some might be free and advert/VC-supported, others would be
  'profitable and proud', others still would be open-source.
* It can be private, if you want it to be: just run your own server. Obviously
  there'd be a benefit to using Google's provider—they're really good at
  predicting this sort of stuff, and it'd integrate seamlessly with Google
  Apps.

I just had this idea while drinking my espresso this morning, but you can
discuss it further on [Hacker News](https://news.ycombinator.com/item?id=5259032).
