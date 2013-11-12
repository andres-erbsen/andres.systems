title: Receiving mail without a proper SMTP server
date: 2013-08-07
tags: pi, hack, shell, internet-standards
----

After hearing that [CACert] offers free server SSL certificates, I just
had to get one for myself to. The procedure is quite simple: after the
usual fill-next-agree-email signup process, you can add domains by
proving that you can receive email sent to `root@yourdomain.tld` and
have certicates issued for them.

In normal cicumstances, I guess receiving mail could be trivial, but I
had no mail server running on my Pi and no intention to get one either.
Mail servers are a mess. The protocol is so complicated that most
implementors get it wrong and end up with a long history of security
holes. The notable exception is [`qmail`] by djb, but it's decades old and
unmaintained by the author. Setting it up on a modern computer is not
straightforward.

The solution: `sudo nc -l 25` and type in the SMTP server responses
manually. Or if you already know what the server needs to send, automate
it:

	while : ; do (
	cat << EOF
	220 andres.tedx.ee ESMTP Postfix
	250 Hello www.cacert.org, I am glad to meet you
	250 Ok
	250 Ok
	354 End data with <CR><LF>.<CR><LF>
	EOF
	) | sudo nc -l 25; done

FYI, CACert actually connects twice: first to check that there indeed is
a SMTP server on port 25 and then again to actually send the email with
the confirmation link. Don't forget to decode the link from
`quoted-printable` before visiting it.


[`qmail`]: http://qmail.org/
[CACert]: 'https://cacert.org
