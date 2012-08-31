---
created_at: 2012-08-31
kind: article
title: "Probabilistic M2M Relationships Using Bloom Filters"
---

Here’s an idea that’s been kicking around inside my head recently.

A standard M2M relationship, as represented in SQL, looks like this:

    #!postgresql
    CREATE TABLE movie (
      id SERIAL PRIMARY KEY,
      title VARCHAR(255)
    );

    CREATE TABLE person (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255)
    );

    CREATE TABLE movies_people (
      movie_id INTEGER REFERENCES movie,
      person_id INTEGER REFERENCES person
    );

To find the people for a given movie (including the details of the movie
itself):

    #!postgresql
    SELECT *
    FROM
      movie
      INNER JOIN movie_people ON (movie.id = movie_people.movie_id)
      INNER JOIN person ON (movie_people.person_id = person.id)
    WHERE movie.id = MOVIE_ID;

Finding the movies for a given person just involves changing the `WHERE`
predicate to filter for `person.id` instead.

Using a junction table for a sparse or small data set (where there are not many
associations between movies and people) gives acceptable space and time
consumption properties. But for denser association matrices (which may grow
over time), the upper bound on the size of the junction table is *O(n(movies) *
n(people))*, and the upper bound on the time taken to join all three tables
will be the square of that. So what optimizations and trade-offs can be made in
such a situation?

Well, we can use a [bloom filter][] on each side of the M2M relationship and do
away with the junction table altogether. Here’s what the SQL (for Postgres)
looks like:

  [bloom filter]: http://en.wikipedia.org/wiki/Bloom_filter

    #!postgresql
    CREATE TABLE movie (
      id SERIAL PRIMARY KEY,
      title VARCHAR(255) UNIQUE,
      person_filter BIT(PERSON_FILTER_LENGTH),
      hash BIT(MOVIE_FILTER_LENGTH)
    );

    CREATE TABLE person (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255),
      movie_filter BIT(MOVIE_FILTER_LENGTH),
      hash BIT(PERSON_FILTER_LENGTH)
    );

