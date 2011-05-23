--- 
kind: article
created_at: 2010-02-03
title: "Django Project Conventions, Revisited"
---

A year and two blogs ago, I wrote about the way I prefer to organize my Django
projects and deployments. Since then, I’ve refined my approach, taking into
account the experience I’ve accrued, and the changing nature of Django itself.
In this blog post, I’ll share with you what I’ve found to be incredibly valuable
techniques.


## Filesystem Layout

The first step is to divide the Django *deployment* into two halves: a **site
root** and a **project root**. The site root consists of a [virtualenv][] at the
top level, and sub-directories for SQLite databases, temporary files, and
several other files. A short description of each sub-directory is given below:

  [virtualenv]: http://pypi.python.org/pypi/virtualenv

    SITE_ROOT/
    |-- bin/      # Part of the virtualenv
    |-- cache/    # A filesystem-based cache
    |-- db/       # Store SQLite files in here (during development)
    |-- include/  # Part of the virtualenv
    |-- lib/      # Part of the virtualenv
    |-- log/      # Log files
    |-- pid/      # PID files
    |-- share/    # Part of the virtualenv
    |-- sock/     # UNIX socket files
    |-- tmp/      # Temporary files
    `-- uploads/  # Site uploads

Obviously each of these components is optional, and will vary based on the
requirements of the application. This listing represents the most you will
usually ever need.

The **site root** functions as a container for a specific deployment. All the
files it contains are those that will vary from deployment to deployment, and
most importantly will change *during the running of the site*—log files, user uploads, filesystem-based caches and PID files all fall into this category. For
this reason, the site root **is not** checked into version control.

Conversely, the **project root** contains those files which remain immutable
while the site is running. This means code, static media and configuration
files. As a result, this directory **is** checked into version control. You
should also make the project root a sub-directory of the site root; this will
keep everything in one place. The project directory will look like this:

    PROJECT_ROOT/
    |-- apps/         # Site-specific Django apps
    |-- etc/          # A symlink to an `etcs/` sub-directory
    |-- etcs/         # Assorted plain-text configuration files
    |-- libs/         # Site-specific Python libs
    |-- media/        # Static site media (images, stylesheets, JavaScript)
    |-- settings/     # Settings directory
    |-- templates/    # Site-wide Django templates
    |-- .hgignore     # VCS ignore file (can be .gitignore, .cvsignore, etc)
    |-- README        # Instructions/assistance for other developers/admins
    |-- REQUIREMENTS  # pip dependencies file
    |-- __init__.py   # Makes the project root a Python package
    `-- urls.py       # Root URLconf

There are a few key things to notice:

*   The `apps/` directory contains individual Django apps that are specific to
    this project. Anything generic should be specified in the `REQUIREMENTS`
    file.

*   The `libs/` directory contains individual Python libraries—again, only those
    specific to this project. If a particular library deals with only one app,
    it should go into that app; `libs/` is for the general-purpose tools that
    don’t fit inside a single app, but aren’t generic enough to be a separate
    requirement or dependency.

*   The `etcs/` directory should contain a sub-directory for each deployment—so
    you might have `etcs/development/`, `etcs/staging/` and `etcs/production/`.
    `etc/` is a symlink to one of these, and should be ignored by the VCS. These
    plain-text configuration directories might contain web server configs
    (`lighttpd.conf`, `nginx.conf`), [Supervisor][] configs
    (`supervisord.conf`), and so on.

  [supervisor]: http://supervisord.org/

*   `REQUIREMENTS` should be a [pip requirements file][pip-req].

  [pip-req]: http://pip.openplans.org/requirement-format.html

*   No `manage.py` file. It turns out you can just use `django-admin.py` from
    within the project root (although I use [`django-boss`][django-boss]). As an
    added bonus, these will both actually *listen* to the
    `DJANGO_SETTINGS_MODULE` environment variable, which is really important, as
    you’ll see in a bit.

  [django-boss]: http://bitbucket.org/zacharyvoase/django-boss/

*   More on `settings/` in just a hot second.


## Settings

Managing settings across various deployments has been something of a standing
problem in Django for a while now. It’s not one that can be fixed by a change to
Django itself—in fact, Django is incredibly flexible when it comes to specifying
settings, which has given developers room to experiment with a range of
solutions. I think I’ve found one which works pretty well.

