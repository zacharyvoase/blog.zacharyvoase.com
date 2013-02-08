---
created_at: 2013-02-08
kind: article
title: "In Defense of Copy & Paste"
---

Adherence to DRY ("[Don't Repeat Yourself][dry]") does not necessarily preclude
repetition of code. In the endless struggle to refactor, the [entropy we are
trying to reduce][entred] is not in the raw text of our source code; it is in
our business logic, which (in applications with little or poor testing) is
often uncodified. Sometimes, refactoring can hamstring our code, and when done
naïvely it can be a source of technical debt, rather than an antidote thereto.
{: .summary}

  [dry]: http://www.artima.com/intv/dry3.html
  [entred]: http://c2.com/cgi/wiki?EntropyReduction

Many programmers would agree with the following statement:

> [I]f you use copy and paste while you’re coding, you’re probably committing a
> design error. Instead of copying code, move it into its own routine. Future
> modifications will be easier because you will need to modify the code in only
> one location. The code will be more reliable because you will have only one
> place in which to be sure that the code is correct.
>
> — <http://www.stevemcconnell.com/ieeesoftware/bp16.htm>

I subscribed to this philosophy for the first few years of my real-life
programming career. But recently I've questioned it, driven by experience
working with clients whose requirements change (that is, all of them).


## Identity

There are often situations where a code path is required to be the same as
another for an explicit reason. Take the Twitter API documentation, for example:

