--- 
kind: article
timestamp: 2009-05-18
title: "Why JSON Will Save Bioinformatics (Well, Sort Of…)"
---

I’ve been doing a lot of work recently with rather large (i.e. 55,000+ records)
sets of biological data, both for fun (well, I *am* a geek) and to help out a
friend who’s using Python for some work in the field of Bioinformatics. One
thing that’s pretty much impossible *not* to notice is that a lot of data is
provided in one of two formats: XML (usually without any kind of schema or even
informal documentation), or some *ad hoc* unspecified plaintext format where you
have to write a 32-page long regular expression to parse the first line, and
can’t even be sure that it’ll work on the other 54,999 lines in the file.

One of the documents which shines as an example of an AHUF (ad hoc unspecified
format) is the list of
[Human Single Amino Acid Variants](http://www.expasy.ch/cgi-bin/lists?humsavar.txt),
a document containing a large list of the known single-amino-acid polymorphisms
in human proteins. A polymorphism is one of the particular forms a protein may
be found in (for the physicists, polymorphisms are to proteins as isotopes are
to elements). A single-amino-acid polymorphism is a polymorphism wherein a
single amino acid has been changed from one to another at a single locus
(position) along the protein’s sequence. In order for a polymorphism to be
classified as such (as opposed to just an arbitrary mutation), it needs to be
present in a significant portion of the population.

But I digress. So if you take a look at that file, you’ll notice that it’s made
up of an English ‘header’, followed by column definitions, and finally the
records themselves — 54,424 to be exact. Each of these records has several
columns which are delimited by their position; for example, the ‘Main gene name’
column goes from the 0th character on the line to the 8th character (inclusive),
and so on and so forth. Anyone who has had to parse this file has had to figure
out the widths and positions of each column, and write a parser in their
programming language of choice which could handle it.

The particular task I was working on required me to use data from this file.
Problem was, I *so* did not want to have to whip out my custom parser every time
I used it! Speed and performance issues aside, I was going to need to manipulate
the data and store it again. I asked myself: why am I going to massive lengths
to work with this format? There *had* to be an easier way!

And it turned out there was. [JSON](http://json.org) is a data format which is
several things at once. On one hand, it’s kind of like a cross-language Pickle
(Pickle being the Pythonic way of writing native Python objects to a file or
string and being able to read them back out again as if they were the original
objects). In this sense I could parse the file, take these abstract objects I’d
created, in memory, from each line of the file, and write them out again to JSON
format. This new JSON file now contained a list of objects in a pretty
human-readable format (to some extent), which I could read back into memory and
get a list of dictionaries, with keys like `main_gene_name` pointing to the
corresponding entry’s *Main gene name* column. So from this point of view it was
good; I didn’t have to write my own parser, I could use the `simplejson` library
for Python 2.5 or the `json` built-in module in Python 2.6 (which is,
incidentally, `simplejson` packaged into the standard library and renamed).

But the other benefit that JSON gives me is that I can share the data with
almost any other language I want. Whether there’s the professor on the other
side of the world using BioPerl, or some hacker using LISP, or someone using
Ruby or PHP or Smalltalk or Visual Basic, it doesn’t matter—parsers for these
languages are readily available as free software, and the basic datatypes of
JSON (numbers, strings, lists, dictionaries, booleans and `null`) have
representations in almost every language yet invented.

A benefit of JSON over XML (and believe me, there is a war raging on the forums
and mailing lists as we speak) is that it is a lot quicker to manipulate.
There’s no Document Object Model or SaX parser to worry about: just plain old
objects. JSON is schema-less (although there are
[working groups](http://www.json.com/json-schema-proposal/) working on how to
define JSON schema right now), so no validation of input is necessary. JSON is
far more terse than XML, which means faster over-the-wire transfers. All-in-all,
it’s a helluva lot easier to just get in and start working with the data without
having to fuss about with parsing either AHUF or XML.

Another thing which concerns me with Bioinformatics in Python especially is that
I still see a lot of the bad habits of Perl creeping into Python programmers’
code. The tell-tale signs of this style of Write-Only programming are all there:
short (almost cryptically so) variable and function names, a severe lack of
whitespace (which both programmers *and* designers will tell you is massively
important), a very low comment-to-code ratio (it’s a good idea to keep it around
15–25%, which sounds like a lot but is definitely worth it) and an abundance of
regular expressions where they aren’t even necessary. I don’t think I need to
explain myself on the first three of these.

On the subject of the fourth, I shall paraphrase Jamie Zawinski, one of the
early Netscape engineers, who succinctly stated
[in other words](http://regex.info/blog/2006-09-15/247) that using regular
expressions to solve a problem simply gives you another problem. Why do I agree
with this statement? Well, when you look at code, it’s immensely helpful (if not
vital) to grok two things: what it *does*—i.e. that code’s *purpose*—and *how*
it does it—i.e. that code’s *design*. But when a programmer looks at a long
regular expression, it offers no clue as to one nor the other. No amount of
syntax highlighting can mitigate the cloud of obfuscation created by the
unintelligible string of asterisks, brackets, parentheses, backslashes and
question marks. Yes, I’m sure it made perfect sense when you *wrote* it. But
just shut your eyes for five minutes, or go and have a coffee—when you come
back, you won’t be able to understand *what* you’ve written, let alone *why* you
wrote it. This is how regular expressions, over time, become their own ‘black
boxes’; these complex systems that we don’t dare touch, lest we aggravate the
beast. They *are* the access control list which make Perl a write-only language.

So what are your other solutions? For one, I’d recommend the use of a BNF
grammar parser. I’ve used [pyparsing](http://pyparsing.wikispaces.com/) and
found it to be brilliant—it’s fast, terse and comprehensive.
[BNF grammars](http://en.wikipedia.org/wiki/Backus–Naur_form) are a clean,
modular and maintainable way of expressing formal grammars of any complexity.
One of the main arguments for the use regular expressions *was* speed, but
computing performance is definitely at the stage now where your applications are
going to be I/O-bound, not CPU-bound, so you can definitely afford to spend the
extra CPU cycles making your program maintainable. On the other hand, you *can*
still make those disposable apps using regular expressions: just make sure that
whatever you parse, you serialize to JSON (or some other well-known format) so
that you can skip that nastiness in the future. This was the route I went down
with the aforementioned list of polymorphisms; I wrote an application which
parsed the file by columns of characters and output a dictionary for each line,
and then I serialized the resulting list of dictionaries to a JSON file. When I
want to manipulate the data, I simply open up the Python interpreter, `import
json`, run `data = json.load(open('humsavar.json'))` and I’m away.

So that’s why JSON (along with a dash of BNF) will save Bioinformatics. Well,
sort of…
