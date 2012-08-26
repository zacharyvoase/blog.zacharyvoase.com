--- 
kind: article
created_at: 2009-11-17
title: "Announcing Markdoc"
---

I’m posting this to announce a project I’ve been working on for a few weeks now;
something which has only just reached a state of relative stability and
functionality. It started off slow, on October the 1st (it was a birthday
present to myself), but I’ve since spent a lot of time tweaking, extending,
refactoring and cleaning. I now think it’s ready for a public preview.

## Enter Markdoc

Markdoc is “a lightweight Markdown-based wiki system.” I started work on it
because I was slightly fed up with the state of documentation tools out there. I
had a choice between:

*   **MediaWiki**, which needs a whole SQL database and a PHP web server just to
    run.

*   **API docs** (via epydoc or otherwise), which would auto-generate
    documentation from the docstrings in my source code. Fine, unless I want to
    document something other than functions, modules and classes.

*   **Sphinx**, which is a great project, but unfortunately uses
    reStructuredText, which I just can’t enjoy using; it’s also geared almost
    completely towards documenting software.

*   **Something completely different**: I could make something myself, which
    would provide exactly what I need, at a significant time cost.

Being the hacker (and perhaps masochist) that I am, I went for the last option.
It was clear that the new system would have to meet several criteria:

*   **VCS-friendly** — it would have to be entirely plain-text, ruling out
    anything based on SQL. It should be trivial to diff and merge files, and
    even whole wikis.

*   **VCS-agnostic** — it shouldn’t make a difference if I’m using Mercurial,
    Git, SVN or indeed nothing at all: the wiki shouldn’t care about how I’m
    managing its files.

*   **Plain-text** — it’s no use having a wiki which uses HTML, XML, binary or
    any other unreadable format. I should be able to read the wiki without even
    *knowing* that it’s anything more than a collection of plain-text documents.

*   **Statically-generated** — A wiki with a web interface would be nice, but it
    would be a million times more useful if wikis could compile down to
    standalone, static HTML directories, for later viewing or tarballing.

*   **Cross-platform** — the command-line interface (CLI) to the wiki should run
    on every platform it possibly can; that’s just good programming practice. I
    don’t want to go out of my way to make it work on every single platform, but
    *platform-agnosticism* is a fair enough criterion, and gives a certain
    robustness to the software.

*   **Continuous** — it should be possible to serve the wiki via HTTP in one
    process, and in another to update the source and re-build the HTML, without
    having to restart the HTTP server. This could be used in a situation where a
    wiki is being served from a DVCS node, and a post-commit hook re-builds the
    HTML when changes are pushed to it (N.B. I have actually done this with
    Markdoc, and it’s insanely simple).

*   **Markdown-based** — Markdown is my favorite plain-text formatting syntax,
    and the Python implementation is fast, correct and extensible. It already
    has Pygments syntax highlighting, definition lists, TOC generation and more.
    The wiki might as well exploit these features.

*   **Flexible** — hackability is important in any piece of software, but I want
    to be able to create wikis for many different scenarios (software
    documentation, static website generation, blogs, et cetera), without
    sacrificing simplicity.

Seems like a difficult set of constraints to meet, doesn’t it? Well, it *did*
take me a month and a half to complete.

## Using Markdoc

### Installation

It’s pretty simple, really. For those familiar with Python’s installation
routine, this is the usual:

    #!bash
    $ hg clone http://bitbucket.org/zacharyvoase/markdoc
    $ cd markdoc/
    $ pip install -r REQUIREMENTS
    $ python setup.py install

That’s it for installation. You’ll need [pip](http://pip.openplans.org/), which
is a next-generation package management tool for Python. You can get it with
`easy_install -U pip`. If your OS has a package manager, it may be available
there too.

You’ll also need Python 2.4 or above (2.5+ is highly recommended), and you must
have a working `rsync` binary available on your search path (`rsync` comes
out-of-the-box with most major OSes today, including Mac OS X and Ubuntu).

<ins>
  Please note that I <em>am</em> working on streamlining the installation
  process; it’s just not my main priority whilst Markdoc is under heavy
  development.
</ins>

### Making a Wiki

This is also pretty simple.

`markdoc init` creates the wiki skeleton; this is just three directories and a
single file, all empty to begin with.

    #!bash
    $ markdoc init my-wiki
    # ...logging output...
    $ ls -A my-wiki/
    .templates/
    markdoc.yaml
    static/
    wiki/

Enter your wiki and start editing files in the `wiki/` sub-directory. Wiki pages
must end in one of `[.md, .mdown, .markdown, .wiki, .text]`; this may be
configured by editing the wiki’s `markdoc.yaml` file.

    #!bash
    $ cd my-wiki/
    $ vim wiki/somefile.md
    # ...edit some markdown files...

After you’ve edited enough, and you want to see your files rendered, just run
`markdoc build` in the wiki root.

    #!bash
    $ markdoc build
    # ...more logging output...

That will build your files into `.html/`, which should now contain a number of
HTML files corresponding to all the pages you wrote. You can now serve up these
files with `markdoc serve`:

    #!bash
    $ markdoc serve
    # ...even more logging output...

Now visit <http://localhost:8008/> and you’ll see your wiki being served up as
freshly rendered HTML! You can also use the `-p` option to `markdoc serve` to
control which port it listens on.

IMHO, one of Markdoc’s neatest features is its automatic directory listings. If
you visit <http://localhost:8008/_list>, a listing of the directory will be
automatically generated, with sub-directories, pages and files displayed (pages
and files also have their file size shown next to their links). If a directory
in your wiki lacks an `index` page, the listing will become the directory index.

## The Markdoc Project

Markdoc’s main hub at the moment is the
[Bitbucket repository](http://bitbucket.org/zacharyvoase/markdoc). You can get
the source code from there, which contains both the actual utility *and* all of
the documentation as (you guessed it) a Markdoc wiki.

You can submit bug reports via Bitbucket, too, or just e-mail me at
<zacharyvoase@me.com> if you’ve found an issue or have a feature request.

### Documentation

Markdoc (of course) eats its own dogfood. If you’d like to see a
fully-functional wiki in action, the official Markdoc documentation is a good
example. You can find the complete source for the wiki in the `doc/` directory
in the [repo](http://bitbucket.org/zacharyvoase/markdoc). To see the
documentation in a browser (assuming you’ve cloned the repo locally):

    #!bash
    $ cd markdoc/ # the Markdoc source repository
    $ cd doc/
    $ markdoc build && markdoc serve

Then just visit <http://localhost:8008/> again.

## Related Links

* [Markdoc at Bitbucket](http://bitbucket.org/zacharyvoase/markdoc)
* [Markdown at Daring Fireball](http://daringfireball.net/projects/markdown)
