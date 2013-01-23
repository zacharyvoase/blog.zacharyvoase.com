---
created_at: 2013-01-22
kind: article
title: "Object-based Views in Django"
---

I'm not a fan of [class-based views][cbv], much for the same reason I prefer C
over C++—why use classes when simple functions and data structures will
suffice? I think it stems from misinterpretation of [DRY][]; it's a way of
reducing complexity, but it's often interpreted as a call to effectively gzip
your code, and taken to the extreme you get highly nested structures, amounting
to a [Huffman code][] of your business logic.

  [cbv]: https://docs.djangoproject.com/en/dev/topics/class-based-views/
  [dry]: http://www.artima.com/intv/dry.html
  [huffman code]: https://en.wikipedia.org/wiki/Huffman_coding

Additionally, I'm worried that many Python developers view class syntax as a
way of producing DSLs instead of creating actual type hierarchies. In my
experience, such clever programming leads to a much higher difficulty debugging
errors, with only marginal improvements (or often drops) in code legibility. So
here's a classless (hehe) alternative to solving the code reuse and
authoritative definition problems.

The Django docs include a section on [generic form handling][cbv-forms], so
let's start with that (because it's a pretty common use case).

  [cbv-forms]: https://docs.djangoproject.com/en/dev/topics/class-based-views/generic-editing/

Here's what I want the basic API to look like:

    #!python
    # myapp/views.py
    from objviews import ModelResource

    from myapp.models import Contact  # Assume this exists.

    contact = ModelResource(name='contact', model=Contact)

From your URLconf:

    #!python
    from django.conf.urls import patterns, include
    from myapp.views import contact

    urlpatterns = patterns('myapp.views',
      (r'^contacts/', include(contact.urls)),
      # Effectively produces these rules (URL => name):
      # contacts/ => contact_list
      # contacts/add/ => contact_add
      # contacts/\d+/ => contact_detail
      # contacts/\d+/edit/ => contact_edit
      # contacts/\d+/delete/ => contact_delete
    )

Here's a more sophisticated example, featuring a different URL identifier (slug
instead of numeric):

    #!python
    from objviews import ids  # Effectively an enum of URL-suitable regexes.

    # Here you'd only get the /contacts/, /contacts/add/ and /contacts/<slug>/
    # URL patterns being generated.
    contact = ModelResource(name='contact', model=Contact, id=ids.SLUG,
                            actions=('list', 'add', 'detail'))

Note that you configure the 'resource' object through keyword parameters, not
subclassing and extending. This limits the possibilities for extension, but
thereby keeps things constrained and more easily debuggerable. You might be
personally super-familiar with Python's multiple inheritance mechanism, but I
bet not every developer on your team is—and it still adds a layer of
complication when stuff breaks (think: mixins). When you do need extension and
polymorphic behavior, object-based views can create sub-objects and delegate to
them—favouring [composition over inheritance][coi].

  [coi]: https://en.wikipedia.org/wiki/Composition_over_inheritance

You can also build a number of standard URLs from a single definition by using
``include()`` and having a ``urls`` property on the object. If you wanted the
same thing for a class-based view, you'd have to implement 'class properties'
(that is, descriptors on the metaclass—it sounds complicated because it is), or
otherwise call a classmethod to generate the ``patterns`` object. And with
objects, because you can directly call them or their methods, you get to skip
all of the ``as_view()`` malarkey, too.

I'm aiming to provide a working prototype of an object-based view, but for now
I want to just put the idea and potential API out there.
