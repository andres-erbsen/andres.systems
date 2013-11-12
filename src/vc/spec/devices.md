## Representing devices

Out of the [Zooko's triangle] the, properties of decentralization and security
are picked for this system. Every device is known by its public signing key(s),
but different representations are used in different contexts.

- Device identifiers - variable length prefix of the (SHA-3) hash of the key.
  A device with multiple signing keys has multiple identifiers. In global
  context (and especially in signed statements) only identifiers at least 128
  bits long should be considered valid, but in route requests anything that
  uniquely specifies a neighbor is good. GPG analogy: key fingerprints, but no
  subkeys are allowed.
- Device info - A list of a devices properties, such as public (encryption and
  signing) keys followed by issue time. Note that just seeing two keys in the
  same list does not mean they belong to the same device -- anyone could have
  composed the list. For this reason, device businesscards are distributed instead
  of infos.
- Device businesscard - A device info and a list of signatures on the info,
  one for each signing key in it.

Two signing keys belong to the same device if there is a device businesscard
containing both of them in its info part that has valid signatures on the info 
by both keys in the keys part.

An encryption key belongs to a device with a signing key, if there is a device
businesscard where the encryption key is signed using the signing key.


[Zooko's triangle]: http://en.wikipedia.org/wiki/Zooko's_triangle
