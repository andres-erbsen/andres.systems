## Forward-me packet

This packet is expected to be the most common one and therefore known-length
fields are used instead of the usual protocol buffer message structure to allow
forwarders to parse only a small part of the packet.

### Contents and structure

----------------------------
bytes  meaning
-----  ----------------
0..7   route identifier

8..15   packet identifier

...    cargo
----------------------------

The packet size and thus the size of the cargo part must be known from a
lower-level protocol. The forwarders must not make any attempt to interpret the
cargo.

### Handling

Having received a forward-me packet, the corresponding route should be
looked up using the route identifier. If no route with that identifier is known,
the packet must be dropped. If the route is known, the packet should be
forwarded to the next device specified, but may also be dropped (e.g., under
heavy load). The route specification may include additional details about what
to do with a packet (defined together with the route request packet).

### Extensions

An option to send back a "dead route" or "temporary failure" notification after
dropping a packet is likely to be added in a later version.

The route specification may include additional details about what to do with a
packet. For example, to thwart traffic analysis the forwarder may be asked to
decrypt the cargo.
