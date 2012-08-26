---
kind: article
created_at: 2009-09-11
title: "Easy Path Manipulation in Python"
---

One of the things that really gets on my nerves when working with file paths in
Python is the aesthetically ugly use of `os.path` functions to perform even
simple manipulations of path names.

Luckily, Jason Orendorff’s `path.py` module provides a very simple wrapper over
these path operations. It contains a single `path` class which you can use like
this:

    #!pycon
    >>> from path import path
    >>> homedir = path('/Users/zacharyvoase/')
    >>> homedir
    path('/Users/zacharyvoase/')

You can manipulate these paths easily, using methods and operator overrides.
`path` also has a lot of the functions from `shutil`, `glob`, `os.path`, et
cetera defined as methods.

In fact, this module was the inspiration for
[URLObject](http://bitbucket.org/zacharyvoase/urlobject/)’s use of operator
overrides for URL manipulation.

### Examples

#### Path Manipulation

    #!pycon
    >>> filename = homedir / 'file.txt'
    >>> filename
    path('/Users/zacharyvoase/file.txt')
    >>> filename.splitext()
    (path('/Users/zacharyvoase/file'), '.txt')


#### Filesystem Operations

    #!pycon
    >>> filename.exists()
    False
    >>> filename.touch()
    >>> filename.exists()
    True

    >>> homedir.isdir()
    True
    >>> homedir.listdir()
    [path('/Users/zacharyvoase/.bash_history'), ...]



#### Globs

    #!pycon
    >>> homedir.files('*.txt')
    [path('/Users/zacharyvoase/file.txt')]
    >>> homedir.dirs('Desk*')
    [path('/Users/zacharyvoase/Desktop')]

### Installing `path`

There is a slight problem in that Jason’s website, where the original version of
the module was hosted, has disappeared. Luckily, the `path` module lives on in
the [Paver](http://www.blueskyonmars.com/projects/paver/) project, which can be
installed via `easy_install Paver`. You can then use the class with `from
paver.path import path`.

### How I Use `path`

I like to put `path` to use in my Django settings module. Have a look at this
for an example:

    #!python
    from paver.path import path

    PROJECT_ROOT = path(__file__).abspath().dirname()

    MEDIA_ROOT = PROJECT_ROOT / 'media'
    UPLOAD_ROOT = PROJECT_ROOT / 'uploads'

    TEMPLATE_DIRS = (
        PROJECT_ROOT / 'templates',
    )

Elsewhere in my Django project, I can then use those paths without having to
import `os.path` and friends.
