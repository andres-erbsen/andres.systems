title: Google dropped XMPP
date: 2014-07-05
tags: internet-standards
----

Google dropped XMPP^[also known as Jabber] cross-server interoperability. This
means that Google accounts are no longer able to chat with other services'
users, such as me.  You can still use your GChat account using an XMPP client
(for now) but you can only talk to Google users. Oddly enough, presence updates
do go through, so I still see most of my contacts who use GChat as "online" even
though I am not able to talk to them. This is not not intermittent problem,
Google XMPP support has always been lacking and interoperability is not a
priority.

EDIT: Apparently, this change does not apply to some contacts added before it.
Adding new contacts that use other servers to a GChat account still seems
impossible.

I have hunch that the expected outcome of this move is that users of other
services will move to GChat. I will not, for the reasons outlined in an earlier
post [Communications platforms]. If you have me on your GChat contact list right
now, you will have to find another means to reach me. My XMPP address is also my
email address and Google does allow inter-server mail so you can still email me.
For chat, you need a XMPP account at a standards-compliant server.

- DuckDuckGo also offers an [XMPP service](https://duck.co/blog/using-pidgin-with-xmpp-jabber)
  that receives a rating of [B](https://xmpp.net/result.php?domain=dukgo.com&type=client) at the [IM Observatory].
  In-client account creation works as explained on their page, the address will be of form `you@dukgo.com`.
- [`jabber.de`](http://www.jabber.de/) receives a rating of [A](https://xmpp.net/result.php?domain=jabber.de&type=client),
  but their homepage is in German. You can register an account [here](http://www.jabber.de/register/).
- [`chatme.im`](http://chatme.im/) receives a rating of [A](https://xmpp.net/result.php?domain=chatme.im&type=client),
  but their homepage is in Italian. In-client account creation works (as explained
  [here](https://duck.co/blog/using-pidgin-with-xmpp-jabber)), but you may
  need to click "Accept" to a certificate warning^[`chatme.im` gets their
  certificates from CACert, which is not allowed by default on most systems].
- MIT accounts are also XMPP accounts.

XMPP is meant to be used through a local application.

- I generally recommend [Pidgin](https://pidgin.im/), ideally with [`OTR`](https://securityinabox.org/en/pidgin_securechat).
- If you are using a Mac, you probably want [Adium](https://www.adium.im/) instead.
- If you really want to use XMPP without downloading anything, you can try  [`jwchat.org`](https://jwchat.org/).
- Command line users can check out [`xmpp-client`](https://github.com/agl/xmpp-client).

I am disappointed by the general state of online communication. I do not think
that XMPP is a silver bullet, I am even unsure whether it will succeed in of
becoming *the* platform of instant messaging as many people hope it will, but I
think it is less of a dead end than any other option I am aware of.

[IM Observatory]: https://xmpp.net/directory.php
[Communications platforms]:/blog/2013-08-11-communications-platforms/
