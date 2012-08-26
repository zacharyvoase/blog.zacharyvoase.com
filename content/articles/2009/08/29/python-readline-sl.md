--- 
kind: article
created_at: 2009-08-29
title: "Getting A Proper Readline Module for Python on Snow Leopard"
---

<ins>
  The original administrator of the <code>readline</code> package, Ludwig
  Schwardt, <a href="#comment-32227068">has updated</a> the egg, so you can now
  just run <code>[sudo] easy_install readline</code> and get a fully-functional
  readline without having to follow these steps.
</ins>

I just bought and installed my copy of Snow Leopard this morning, and whilst
it’s nice to have a fresh system, it can also be a little annoying to set Python
up on OS X. Not to worry; I’ve included instructions here to get the *most*
annoying part of it out of the way with: setting up the `readline` module.

<ins>
  <strong>BIG FAT Disclaimer: Your Mileage May Vary</strong>.
  This all worked for me on a MacBookPro 4,1 (Penryn), with a 2.4GHz Intel Core
  2 Duo processor and 2GB of RAM.
</ins>

<ins>
  I also realize that for many people, this won’t be the <em>most</em> annoying
  part of the Python/Mac setup process. It’s still pretty annoying.
</ins>

To get the full Readline experience, you’ll want to install
[GNU Readline](http://tiswww.case.edu/php/chet/readline/rltop.html), which
allows you to get interactive line-editing and tab completion from the Python
interpreter. The Python which comes with Snow Leopard does have a `readline`
library by default, but it is based on a less feature-complete version of
Readline called `libedit`, due to licensing issues (GNU Readline is GPL, so
Apple can’t distribute it with their OS). Since Snow Leopard comes with Python
2.5.4 *and* 2.6.1, you can run:

    #!bash
    $ sudo easy_install-2.5 readline

to get a proper `readline` going for Python 2.5 straight away. However, it’s a
little more complex with Python 2.6, since pre-built binaries don’t exist, and
`easy_install` will fail when trying to build the default source package (due to
Snow Leopard being fully 64-bit). In order to get around this, you need to
compile (or at least download) your own copy of GNU Readline, and build the
Python `readline` library with a minor hack.

I’ve actually taken care of this myself, and provided a simple binary
distribution in egg format. For those who want to vet the process I followed to
create this, please see below. To install the egg straight away, just run the
following command:

    #!bash
    $ sudo easy_install 'http://idisk.mac.com/zacharyvoase-Public/readline/readline-2.5.1-py2.6-macosx-10.6-universal.egg'

If you want to replicate my steps yourself, start off in a fresh directory (it
doesn’t matter where, since we’ll just delete it when we’re done). You’re going
to need to have installed the latest version of Xcode, since it comes with the
GNU Compiler Collection (which you’ll need to compile libraries). Begin by
downloading [readline](http://pypi.python.org/pypi/readline) from PyPI,
extracting it, and entering the new directory:

    #!bash
    $ curl 'http://pypi.python.org/packages/source/r/readline/readline-2.5.1.tar.gz' -O
    $ tar -xzf readline-2.5.1.tar.gz
    $ cd readline-2.5.1/

The directory layout will look like this:

    MANIFEST.in
    Modules/
    PKG-INFO
    README.txt
    ez_setup/
    readline.egg-info/
    rl/
    setup.cfg
    setup.py
    setupegg.py

In this directory, you now need to download GNU Readline v0.6 (the latest
version) and build it. Follow these steps:

    #!bash
    $ curl 'ftp://ftp.cwru.edu/pub/bash/readline-6.0.tar.gz' -O
    $ tar -xzf readline-6.0.tar.gz
    $ cd readline-6.0/
    $ curl 'http://idisk.mac.com/zacharyvoase-Public/readline/no_append_character.diff' | patch
    $ ./configure && make

<ins>
  After a bit of playing around, I found out that the default configuration does
  this really annoying thing, whereby it appends a space character after every
  completion. I’ve fixed it in the egg I linked to at the top, but that
  additional <code>curl ... | patch</code> part will fix the problem in the
  readline source. And you don’t have to worry about this clobbering the
  system-wide libreadline either, since GNU Readline gets statically linked into
  the Python module.
</ins>

Now that you've built GNU Readline, just `cd ..` back into the directory above
and rename the directory you just left from `readline-0.6` to just `readline`
(that is, `mv readline-0.6/ readline/`) Now run:

    #!bash
    $ python setup.py build

This will output a lot of text but should eventually tell you whether or not the
build was successful. There may be some warnings about architecture types, but
they’re safe to ignore. If all went well, you’ll want to test out the built
module. To do this, run `python setup.py develop` (which will install it as a
development package), open a new console session somewhere else and run the
following in an interactive Python interpreter:

    #!pycon
    >>> import readline
    >>> import rlcompleter
    >>> readline.parse_and_bind('tab: complete')

Now try typing `rea` and hitting the *tab* character. You should have full tab
completion, as you do in the system shell. To finalize the installation, go back
to the directory containing `setup.py` and run `sudo python setup.py install`.
This will install the package into your global site packages directory. I also
built the binary distribution from above using `python setup.py bdist_egg`.