Begin by breaking your settings into two groups: **common** settings, and
**deployment-specific** settings. Common settings are defined in a
`settings.common` sub-module, and may include:

*   Defaults for settings like `DEBUG`, `ADMINS`, `MANAGERS` and
    `CACHE_MIDDLEWARE_SECONDS`. If not subsequently overridden, the values
    specified here will be used, so they should provide sensible defaults.

*   App installation and setup: `INSTALLED_APPS`, `MIDDLEWARE_CLASSES`,
    `ROOT_URLCONF` and `TEMPLATE_CONTEXT_PROCESSORS` all fall under this
    category.

*   A basic logging setup. It’s good to define, but not install, several
    handlers—these can optionally be added to the root logger in the
    deployment-specific configuration. For example, in my common settings, I
    always do:
    
        import logging
        
        LOG_DATE_FORMAT = '%d %b %Y %H:%M:%S'
        LOG_FORMATTER = logging.Formatter(
            u'%(asctime)s | %(levelname)-7s | %(name)s | %(message)s',
            datefmt=LOG_DATE_FORMAT)
        
        CONSOLE_HANDLER = logging.StreamHandler() # defaults to stderr
        CONSOLE_HANDLER.setFormatter(LOG_FORMATTER)
        CONSOLE_HANDLER.setLevel(logging.DEBUG)
    
    In my development settings, I add `CONSOLE_HANDLER` to `logging.root`; in
    production, however, I use a file handler.

<ins>
  Daniel Bruce kindly <a href="#comment-38135625">pointed out</a> that if you’re
  using i18n in your project, you need to set
  <code>LOCALE_PATHS = (PROJECT_ROOT / 'locale',)</code> (a tuple).<br />
  This is because Django’s translation machinery uses
  <code>settings_mod.__file__</code> to find translations by default, and so is
  incompatible with package-based settings modules.
</ins>

Deployment-specific settings, in another `settings.DEPLOYMENT_NAME` sub-module, could consist of:

*   `DEBUG` and `TEMPLATE_DEBUG`
*   `DATABASE_*`
*   `CACHE_BACKEND`
*   `EMAIL_HOST` and `EMAIL_PORT`
*   `TIME_ZONE`
*   `SITE_ID`
*   The global logging level (via `logging.root.setLevel()`).

