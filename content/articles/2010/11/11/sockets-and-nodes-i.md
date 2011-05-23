---
created_at: 2010-11-11
kind: article
title: "Sockets and Nodes—An Experiment, Part I"
---

In anticipation of [Full Frontal][ff] tomorrow, I decided to play around with
two hot new tools, [node.js][] and [socket.io][], in putting together a useful
‘toy’ application. Over a few blog posts, I’ll demonstrate how to build a
lightweight app to track live Twitter feeds, starting with something incredibly
basic and adding features incrementally.

  [ff]: http://2010.full-frontal.org
  [node.js]: http://nodejs.org/
  [socket.io]: http://socket.io/


## Requirements

Start by installing [node.js][], `npm` (the node package manager), and a
couple of JS libraries. Using [homebrew][]:

  [homebrew]: http://mxcl.github.com/homebrew/

    brew install node npm
    # Add NODE_PATH to your shell environment and config at the same time!
    `echo 'export NODE_PATH=/usr/local/lib/node' | tee -a ~/.zsh_profile`

    npm install socket.io
    npm install twitter-node

Installation instructions for other systems may be found on the internet. I
have faith in your Googling abilities.


## Client-side

Version zero’s client will consist of a single HTML file; start with a basic
skeleton in a file called `index.html`:

    <!DOCTYPE html>
    <html>
      <head>
        <title>BIEBER!!!!1!</title>

        <!-- jQuery -->
        <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.3/jquery.min.js"></script>

        <!-- socket.io client library -->
        <script src="/socket.io/socket.io.js"></script>

        <!-- this is where the main body of the app will go: -->
        <script>
        </script>
      </head>

      <body>
        <ul id="tweets">
          <!-- this list initially empty -->
        </ul>
      </body>
    </html>

Now for the client JavaScript (which you should add to the empty `<script>`):

    var socket = new io.Socket();

    socket.connect();

    $(function () {
      var tweets = $("#tweets");
      socket.on('message', function (tweet) {
        var tweetLi = $("<li/>").text(tweet.text);
        tweets.prepend(tweetLi);
      });
    });


`socket.io` will work out the connection parameters itself, by assuming some
sensible defaults. The behaviour is easy enough to understand; the socket
receives messages (in this case, tweet objects), and adds the tweet text to the
beginning of the `<ul>`.


## Server-side

Add the following to a file called `serve.js`, in the same directory as
`index.html`:

    var http = require('http'),
        fs = require('fs'),
        TwitterNode = require('twitter-node').TwitterNode,
        io = require('socket.io');

    // Serves 'index.html' from the current directory.
    server = http.createServer(function (req, res) {
      res.writeHead(200, {'Content-Type': 'text/html'});
      fs.readFile("index.html", function (err, data) {
        if (err) throw err;
        res.write(data);
        res.end();
      });
    });

    server.listen(4000);

    // The twitter client (populate with your own credentials).
    var twit = new TwitterNode({user: 'foo', password: 'bar'});

    var socket = io.listen(server);

    socket.on('connection', function (client) {
      // Just send the tweet objects directly to the client.
      var tweetReceived = function (tweet) { client.send(tweet); };
      twit.addListener('tweet', tweetReceived);
      client.on('disconnect', function () {
        twit.removeListener('tweet', tweetReceived);
      });
    });

    // Set up the tracking. Modify to suit your tastes.
    twit.track('bieber');
    twit.headers['User-Agent'] = 'bieber.zacharyvoase.com';
    // If you don't listen for them, errors will be thrown.
    twit.addListener('error', function (err) { console.log(err.message); });
    twit.addListener('tweet', function (tweet) {
      console.log("Tweet received: " + tweet.id_str);
    });
    // Start the Twitter client.
    twit.stream();

The server-side component, as you can see, is a little more involved. There are
three components to this app (which could do with being split into separate
files):

1.  The HTTP server, which will just serve `index.html` from the current
    directory on port 4000.

2.  The WebSocket server, which deals with clients connecting/disconnecting.

3.  The Twitter client.

The easiest way to send tweets to WS clients is to hook them up directly to
the Twitter feed, using their `send()` methods as listeners. When a WS client
disconnects, we simply remove that listener from the Twitter client.


## Running the application

If you’ve set `node.js` up correctly, you should be able to run the following
from your working directory:

    node serve.js

Now browse to <http://localhost:4000/>. You should see a fast-moving stream of
tweets about Justin Bieber.


## Next time

In the next chapter I’ll focus on the server-side app: modularizing the code
base and adding new features (like enabling hot-swapping of the tracking
parameters).
