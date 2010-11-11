--- 
kind: article
timestamp: 2009-08-20
title: "OpenPGP for Complete Beginners"
---

This is a rather comprehensive post detailing how to set up PGP encryption on
your machine using GnuPG, an open-source implementation of the OpenPGP standard.
I'll go through the core concepts of OpenPGP, generating a keypair and
revocation certificate, backing up your configuration and data, and carrying out
\*cryption and signing easily from both the command-line and your favourite
e-mail client.

<ins>
  Please note: the installation instructions are mostly geared towards Mac
  users, but the command-line interaction and concepts are applicable to all
  systems.
</ins>

### A Quick Introduction to Encryption

There are two main types of electronic encryption: *symmetric* and *asymmetric*.
In symmetric encryption, a single, shared key is used to encrypt a document from
cleartext to ciphertext, and the *same* key is used to decrypt from ciphertext
back to cleartext. Obviously there is a problem using this to encrypt e-mails,
since everyone has to know the shared key in order to send you an e-mail, and if
the key is public then it offers you zero protection (since any third party
might be able to read the 'encrypted' data). Symmetric encryption is only worth
anything if *only* the sender and receiver know the secret. It's also useful
when there is only one party involved; for example, if you are encrypting files
on your hard drive that only you will see, or if a website is encrypting users'
data to put into a session cookie, etc.

