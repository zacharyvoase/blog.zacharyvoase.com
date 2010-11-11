--- 
kind: article
timestamp: 2009-11-02
title: "Bioinformatics and the Semantic Web"
---

In this blog post, I’m going to describe how an approach which unifies
Content-Addressable Storage (via BioSeq and Bitcache), RDF and SPARQL
technologies to develop a scalable, distributed system for storing and querying
large quantities of massively-linked biological data.

I’m assuming that readers are familiar with the basic concepts of RDF; if you
aren’t, it would help to read the “Overview” section of the
[Wikipedia article](http://en.wikipedia.org/wiki/Resource_Description_Framework).
Those familiar with graph theory will understand RDF as a framework for
describing labelled, directed multi-graphs.

Also, note that RDF itself is just a *model* and is not to be confused with a
*serialization format*, much in the same way that the general concept of ‘sound’
is distinct from the MP3 file format. A mimetype of `RDF/XML`, for example,
signifies that a file is the serialized form of an RDF graph *represented as*
XML-encoded data. Some other (IMHO superior) RDF serialization formats include
[Notation 3](http://en.wikipedia.org/wiki/Notation_3) (commonly abbreviated to
“N3”), [Turtle](http://en.wikipedia.org/wiki/Turtle_(syntax)) and
[N-Triples](http://en.wikipedia.org/wiki/N-Triples).

## The State of Play

But back to Bioinformatics. At the moment, several serialization formats are
used for storing and sharing biological data, including (but by no means limited
to):

* [FASTA](http://en.wikipedia.org/wiki/FASTA_format)
* [GenBank](http://en.wikipedia.org/wiki/GenBank)
* [Swiss-Prot](http://en.wikipedia.org/wiki/Swiss-Prot)
* HTML (yup, screen-scraping!)
* XML

Some of these formats are very difficult to use, with parsers available only in
a few languages, and most of them hard-coding the entire set of possible
expressions about data into the format itself. Furthermore, inter-format
conversion can often be lossy, and there is no clear way to store, retrieve and
query the data in these files without developing complex schemata and swapping
data into and out of SQL databases.

## Enter RDF

RDF and SPARQL can solve almost all of these issues. 90% of the incidental
complexity that bioinformaticians have to deal with vis-à-vis data interchange
formats *should not exist*, plain and simple. The main benefit that RDF brings
to the table is that ontologies (i.e. the set of all expressible relationships
between resources) are theoretically universal: if the predicate
`<ncbi:organism>` is understood by every computer program in the universe to
mean that “the (subject) biological sequence *is found in* the (object)
organism”, then a huge hurdle of interoperability is overcome. Now various
agents in the system can produce and consume data with a *universally-understood
meaning*.

### SPARQL

As if the universal semantics offered by RDF aren’t sufficient, it’s accompanied
by a kick-ass query language. SPARQL is enough on its own to make you want to
switch all your data to RDF. I don’t know of any other widely-implemented query
language which allows you to issue queries like the following (all of these
prefixes have been made up, by the way):

Find all the research papers published since 1989 which mention a specific
protein (essentially a one-query lit review):

    PREFIX bioseq: <http://bioseq.org/>
    PREFIX ncbi: <http://www.ncbi.nlm.nih.gov/ontology#>
    
    SELECT ?paper
    WHERE {
        # The specific sequence mentioned here has the paper as a citation.
        bioseq:a2126...d8c33 ncbi:citation ?paper .
        # The paper's publication year is stored as `?year`.
        ?paper ncbi:pubyear ?year .
        # The result set is filtered by the ‘since 1989’ criterion.
        FILTER (?year >= 1989)
    }

Find all proteins mentioned in research papers in which both of the given
diseases are mentioned too, and return the list of papers and proteins:

    PREFIX diseases: <http://example.org/disease-ontology#>
    PREFIX ncbi: <http://www.ncbi.nlm.nih.gov/ontology#>

    SELECT ?paper ?protein
    WHERE {
        # The protein has the paper as a relevant citation.
        ?protein ncbi:citation ?paper .
        # As do the diseases identified by ‘disease-id-1’ and ‘disease-id-1’.
        diseases:disease-id-1 ncbi:citation ?paper .
        diseases:disease-id-2 ncbi:citation ?paper .
    }

SPARQL supports more than just a basic `SELECT` form. `ASK` queries return
booleans indicating whether a solution for the query exists (so are perhaps more
efficient in some cases), and `CONSTRUCT` queries create whole new RDF graphs
with data filtered, sorted and modified according to the query parameters
(useful for exporting certain neighborhoods of a large triplestore). And you’d
be surprised how efficient some of the SPARQL implementations are; it’s feasible
to run complex queries on repositories with millions, even billions of triples.

## Porting Existing Data to RDF

To show how porting your data to RDF can simplify its representation, I've
chosen an example of a biological sequence to RDF-ize. This is how the genetic
sequence of the first chromosome of *Saccharomyces cerevisiae* (brewer's yeast)
is represented in FASTA format (data taken from
[yeastgenome.org](http://downloads.yeastgenome.org/sequence/genomic_sequence/chromosomes/fasta/)):

    >ref|NC_001133| [org=Saccharomyces cerevisiae] [strain=S288C] [moltype=genomic] [chromosome=I]
    CCACACCACACCCACACACCCACACACCACACCACACACCACACCACACCCACACACACA
    CATCCTAACACTACCCTAACACAGCCCTAATCTAACCCTGGCCAACCTGTCTCTCAACTT
    ...
    AGTATTAGGGTGTGGTGTGTGGGTGTGGTGTGGGTGTGGGTGTGGGTGTGGGTGTGGGTG
    TGGGTGTGGTGTGGTGTGTGGGTGTGGTGTGGGTGTGGTGTGTGTGGG

There are about 3,800 lines in the whole file, so I’ve snipped the dataset. The
first line is the sequence header: the FASTA format specifies that this must
begin with a right-angle bracket character (‘>’). The rest is an *ad hoc* format
giving more information about the sequence. The lines which follow are the
sequence itself; this is an unambiguous DNA sequence, and so it is only made up
of the characters ‘A’, ‘C’, ‘G’ and ‘T’.

The problems we can immediately notice here are that:

*   Only a small amount of sequence metadata can be given on the one line
    provided by the FASTA format;

*   The metadata format, being *ad hoc*, limits the amount of computer-readable
    information.

Now we'll see how an RDF representation of the sequence might look. The
following example is written in the
[Turtle](http://www.w3.org/TeamSubmission/turtle/) format. The prefixes used
have mostly been made up, but the real document could feasibly be this simple:

    @prefix alphabets: <http://www.ncbi.nlm.nih.gov/alphabets/> .
    @prefix bioseq: <http://bioseq.org/> .
    @prefix ncbi: <http://www.ncbi.nlm.nih.gov/ontology#> .
    @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
    
    <bioseq:a21268b77c91c67973efa8289cc42a62772d8c33>
        <ncbi:alphabet> <alphabets:unambiguous/dna>;
        <ncbi:chromosome> "1"^^<xsd:integer>;
        <ncbi:organism> "Saccharomyces cerevisiae";
        <ncbi:ref> "NC_001133";
        <ncbi:strain> "S288C" .

The `@prefix` notation is just a sprinkle of syntactic sugar for abbreviating
common parts of URIs. In plain English, this collection of RDF triples expresses
the following ‘meaning’:

*   We’re talking about the sequence identified by the URI
    `http://bioseq.org/a21268b77c91c67973efa8289cc42a62772d8c33`. This sequence:
    
    *   Is expressed in the alphabet
        `http://www.ncbi.nlm.nih.gov/alphabets/unambiguous/dna`
        (i.e. unambiguous DNA);
    *   Is the first chromosome of the organism in which it is found;
    *   Is found in the organism “Saccharomyces cerevisiae”;
    *   Has an NCBI reference identifier string of `NC_001133`; and
    *   Belongs to the organism strain `S2288C`.

A few things should be noted about this particular example:

*   It is assumed that NCBI hosts a complete ontology for expressing information
    about biological sequences, such as
    `http://www.ncbi.nlm.nih.gov/ontology#organism`, and so on.
*   You should read my
    [previous post about BioSeq](http://blog.zacharyvoase.com/post/230595085)
    for more information on `bioseq:` URIs; in short, these allow you to
    universally identify individual biological sequences.

So we can now insert this sort of RDF data into a local ‘triplestore’ (the RDF
equivalent of a database) and run SPARQL queries on it. Assume we’ve loaded a
sizeable dataset into our RDF store, and we now want to filter through the
triples to find exactly what we want. Thankfully, SPARQL is incredibly
expressive, and queries can go from extremely precise to extremely general. Say
we want to look for *all* unambiguous DNA sequences:

    PREFIX alphabets: <http://www.ncbi.nlm.nih.gov/alphabets/>
    PREFIX bioseq: <http://bioseq.org/>
    PREFIX ncbi: <http://www.ncbi.nlm.nih.gov/ontology#>
    PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
    
    SELECT ?sequence
    WHERE {
        ?sequence ncbi:alphabet <alphabets:unambiguous/dna>
    }

How about just DNA sequences, unambiguous *or* ambiguous? Assuming the same
prefix bindings:

    SELECT ?sequence
    WHERE {
        {
            ?sequence ncbi:alphabet <alphabets:unambiguous/dna>
        } UNION {
            ?sequence ncbi:alphabet <alphabets:ambiguous/dna>
        }
    }

Or all DNA sequences on the 2nd chromosome of *S. cerevisiae*?

    SELECT ?sequence
    WHERE {
        ?sequence ncbi:chromosome "2"^^<xsd:integer> ;
                  ncbi:organism "Saccharomyces cerevisiae" .
        {
            ?sequence ncbi:alphabet <alphabets:unambiguous/dna> .
        } UNION {
            ?sequence ncbi:alphabet <alphabets:ambiguous/dna> .
        }
    }

And don’t forget you can also issue `ASK` and `CONSTRUCT` queries. If you want
to know more about SPARQL, I’d sincerely recommend reading the
[official spec](http://www.w3.org/TR/rdf-sparql-query/).

## Wrap-Up

As you can see, the benefits brought to bioinformatics data by these
technologies are manifold. Comprehensive RDF parsing and serialization libraries
exist for most major languages, Bitcache and BioSeq bring efficient CAS to any
programming language with a HTTP client library, and SPARQL opens up these vast
stores of knowledge to expressive and dynamic querying.

The next steps in integration for the semweb and bioinformatics communities are:

*   **Education**: Writing and sharing more tutorials on using and implementing
    these technologies.

*   **Adoption**: As more bioinformaticians and related institutions consume and
    produce RDF, semweb technologies will reach a critical mass within the
    bioinformatics community.

*   **Contribution**: As the semweb concepts are ‘field-tested’ by
    bioinformaticians, hopefully a feedback loop will be set up between the two
    communities: bioinformaticians make recommendations and contributions back
    to the semweb speci writers, who themselves seek input from
    bioinformaticians on how new proposals might help or hinder their work.

I hope you enjoyed this blog post; please don’t refrain from commenting if you
have anything to say about it.
