--- 
kind: article
created_at: 2010-03-05
title: "Deployment with uWSGI and nginx"
---

This post attempts to be a complete guide to setting up a production-ready
Django deployment. I’m publishing it because I hope it will help someone. It is
subject to revision, as I get feedback from experience and other developers. I’m
not going to populate this post with my usual literary cruft, either.

I’m using [nginx][] and [uWSGI][] because, so far, it’s been the best-performing
combination I’ve tried. At low concurrency, it’s comparable in performance to
Apache with mod_wsgi; as concurrency increases, it becomes screamingly fast in
comparison. Speed is certainly a factor in making the choice, but nginx’s
super-simple configuration doesn’t hurt its chances ([zen[2]][zen2]).

  [nginx]: http://wiki.nginx.org/Main
  [uwsgi]: http://projects.unbit.it/uwsgi
  [zen2]: http://www.python.org/dev/peps/pep-0020/

Let’s jump in.


## Installation

1.  Create a virtualenv. This will house a complete Python environment, and all
    the compiled nginx and uwsgi binaries:
    
        $ virtualenv examplesite
        $ cd examplesite/
        $ . bin/activate
    
    I like to create mine in `/sites/` — for example, `/sites/example.com/`.
    
2.  Download the nginx and uWSGI tarballs into a `pkg/` directory:
    
        $ mkdir pkg && cd pkg/
        $ wget 'http://projects.unbit.it/downloads/uwsgi-0.9.4.2.tar.gz'
        $ wget 'http://nginx.org/download/nginx-0.7.65.tar.gz'
    
3.  Start by compiling uWSGI. I prefer to use the `ROCK_SOLID` mode, as this is
    for a production site:
    
        $ tar -xzvf uwsgi-0.9.4.2.tar.gz
        $ cd uwsgi-0.9.4.2/
        $ make -f Makefile.ROCK_SOLID
    
    Note that you may need to edit `Makefile.ROCK_SOLID` for your particular
    version of Python. The last command will have created a binary called
    `uwsgi_rs`; move this into your virtualenv’s `bin/` directory and rename it
    to `uwsgi`:
    
            $ mv uwsgi_rs $VIRTUAL_ENV/bin/uwsgi

4.  Next, you’ll compile nginx with the uWSGI extension module. Extract the
    nginx tarball and enter the directory:
    
        $ cd $VIRTUAL_ENV/pkg
        $ tar -xzvf nginx-0.7.65.tar.gz
        $ cd nginx-0.7.65/
    
    You may have your own preferred setup for nginx; you just need to add a
    single option:
    
        $ ./configure --add-module=../uwsgi-0.9.4.2/nginx/
    
    Now compile the web server:
    
        $ make
    
    This will create an `nginx` binary in `objs/`; install this into the
    virtualenv:
    
        $ mv objs/nginx $VIRTUAL_ENV/bin/nginx

You now have all the required (non-Python) software to deploy a Django project
under nginx/uWSGI. Keep the `pkg/` directory and its contents for now; you’ll
need them during configuration.


## Configuration

There are a few parts to configure before you can run the web server. nginx is
configured using a standalone plain-text configuration file (`nginx.conf`),
whereas uWSGI, in `ROCK_SOLID` mode, uses only command-line options. Before
considering any of this, however, it’s best to take a look at the structure of
the deployment. I like to put my Django project directly under the virtualenv,
like so:

    uwsgitest/
    |-- PROJECT_ROOT/
    |   |-- apps/
    |   |-- etc/ -> etcs/DEPLOYMENT_NAME
    |   |-- etcs/
    |   |-- libs/
    |   |-- media/
    |   |-- settings/
    |   |-- templates/
    |   |-- .hgignore
    |   |-- README
    |   |-- REQUIREMENTS
    |   |-- __init__.py
    |   `-- urls.py
    |-- bin/
    |-- include/
    |-- lib/
    `-- pkg/

This follows the layout discussed in my previous blog post on
[Django project conventions][dj-proj-conv]. You should do the usual set-up as
described in that post; symlink the project root onto the site path, add
`DJANGO_SETTINGS_MODULE` to the `bin/activate` script, et cetera.

And now for the main event.

  [dj-proj-conv]: http://blog.zacharyvoase.com/2010-02-03-django-project-conventions-revisited

1.  Create an `etcs/production` directory to keep plain-text configs in:
    
        $ cd $VIRTUAL_ENV/PROJECT_ROOT
        $ mkdir -p etcs/production
    
    Symlink `PROJECT_ROOT/etc/` to `PROJECT_ROOT/etcs/production/`, to represent
    the currently-activated config directory:
    
        $ ln -s $PROJECT_ROOT/etcs/production $PROJECT_ROOT/etc
    
    This whole architecture is so that you can create different sets of
    plain-text configs for different deployments. Again, read my blog post for
    more information.

