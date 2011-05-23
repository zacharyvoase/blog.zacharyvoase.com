---
created_at: 2011-01-18
kind: article
title: "Modern Accounting on the Open Web"
---


Accounting and bookkeeping are essential aspects of running any business.
Usually considered dull and tedious by laymen, the books of a company provide a
unique insight into its operation. Using the information contained therein,
perhaps supplemented by data from other sources, novel ways of minimizing costs
and maximizing revenues may be discovered.

The advent of the computer should have been enough. By modelling a company as a
complex information network, the in- and out-flows of each part of the business
will act as signals and semaphores revealing reckless spending, potential
embezzlement, or unsuccessful ventures. Collecting information allows for an
empirical, scientific approach to management, based on actual performance, and
backed up by numbers.

Unfortunately, the landscape of publicly-available accounting software is
rather poor. Most is either closed-source or GPL. I can find no examples which
observe the [UNIX philosophy][] of simplicity and modularity. Extensibility is
difficult even with open-source applications: most are written in compiled
languages, and/or store their data in proprietary or obscure formats. The GPL
acts as a major obstacle to commercial contribution, so companies are more
likely to work on in-house proprietary solutions.

  [unix philosophy]: http://en.wikipedia.org/wiki/Unix_philosophy

[**Up The Asset**][uta] is a reimagination of accounting software for the
modern age. Based on the proven, centuries-old principle of double-entry
bookkeeping, yet using nothing but [open web standards and formats][rdf] stored
in plain-text files, it aims to bring to accounting the same breath of fresh
air which [git][] brought to version control. At the moment, only a small chunk
of the system has been implemented, but it already feels promising (if I say so
myself).

  [uta]: http://github.com/zacharyvoase/uptheasset
  [rdf]: http://en.wikipedia.org/wiki/Resource_Description_Framework
  [git]: http://git-scm.com/

Because the system is nothing but text and cross-platform executables which
operate on that text, it is fully extensible. The use of [RDF][] means you can
supplement the core UTA vocabulary with your own domain-specific (or even
organization-specific) ontology. Scripting or extending the application itself
is easy thanks to the power of [Ruby][]. The excellent [RDF.rb][] and [Spira][]
libraries allow you to operate on the RDF data at the highest or lowest levels.

  [ruby]: http://www.ruby-lang.org/
  [rdf.rb]: http://rdf.rubyforge.org/
  [spira]: http://spira.rubyforge.org/

## An Example

The most basic action is recording a single transaction in the general journal.
This shell command:

    $ uta record 30 assets/current/cash revenue/service "Consulting" \
        --with-comment --on 2010-12-28
    Gave John Doe my services for 1 hour in exchange for $30.
    ^D

Evaluates to the following Ruby code:

    Transaction.generate do |tr|
      tr.label = "Consulting"
      tr.comment = "Gave John Doe my services for 1 hour in exchange for $30."
      tr.date = Date.civil(2010, 12, 28)
      tr.debit  30, Account["assets/current/cash"]
      tr.credit 30, Account["revenue/service"]
    end.save!

Which generates this RDF (shown in Turtle):

    # Prefixes shown here for illustrative purposes.
    @base <file:///Users/zacharyvoase/books/transactions> .
    @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
    @prefix this: <file:///Users/zacharyvoase/books/> .
    @prefix dc: <http://purl.org/dc/terms/> .
    @prefix uta: <http://uptheasset.org/ontology> .
    @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

    <this:transactions#1a183830-f465-012d-dcb8-001ff3d30363> a uta:Transaction ;
        dc:date "2010-12-28Z"^^xsd:date ;
        dc:identifier <urn:uuid:1a183830-f465-012d-dcb8-001ff3d30363> ;
        rdfs:label "Consulting"@en ;
        rdfs:comment "Gave John Doe my services for 1 hour in exchange for $30."@en ;
        uta:entry
            [ a uta:Debit ;
              uta:account <this:accounts#assets/current/cash> ;
              uta:amount 30 ] ,
            [ a uta:Credit ;
              uta:account <this:accounts#revenue/service> ;
              uta:amount 30 ] .

These RDF statements will be appended to `~/books/transactions`.


## More Ideas

There’s nothing to stop you writing your own interface to the underlying data
model. The ontology and software have been released into the
[public domain][unlicense], so you're free to modify either and use them as you
wish, devoid of any encumberances. Here are some ideas:

  [unlicense]: http://unlicense.org/

*   A hosted accounting web service, using the Ruby library.
*   A supplementary sales ledger ontology, using RDF inference to convert sales
    entries into transactions in the general journal (still maintaining a
    linked record of 'sales' as a first-class concept).
*   A command-line interface for time tracking which creates journal entries as
    transactions to/from 'time' accounts (in a currency of minutes).
*   An invoicing and receipting system, using LaTeX to generate PDFs or HTML.
    Combine this with [GnuPG][] for proper cryptographic security.
*   An ontology for tracking creditors and debtors, including a CLI for
    calculating outstanding balances and sending the appropriate
    invoices/notifications.
*   A CLI using [roqet][] to produce your [income][] and [cash flow][]
    statements, with printed reports via LaTeX.
*   Using [R Sparql][] to pull your account data into [R][], perform
    heavyweight statistical analysis, and produce charts (e.g. of account
    balance and transaction volume over time).

  [gnupg]: http://www.gnupg.org/
  [roqet]: http://librdf.org/rasqal/roqet.html
  [income]: http://en.wikipedia.org/wiki/Income_statement
  [cash flow]: http://en.wikipedia.org/wiki/Cash_flow_statement
  [r sparql]: http://code.google.com/p/r-sparql/
  [r]: http://www.r-project.org/

The code is actively being developed on [GitHub][uta], with documentation
hosting at <http://uptheasset.org/>. If you’re interested, watch the project.
If you have any suggestions, use the [GitHub issue tracker][issues]; better
yet, submit a pull request.

  [issues]: https://github.com/zacharyvoase/uptheasset/issues