I haven’t calibrated these filters yet, so I’ve yet to decide how long to make
each one. I’m also doing something different compared to the normal explanation
of a bloom filter. Typically each element is expressed as the set of results of
*k* hash functions, each mapping to an index in a bit array of length *m*. I
prefer to think of a single hash function with an *m*-bit output and a popcount
guaranteed to be less than or equal to *k*. This is effectively identical, but
it helps you think of the filters themselves in a different way: as a union of
a set of hash outputs. All of a sudden, these filters seem less
daunting—they’re just fancy [bit arrays](http://en.wikipedia.org/wiki/Bit_array).
That’s why `length(person.hash) = length(movie.person_filter)`, and vice versa.


### Picking a Hash

According to [Kirsch and Mitzenmacher](http://www.eecs.harvard.edu/~kirsch/pubs/bbbf/rsa.pdf),
you can implement *k* hash functions using only two, with no increase in the
false positive probability. Here's a Python example:

    #!python
    import pyhash  # http://pypi.python.org/pypi/pyhash
    import bitstring  # http://pypi.python.org/pypi/bitstring

    murmur = pyhash.murmur3_32()
    def bloom_hash(string, k, m):
        """Hash a string for a bloom filter with given `m` and `k`."""
        hash1 = murmur(string)
        hash2 = murmur(string, seed=hash1)
        output = bitstring.BitArray(length=m)
        for i in xrange(k):
            index = (hash1 + (i * hash2)) % m
            output[index] = True
        return output

I'm generating a bit array here so it can be simply OR'd with an existing bloom
filter to add the given element to the set.


## Testing on Example Data

To test my system out, I’ll use the community-generated
[MovieLens](http://www.grouplens.org/node/12) database.


### Cleaning the Data

Download and unzip the **1M** dataset, with ~6000 users, ~4000 movies and 1
million ratings.:

    #!bash
    $ ls
    README	movies.dat	ratings.dat	users.dat
    $ wc -l *.dat
        3883 movies.dat
    1000209 ratings.dat
        6040 users.dat
    1010132 total

The field separators in these files are `::`, but I want to convert them to
tabs, so they play better with standard GNU userspace tools:

    #!bash
    $ sed -i -e 's/::/\t/g' *.dat

Because we’re treating set membership as binary, I’ll use a high-pass filter
for ratings—that is, I’ll only consider higher-than-average ratings.

    #!bash
    # Compute the average (the rating is the third column of ratings.dat).
    $ awk '{ sum += $3 } END { print sum/NR }' ratings.dat
    3.58156
    # Ratings are integral, so we just keep ratings of 4 or 5.
    $ awk '$3 > 3 { print }' ratings.dat > good-ratings.dat

How many ratings now?

    #!bash
    $ wc -l good-ratings.dat
    575281


### Picking Filter Sizes

Given that we have 3,883 movies, 6,040 users and 575,281 ratings, we can estimate
the average number of elements in `movie.person_filter` to be 148, and for
`person.movie_filter`, 95. The optimal size for a filter is given by the
following formula:

{:.center}
![Optimal Bloom filter size formula](bloom-size-formula.png)

Choosing a false positive probability of 0.5% (0.005), that gives us a
`movie.person_filter` of 1,632 bits, and a `person.movie_filter` of 1,048 bits.
So our schema now looks like this (with some minor modifications):

    #!postgresql
    CREATE TABLE movie (
      id INTEGER PRIMARY KEY,
      title VARCHAR(255) UNIQUE NOT NULL,
      person_filter BIT(1632) DEFAULT 0::BIT(1632),
      hash BIT(1048) NOT NULL
    );

    CREATE TABLE person (
      id INTEGER PRIMARY KEY,
      name VARCHAR(255) UNIQUE NOT NULL,
      movie_filter BIT(1048) DEFAULT 0::BIT(1048),
      hash BIT(1632) NOT NULL
    );

These may seem large, but we're only adding 335 bytes for each movie and
person. Our *k* value can also be calculated as follows:

{:.center}
![Optimal k formula](optimal-k.png)

Yielding a *k* of around 8 for both filters (since we decided our *p* in
advance).


### Loading the Data: Movies and People

The next step is to load the raw data for movies and people (but not yet
ratings) into the database. Assuming the `CREATE TABLE` statements have already
been issued separately:

    #!python
    from collections import namedtuple
    import csv

    import psycopg2


    # Classes for handling the TSV input.

    _User = namedtuple('_User', 'id gender age occupation zipcode')
    class User(_User):

        @property
        def name(self):
            return '%s:%s:%s' % (self.id, self.age, self.zipcode)

        @property
        def hash(self):
            return bloom_hash(self.name, 8, 1632).bin


    _Movie = namedtuple('_Movie', 'id title genres')
    class Movie(_Movie):

        @property
        def hash(self):
            return bloom_hash(self.title.encode('utf-8'), 8, 1048).bin


    # This should be run from the directory containing `users.dat` and
    # `movies.dat`
    conn = psycopg2.connect('host=localhost dbname=movielens')

    with conn.cursor() as cur:
        cur.execute('BEGIN')

        with open('users.dat') as users_file:
            users = csv.reader(users_file, delimiter='\t')
            for user in users:
                # The input is encoded as ISO-8859-1, and unfortunately
                # Python's csv lib doesn't handle Unicode text well, so we have
                # to decode it after reading it.
                user = User(*[s.decode('iso-8859-1') for s in user])
                cur.execute('''INSERT INTO person (id, name, hash)
                               VALUES (%s, %s, %s)''',
                            (int(user.id), user.name, user.hash))

        with open('movies.dat') as movies_file:
            movies = csv.reader(movies_file, delimiter='\t')
            for movie in movies:
                movie = Movie(*[s.decode('iso-8859-1') for s in movie])
                cur.execute('''INSERT INTO movie (id, title, hash)
                               VALUES (%s, %s, %s)''',
                            (int(movie.id), movie.title, movie.hash))

        cur.execute('COMMIT')

### Loading the Data: Ratings

For the purpose of comparison, I'm going to load the data using both Bloom
filters and a standard junction table. Create that table:

    #!postgresql
    CREATE TABLE movie_person (
      movie_id INTEGER REFERENCES movie (id),
      person_id INTEGER REFERENCES person (id)
    );

Now load in the ratings data for both the junction table and the Bloom filters:

    #!python
    with closing(conn.cursor()) as cur:
        cur.execute('BEGIN')
        with open('good-ratings.dat') as ratings_file:
            ratings = csv.reader(ratings_file, delimiter='\t')
            for rating in ratings:
                cur.execute('''INSERT INTO movie_person (movie_id, person_id)
                               VALUES (%s, %s)''',
                            (int(rating[1]), int(rating[0])))
        cur.execute('''UPDATE movie
                       SET person_filter = (
                           SELECT bit_or(person.hash)
                           FROM person, movie_person
                           WHERE person.id = movie_person.person_id AND
                                 movie_person.movie_id = movie.id);''')
        cur.execute('''UPDATE person
                       SET movie_filter = (
                           SELECT bit_or(movie.hash)
                           FROM movie, movie_person
                           WHERE person.id = movie_person.person_id AND
                                 movie_person.movie_id = movie.id);''')
        cur.execute('COMMIT')

This may take a few minutes minutes.

### Checking the Performance

To query the movies for a given user (and vice versa) in the *traditional* way:

    #!postgresql
    CREATE VIEW movies_for_people_junction AS
    SELECT movie_person.person_id,
           movie.id AS movie_id,
           movie.title AS title
    FROM movie, movie_person
    WHERE movie.id = movie_person.movie_id;

And in the new, *Bloom filtered* way:

    #!postgresql
    CREATE VIEW movies_for_people_bloom AS
    SELECT person.id AS person_id,
           movie.id AS movie_id,
           movie.title AS title
    FROM person, movie
    WHERE (person.hash & movie.person_filter) = person.hash;

Checking the query performance for the junction-based query:

<pre><code class="language-postgresql">EXPLAIN ANALYZE SELECT * FROM movies_for_people_junction WHERE person_id = 160;</code></pre>

    Hash Join  (cost=282.37..10401.08 rows=97 width=33) (actual time=7.440..64.843 rows=9 loops=1)
      Hash Cond: (movie_person.movie_id = movie.id)
      ->  Seq Scan on movie_person  (cost=0.00..10117.01 rows=97 width=8) (actual time=2.540..59.933 rows=9 loops=1)
            Filter: (person_id = 160)
      ->  Hash  (cost=233.83..233.83 rows=3883 width=29) (actual time=4.884..4.884 rows=3883 loops=1)
            Buckets: 1024  Batches: 1  Memory Usage: 233kB
            ->  Seq Scan on movie  (cost=0.00..233.83 rows=3883 width=29) (actual time=0.010..2.610 rows=3883 loops=1)
    Total runtime: 64.887 ms

And for the Bloom query:

<pre><code class="language-postgresql">EXPLAIN ANALYZE SELECT * FROM movies_for_people_bloom WHERE person_id = 160;</code></pre>

    Nested Loop  (cost=4.26..300.35 rows=1 width=33) (actual time=0.033..2.546 rows=430 loops=1)
      Join Filter: ((person.hash & movie.person_filter) = person.hash)
      ->  Bitmap Heap Scan on person  (cost=4.26..8.27 rows=1 width=216) (actual time=0.013..0.013 rows=1 loops=1)
            Recheck Cond: (id = 160)
            ->  Bitmap Index Scan on person_id_idx  (cost=0.00..4.26 rows=1 width=0) (actual time=0.009..0.009 rows=1 loops=1)
                  Index Cond: (id = 160)
      ->  Seq Scan on movie  (cost=0.00..233.83 rows=3883 width=241) (actual time=0.014..0.785 rows=3883 loops=1)
    Total runtime: 2.589 ms

Much better! I’m pretty sure there are still places where both the junction
table and the bloom table could be optimized, but this serves as a great
demonstration of how a typically inefficient query can be sped up by just using
a garden-variety probabilistic data structure, and sacrificing a minimal amount
of accuracy.
