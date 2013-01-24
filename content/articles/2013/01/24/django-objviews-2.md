---
created_at: 2013-01-24
kind: article
title: "More Object-based Views"
---

Another riff on the theme of [object-based views](/2013/01/22/django-objviews/)
is that of view combinators. This might seem weird, but bear with me:

    #!python
    # views.py
    comments = ModelResource(name='comments', model=Comment)
    videos = ModelResource(name='videos', model=Video)
    video_comments = videos.sub_resource(comments)

    # urls.py
    urlpatterns = patterns('',
        (r'^videos/', include(videos.urls + video_comments.urls)),
    )

The `sub_resource()` method on `ModelResource` takes both resources and creates
a URL and object hierarchy. It would be capable of inspecting the models and
discovering the relationship (whether that was a foreign key, generic FK or
M2M), then generating sub-URLs like `/videos/123/comments/456/`.

Just a thought.