> In version 1.1, we're requiring applications to authenticate all of their
> requests with OAuth 1.0a. — [Overview: v1.1 of the Twitter API](https://dev.twitter.com/docs/api/1.1/overview#Authentication_required_on_all_endpoints)

The whole OAuth protocol setup, and addition of necessary tokens to each
request, would no doubt benefit from being written once and only once. Bugs and
security issues that arise will only need to be fixed in one place, and OAuth
is mandated by the specification for *all* calls to the API. If you were to
look at the call trace of a process requesting tweets for a given user, and
that of one searching for a hashtag, the OAuth-related logic in common between
the two would be **identical** in the [philosophical sense][identity].

  [identity]: https://en.wikipedia.org/wiki/Identity_(philosophy)


## When Refactoring Goes Bad

But just because two processes have to do the same thing, it doesn't mean the
*business cases* represented by those code paths are necessarily identical.
Let's say we're building a very basic Twitter clone, with both a global feed
displaying all tweets on the site, and individual user timeline pages showing
just tweets from that user. Well, we might start out like this:

    #!python
    # urls:
    urlpatterns = patterns('twitclone.views',
        url(r'^$', 'global_feed'),
        url(r'^(?P<username>\w+)/$', 'user_timeline'),
    )

    # twitclone.views:
    def global_feed(request):
        tweets = Tweet.objects.all()
        return render(request, 'global_feed.html', {'tweets': tweets})

    def user_timeline(request, username):
        tweets = Tweet.objects.filter(user__username=username)
        return render(request, 'user_timeline.html', {'tweets': tweets})

This is reasonable enough. The overzealous refactorer would look at code like
this and say: "Configuration over code—I can see similarities between two
different functions!" and replace it with this:

    #!python
    # urls:
    urlpatterns = patterns('twitclone.views',
        url(r'^$', 'tweet_list', kwargs={'template': 'global_feed.html'}),
        url(r'^(?P<user__username>\w+)/$', 'tweet_list', kwargs={'template': 'user_timeline.html'}),
    )

    # twitclone.views:
    def tweet_list(request, **kwargs):
        template = kwargs.pop('template')
        tweets = Tweet.objects.filter(**kwargs)
        return render(request, template, {'tweets': tweets})

Said developer congratulates itself with a pat on the back for a job well done.

Then a product owner says that a profanity filter needs to be added to the
global feed, but not the individual user feed. The freshly-refactored code now
gets a configurable profanity filter switch:

    #!python
    # urls:
    urlpatterns = patterns('twitclone.views',
        url(r'^$', 'tweet_list',
            kwargs={'template': 'global_feed.html', 'filter_profanity': True}),
        url(r'^(?P<user__username>\w+)/$', 'tweet_list',
            kwargs={'template': 'user_timeline.html', 'filter_profanity': False}),
    )

    # twitclone.views:
    import itertools

    def tweet_list(request, **kwargs):
        template = kwargs.pop('template')
        filter_profanity = kwargs.pop('filter_profanity')
        tweets = Tweet.objects.filter(**kwargs)
        if filter_profanity:
            tweets = itertools.ifilter(lambda t: not t.is_profane(), tweets)
        return render(request, template, {'tweets': tweets})

Because the profanity filter is implemented in Python, we have to sacrifice the
QuerySet API for the `tweets` object, and hope that the `global_feed.html`
template doesn't rely on any QuerySet methods. But we maintain a single function,
with the options configurable through the URLconf, so we're still 'DRY', right?

Now a requirement is introduced that the user timeline (but not the global
feed) needs to be paginated.  Again, our solution grows more legs:

    #!python
    # urls:
    urlpatterns = patterns('twitclone.views',
        url(r'^$', 'tweet_list',
            kwargs={'template': 'global_feed.html', 'filter_profanity': True}),
        url(r'^(?P<user__username>\w+)/$', 'tweet_list',
            kwargs={'template': 'user_timeline.html',
                    'filter_profanity': False,
                    'tweets_per_page': 20}),
    )

    # twitclone.views
    import itertools

    def tweet_list(request, **kwargs):
        template = kwargs.pop('template')
        filter_profanity = kwargs.pop('filter_profanity')
        tweets_per_page = kwargs.pop('tweets_per_page', None)
        if tweets_per_page is not None:
            page = request.GET.get('page', 1)
            offset = (page - 1) * tweets_per_page
            tweets = Tweet.objects.filter(**kwargs)[offset:offset + tweets_per_page]
        else:
            tweets = Tweet.objects.filter(**kwargs)
        if filter_profanity:
            tweets = itertools.ifilter(lambda t: not t.is_profane(), tweets)
        return render(request, template, {'tweets': tweets})

I find this code to be unnecessarily confusing, and I believe most other
developers would agree. I strongly dislike putting configuration of any sort in
the URLconf unless it directly impacts the URLs, and we now have a single
generic function in the place of two specific ones, which has the potential to
grow combinatorially in the future as more options are added.

Furthermore, the business spec talks about a global feed, which is
profanity-filtered but not paginated, and a user timeline, which is paginated
but not profanity-filtered. Our generic code implements both cases, so it would
seem it meets the spec, but it *also* implements two cases which aren't called
for by the specification. When another developer (or even the same one, in six
months' time) reviews this code, it will be unclear whether the cases of
'filtered and paginated' and 'neither filtered nor paginated' are intended but
untested, or unintended cases which nevertheless must now be supported for
the sake of backwards-compatibility. The code has been parametrized to the
point where you can no longer determine if anything else relies on it behaving
a certain way.

This may come across as a straw man argument, but I've worked in many a
situation isomorphic to this—most frequently when I've been called in to deal
with a mess after the old developers abandoned ship.


## Equality

The reason two specific functions were replaced with an unnecessarily-complex
generic one was because our developer mistook **equal** code for **identical**
code.  Code paths which happened to be *accidentally* the same were viewed as
being *essentially* the same, and thus a [Huffman coding][huff] was applied to
the source without attention to the business specification—which, remember, may
not even exist in codified form. As a result, when the product owner asked for
what should have been an isolated change to an uncoupled part of the
information architecture, technical debt was created.

  [huff]: https://en.wikipedia.org/wiki/Huffman_coding


## A Better Solution

<ins>
Added after <a href="https://news.ycombinator.com/user?id=danso">@danso</a> on
Hacker News asked for an example of how the non-refactored way would be better.
</ins>

Keeping the two functions separate:

    #!python
    # urls: (still the same)
    urlpatterns = patterns('twitclone.views',
        url(r'^$', 'global_feed'),
        url(r'^(?P<username>\w+)/$', 'user_timeline'),
    )

    # twitclone.views:
    def global_feed(request):
        tweets = Tweet.exclude_profane()
        return render(request, 'global_feed.html', {'tweets': tweets})

    def user_timeline(request, username):
        tweets = Tweet.objects.filter(user__username=username)
        # You could put the `per_page` argument in your Django settings as
        # `USER_TIMELINE_TWEETS_PER_PAGE`, if you're that way inclined.
        tweets = paginate(tweets, 20, request.GET.get('page', 1))
        return render(request, 'user_timeline.html', {'tweets': tweets})

    def paginate(qset, per_page, page_num=1):
        return qset[(page_num - 1) * per_page:page_num * per_page]

    # twitclone.models:
    class Tweet(models.Model):
        ...
        # Better implemented as a method on the QuerySet, but this'll do.
        # See: https://github.com/zacharyvoase/django-qmethod
        @classmethod
        def exclude_profane(model):
            for tweet in model.objects.iterator():
                if not tweet.is_profane():
                    yield tweet

Obviously there's more going on here than in my straw man example. But the
views are simple, and far more easy to debug, because rather than dealing with
an implicit, dynamic configuration object (in the form of the `kwargs`
dictionary), there's a single, simple path through the code.

In terms of testing, you would ideally unit test both the `paginate` function
and the `exclude_profane` classmethod, *and* do high-level behavioral testing
on the `global_feed` and `user_timeline` views to ensure they met their
contract, and there would be no ambiguity due to the combinatorial
possibilities introduced by the configuration object.


## When Tools Make It Worse

I want to draw attention to a very simple case of where this affected an
application I worked on, because it was enabled and encouraged by Django: you
can specify an `ordering` property on a model class, and all queries for that
model will have the ordering implicitly applied to them. So let's say you're
reading through your code one day, and you notice the following everywhere:

    #!python
    def view(request):
        tweets = Tweet.objects.filter(...).order_by('-created_at')

The principle of Not Repeating Yourself kicks in, and you work on 'cleaning up'
your code by removing all those pesky `order_by()` calls, replacing them with
this:

    #!python
    class Tweet(models.Model):
        ...
        class Meta:
            ordering = ['-created_at']

Over the next six months, your Twitter clone becomes a big hit, and you're
storing tens of millions of tweets. However, many of your queries are slow, and
Postgres query stats indicate that applying ordering to every single tweet
query is slowing your site down. So you want to remove that `ordering`
property—but you can't, because you've now lost track of which methods
necessarily *rely* on tweets being ordered, which ones don't care, and which
ones implicitly need the ordering to work, but you can't detect breakages
because the ordering is added by default. No application's tests are perfectly
comprehensive (except perhaps [SQLite][]), so you can't be certain you won't
break everything by removing the property.

  [sqlite]: https://www.sqlite.org/testing.html

This is how Django's `ordering` property invites us to shoot ourselves in the
foot.


## The Lesson

I'd like coders to recognize the relationship between the business
specification, information architecture and source code, and use that to inform
smart refactoring decisions, rather than basic gzipping of code.

You can discuss this article on [Hacker News](https://news.ycombinator.com/item?id=5189141).
