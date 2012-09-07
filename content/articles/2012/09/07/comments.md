---
created_at: 2012-09-07
kind: article
title: "The Problem With Comments"
---

As much as we appreciate well-written comments, most of us would admit to
finding it difficult to keep comments up-to-date. Why is this? Surely, when
you're editing code, the comments are *right there* and easy to update along
with the code? Yet still we forget, overlooking a comment when changing the
fundamental behavior of semantics of the code to which it relates.

My argument is that this is actually a UX failure on the part of our text
editors; to see why, here's a real-world example of a contextual message which
doesn't change the substance of the object to which it relates:

![Post-it notes sit brightly on a dull background.](postit.png)

The Post-it note is more than just an optional message—it's an admonition, a
sign to whoever is using the object that there is some critical piece of
information that should be considered before proceeding. In fact, it's
deliberately colored in such a way as to *clash* with almost any background
you'd put it against.

Compare this with how comments are typically displayed:

![Comments in code are usually displayed in a grey typeface.](comments.png)

The comment, as a syntactic structure, is supposed to be a piece of
human-readable information which is ignored by the compiler. But why, then, do
our editors display comments in such a way as to be *ignored by the
programmer?* Imagine if comments were displayed like
this instead:

![Brighter comments](bright_comments.png)

I think there would be a lot fewer meaningless, out-of-date and unhelpful
comments.
