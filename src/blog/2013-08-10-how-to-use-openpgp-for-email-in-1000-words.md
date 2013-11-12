title: How to use OpenPGP for email, in 1000 words
date: 2013-08-10 23:40:05 +03
tags: privacy, internet-standards
----

[OpenPGP](https://en.wikipedia.org/wiki/Pretty_Good_Privacy)
 is a standard format for private and signed digital messages. It can
be used on its own or inside other formats, for example email. GPG is a 
[free](https://www.gnu.org/philosophy/free-sw.html)
program to create and open these messages. The following is a story of how
Alice and Bob and used GPG. It is intended to serve as a concise guide
to help you start using OpenPGP yourself.

I do not explain the vast variety of different ways to use OpenPGP here.  Many
guidelines in this document are just based on my personal taste, doing
otherwise is sometimes fine too. You are welcome to experiment, but please
create a separate keypair for that.

Also, the mathematics that make OpenPGP work are not covered. When I say here that
something is impossible, I mean that even if somebody employed all the world's
computers to do it using today's mathematics, it would, with overwhelming
probability, take long enough for us and everybody we know to be long gone.

> One day Alice decided that she has had enough of governments and companies
> reading her email: she downloaded and installed GPG
> (which is probably already installed in Linux; download:
> [win](http://www.gpg4win.org/)
> [mac](https://gpgtools.org/index.html)
> [other](http://macgpg.sourceforge.net/))
> together with
> [Thunderbird](https://www.mozilla.org/en-US/thunderbird/)
> and
> [Enigmail](http://www.enigmail.net/download/index.php).
> Even though there were three separate things to download and install, they
> made up one thing for her to use.

> She opened Thunderbird, entered her email details, picked OpenPGP from the menu
> bar and started the Setup Wizard. After clicking through some questions with
> default settings, she chose to create a new keypair as she didn't have one yet.
> She chose a good random English sentence as her passphrase: `On May 2, 1991, I
> didn't bug a yellow hill for $2`. She also generated a revocation certificate,
> printed it out and put it into the box where she stored old family photos in
> case her laptop was stolen.

Every OpenPGP user has a keypair: a secret key and a public key. The secret key is
stored in their computers and protected by a passphrase. It is used to open
private messages sent to you and sign your messages so that others can be sure
that these messages are from you. The public key is only called a key because
it is mathematically related to the secret key, it doesn't open anything. It is
actually similar to an open padlock: using a public key, you can encrypt
a message so that only the owner of the corresponding secret key can open it.
The public key is also used to verify signatures. A public key can not be used
to open messages, create signatures or compute the secret key.

> To share her public key, Alice opened the key management window from
> Thunderbird's OpenPGP menu, searched for her own name, selected her key and
> uploaded the public part to a keyserver using the relevant item on the menu bar.
> She also looked up her key fingerprint by right-click on her key and choosing
> `Key Properties`. She put this string of 32 gibberish digits on her
> business card, next to her email.

Fingerprints are what people use to refer to keys. Every public key has one
fingerprint; it is impossible to create two keys with the same fingerprint.

> Knowing that Bob already uses OpenPGP, Alice called him and told him her key
> fingerprint. Bob searched for Alice's email on the keyservers (Thunderbird menu
> -> `OpenPGP` -> `Key Management` -> menu -> `Search for keys`), imported the
> corresponding key (click the box in front of the key, click next) and compared
> its fingerprint (Right click -> `Key Properties`) to the one Alice gave her: it
> indeed was the same key she was talking about.

Why did he check the fingerprint when he already had the key? And why did she
call him anyway, couldn't she just have sent an email?  Well, nope. Anybody
could have created a key, written Alice's email address on it and uploaded it
to the keyservers. Sending email from others' addresses is
[trivial](http://emkei.cz/) too, as it is with many other means with online
communication.

Alice called Bob because she knew Bob would recognize her voice and therefore
know that it's really Alice who is giving her the fingerprint, and he checked
the fingerprint to be sure that the key he had found is really the one Alice
wanted to give him. Being so careful may look tedious or paranoid, but it's
better done than not done. Unlike with real persons, if Bob had confused
somebody else's key with Alice's, he may very well have never noticed it -- the
impostor who created the look-alike key could have forwarded the emails he
received to Alice's real key so everything would have seemed just normal.
And the impostor wouldn't even have had been a real person --
such trickery is most routinely done automatically to find sellable information.

> Alice's call reminded Bob that he had to reply to an email from her. After
> re-reading that email, he clicked on Alice's email address on the from field
> and created a OpenPGP rule to encrypt and sign all his future messages to
> Alice.  He sent the reply and entered is passphrase to unlock his secret key
> for signing the message.

> Meanwhile, Alice had dug up the business card Bob gave him when they first met
> and imported the key whose fingerprint was on the card, just like Bob did
> with Alice's key. When she received Bob's reply (and entered her passphrase to
> decrypt it) she saw a light blue ribbon telling her that this message has an
> `UNTRUSTED Good signature` from Bob. Untrusted, because she had forgot to tell
> her software that she had verified that the key really belongs to Bob. She
> clicked on the `Details` button on the right and chose `Sign Sender's Key` to
> make the ribbon light up in green, indicating a good signature by a verified
> key.

> But what was the message about? We don't know. It was encrypted and
> Alice didn't tell anybody. Most likely something mundane.
