title: Keyserver Auditing vs Hiding the Headcount
date: 2015-07-25
tags: privacy
----

TLDR: CONIKS doesn't usefully hide any userspace statistics either: it exposes
the equivalent of one HyperLogLog bucket per lookup.

Trevor pointed out the following concern about the keyserver design I presented
in my last post:

>  * You're publishing more of the user database than CONIKS, so there's
> perhaps more info on the keyserver's userbase revealed.

I would like to elaborate on how much information about the userbase is
revealed in each system, and what can be done about it.

In my design, there is a defined interface using which verifiers can access
all changes that occur in the userbase: each registration and each key change.
Now, the verifiers do not see anything but the the signing key, but they do see
that a change happened and are able to tell registrations from updates. Thus,
it is trivial for an interested party to see how many users a keyserver has and
how many users it is gaining, modulo dummy entries added to confuse this exact
measurement.

CONIKS as described in the latest public paper does not provide any special
interface for accessing userbase data in bulk. However, the Merkle tree proofs
used to argue that an index (vrf output) maps to an entry do leak some
information about the userbase. In particular, looking up a 256-bit index p
revealds for each i \in 0..255 whether the tree contains some index p'
such that the first i bits of p and p' are equal but bit i+1 differs. It does
not reveal the number of such p', but just the existence is enough to leak the
number of users through multiple queries.

Let's say (for the sake of the argument) that we are trying to figure out the
number of users of a secretive CONIKS server. Let's start with the simplified
case where we are allowed to look up any index (path) of our choice without
having to provide an username that maps to it (I will generalize later). We
would set m = 2^d to the largest power of two that is not above the number of
queries we are allowed to make. We would query m indices, each one starting with
a different d-bit prefix and followed by all 0-s. To consider a small example,
m = 4 (d = 2) would result in the queries 11000000..., 1000000..., 01000000...,
and 000000000..., each one padded to 256 bits. For each query q_i we would note
the largest depth l_i (starting from 0 at our offset d) at which another index
branches off from the one queried. A simple (but high-uncertainty) estimate for
the number of users in subtree i would be 2^l_i. However, our estimates for the
number of users in each of the m subtrees are independent, so their absolute
variances add and result in the total the total relative standard error being
divided by sqrt(m) as in HyperLogLog estimation[1][][2][]. To throw some numbers,
m=1024 (d=10) lookups would admit a relative error of 4%, and multiplying m by
100 would divide the relative error by 10.

The last paragraph assumed that we can look up indices of our choice, but that
really isn't necessary. According to the coupon collector's problem, we could
acquire our m buckets using (in expectation) m*ln(m) queries, or alternatively
we just accept a slightly higher error by taking the first k of m that we are
able to query and estimate the rest based on these. We also can't ensure that
the suffixes contain only zeroes, but that doesn't matter; we get the same
information (in expectation) from any query in the bucket.

I believe the rate of change of userbase can be estimated similarly: to compute
the number of changes between two rounds of queries, simply consider the
responses that already appeared during the first round not to exist during the
second. Also note that the heuristic described in the last paragraph, while
probabilistically sound, is by no means optimal: all but one branch point that
we see in a lookup get ignored.

Now, none of this constitutes a break of any property of CONIKS I care about.
I would even say that this situation makes intuitive sense to me: the proof of
one username:key mapping has to be distinct from the proofs for all other
mappings, and thus has a minimal size limit dictated by the number of entries.
It would probably be possible to make the proof less structured and thus make
it harder to recover statistics from there, and it might be worth thinking
about whether the service-provider could use a zero-knowledge argument, but
neither of those address the size requirement. And accepting the dataset size
leak as inevitable hints at an obvious work-around: dummies. The keyserver is
free to create dummy users which do not correspond to real people and exist
solely to add noise to the measurements about the actual userbase.  This works
as long as the dummy users are indistinguishable from real ones, which is easy
to achieve in both CONIKS and the design I proposed. Updates to the dummies can
mask real key changes. ... I agree that this sounds inelegant, but I am not
aware of anything easier that would be compatible with auditing.

[1]: https://highlyscalable.files.wordpress.com/2012/04/log-log-formulas.png
[2]: https://highlyscalable.wordpress.com/2012/05/01/probabilistic-structures-web-analytics-data-mining/