Asymmetric encryption is just plain cool, imho. Two keys are used throughout the
\*cryption process. The way this form of encryption works is that documents
encrypted with one key can *only* be decrypted using the other key (they cannot
even be decrypted with the same key that was used to encrypt them). So if I have
keys A and B, which constitute a keypair, and I encrypt a document (such as an
e-mail) with key A, it can *only* be decrypted by someone with key B, and vice
versa. Algorithms which implement this kind of encryption are known as [trapdoor
algorithms](http://en.wikipedia.org/wiki/Trapdoor_function), since a single key
only works in one direction. In addition, another property of asymmetric
encryption is that if you know for certain that key B *decrypts* a piece of
ciphertext, key A *must* have been used to encrypt it.

#### Confidentiality

The way asymmetric encryption is used in maintaining confidentiality (i.e. the
privacy of your precious documents) goes something like this: you generate a
'keypair' (a pair of keys such that documents encrypted with one can be
decrypted with the other, and vice versa). One of these is your *public* key,
the other is your *private* key. So, you share your public key with the world,
and keep your private key, well, private. People who want to send you an
encrypted e-mail find your public key, write the e-mail, encrypt it using the
public key and send it to you. You, on receiving the e-mail, whip out your
private key, decrypt the ciphertext and read it. This is how **confidentiality**
is obtained with OpenPGP, and it's relatively simple.

In actual fact, it doesn't quite work like this. As it happens, and quite
unfortunately so, asymmetric encryption has a few drawbacks. It is quite
computationally intensive, and some algorithms can produce ciphertext up to
twice the size of the original text. For these reasons, a technique known as
*hybrid encryption* is employed. Rather than just encrypting a document with
your public key, a unique, random *session key* is generated for that document.
This is also sometimes referred to as a *nonce* (*n*umber used *once*). The
session key needs to be completely random, essentially 'unguessable'; this is
why having a good source of randomness (a.k.a. entropy) is very important in
system security.

The document is encrypted *symmetrically* with that session key, and then the
session key is encrypted with your public key. This will probably be much
shorter than the document itself, so the computational load of asymmetric
encryption is lightened significantly. The encrypted session key is attached to
the symmetrically-encrypted document, and the session key discarded forever.
Upon receiving the encrypted document, you use your private key to decrypt the
session key, and then use the session key to decrypt the entire document.

#### Authenticity

One of the other uses of asymmetric encryption is for verifying the authenticity
of data. For example, how do I know that this e-mail was *actually* sent to me
from Joe Bloggs and not some impostor? We can take advantage of the fact that,
if one key can decrypt a piece of ciphertext, the other key must necessarily
have encrypted it. First, the sender will take the e-mail and construct a *hash*
using a *cryptographic hash function*. This function must have several
properties:

*   It should be impractical to find two distinct messages with the same hash.
*   It should be impractical to obtain the original message given a hash (a CHF
    is a *one-way function*).
*   It should be easy to compute the hash value for any given message.

The sender then takes that hash and his/her own secret key, and *encrypt* the
hash with the secret key. This encrypted hash, known as the signature, is
bundled along with the message when it is sent. The recipient can then take the
signature, the original message, and the sender's public key, and attempt to
decrypt the signature using the public key. The recipient will hash the message
themselves, and compare the decrypted signature to the hash of the message. If
equal, the recipient can know for certain that the message was created by
someone with a certain private key (without knowing the key themselves). This is
how **authenticity** is obtained using OpenPGP.

It also helps to enforce data **integrity**, since the hash check will fail if
the document has been changed in transit, so either data corruption *or*
malicious intent will be detected.

This is usually used in tandem with encryption, providing confidentiality and
integrity, but it's also pretty useful for things like software releases, where
the maintainer will sign the release file with his/her private key. You'll
download the release file and the corresponding `.sig` or `.asc` file, and
verify that the package was downloaded intact and that it was published by the
bona fide maintainer.

#### Keyservers

Obviously, if you have your public/private keypair, you'll want to somehow
publish the public key somewhere where everyone can access it. Keyservers are a
relatively simple way to do so. A keyserver is literally just a repository of
public keys; I'll show you later how to push to and fetch from a keyserver,
since this is an important way of keeping your keyring (i.e. the public keys of
others you have saved locally) up-to-date, and also keeping others' keyrings
up-to-date (such as when you make a change to your key).

##### Web of Trust

One of the most important concepts in OpenPGP is that of a Web of Trust. Let's
say Alice decides to generate a keypair using your identity (name and e-mail
address). How are people to decide which belongs to who? Not only might someone
send you e-mail encrypted for Alice, rendering you unable to read it, but Alice
could also read that e-mail, constituting a major breach of security (not to
mention a *serious* inconvenience). Alice could also sign documents, tricking
recipients into thinking that you created them.

Fortunately, using the concept of signing as detailed above, you can sign a
public key, as if to say 'I trust this key—owner relationship'. The more keys
sign that key, the more that key becomes 'trusted'. Eventually, you will have
what is known as a 'Web of Trust'; where key A is signed by key B and C, key B
is signed by keys A and D, and key C is signed by keys A, B and D, for example.
The set of keys and signatures makes up the Web of Trust. You can determine
whether an identity is to be trusted or not by following the chain of trusted
friends. This way, anyone trying to pose as a user will not be able to get much
trust; you'll always go with the key that works out as most trusted.

I'll give an example. Let's say you and Bob are best friends. You trust him
completely, so you've signed his key. Bob has a friend called Chris, who *he*
trusts completely, so he has signed his key. If Chris sends you a signed e-mail,
you're very likely to believe that signature indeed belongs to Chris, because
the authenticity of the key with which it is signed has itself been attested to
by your best friend Bob (and you can verify *that* by checking Bob's signature
against his public key). It can get confusing for even relatively small
networks, but fortunately a simple computer algorithm can calculate a 'trust
level' for a given signature, based on following the sequence of connections of
trust linking you to that signature.

You might also be happy to know that OpenPGP is a good reason to have a party.
At [key-signing parties](http://en.wikipedia.org/wiki/Key-signing_parties),
groups of people get together and exchange their key fingerprints (since each
OpenPGP key has a unique identifier); the morning after, everyone goes online
and signs the keys they accepted the night before.

#### Subkeys

Subkeys are quite a subtle but powerful concept. The problem with the keypair is
this: what happens when a key is compromised? You'll have to revoke your old
keypair (a process which involves you verifying that you are the owner of the
key, after which it will be marked as revoked), thus losing your entire Web of
Trust, and then re-generate a key and publish that. Clearly not a very good
situation to be in.

OpenPGP uses a concept known as a subkey to mitigate this problem. Rather than
have a single keypair, you'll have a 'master' keypair which acts as your
identity, and a 'subkey' pair which does the actual \*cryption. If for some
reason a subkey pair becomes compromised (i.e. someone finds out your
passphrase), you can revoke just that subkey and create a new one, without
losing your identity or WoT.

### Getting Started with OpenPGP

This'll just be a brief guide to getting GnuPG2 installed and running on your
Mac. I haven't included full instructions for GNU/Linux, \*BSD, other good OSes
or Windows here because I'm not running any of those platforms right now; you
can probably find some good guides to installing GnuPG2 elsewhere. Since a lot
of this involves command-line work, which is likely to be the same on most
platforms, it may be applicable to you anyway.

#### Install GnuPG2

This is pretty easy to do on Mac; download the ZIP file from
[here](https://sourceforge.net/projects/macgpg2/files/), unzip, install the
`.mpkg` file and you're done.

Alternatively, if you use MacPorts, you can just run `sudo port install gnupg2`.

Systems with `apt`, `rpm`, `emerge`, et cetera can also use their respective
package managers to obtain a copy of GnuPG2.

#### Generate A Keypair

This will involve using the command line. Launch Terminal.app (or your preferred
terminal emulator) and do this:

    gpg2 --gen-key

You'll see:

    gpg (GnuPG/MacGPG2) 2.0.12; Copyright (C) 2009 Free Software Foundation, Inc.
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.

    Please select what kind of key you want:
       (1) RSA and RSA (default)
       (2) DSA and Elgamal
       (3) DSA (sign only)
       (4) RSA (sign only)
    Your selection? 

Hit enter, since the defaults tend to work fine. Then:

    RSA keys may be between 1024 and 4096 bits long.
    What keysize do you want? (2048) 

I personally go with 4096 at this point, but you do need to make a decision
here. Whilst longer keys are more secure, they can also take a long time to
generate (*especially* on older hardware; 4096-bit keys can take up to an hour
to be generated on a PowerPC-based Mac), and \*cryption will also be slower.
This might not matter if you and all your contacts are running relatively recent
and powerful hardware, but once OpenPGP support for embedded and mobile devices
becomes more available, it will present a serious issue. For this reason you may
want to go for the default. After deciding, you'll be presented with this
screen:

    Requested keysize is 4096 bits       
    Please specify how long the key should be valid.
             0 = key does not expire
          <n>  = key expires in n days
          <n>w = key expires in n weeks
          <n>m = key expires in n months
          <n>y = key expires in n years
    Key is valid for? (0) 

Hit enter again. This should be fine: if somehow your key becomes compromised
you'll be able to revoke it using the revocation certificate (more on that
later). It'll also ask you for confirmation; just hit `y` then enter again. The
generator will then ask you to answer a series of questions:

    GnuPG needs to construct a user ID to identify your key.
    
    Real name: <Type your full name, hit enter>
    Email address: <Type your email address, hit enter>
    Comment: <Optional: type a comment or your homepage URL, hit enter>
    You selected this USER-ID:
        "Real Name (http://example.com) <name@example.com>"

After that it will ask you to confirm:

    Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit?

Just type `O` (that's the capital letter, not the numeral) and then enter. At
this point a dialog box will appear asking for a passphrase. This is necessary
to make sure that even if someone does gain access to your secret key, they
might not be able to use it. The normal rules for strong passwords apply. Try
and make it at least 15 characters long, memorable but not obvious to anyone who
knows you, include a mixture of upper- and lower-case letters, numbers and
punctuation. You will, of course, be asked to repeat the password.

At this point, you'll see something like this:

    We need to generate a lot of random bytes. It is a good idea to perform
    some other action (type on the keyboard, move the mouse, utilize the
    disks) during the prime generation; this gives the random number
    generator a better chance to gain enough entropy.

Do what it says. It's generating your keys, but needs a lot of random numbers to
do so. I recommend playing around on the keyboard, fiddling with the mice, or
having a game of [Quake Live](http://quakelive.com). If you chose a key size of
4096 bits earlier, this might take a while, but don't worry because it'll only
happen once per keypair that you generate. After this is done, you should see
something along the lines of:

    gpg: checking the trustdb
    gpg: 3 marginal(s) needed, 1 complete(s) needed, PGP trust model
    gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
    pub   4096R/<8-CHAR KEY ID> 2009-07-17
          Key fingerprint = <36-CHARACTER KEY FINGERPRINT>
    uid                  Real Name (http://example.com/) <name@example.com>
    sub   4096R/<8-CHAR KEY ID> 2009-07-17

The 8-character Key ID on the line beginning with `pub` is the ID of your public
master key (the one used for identity and signing), the one on the line
beginning with `sub` is that of your public subkey (the one used for
\*cryption), and your primary user ID is on the line beginning with `uid`. Note
that you can actually add user IDs to this key later. This is useful if you want
to do \*cryption on multiple e-mail addresses (like if you have a personal and a
work e-mail address). Take a look at the manual for the `gpg2` command (by
typing `man gpg2` at the console) for more information.

#### Sending your Key to a Keyserver

To publish your public key to a keyserver, run:

    gpg2 --send-keys PUB_KEY_ID

Where `PUB_KEY_ID` is the public master key ID (as shown towards the end of the
previous step). GnuPG2 will default to using the `keys.gnupg.net` public
keyserver; most public keyservers synchronize with one another, so you can
safely leave this as the default.

#### Creating a Revocation Certificate

If your key becomes compromised or useless somehow, you'll need to be able to
revoke it (i.e. declare that it has been compromised or is no longer used). This
is simple enough; just run:

    gpg2 --gen-revoke PUB_KEY_ID > revocert.asc

Where `PUB_KEY_ID` is the public master key ID. The right angle-bracket
character (`>`) will cause the output of the command (i.e. the certificate
itself) to be saved into the file `revocert.asc`. You might want to change this
to include the key ID itself (i.e. `rev-KEY_ID.asc`).

To revoke your key, run:

    gpg2 --import REVO_CERT_FILENAME

This will mark your key as revoked *locally*. In order to let the keyserver
know, just send the key ID to it using:

    gpg2 --send-keys PUB_KEY_ID

Note that this is exactly the same command as when you sent it your key the
first time.

A lot of people like to print out (as in *dead tree*) an ASCII-armored version
of their revocation certificate and keep it safe in storage. Should they ever
need to use it, they can just scan the printout and use OCR to retrieve the
certificate.

#### Signing Keys

Signing keys is crucial to creating a Web of Trust. Thankfully it's relatively
easy to sign someone else's key. First you have to grab the user's key. If it is
stored on a keyserver, run:

    gpg2 --recv-keys KEY_ID

If it's in a text file on your local machine, you can just do
`gpg2 --import FILENAME`. To sign the key, run:

    gpg2 --sign-key KEY_ID

It'll ask you to confirm the signature operation, and then it'll ask you to
input your passphrase. Once this is done, you'll have added your signature to
the key. Since the key is now modified, you'll want to send it back to the
keyserver. To do this, run:

    gpg2 --send-keys KEY_ID

This is the same command used when you send your own key.

#### \*crypting Documents

After all that setup, it's actually quite simple to encrypt and decrypt
documents. If you have a file called `document.txt` on your hard drive that
you'd like to encrypt, just run:

    gpg2 --encrypt document.txt

You'll be prompted to enter the user IDs to whom you're sending the encrypted
document:

    Enter the user ID.  End with an empty line: <Type User ID here>

If you have only one key in your keyring for a person called "Joe Bloggs", you
can just type that and it'll get the correct key for you. At each stage the
command will print all the recipients you've specified so far. To finish, just
hit enter on a prompt without typing anything. Alternatively, you can specify
all of the User IDs on the command line, like so:

    gpg2 --encrypt document.txt -r "Recipient 1" -r "Recipient 2"

Where `-r` is short for `--recipient`. You can pass `-r` as many times as you
like in one command.

GPG2 will encrypt the document and save the encrypted ciphertext as
`document.txt.gpg` (mutatis mutandis). This file will, however, be in a binary
format. If you need a plaintext version, just pass the `--armor` flag to the
`gpg2` invocation. This produces an *ASCII-armored* version of the ciphertext
called `document.txt.asc` (m.m.), suitable for inclusion in e-mails, web pages
et cetera.

To decrypt a document that someone has sent you, you can just run:

    gpg2 --decrypt document.txt.gpg

This will prompt you for your private key's passphrase, and save the decrypted
document in `document.txt` (m.m.). It doesn't matter if the document is in an
ASCII-armored or binary format, since GPG2 will recognize it either way.

#### Signing and Verifying Documents

Signing a document to prove its authenticity is also simple with GPG2. You don't
need to specify any recipients, but you will need to provide your private key's
passphrase. To sign a document, just run:

    gpg2 --sign document.txt

You can also pass in `--armor`, if you need plaintext output. This will create a
file called `document.txt.gpg` or `document.txt.asc`, depending on whether or
not you armor the output. To verify a signature, just run:

    gpg2 --verify document.txt.gpg

For this to work, `document.txt` has to be in the same directory as its
signature, and you also must have imported the public key of the person who
signed it (since the public key is used in verification).

### Making Backups

At this point you'll want to make regular back-ups of your keyring and
associated files. This is easy enough; simply back-up the contents of the
`.gnupg` directory in your home folder, and also create a single back-up of the
revocation certificate you generated in the last step. You'll actually want to
back-up all the files *not* ending in either `.gpg-agent` or the tilde character
(`~`). The first denotes a *file lock* which a process on the system called
`gpg-agent` uses, and files ending in a tilde are back-up files (which obviously
you won't need if you are actually *making* a back-up). You probably have your
own back-up strategy, but I will tell you how best to make backups so that third
parties can't easily access your backed-up data.

I use (and recommend) a piece of software called
[TrueCrypt](http://truecrypt.org) to secure all of my backups. TrueCrypt allows
you to create an encrypted drive in a file, which can then be *mounted* by the
application, read from/written to, and then unmounted again. To most eyes it
will look like it is made of completely random data. You can also encrypt whole
partitions, allowing you to create an encrypted USB stick or external hard
drive.

I'd recommend that you use TrueCrypt to create the drive on which you carry out
all your back-ups. I won't go into the details of setting up an encrypted drive,
since I was able to figure out what to do on my first try (it is a GUI
application after all).

In addition, another nifty trick you can use is to *move* the `.gnupg` directory
to the encrypted external drive, and just make it into a symbolic link like so:

    ln -s /Volumes/EncDrive/gnupg ~/.gnupg

When the drive is mounted, GnuPG2 will work fine; when ejected, trying to use
GnuPG2 will just fail with an error (which is what you want it to do anyway).

### Using OpenPGP with an E-mail Client

OpenPGP's main area of application is in securing e-mails. Most important and
confidential information is still sent via e-mail, so you need to be able to
quickly \*crypt your e-mails and verify that they are from trusted sources. In
this respect, e-mail client integration is key. Fortunately, most mail clients
have mature and readily-available OpenPGP plugins.

If you want to be able to encrypt, decrypt, sign and verify e-mails from within
Apple Mail 3.0 (the Leopard version) in a very simple way, you can use the free
and fantastic [GPGMail](http://www.sente.ch/software/GPGMail/) software. The
installation instructions on its homepage work fine; just walk through the
installer and restart Mail, and you should have all the good PGP functionality
right there in Mail.

Thunderbird users can install the
[Enigmail plugin](http://enigmail.mozdev.org/home/index.php) to get PGP goodness
from within Thunderbird. I don't actually have any experience with either
Thunderbird or Enigmail, so I can't offer much guidance, but I hear that it's
pretty much the most complete solution available (and it works on all the
platforms that Thunderbird does).

If you use GMail from Firefox, you can install
[FireGPG](http://getfiregpg.org/s/home), which will let you do all the useful
OpenPGP operations from within your browser.
