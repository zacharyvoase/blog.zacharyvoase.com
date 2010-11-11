--- 
kind: article
timestamp: 2009-07-20
title: "Idea: Distributed HTTP Lock Server"
---

I’d like some input on this idea: a HTTP server which acts as a distributed lock
system, whereby:

    POST /lock/<lock_id>/acquire/

would acquire a lock, and

    POST /lock/<lock_id>/release/

would release it. If the lock doesn’t exist, it’s created. Locks could be
‘sharded’ across multiple processes or servers (although single locks would
reside on a single process or server), and an attempt to acquire a lock that is
in use would block (unless a timeout parameter is supplied).

The basic problem which this would try to solve is dealing with a resource
shared between multiple processes. By implementing it on top of HTTP, client
libraries and tools could be written in practically any language or for any
platform in existence.

Here’s an example of where you’d use it: you’re running a very AJAX-intensive
website. While the user might only have one browser window open, they’re still
making multiple concurrent AJAX requests back to your server. On the
server-side, you’re running multiple processes to handle these HTTP requests
(this might be a Mongrel cluster, or perhaps a bunch of WSGI-handling Python
processes). So as a request comes in, you don’t actually know which one of these
processes the request will be handled by. Now let’s also propose that your AJAX
views modify the request session in some way. So this is what happens if two
requests come in at nearly the same time, one very shortly after the other:

    Request 1               |
    ------------------------+
    POST /ajax/view1/       |
      loads session data    | Request 2
      begins processing     +-------------------------
        ...                 | POST /ajax/view2/
        ...                 |   loads session data
        ...                 |   begins processing
      changes session data  |     ...
      saves session data    |     ...
    200 OK (responds)       |   changes session data
                            |   saves session data
                            | 200 OK (responds)

By the end, only the changes `view2` made are actually present in the session,
since it made those changes to a stale copy of the session data and clobbered
all of `view1`’s changes. With locking, something else would happen:

    Request 1               |
    ------------------------+
    POST /ajax/view1/       |
      ACQUIRE SESSION_KEY   |
      loads session data    | Request 2
      begins processing     +---------------------------
        ...                 | POST /ajax/view2/
        ...                 |   ACQUIRE SESSION_KEY
        ...                 |     acquisition blocks
        ...                 |       ...
      changes session data  |       ...
      saves session data    |       ...
      RELEASE SESSION_KEY  ==>    acquisition succeeds
    200 OK (responds)       |   loads session data
                            |   begins processing
                            |     ...
                            |     ...
                            |   changes session data
                            |   saves session data
                            |   RELEASE SESSION_KEY
                            | 200 OK (responds)

In this case, by the time `view2` has loaded the session data, it has already
been updated by `view1`, and so it doesn’t clobber the old data. This follows on
to subsequent AJAX requests; other views attempting to change the session will
have to wait until `view2` has finished doing so.

That’s the general idea about locking. The system I’ve described, however, would
make such behavior possible across the multiple processes and even machines
which are so often used in web-serving environments. At the moment, most
languages support in-process locks and filesystem locks. These are difficult if
not impossible to distribute, since the first can only live within one process
and the latter can only live within one machine (and even still may not be very
cross-platform).

I’m sure there are a bunch more use-cases, but this was the most obvious one
which came to mind.

The basic questions I’d like answered by the community (not because I’m lazy,
but because I can’t speak for everyone) are:

*   Is this a good idea (i.e. worth spending the time/effort to implement)?

*   Are there already similar implementations available, preferably open-source?

*   Is there a feature you’d like to see implemented in such a system, whilst
    sticking to [D1T&DIW](http://en.wikipedia.org/wiki/Unix_philosophy)?

*   How might you go about implementing such a system?

*   Do you have good ideas for a name for such a system?
