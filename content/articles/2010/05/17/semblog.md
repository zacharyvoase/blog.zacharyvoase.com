---
created_at: 2010-05-17
kind: article
title: "The Semantic Blog"
---

You might see that I’m up and running on a new blog of late; I just wanted to
take some time to go over its architecture and some neat features.


## Cool URIs

Firstly, I’ve changed the URI structure for my posts. Before I had URIs like:

    /2009-08-20-openpgp-for-complete-beginners

Now they’re more like:

    /2009/08/20/openpgp/

Yes, I know. [Cool URIs don’t change](http://www.w3.org/Provider/Style/URI). But
the URIs I had before weren’t cool. These ones are, and I don’t see any reason
to change them in the future.


## Powered by nanoc3

My previous blog was powered by my very own [Markdoc](http://markdoc.org/),
which I’m still quite proud of. Unfortunately it doesn’t really accommodate the
blogging model (i.e. chronologically-ordered content) very well.

This blog is powered by [nanoc3](http://nanoc.stoneship.org/), which is a great
Ruby utility for static publishing. It provides much more control over how the
content is built into a HTML site, and it’s definitely a better fit for
blogging. My templates are written in [Haml](http://haml-lang.com), stylesheets
in [Sass](http://sass-lang.com/), and content in
[Markdown](http://daringfireball.net/projects/markdown/).


## No Comment

There’s no real reason to host my own peanut gallery. Disqus comments break with
proper XHTML (that’s XHTML served with `Content-Type: application/xhtml+xml`),
and they’re quite ugly. If you really feel the need to get something off your
chest, I’m sure someone on [Hacker News](http://news.ycombinator.com/) cares. If
you have a question, e-mail me, and if I feel it’s important enough, I’ll update
the relevant post.


## Public

It’s worth pointing out again that the contents of this blog—design, code and
text—have all been released into the Public Domain. You are free to remix, reuse
and redistribute whatever you find here, without any encumbrance or attribution
requirement.


## Semantic

I saved the best ’til last. Take a look at the source of this page. You’ll
notice a few things that aren’t so common—the doctype:

    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.0//EN"
      "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-1.dtd">

The big set of namespace declarations:

    <html lang="en" xml:lang="en"
      xmlns:content="http://purl.org/rss/1.0/modules/content/"
      xmlns:dc="http://purl.org/dc/elements/1.1/"
      xmlns:foaf="http://xmlns.com/foaf/0.1/"
      xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
      xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
      xmlns:rss="http://purl.org/rss/1.0/"
      xmlns:sy="http://purl.org/rss/1.0/modules/syndication/"
      xmlns:xsd="http://www.w3.org/2001/XMLSchema"
      xmlns="http://www.w3.org/1999/xhtml">

`property` attributes on almost every text-containing element:

    <h1 datatype="" property="rss:description">
      The Blog of Zachary Voase, brought to you in glorious HyperText.
    </h1>

This is called [RDFa](http://en.wikipedia.org/wiki/RDFa), and it is a big part
of the web’s future. It is a standard for embedding RDF triples in the natural
structure of your HTML documents, such that they provide semantic context
*and* can easily be parsed out into raw triples later.


### Demonstration

To get a valid [RSS 1.0](http://web.resource.org/rss/1.0/) feed for this site:

    rapper -q -i rdfa -o rdfxml-abbrev 'http://blog.zacharyvoase.com/'

<ins>
  You’ll need to
  <a href="http://blog.datagraph.org/2010/04/transmuting-ntriples">install rapper</a>.
</ins>

Since RSS 1.0 is just an RDF ontology, you can embed its semantics into the
fabric of the page itself. `http://blog.zacharyvoase.com/` *is* an RSS 1.0 feed,
although represented in XHTML+RDFa instead of RDF/XML. Ideally I’d like to have
the following retrieve the XML version of the feed:

    curl -H 'Accept: application/rss+xml' 'http://blog.zacharyvoase.com/'

I’ll set this up once I figure out all the Apache options.