2.  Now to configure nginx. There are a couple of required files which are
    imported into the config; you’ll need to add these to the config directory.
    Copy the file `mime.types` from the nginx tarball into `etcs/production`:
    
        $ cp $VIRTUAL_ENV/pkg/nginx-0.7.65/conf/mime.types etcs/production/
    
    Then, add `uwsgi_params` from the uWSGI tarball:
    
        $ cp $VIRTUAL_ENV/pkg/uwsgi-0.9.4.2/nginx/uwsgi_params etcs/production/

3.  What follows is the meat of the nginx configuration. Make sure you read
    *and understand* it thoroughly; there's nothing particularly difficult about
    it:
    
        worker_processes  1;
        pid               pid/nginx.pid;
        
        error_log         log/nginx-error.log;
        
        events {
          worker_connections  1024;
        }
        
        http {
          # Some sensible defaults.
          include               mime.types;
          default_type          application/octet-stream;
          keepalive_timeout     10;
          client_max_body_size  20m;
          sendfile              on;
          gzip                  on;
          
          # Directories
          client_body_temp_path tmp/client_body/  2 2;
          fastcgi_temp_path     tmp/fastcgi/;
          proxy_temp_path       tmp/proxy/;
          uwsgi_temp_path       tmp/uwsgi/;
          
          # Logging
          access_log            log/nginx-access.log  combined;
          
          # uWSGI serving Django.
          upstream django {
            # Distribute requests to servers based on client IP. This keeps load
            # balancing fair but consistent per-client. In this instance we're
            # only using one uWGSI worker anyway.
            ip_hash;
            server unix:sock/uwsgi.sock;
          }
          
          server {
            listen      80;
            server_name example.com;
            charset     utf-8;
            
            # Django admin media.
            location /media/admin/ {
              alias lib/python2.6/site-packages/django/contrib/admin/media/;
            }
            
            # Your project's static media.
            location /media/ {
              alias PROJECT_ROOT/media/;
            }
            
            # Finally, send all non-media requests to the Django server.
            location / {
              uwsgi_pass  django;
              include     uwsgi_params;
            }
          }
        }
    
    You should put this in `etcs/production/nginx.conf`; also, make sure you
    replace `PROJECT_ROOT`, `example.com` and `python2.6` with the appropriate
    values.

4.  You now need to create the necessary directories. From the root of your
    virtualenv:
    
        $ mkdir tmp/ sock/ pid/ log/

5.  Finally, you’ll need a module containing a WSGI callable called
    `application`. This is used by uWSGI. You can just put the following in a
    file called `wsgi.py` in your `PROJECT_ROOT`:
    
        import django.core.handlers.wsgi
        
        application = django.core.handlers.wsgi.WSGIHandler()

And that’s it for configuration!


## Execution

Of course, another key step in the whole process is *running* nginx and uWSGI.
Most people have preferred ways of running daemons; I like to use
[Supervisor][], but others prefer [init][] or [daemontools][]. I don’t really
want to put a whole config here; instead I’ll tell you what you need to run.

  [supervisor]: http://supervisord.org/
  [init]: http://en.wikipedia.org/wiki/Init
  [daemontools]: http://cr.yp.to/daemontools.html


### nginx

The command for nginx is very simple. From the root of your virtualenv:

    $ bin/nginx -p `pwd`/ -c PROJECT_ROOT/etc/nginx.conf

You may need to run `nginx` as root (e.g. via `sudo`) to listen on port 80; I
tend to just try running it on port 8080 while I’m setting it up, so I can avoid
permissions problems in the beginning. I won’t try and dictate how you should
organize your users, groups and permissions — nginx is pretty flexible, anyway.


### uWSGI

As I mentioned before, uWSGI’s ‘configuration’ is made up of the command-line
arguments you choose to pass to it. See the output of `uwsgi -h` for detailed
information. Here’s a very simple example (but one which works fine):

    $ bin/uwsgi -p 4 -s sock/uwsgi.sock -H `pwd`/ PROJECT_NAME.wsgi

The breakdown:

*   `-p 4` tells uWSGI to run four worker processes.
*   `-s sock/uwsgi.sock` specifies the UNIX socket file to use.
*   ``-H `pwd/` `` tells uWSGI to use the current virtualenv.
*   `PROJECT_NAME.wsgi` is the name of a module with an `application` callable
    (i.e. your WSGI app).

Just run nginx and uWSGI as detailed above and try visiting your site. It should
all work perfectly. You might want to try running a HTTP benchmark or load
tester on it, to see how it stacks up.

As always, feedback is hugely appreciated.
