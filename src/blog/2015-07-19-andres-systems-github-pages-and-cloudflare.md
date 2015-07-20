title: andres.systems, Github pages, and Cloudflare
date: 2015-07-19
tags:
----

I have decided to attempt to revive this blog. As a first action item (or,
perhaps, a clever form of procrastination), I updated the technical
infrastructure.

This page is moving to new infrastructure: the canonical copy of the HTML will
be served from Github pages, and mostly accessed through the Cloudflare CDN
using the hostname `andres.systems`. The main upside of this change is that I
am no longer in charge of keeping any machine up and running to serve this
page, in particular, I don't have to worry about x509 certificates. I guess the
downside is that ancient browsers will not be able to use HTTPS because the
free tier service from Cloudflare requires TLS Server Name Indication support
from the client, but I don't think I care that much about that. As I was
already getting a new domain, I also decided to set up email for it on a whim.
Let's see how all this keeps together: I would not be too surprised if the
answer was "not quite perfectly", after all, the domain name is the only piece
I am paying for here is the domain name.

EDIT: also revamped how the source is managed in git (the output site is a
submodule of the source using a Makefile).
