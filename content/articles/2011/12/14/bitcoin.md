---
created_at: 2011-12-14
kind: article
title: "Bitcoin and Digital Cash: A Vision of the Future"
---

As an experiment, I've recently been investigating Bitcoin and its
characteristics as a form of money. I'm not a fan of the use of Bitcoin in
everyday transactions; clearing is far too slow for real-time use, and the
concept of a fixed pool of circulating currency with diminishing returns on
'mining' is subject to a variant of [Gresham's law][gresham]. Besides, my
initial feeling is that the intricacies of the protocol currently make it
appealing only to hackers/early adopters.

  [gresham]: http://en.wikipedia.org/wiki/Gresham's_law

However, one aspect where I *do* like the idea of Bitcoin is as a reserve
currency in a larger digital cash ecosystem. Bitcoin's properties make it a bad
circulating currency, but as a monetary reserve it's similar to gold (fungible,
divisible, scarce), with the additional benefit that an issuer's reserves are
completely verifiable by anyone in the network. This opens the market to
competition: rather than requiring a secure underground storage facility in
Zurich, with expensive monthly checks by 'trusted' independent auditors, all it
takes to start a bank is a Bitcoin address and an encrypted keyring file.


## Digital Cash: A Rejoinder

For those who aren't familiar with the concept, digital cash is a method of
semi-centralized anonymous payment based on cryptography; specifically, it
relies on the properties of [blind signatures][]. A typical transaction looks
like this:

  [blind signatures]: http://en.wikipedia.org/wiki/Blind_signature

1. Two parties, Alice and Bob, hold an account with an issuer (or 'bank').
2. Alice requests a number of coins from the bank. The appropriate value is
   debited from her account, credited to the bank's float account, and Alice is
   sent the coins as digital tokens (i.e. very large numbers, probably
   represented as character strings). These tokens come signed by the bank,
   which means it can be verified that they were issued on their authority.
3. Alice performs an operation on those tokens which decouples them from the
   original tokens, yet *preserves* the signature.
4. Alice spends these obscured coins in Bob's shop.
5. Bob deposits the coins at the bank, the float account is debited, and his
   account is credited. Since the signature is intact, the bank can recognize
   that they issued the coins, but they can't link these deposited coins with
   the coins issued in step 2, and so can't link the transaction back to Alice.

Here I'm using the concept of an account balance with an institution, but
really anything that's *redeemable* could be the subject of a digital cash
system, including train tickets and coupons.


## How a Dual System Might Work

Theoretically, a bank would have a public Bitcoin address representing its
reserves, and then it would simply issue redeemable tokens against these
reserves. It's possible to bail in simply by transferring BTC to the bank's
reserve address; all accounts held at a bank would be identified with a public
Bitcoin address. This makes bailing out easy, and banks could even charge a fee
for bail-out (much like how withdrawing cash from a card often incurs a fee).
The fact that the transactions for bailing in/out are 'netted' protects the
addresses from the statistical attacks on anonymity that Bitcoin itself is
susceptible to.

Different banks are able to accept (and even issue) each others' currencies at
open-market rates, with interbank clearing very similar to how existing banks
operate, only based on the decentralized Bitcoin protocol rather than a single
[clearing house][]. If RSA-based blinded signatures are used, it's possible to
verify that a coin was issued by a bank without having to contact the bank, and
thus coins are universally non-repudiable.

  [clearing house]: http://en.wikipedia.org/wiki/Clearing_house_(finance)

It's likely a [fractional reserve][] system would emerge; those preferring a
full reserve system would probably just carry out raw Bitcoin trades. I have to
side with [George Selgin][] on this one; I think FR systems can be very
valuable. Of course, because it would be a free and unregulated market, the
reserve ratio would be elastic (and likely differ between institutions based on
risk appetite). So one bank could offer you high interests with a corresponding
high default risk, and another would offer low interest with low default risk.

  [fractional reserve]: http://en.wikipedia.org/wiki/Fractional_reserve_banking
  [george selgin]: http://www.terry.uga.edu/~selgin/index.html

Because these currencies aren't linked to nation-states, the phrase 'foreign
exchange' wouldn't really apply; nevertheless, the exchange market would be a
cornerstone of any digital cash ecosystem, due to the need for currency
conversion services and the desire for a [carry trade][]. When financial
institutions are truly supra-jurisdictional entities, the concept of 'money
laundering' gets a little hazy; when you're using a dual-layer cryptocurrency,
it's downright mercurial. The complex, chaotic, but always beautiful nature of
financial markets which operate on an 'extranational' scale is expounded by
[James Orlin Grabbe][] in his book *International Financial Markets*;
unfortunately it's a little dated now, and won't be getting any updates (since
its author is no longer metabolizing). However, the underlying principles of
what trade looks like when it's not controlled by a single government are still
as relevant as ever, so *IFM* is recommended—nay, mandated—reading if you're
interested in building the economy of the future.

  [carry trade]: http://en.wikipedia.org/wiki/Carry_trade#Currency
  [james orlin grabbe]: http://en.wikipedia.org/wiki/James_Orlin_Grabbe


## Are We There Yet?

A few things stand in our way before we have a full economy up and running.
Despite the importance of human psychology in the field of cryptography, the
user interfaces and form factors we're faced with for securing transactions and
communications currently **suck**. I don't believe it's necessary to sacrifice
security for usability; it just requires a modicum of thought and a generous
helping of user empathy.

It's also necessary to develop a secure, open-source digital cash system, based
on the [original designs][] but without infringing Chaum's software patents
(\*eyeroll\*). [Lucre][] seems to come some way to solving this, but I've not
investigated it in depth yet. We'll also need simple clearing and ledger
systems for bank operations and interbank clearing, though I don't feel these
pose a huge technical challenge.

  [original designs]: http://blog.koehntopp.de/uploads/Chaum.BlindSigForPayment.1982.PDF
  [lucre]: http://anoncvs.aldigital.co.uk/lucre/

More than just the ability to issue and redeem tokens, we need serious work on
the user experience—we need to think about desktop, mobile and even paper
transactions. If the system isn't usable by ordinary 'late adopters', it's
worthless; financial systems (especially those based on Bitcoin) are subject to
an extreme [network effect][].

  [network effect]: http://en.wikipedia.org/wiki/Network_effect


## More Resources

* [George A. Selgin, The Theory of Free Banking: Money Supply under Competitive Note Issue](http://oll.libertyfund.org/?option=com_staticxt&staticfile=show.php%3Ftitle=2307)
* [J. Orlin Grabbe, The End of Ordinary Money, Part I](http://orlingrabbe.com/money1.htm)
* [Bruce Schneier, Applied Cryptography](http://www.schneier.com/book-applied.html)
* [The Online Library of Liberty](http://oll.libertyfund.org/)
* [The Ludwig von Mises Institute](http://mises.org/)

There's a discussion for this article over at
[Hacker News](http://news.ycombinator.com/item?id=3354525).
