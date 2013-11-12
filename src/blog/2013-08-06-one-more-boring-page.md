title: One more boring page on the Internet
date: 2013-08-06
tags: pi, golang, internet-standards
----

This page is running on the $40 [Raspberry Pi Model B], consuming about
two watts of power on average. It hosts my site, stores encrypted
backups of my current works in progress, downloads stuff over `HTTP` and
`BitTorrent` while I am away and functions as a better-than nothing
`OpenVPN` server to be used in case the local network has a really
intrusive firewall.

The blog is maintained using [`gostatic`]. I write posts in plain text (the
`pandoc` dialect of `markdown` to be more precise), inspect the final result in
real time in a web browser using `gostatic -w config` and push the updated
version out to the public using `rsync`.

Math only works with recent browsers for now. There is an alternative
Javascript-based solution that would let more users see the equation on this
page, but unless somebody actually reads this and complains, I will be keeping
JS off my site.

$\left(1+\frac{1}{1+\frac{2}{3+\frac{4}{5+\dots}}}\right)^{2i\pi} = -1$

The fact that I am using a subdomain of `tedx.ee` should be interpreted
as me endorsing them, not vice versa. I got it for from [FreeDNS] a
couple of years ago.

[Raspberry Pi Model B]: https://www.adafruit.com/products/998
[`gostatic`]: https://github.com/piranha/gostatic/
[FreeDNS]: https://freedns.afraid.org/
