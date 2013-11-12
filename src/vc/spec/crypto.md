## Cryptography

Here, all cryptosystems are described by their properties. The concrete system
used to encrypt a packet is identified in its header. To avoid the problems
created by the [complexity of IPsec], the only thing that is pluggable is the
cryptosystem as a whole. For example, there is no way to separately specify
authentication and encryption algorithms.

### Public key authenticated encryption schemes

The [nacl crypto_box_curve25519xsalsa20poly1305] cryptosystem can be used as an
example of what security model is expected and is currently the only option,
with identifier 1. If a comparable system resistant to quantum attacks is
implemented, it will most likely be added.

[complexity of IPsec]: http://curvecp.org/security.html
[nacl crypto_box_curve25519xsalsa20poly1305]: http://nacl.cr.yp.to/box.html
