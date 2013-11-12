<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

## How about a network...

- where anyone can connect to any device
- that automatically adapts to changes, such as links appearing and disappearing
- where a connection can be assumed to be secure unless explicitly requested otherwise by both communicating parties
- that does not rely on any central authority
- where the users are not on the sole disposal of their internet service providers
- that requires no manual configuration
- that wouldn't inevitably stop working if it became huge

## Some thoughts on it...

- slides with lots of links, shown at TLÜ IFI research seminar: [pdf](vc-slides-ifi.pdf), [txt](vc-slides-ifi.txt)
- (old) high-level introduction: [pdf](vc-routing.pdf), [txt](vc-routing.txt)
- code (or the lack of it): [github](https://github.com/andres-erbsen/vindicat)
- [specification (draft)](spec)

### The general idea
...is to keep routing and route finding separate. If the network was a postal system, the sender would instead of writing the intended recipients address on the envelope write through which post offices the letter must go. Making sender pick the exact route gives them more freedom, but also more responsibility.

Even though making the devices automatically cooperate to find a route may not be easier than making them route packets, doing allows security issues to be addressed separately. Additionally, many different ways to find routes may be used in the same network without the devices having to understand most of them, but the routing would still work the same way for everybody.


### Security bits
Every device is known by their public key, so pretending to be someone else is really hard. The connections are similar to the ones of [CurveCP].

<small> [GPL/CC-BY-SA](/copyright/) </small>


[CurveCP]: http://curvecp.org/security.html
