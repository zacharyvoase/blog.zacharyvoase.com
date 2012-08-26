---
kind: article
created_at: 2009-07-23
title: "Django ORM: Neat (undocumented) trick"
---

<ins>
  <strong>UPDATE:</strong>
  I’m actually working on a
  <a href="http://code.djangoproject.com/ticket/11527">ticket and patch</a>
  so that this feature is both documented and regression-tested for future
  releases of Django (starting with 1.1).
</ins>

<ins>
  <strong>UPDATE 2:</strong>
  My patch was accepted and
  <a href="http://code.djangoproject.com/changeset/11322">included</a> as part
  of Django 1.1.
</ins>

I just found out something pretty damn cool about Django’s ORM which, as it
happens, is completely undocumented (as far as I can tell). Let’s assume your
model definition is something like:

    #!python
    from django.db import models

    class MyModel(models.Model):

        count = models.IntegerField(default=0)

The following is completely valid, and actually eliminates a lot of the race
conditions that have plagued the Django ORM in the past:

    #!pycon
    >>> from django.db.models import F
    >>> from myapp.models import MyModel
    >>> obj = MyModel(count=4)
    >>> obj.save()
    >>> obj.count
    4
    >>> obj.count = F('count') + 3
    >>> obj.save()
    >>> obj = MyModel.objects.get(pk=obj.pk) # We need to reload the object.
    >>> obj.count
    7

Typically you’d do something like `obj.count += 3`, but that sets the attribute
to an absolute value, which can be the cause of many a race condition wherein
two threads/processes are editing the same record at a time; the `obj.save()`
would cause one thread to clobber another’s changes. Using `F()`, the SQL
expression instead looks like:

    #!sql
    UPDATE "myapp_mymodel" SET "count" = "myapp_mymodel"."count" + 3 WHERE "myapp_mymodel"."id" = 1;

Here, the ACIDity of the RDBMS ensures that parallel attempts to increment the
count occur without issue.

This behaviour’s undocumented status means it could break at any minute, and
reloading the object is necessary because otherwise `obj.count` ends up being an
instance of `django.db.models.expressions.ExpressionNode`, even after the object
is saved.
