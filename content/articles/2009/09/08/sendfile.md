--- 
kind: article
timestamp: 2009-09-08
title: "Serving Authenticated Static Files with Django"
---

A common problem in Django is serving static files whilst still keeping
application-based authentication. It’s highly recommended that you use your web
server for serving *all* static files, but how can you when you need to
authenticate and authorize users from your application? The first approach one
would try is to read the file into a string *in your application*, then pass
that back in a `HttpResponse`. Unfortunately, this solution is very inefficient
for several reasons:

*   You’ll usually be running your application under WSGI, FastCGI, SCGI or AJP,
    connected to or embedded in a web server (such as Apache, lighttpd or
    nginx). This means you’ll have a persistent daemon with a limited number of
    threads handling requests. Sending a whole file takes some time, so you’re
    going to lock up these threads, making it very difficult to deal with
    concurrent load.

*   Reading large files into memory (as you’ll have to) will cause major RAM
    bloat. As files increase in size (10s of Megabytes and larger), the load on
    your server could become unbearable. High concurrent load will harden the
    blow.

*   Web servers are good at dealing with caching headers. If the client passes
    along an Etag or Last-Modified header (which all modern browsers will), the
    web server can make huge optimisations.

What we need is a form of *trampolining*: the web server accepts the request,
delegates authentication and further processing to our application, after which
our application hands control back to the server, *instructing it* to respond
with the contents of a given file (or not).

This problem has been around for a while and, fortunately enough, so has its
solution. The `X-Sendfile` HTTP header is a non-standard header, which is used
as an instruction to the web server. When you return a response from your
application, and you need it to contain a given file, simply set the
`X-Sendfile` header on your response to the appropriate filename. You don’t need
to include any content in your response; just that header, an appropriate status
code, and any other headers you wish to include.

Upon encountering the `X-Sendfile` header, the web server should do a few things:

*   Check the caching headers on the request, cross-referencing them with
    information on the given filename (as provided by the operating system), to
    determine whether the file needs to be re-sent. If not, a `304 Not Modified`
    response will be returned from the web server to the client.

*   Set the `Content-Length` header on the HTTP response, using the OS-provided
    information on the file’s size, rather than counting the bytes in memory all
    at once (which is what Django would have to do otherwise).

*   Set the `Content-Type` header, if it’s not already set in the application’s
    response (this is gleamed from the file extension otherwise).

*   Stream the file through as the body of the response, using a minimal amount
    of RAM and CPU as it does so (since this is what web servers *do*).

### Using `X-Sendfile` in Django Applications

#### Configuring the Web Server

It’s relatively easy to get started with `X-Sendfile`, since it only involves
setting a single HTTP header. First, you’ll need to configure your web server to
accept the header. For lighttpd + FastCGI setups, you can do this with a single
option in your `lighttpd.conf` file:

    fastcgi.server = (
      "/mysite.fcgi" => (
        "main" => (
          "socket" => "myproject/fcgi.sock",
          "check-local" => "disable",
          "allow-x-send-file" => "enable"
        )
      )
    )

That’s the `allow-x-send-file` one, if you didn’t notice.

For Apache setups, you’ll need to install the
[`mod_xsendfile`](http://tn123.ath.cx/mod_xsendfile/) module. You can then just
use a simple `XSendfile On` directive in your configuration to enable support.

Nginx doesn’t support `X-Sendfile`, but it does have its own answer to it:
`X-Accel-Redirect`. The concept is similar, but the configuration is slightly
different; you can read about it at the corresponding
[wiki page](http://wiki.nginx.org/NginxXSendfile).

#### Writing the Application

Here’s how you might use the header from your application:

    import os
    import django.contrib.auth.decorators as auth_decorators
    import django.http
    
    # This would be best placed in your settings file.
    STATIC_ROOT = '/home/user/myproject/static/'
    
    def get_absolute_filename(filename='', safe=True):
        if not filename:
            return os.path.join(STATIC_ROOT, 'index')
        if safe and '..' in filename.split(os.path.sep):
            return get_absolute_filename(filename='')
        return os.path.join(STATIC_ROOT, filename)
    
    @auth_decorators.login_required
    def retrieve_file(request, filename=''):
        abs_filename = get_absolute_filename(filename)
        response = django.http.HttpResponse() # 200 OK
        del response['content-type'] # We'll let the web server guess this.
        response['X-Sendfile'] = abs_filename
        return response

And the URLconf:

    from django.conf.urls.defaults import *
    
    urlpatterns = patterns('',
        (r'^file/(?P<filename>.*)$', 'myapp.views.retrieve_file'),
    )

It’s simple enough, and in fact your code looks a lot cleaner than when handling
file objects.
