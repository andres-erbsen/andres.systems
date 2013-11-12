## Route request packet

This packet is used to negotiate a route to use for forwarding
future forward-me packets. The structure is similar to the one of a forward-me
packet where the cargo is replaced by a protocol buffer message.

### Contents and structure

----------------------------
bytes  meaning
-----  ----------------
0..3   route identifier

4..7   packet identifier

...    *protocol buffer message*: Routing request
----------------------------

The protocol buffer message must contain the following fields:

1. varint: [public key cryptosystem] identifier
2. bytes: senders (temporary) public key
3. bytes: **encrypted and authenticated** from the senders temporary key included in
   this message to the receivers public key. *protocol buffer message*: Hop
   description
	1. varint: Hop type, says what to do with forward-me packets with the same
identifier as this packet.
		1. "UP": destination reached, hand them to the next level protocol
		2. "SIMPLE_ONEWAY": if they come from the same device as this
		  packet, forward them to the next device (id in next field). Otherwise,
		  drop them.
		3. "SIMPLE_TWOWAY": if they come from the same device as this packet,
		  forward them to the next device (id in next field). If they come from the
		  next device, forward them to the device this packet came from. Otherwise,
		  drop them.
	2. ?bytes: The next [devices identifier](device-identifier.html).
	3. ?bytes: *as 1.*
	4. ?bytes: *as 2.*
	5. ?bytes: *as 3.*

### Handling

Check whether the cryptosystem is known and supported, if not, stop.

Decrypt the protocol buffer message in field 3.

- If the cryptosystem needs a nonce (good ones do),
the bytes 0..7 of this packet (the route and packet id) are used. If the
algorithm accepts a nonce longer than 8 bytes, the extra bytes at the end must
be filled with (the beginning of) the string "vc route request".
- The senders public key should be read from field 2.
- If decryption or message authentication (provided it is supported by the
cryptosystem) fails for any reason, stop.

Check whether the hop type is known and supported, if not, stop.

Save the route id, hop type and the previous and next device for future
reference. These are needed to know to what device and how forward-me packets
with the same route id whould be forwarded.

If any of fields 3.3, 3.4 and 3.5 is present, copy their contents to fields 1, 2 and 3 respectively.
Send the resulting packet to the device identified in 3.2.

### Future extensions

Instead of silently dropping a packet if unable to process it, in some cases
sending back a failure notification would be beneficial. It should be encrypted
so it is only readable by the sender unless explicitly specified othwerwise by
them. The contents and format of such messages is yet to be decided.

New routing types will be added, but only those already described are expected
to be implemented by all devices.


[public key cryptosystem]: crypto.html
