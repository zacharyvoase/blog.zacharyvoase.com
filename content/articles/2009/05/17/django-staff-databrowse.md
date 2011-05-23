--- 
kind: article
created_at: 2009-05-17
title: "Django Tip: Staff-only Access to Databrowse"
---

Databrowse has to be one of the most underappreciated Django apps. It’s been
included with Django since 1.0, and it’s really simple to use; just register
some models to a site, point to that site from your URLconf and you get a
fully-featured data browser for free. You can read the databrowse docs
[here](http://docs.djangoproject.com/en/dev/ref/contrib/databrowse/), but
there’s something they don’t mention which I think is really nifty.

Down at the bottom of that page, it recommends using the `login_required()`
decorator to restrict access to registered users, like so:

    from django.conf.urls.defaults import *
    from django.contrib import databrowse
    from django.contrib.auth.decorators import login_required
    
    urlpatterns = patterns('',
        (r'^databrowse/(.*)$', login_required(databrowse.site.root)),
        (r'^login/$', 'django.contrib.auth.views.login'),
    )

But if you want to restrict access to staff (i.e. users who can access the
admin), you’ll have to use another (undocumented) decorator instead.

    from django.conf.urls.defaults import *
    from django.contrib import databrowse
    from django.contrib.admin.views.decorators import staff_member_required
    
    urlpatterns = patterns('',
        (r'^databrowse/(.*)$', staff_member_required(databrowse.site.root)),
    )

Only users with the `is_staff` flag will be able to access databrowse now, and the login form presented is essentially that of the Django admin. Note that `django.contrib.admin` must be in your `INSTALLED_APPS` for this to work.
