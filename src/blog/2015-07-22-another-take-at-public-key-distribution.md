title: Another Take At Public Key Distribution
date: 2015-07-22
tags: privacy, work
----

This Post
=========

For about four years I've been experimenting with different ways of
making rigorous end-to-end security and public key cryptography
manageable for casual users (in particular, users who do not know and
should not be forced to learn the meanings of the words in the last
sentence). This post describes the overall design and security
properties of a system whose initial version I drafted in September
2013, and which I am now quite satisfied with. I am currently working on
an open source implementation, with the intent to make it deployable in
scenarios like OpenPGP email.

While this post represents my understanding (and not necessarily the
understanding of anybody else), the design I am describing has benefited
significantly from many contributions. Daniel Ziegler is a co-author
with an essentially equal contribution throughout the last 3 iterations.
The lookup rate-limiting design was ported directly from from [CONIKS](https://eprint.iacr.org/2014/1004.pdf).
Adam Langley, Gary Belvin, Ian Goldberg, Ian Miers, Joe Bonneau, Madars
Virza, Nickolai Zeldovich, Trevor Perrin, Yan Zhu and numerous others
provided useful comments. Both MIT and Yahoo have funded me and Daniel
for working on this, and the previous iteration was completed as an open
source side project while employed by Google.

Motivation and Background
=========================

Mass surveillance sucks. But so does PGP for
[so](http://www.thoughtcrime.org/blog/gpg-and-me/)
[many](http://blog.cryptographyengineering.com/2014/08/whats-matter-with-pgp.html)
[users](https://media.ccc.de/browse/congress/2014/31c3_-_6154_-_en_-_saal_1_-_201412272300_-_crypto_tales_from_the_trenches_-_nadia_heninger_-_julia_angwin_-_laura_poitras_-_jack_gillum.html#video).
We want end-to-end encryption to be painless to get people to default to
it, and we want it to work even if the user is distracted or stressed,
under time pressure, and would really like to be thinking about the
content of the communication instead of the mechanism. This means that
we cannot have users reason about how likely it is that an attacker
could have brute-forced a key with the same short ID, manipulated a
"marginal" web of trust rating, or performed a man-in-the-middle attack
against an ad-hoc verification scheme like tweeting a PGP fingerprint.
Furthermore, we want to have one system that supports *casual* use as
well as strong security so that the users who do need every bit of
security they can muster do not immediately stick out from the crowd.
None of the common ways of using PGP (fingerprints, web of trust) and
OTR or Pond (trust on first use, shared secret for each pair of users)
fulfill these requirements.

The security requirements for end-to-end encryption leave us with an
unfortunate tradeoff known as [Zooko's
triangle](https://web.archive.org/web/20081111050316/https://zooko.com/distnames.html)
(the [CAP
theorem](https://groups.csail.mit.edu/tds/papers/Gilbert/Brewer2.pdf) of
security?): we do not know how to build a global secure directory of
human-chosen usernames. We are not giving up on security, and giving up
usability would boomerang back to hurt security, so we must accept some
degree of centralization. I can imagine two kinds of approaches being
viable: in the long term, we could form a global alliance whose members
coordinate (possibly using a federated consensus system like the
[Stellar
Consensus](https://www.stellar.org/blog/stellar-consensus-protocol-proof-code/)
to automatically manage a global namespace of usernames. This was the
vision that guided
[`dename`](https://media.ccc.de/browse/congress/2014/31c3_-_6597_-_en_-_saal_2_-_201412301600_-_now_i_sprinkle_thee_with_crypto_dust_-_ryan_lackey_-_andres_erbsen_-_jurre_van_bergen_-_ladar_levison_-_equinox.html#video)
[iteration number three](https://github.com/andres-erbsen/dename), but
because we lack a global alliance of institutions willing to implement
something as complex as SCP, I have decided to put this idea on hold
until its day has come.

Instead, I and Daniel joined the Yahoo End-to-End team and focused on
building a solution that can be deployed one service provider at a time.
However, make no mistake, the bit of centralization introduced is for
coordination only: it does not limit correctness (security) of the
keyserver in ways other letting the service provider perform a selective
denial-of-service attack against its users. Instead, a proactive
guarantee (not an incentive scheme) that the correct public key is
associated with each user's username is derived from an
[anytrust](http://dedis.cs.yale.edu/dissent/papers/eurosec12.pdf)
assumption similarly to [Certificate
Transparency](http://www.certificate-transparency.org/): the sender of a
message assumes, that the quorum of independent parties that signed the
mapping from the username to the public key contained a honest party.
Anybody (yes, you) will be allowed to participate in the quorums and it
is technically possible for a power user to hand-pick which quorums they
accept (we will make sure to pick sane defaults, though). Now, taking it
on faith that it is possible to build a system that implements this
specification, we can look at the design itself.

Overview
========

Participants
------------

Each service provider seeking to enable their users to use this system
will run a keyserver. While the keyserver will most likely be
implemented using a high-availability cluster (think Raft, Paxos), it is
a single semantic entity and will be referred to as such in this post.
High availability of this service is critical: if the keyserver is down,
users will not be able to look up other users' public keys and, to not
give too much power to a network attacker, the client software should
not fall back to plaintext just because the keyserver is unreachable.

Independently operated verifiers are the core of our security argument,
but the uptime requirements for them are flexible. In a nutshell, each
verifier is as useful as how likely one can expect it to be available. A
client may be configured to accept any 3 out of 5 verifiers having
confirmed that a name maps to a particular public key, resulting in
downtime whenever more than 2 verifiers are unavailable. This is the
best possible situation: a verifier cannot help to secure what it has
not seen. Furthermore, there is no need to build a replicated
high-availability verifier: one can just run two of them.

We assume each user has a single client device with persistent storage
for a secret key and account metadata (generalization to multiple
devices is discussed in the end of this post). We do not assume the
user's internet connection is fast or consistently available, and we do
not assume any security on the network layer. We do not assume a block
chain, bulletin board, or any other computation-heavy infrastructure.

State
-----

A client only stores its own secret key and the verifiers' public keys.
Storing some of the servers' replies would enable a client to detect
whether it has been accepting inconsistent lookups, but we are currently
prioritizing proactive security over attack detection.

The core of a keyserver is a per-service-provider mapping from usernames
to sets of public keys. This is stored in a cryptographic data structure
with support for efficient summarization, lookups, and copy-on-write
updates. Summaries of different versions of the mapping are hash-chained
to form a linear history. The central keyserver and all verifiers will
store this mapping (which will take hundreds of gigabytes at 10\^9
users). The keyserver also acts as a cache of verifier signatures: when
a verifier signs a statement saying that some revisions of the
authenticated data structure (up to and including a specified one) are
valid, it posts the signature at the keyserver.

To establish some terminology, the value the authenticated data
structure maps a name to is called a keyserver *entry*, and it contains
keyserver metadata and a *profile* -- the set of keys tagged with
application identifiers.

Believing the Chronicles
========================

Instead of walking through the details internal to the keyserver and
verifiers in causal order, we instead first describe how the client
implementation vets the result of a query. A lookup *proof* contains
much more than just the public key: it on its own is a strong argument
that the username maps to the given profile as of some given time.
Checking a lookup proof has two main parts: judging whether the fresh
signatures on the summary of the keyserver state come from a
sufficiently diverse set of parties to believe that everybody else would
see the same summary (quorum check), and making sure that the referenced
data structure indeed maps the given username to the given profile
(lookup check). We will also describe another layer of indirection to
allow the keyserver to rate-limit lookups (which will introduce a "VRB
check").

The Quorums
-----------

A client will have a persistently configured understanding of what
qualifies as a good Quorum. Let's look at two examples of this: A client
with

    Q1 = two_of(Yahoo, EFF, MIT)

would accept keyserver states if a fresh valid signature from any two of
the named parties is present (the configuration would include the
verifiers' public keys). Thus, a signature from Yahoo and one from MIT
would be sufficient, but two signatures from EFF would not. For
generality and to enable availability optimization without compromising
the independence of quorums, quorum requirements can have
subexpressions: A client with

    Q2 = two_of(Yahoo, EFF, one_of(MIT, MITCSAIL))

would behave the same as Q1 for the examples above, but also accept a
summary with signatures from MITCSAIL plus EFF or Yahoo (but just MIT
and MITCSAIL signing a summary is not sufficient).

Each verifier signature has a timestamp, and the client will reject
signatures older than some threshold (picked considering the client's
network latency and confidence in its own and the verifier's clock).
Also note that the client does not connect to each verifier in its
quorum: the verifiers are expected to post their signatures at the
keyserver, to be retrieved in one go.

To complicate the matters a little, it is not not necessarily going to
be the case that all verifiers signed the same state. Imagine the
following sequence of events as seen by the keyserver.

-   Keyserver publishes (and signs) state S1
-   Yahoo signs S1
-   MIT signs S1
-   Keyserver publishes (and signs) state S2
-   Yahoo signs S2
-   MIT is experiencing heavy load and does not sign S2 yet, but its S1
    sig is valid
-   Yahoo signature on S1 is old enough to be rejected by clients
-   A client queries the keyserver for a quorum proof

This may look like a situation where neither quorum is sufficient: S1
has a valid signature from MIT and S2 has a valid signature from Yahoo.
However, S2 refers to S1 by hash, AND no honest verifier would have
signed S2 if it had not signed (or at least been willing to sign) S1.
Thus, a client can still do a successful lookup in this situation: it
will see that there is a valid signature from Yahoo on S2, and S2 points
to S1, so Yahoo agrees with S1, and so does MIT -- which is good enough
according to both Q1 and Q2. The purpose of this hash-chaining mechanism
is not to tolerate downtime but to mask out the jitter in verifier
performance, and the number of summaries a client will check is limited
both by how many actually have signatures that are still valid, and how
much downstream bandwidth is to be used for this.

The Data Structure Lookup
-------------------------

[Authenticated Data Structures,
Generically](https://www.cs.umd.edu/~mwh/papers/gpads.pdf) gives a good
framework for reasoning about checkable data structure queries in
general, but we will focus on a simple case here. Each name is mapped to
a 32-byte index using a function described in the next section, and the
32-byte indices are used as keys of a prefix tree using the bits of the
index as digits. Now, to go from a normal prefix tree to an
authenticated one, each node will be annotated with the hashes of its
children. This would mean that an implementation in a language with
algebraic data types (e.g., Haskell) would have a hash field next to
each inductive constructor field, and a C-style implementation would
have a hash field next to each pointer. The properties we care about in
this construction are as follows:

1.  The hash of the root node summarizes the entire data structure. It
    is not feasible to find two different data structures with the same
    root hash.
2.  The hash fields can be updated efficiently. A normal copy-on-write
    update to a leaf at depth d from the root will cause d new nodes to
    be allocated. In the authenticated version, an update will also
    cause d hash computations: one for each node. This is sufficient
    because everything touched by the copy-on-write update is copied,
    and thus no modifications to other nodes are necessary.
3.  The result of looking up an index i in the prefix tree can be proven
    using data proportional to the depth of the leaf returned. The
    client is assumed to have the root hash (which is a part of the
    summary the quorum signed), and thus there is only one root node it
    is going to accept. Furthermore, the lookup algorithm always makes
    the decision whether to descend left or right based on the node it
    is currently at (and the index being queried). Every time the lookup
    descends down the tree (when a C implementation would follow a
    pointer), a lookup proof will simply contain the next node. The
    checker will look at the parent node, decide whether the left or
    right child should have been followed, and verify that the next
    provided node's hash matches the hash of that child. When the
    desired child does not exist, the lookup algorithm terminates:
    either the current node contains the stored value, or the queried
    index does not map to any value in this tree.

Rate-limiting lookups using VRB indirection
-------------------------------------------

Even though usernames are not usually considered private information
when reasoning about security, there are surprisingly many concerns
about making a comprehensive list of them available to anybody who
wishes to run a verifier. The most obvious one, in the case of email, is
SPAM: it would be trivial for a spam robot to register as a verifier and
immediately greet each new user with the most accurate details about how
to acquire the newest pharmaceuticals. There also exists a reasonable
argument that a user may not wish to be publicly associated with their
service provider, or vice versa. This section explains a construction
from CONIKS that lets the service provider have good control over
looking up usernames while maintaining the security of the verification
scheme.

The keyserver will make use of a cryptographic primitive called a
collision-resistant verifiable random function (VRF). One way of
thinking about a VRF is to start from a public-key signature scheme in
which each message has exactly one valid signature (even if the signing
key was not chosen at random), and then hash the signature. We also
require that finding two messages for which the same signature is valid
should be unfeasible. Calling this construction a verifiable random
bijection and denoting it VRB\_key(input), here are the two important
properties:

1.  Safety: The set of valid (name, VRB(name)) pairs that validate
    correctly and can feasibly be computed by the signer is a bijection
    (again, regardless of whether the signer is honest).
2.  Hiding: VRB\_x(name) does not leak information about name, and even
    validating whether b is VRB\_x(name) as required in (1) needs a
    *proof* that does not reveal any information about any other name
    (in the construction based on unique signatures, this would be the
    signature which is the preimage of the VRB value).

While the signature analogy may be useful for conceptualizing, it
important to note that none of RSA-PKCS, RSA-PSS, DSA, ECDSA or EdDSA
signatures fit these criteria because the signer can create multiple
different signatures for one message and make one signature apply to
multiple messages. The keyserver uses a function constructed
specifically to be a verifiable random bijection.

The previous section specified that the each name would be mapped to a
data structure index: specifically, the keyserver will compute index =
VRB\_x(name) where x is a secret key of the keyserver used for just this
purpose. The verifiers will never see the real usernames; all
information provided to them will be in terms of indices. When a client
looks up a profile through the keyserver, it can still be convinced that
it got the correct index because the keyserver gives it a proof that the
index that was looked up is indeed equal to VRB\_x(name).

We are planning to use a construction based on the one in the CONIKS
paper, reproduced here with instantiation information for the purpose of
peer review:

    E is Curve25519 (in Edwards coordinates), h is SHA256.
    f is the inverse elligator function (bytes->E) that covers half of E.
    Setup : the prover publicly commits to a public key (P : E)
    H : names -> E
        H(n) = f(h(n))
    VRB : keys -> names -> vrfs
        VRB_x(n) = h(n, H(n)^x))
    Prove : keys -> names -> proofs
        Prove_x(n) = tuple(c=h(n, g^r, H(n)^r), t=r-c*x, ii=H(n)^x)
            where r = h(x, n) is used as a source of randomness
    Check : E -> names -> vrfs -> proofs -> bool
        Check(P, n, vrf, (c,t,ii)) = vrf == h(n, ii)
                                    && c == h(n, g^t*P^c, H(n)^t*ii^c)

Updating keys
=============

Having looked at how a client makes sure that it only accepts a
username:key mapping if a good quorum of verifiers has cleared it (but
without verifying any intrinsic qualities of the key or the username),
it is absolutely critical to also consider the verifier algorithm and
see that it only signs keyserver state summaries that contain
username:key mappings that we want to be presented to users. The main
argument here is similar to how one argues that a PGP subkey is good to
use (by induction on signatures from the main key), but the keys of all
users are mapped to the same timeline for efficient verification.
Furthermore, we can remove the public key fingerprint from the minimal
set of information one user has to tell another to initiate secure
communication under the assumption that there is at least one honest
verifier in each of the pairwise overlaps of the quorums allowed by each
user's client software. Note that the keyserver being honest is a
sufficient condition, but so is the situation where both users only
trust a verifier that a friend of theirs runs and nobody else knows
about.

Initial Registration
--------------------

To start using this key service, a user proves to the keyserver that
they own their email address (using an internal interface if the
keyserver is operated by the email provider or, alternatively, using a
DKIM-signed message). Satisfied, the keyserver accepts a change of
profile for this user: "no keys" changes to the public key provided by
the user. In case the user already has registered a key, they must also
sign the new key with the old one. In full generality, a new keyserver
entry for a user has to be signed by two keys: an entry signing key from
the old entry *and* an entry signing key from the new entry. The
verifiers use the same acceptance criteria (except that they are unable
to verify ownership of the email address, so they assume it was okay).
The details of how entry updates are handled will be covered later, but
for now, let's take another look at the properties this provides.

1.  Alice registers alice@securemail.foo. She uses a new ed25519 key as
    the entry signing key and adds her PGP key to the profile.
2.  The keyserver clears this change and forwards it to the verifiers.
3.  The verifiers sign the new mapping that includes
    alice@securemail.foo and her entry.
4.  Alice receives a reply from the keyserver.
5.  Alice's client verifies that the new keyserver state indeed maps her
    email address to the entry she just added, and then displays a
    success message.
6.  Alice tells Bob that she is now using the address
    alice@securemail.foo, *and* that she successfully uploaded her PGP
    key to the keyserver.
7.  Bob uses his secure email client to send an email
    to alice@securemail.foo. This involves looking up Alice's key and
    checking verifier signatures. The encrypted message will be only
    readable by Alice.

This list is intentionally explicit and representative of a power-user's
view, if anything. Importantly, nothing here prevents the user from
simply thinking in terms of "signing up for secure email". Now, it may
seem that the security of this usage depends on the keyserver honestly
identifying Alice as alice@securemail.foo in step 2. It is indeed true
that the interaction here would not have gone the same if the keyserver
had maliciously swapped Alice's key for its own at the time of
registration, but there would NOT be a security issue:

1.  Alice registers alice@securemail.foo.
2.  The keyserver cheats, and registers its won key instead, and passes
    this change and forwards it to the verifiers.
3.  The verifiers sign the new mapping that includes
    alice@securemail.foo and the malicious keyserver's key.
4.  Alice receives a reply from the keyserver, but the lookup proof does
    not check. Instead of letting her continue, the client application
    apologizes for technical difficulties, produces a transcript of the
    interaction with the keyserver and politely asks her to report it to
    the client application maintainers.
5.  Alice is disappointed, but luckily securemail.foo is not the only
    secure mail provider out there, so she registers
    alice@honestmail.bar instead.

Update Policy
-------------

From the heuristic that data, code and identity are interchangeable, one
could imagine Alice including a program in her entry that is used to vet
possible changes to the entry: entry e can be replaced by e' if
e.checkUpdatePolicy(e') returns true. The verifiers would only sign
state S\_{i+1} if all entries that differ from S\_i have changed in
accordance with this constraint, thus maintaining by construction that
Alice's profile is indeed Alice's.

The vast majority of users would (and should!) leave specifying the
update policy to the client application. As sending code over the
network is a major engineering hassle (even though PNaCl, ethereum and
Bitcoin contracts exist), we omit the generality in favor of simplicity:
the general structure of the update policy is fixed in the verifier
implementation, and only some inputs are specified by the entry. In
particular, each entry contains a public key that will be used to verify
signatures on all potential entries that might replace it, and a
non-decreasing version number to prevent replays of old signed updates.
Given this, the verifiers perform the following checks for each entry
update u from e1 to e2 (registration of new entries is always
permitted).

1.  u must contain a signature by e1.updateSigningKey on e2
2.  u must contain a signature by e2.updateSigningKey on e2
3.  e2.versionNumber must no be smaller than e1.versionNumber

Coordinating Verification
-------------------------

It is important for availabilty that all verifiers receive the same
signed entry updates for each keyserver state change (security-wise, the
quorum overlap requirement prevents a split-brain situation from passing
validation at clients). As a replicated keyserver implementation will be
generating an ordered log of all operations anyway, it can simply
provide a censored (no usernames, no profiles) copy of this to the
verifiers. Each verifier will stream log entries from the keyserver, and
react to them accordingly:

1.  Signed entry update: perform the verification described in the
    previous section
2.  Publish new state summary:
    0.  Persist all entries to disk
    1.  Check the keyserver signature on the new state
    2.  Check that the new state summary contains a valid hash of the
        previous state summary.
    3.  Iff all verifications have passed so far, sign the new state
    4.  Send the verifier signature to the keyserver for distribution
        to clients.

One could imagine a system where each type 1 entry was always implicitly
followed type 2 entry, but that would have two adverse effects. First,
the hash-chains that clients have to verify when verifiers are not
perfectly in sync would grow faster. Second, the servers would need to
synchronously persist state to disk more often. As we are not aware of
any significant benefits to unifying 1 and 2, it makes sense to keep
them separate.

Social Structures Surrounding Verification
==========================================

No verifiers, no security gained. If the keyserver's signature is
sufficient to confound a client, this cannot be called end-to-end
security. Thus, we will need verifiers. Having the keyserver operator
also run the verifiers would defeat the point, because an attacker who
compromises the operator could subvert both the keyserver and these
verifiers. Therefore, we need independently operated verifiers. And as a
verifier is exactly as useful as much we can expect it to be honest
running in the future, the verifiers will need to run on high quality
infrastructure that is under the operator's control. Running a verifier
on a VPS or "cloud" server does not hurt anybody, but the utility
multiple verifiers on the same corporation's servers is limited by our
trust in that corporation. The ideal case would probably be a pair (or
maybe a trio) of verifiers per operator, with some geographic and
network separation between them. To make all this work out and let the
automation that is described in this document work its magic, people
will need communicate and make judgement calls, balancing security and
availability (which can be thought of security against having the users
switch to a less secure service). Somebody will need to choose the
default quorums of client software.

There are four existing forms of public infrastructure that I would like
to point out as good examples of how this might work out.

1.  First, mirrors of package archives for open source projects are in a
    quite similar situation. Availability is important, because users
    are encouraged to connect exclusively to one or two mirrors closest
    to their physical location. Security has probably been less of a
    goal for mirroring because packages are often authenticated by other
    means, but remember that even holding back updates can open up
    attacks (think Java, Flash), and a compromised verifier is as bad as
    no verifer at all.
2.  Second, public NTP pools are often used in security-critical
    situations (certificate verification), and at in spite of the quite
    inherent insecurity of this, we have not heard repeated
    horror stories. And again, we don't need all verifiers to be safe,
    we just need there to be one in every acceptable quorum.
3.  Third, existing PGP keyservers have been slow to appear and
    sometimes mismanaged, but they exist. Individuals are already
    contributing their resources to improve the security of the internet
    in general, and there is the hope that one would run a verifier for
    the same reasons they would run a keyserver.
4.  Root CA programs are on the other end of the spectrum: they need to
    be absolutely perfect at determining the security of the applicant
    (and of course they fail), and availability is a minor concern. The
    security of a verifier will also need to be evaluated (when relaxing
    quorum requirements), but the anytrust guarantee really pays off
    here: one bad apple does not ruin the cider.

As with mirrors and tighter-stratum NTP servers, keyservers may have to
require their downstream (verifiers) to pre-register to avoid accidental
overloading and denial of service attacks. It will be an inconvenience,
but it should work out for the same reasons it has before. There will be
some process for kicking out malfunctioning servers and encouraging
people to update their software to avoid the need for that, but again,
we have seen it work. All of this has happened before and all of this
will happen again.

Interesting Uses of This Service
================================

Trustees for Key Recovery
-------------------------

The habits the web and the cloud computing boom has built in users are
at odds with the requirement with having a persistent secret key. Making
backups, while absolutely important in very many scenarios, is not a
part of the common routine. It can be argued that the limitations human
errors of this kind put on security are intuitive, even to end users: if
you leak your data then you leak your data. However, that losing a
secret key would mean losing access to all incoming mail is a new
pitfall, and we cannot expect all users to be prepared for that. A
well-kept secret key is a non-negotiable requirement for the level of
security expected from PGP, but there are probably many users who would
accept a lesser security benefit if it meant not risking their mail with
their key ("cautious" users in CONIKS). This section describes a
solution specifically tailored for this set of users, that achieves more
security than one would immediately expect. Speficically, the aim is to
maintain that

1.  Each user will be able to opt in to let some entity change their
    keyserver entry on their behalf by adding a trustee's key as a
    update signing key. The most common trustee will probably be the
    service provider, and the key recovery UI can even be united with
    normal account recovery.
2.  It would not be possible to tell cautious users from full users
    without compromising (or being) the service provider.
3.  Each time the trustee acts on the user's behalf, the user will have
    universally verifiable cryptographic evidence that it was indeed the
    trustee and not the user who made a change. In particular, if a
    trustee key is used to add a malicious key to the user's profile,
    the user can detect it *and* dispute it publicly. It will be up to
    the user to call for the society to play whodunnit, and to convince
    us that the trustee acted behind their back and not on their
    request, but unlike in CONIKS, it is clear which one of them made
    the final call to change the entry.

To achieve property two, all keyserver entries created by the default
software will contain a constant number (tentatively 3) of signing keys,
but the world will now know who holds the secret keys. To look at
properties 1 and 3, let's consider how adding a trustee works:

1.  User initiates contact with the trustee
2.  The trustee generates a new signing key, and signs that signing key
    and the message "I will only use this key as requested by \$user"
    with their own long-term signing key.
3.  The user adds the new trustee key to the list of their entry signing
    keys, replacing one of their own keys if there is more than one. The
    number of keys will not change in that case.

Every time a trustee acts on the behalf of the user, a signed entry
update will be left with each verifier. If a trustee were to betray a
user, the signed entry update and the signature from step 2 can be used
to pin their actions on them. We hope that this will not only enable
other users to make better judgements but also disincentivize
misbehavior.

Device Management
-----------------

It is not required that all devices of one use have the same keys. In
case of PGP, there may be one subkey per device, and messages would be
encrypted to all of them, but the entry signing key can be stored on a
single trusted device or even completely offline. We are not advocating
for most users to make their situation this complex, just noting that if
the flexibility is needed, the keyserver system does support it without
requiring any extensions.

Offline Revocation Certificates
-------------------------------

It is possible to sign an entry update with a entry version number more
than one higher than the current one, and that update can then be used
at any time (unless overridden by an even higher entry version). In
situations with particularly high risk of detectable compromise, a
signed entry update deleting all keys can be prepared beforehand and
released whenever the update signing key is compromised. Note that this
is different from having a trustee because the trustee key can be used
to cause arbitrary updates while a pre-signed revocation can only be
used only for the intended purpose (and is thus less risky to have
around). The caveats from the previous section do apply.

Gossip
------

While the main security argument for this system does NOT rely on
gossip, everything here is *compatible* with the gossip systems proposed
for Certificate Transparency and CONIKS. In short, gossip is a mechanism
for detecting attacks when all verifiers are evil and are presenting two
conflicting views of the world. A client might store some of the
keyserver state summaries it sees, send them to other clients over some
out-of-band channel (maybe inside a PGP packet header), and in case a
conflict is found, it can be published. Two different signed keyserver
state summaries with the same same sequence number are indicative of
misbehavior (be it a bug or an attack).

This post is discussed at <https://moderncrypto.org/mail-archive/messaging/2015/001771.html>.