After you’ve sorted out your settings, the `settings/` directory should look
something like this:

    settings/
    |-- __init__.py     # Empty; makes this a Python package
    |-- common.py       # All the common settings are defined here
    |-- development.py  # Settings for development
    |-- production.py   # Settings for production
    `-- staging.py      # Settings for staging

To get these settings working, you just need to put the following at the top of each deployment-specific settings file:

    from common import *

You’ll also need to set the `DJANGO_SETTINGS_MODULE` environment variable. From the `PROJECT_ROOT`: 

    $ export DJANGO_SETTINGS_MODULE=settings.development # Mutatis mutandem
    $ echo "!!" >> ../bin/activate

The last line will append the previous command to `SITE_ROOT/bin/activate`, so that every time you activate the virtualenv you’ll set the necessary variables.


### Dealing With `apps/` and `libs/`

In order to be able to import stuff from the `apps/` and `libs/` directories,
you’ll need to add them to the module search path. Fortunately, this couldn’t be
simpler: you’ll need to have the following in `settings/common.py`:

    import sys
    from path import path
    
    PROJECT_ROOT = path(__file__).abspath().dirname().dirname()
    SITE_ROOT = PROJECT_ROOT.dirname()
    
    sys.path.append(SITE_ROOT)
    sys.path.append(PROJECT_ROOT / 'apps')
    sys.path.append(PROJECT_ROOT / 'libs')

This code must be executed before Django attempts to import any of the installed
apps or libraries. This is the reason why I recommend putting it in `settings/common.py`. See below for more information on `path.path`.

### The Invaluable `path`

Jason Orendorff’s [`path` module][path-module] is so helpful in building your
settings files. Whether you’re dynamically computing settings like `MEDIA_ROOT`,
or just dealing with files and directories in general, this module makes things
infinitely cleaner and easier; you can do away with massively nested calls like
`os.path.join(os.path.dirname(os.path.abspath(...)))`. I’ve been using it for
ages; I even [blogged about it][path-blog] several months ago.

  [path-module]: http://pypi.python.org/pypi/path.py
  [path-blog]: http://blog.zacharyvoase.com/2009-09-11-easy-path-manipulation-in-python

Now, a simple `easy_install` won’t work due to Jason’s website being down.
However, you can manually fetch it by putting the following line in
`REQUIREMENTS`:

    http://pypi.python.org/packages/source/p/path.py/path-2.2.zip

It will, however, raise a deprecation warning when you import it. Just use the
following trick to avoid that when you import it the first time (usually at the
top of `settings/common.py`):

    import warnings; warnings.simplefilter("ignore")
    from path import path

You can then reap the rewards like so:

    ## Directories
    # Call `dirname()` twice because we’re at `PROJECT_ROOT/settings/xxx.py`
    PROJECT_ROOT = path(__file__).abspath().dirname().dirname()
    SITE_ROOT = PROJECT_ROOT.dirname()
    MEDIA_ROOT = PROJECT_ROOT / 'media'
    
    ## Logging
    FILE_HANDLER = logging.FileHandler(SITE_ROOT / 'log' / 'django.log')
    
    ## Database Setup
    DATABASE_ENGINE = 'sqlite3'
    DATABASE_NAME = SITE_ROOT / 'db' / 'development.sqlite3'

`path.path` is a subclass of the built-in `unicode`, so it can be used anywhere
a string or unicode object would work.


## Running Stuff

This is the one big aspect I’m not settled on. I’ve run Django under Apache and
`mod_wsgi`; I’ve also used [lighttpd][] talking to Django via [FastCGI over a
multiplexed UNIX socket, managed by Supervisor][svd-fastcgi]. I’m eager to give
[nginx][] a whirl, too.

  [lighttpd]: http://www.lighttpd.net/
  [svd-fastcgi]: http://supervisord.org/manual/current/configuration.html#fcgi-programx
  [nginx]: http://nginx.org/

I do know that [Supervisor][] was a really awesome find. It’s essentially a tool
which allows you to manage long-running processes and groups of processes, with
a powerful Python extension mechanism, an XML-RPC API, and a command-line client
for controlling processes. Configurations are written in a very basic INI-style
syntax (actually, using Python’s [`ConfigParser`][configparser]), so they’re a
lot easier to set up than an [`init.d` file][init]. I’d definitely recommend it
if you want to be able to stop, start and monitor your server with ease.

  [supervisor]: http://supervisord.org
  [configparser]: http://docs.python.org/library/configparser.html
  [init]: http://en.wikipedia.org/wiki/Init

Another fantasy of mine is to run Django completely under an asynchronous
server. Recent technologies like [Tornado][], [eventlet][] and [gevent][], as
well as (not so recently) [Twisted][], have proven that using asynchronous
networking can result in tremendous performance boosts. Unfortunately, since
most database client libraries remain incompatible with async-I/O, that makes
running Django asynchronously very difficult indeed. It would require either:

  [tornado]: http://www.tornadoweb.org/
  [eventlet]: http://eventlet.net/
  [gevent]: http://www.gevent.org/
  [twisted]: http://twistedmatrix.com/trac/

*   Writing a new database engine backend around a pure-Python DB client
    library, such as [MySQL Connector/Python](https://launchpad.net/myconnpy);
    or

*   Uninstalling all apps which use the Django ORM, and building a completely
    new suite of replacement apps which leverage async-I/O.

Neither of these seems very palatable right now, so for now I’ll stick with some
simple reverse-proxy-based load-balancing across a few processes, and hope the
box stays up. Besides, if I ever need to use async-I/O for performance reasons,
I probably won’t be using Django to handle requests.


## Wrap-up

When you’ve finally finished setting up your project, it should look something
like the following:

    SITE_ROOT
    |-- PROJECT_ROOT/
    |   |-- apps/
    |   |-- etc/
    |   |-- etcs/
    |   |-- libs/
    |   |-- media/
    |   |-- settings/
    |   |   |-- __init__.py
    |   |   |-- common.py
    |   |   |-- development.py
    |   |   |-- production.py
    |   |   `-- staging.py
    |   |-- templates/
    |   |-- README
    |   |-- REQUIREMENTS
    |   |-- __init__.py
    |   `-- urls.py
    |-- bin/
    |-- db/
    |-- include/
    |-- lib/
    |-- pid/
    |-- share/
    |-- sock/
    |-- tmp/
    `-- uploads/

That’s pretty much it for now. As always, comments, suggestions and criticisms
are appreciated.
