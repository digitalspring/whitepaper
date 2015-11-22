---
title: 'Digital Spring: Technical Whitepaper'
author: Simon Hirscher
date: |
  Work in progress
  (version {$gitcommit} from {$gitdate})

abstract: |

  Digital Spring is a software library that solves one of the crucial
  problems of the Snowden era: Private and secure data transfer, be it
  private text messages or status updates, file sharing or device
  synchronization. Nowadays, if Alice wants to send a message to Bob,
  she will use some middleman (e.g. Facebook, Dropbox, an email
  provider) to deliver the message. However, in this way, the middleman
  will also get to the see the message's content and metadata (who is
  talking to whom) and analyze it for his own (e.g. marketing) purposes
  and can hand it over to intelligence agencies. Digital Spring solves
  this issue and eliminates the middleman by establishing a direct
  connection between sender and recipient. The ensuing peer-to-peer
  (p2p) network thereby replaces the server-client model predominant
  today. Data transferred over this connection is encrypted end-to-end
  and, in the prototype, metadata obfuscation is achieved through the
  federated Tor network although another mechanism making use of the
  decentralized p2p topology might get implemented for the final
  version. Building upon this, a publish-subscribe paradigm is combined
  with a custom multicast algorithm, which is tailored to the use case
  of private communication, to allow for reliable and scalable 1-to-$n$
  data transmissions. While $n$ could theoretically be chosen
  arbitrarily high, in practice certain security promises aren't
  feasible for large $n$ and, in fact, don't provide significantly more
  privacy in these cases anyway, as is discussed in the text. Further
  care is taken to enable offline messaging, i.e. to make sure sender
  and recipient need not be online at the same time. Finally, ideas for
  future work involving $n$-to-$n$ conversations and a distributed
  key-value storage are presented.

bibliography: bibliography.bib
csl: harvard-imperial-college-london.csl
documentclass: book
header-includes:
  - \input{abstract.tex}
links-as-notes: true
toc: true
toc-depth: 1
---


Introduction
============

Status quo
----------

> For the first time, we have a microscope that not only lets us examine
> social behavior at a very fine level that we've never been able to see
> before but allows us to run experiments that millions of users are
> exposed to.
>
> -- *Cameron Marlow, Head of Data Science Team of Facebook,
>    2012*^[Source: @facebook-experiments, recited in
>    @engadget-on-facebook.]

The revelations by former government agent Edward J. Snowden have shown
that there is no shortage of problems when it comes to government
surveillance in general and the violation of whole countries'
souvereignity, people's privacy and companies' confidable intellectual
property in particular. However, looking more closely, they all boil
down to the same core issues that allow for this vast scooping of data
to happen in the first place. These are:

1. Missing overview and control over government agencies and
   intertwining of government agencies and big companies and service
   providers. This obviously can only be changed through politics.
2. The fact that technological infrastructure (cables / networks /
   routers and software services) is mostly in the hands of a few big
   monopolies and that both people and companies see no way around them.
3. Hardware and software security: Manufacturers willingly or
   unwillingly introduce backdoors that government agencies exploit. Due
   to 2.) these loopholes typically affect millions of devices and thus
   people.

It's also possible to look at these points from another, more
theoretical angle:

Data scooping can either happen at the sender, during the transmission
from one machine to the other or at the point of the recipient.

Scooping at the **point of the sender** or the recipient is mostly done
through backdoors in hardware and software (and sometimes even direct
access). This is a problem that cannot be solved in a general fashion,
though, as hardware and software can only be improved security-wise by
overseeing their production and making their behavior as transparent and
trustworthy as possible. In the software world this has a long tradition
in terms of open-source / free software licenses that allow anyone to
analyze the software's behavior and also improve it. As for hardware,
open-source blueprints have just begun to gain popularity as 3D printers
make or will make it possible for anyone to implement them.

**Transmission of data** in turn makes use of cables, routers and
networks that are in the hand of a few *network providers*. Intelligence
agencies exploit this fact by tapping in on the data streams at central
points of these providers' infrastructure – either with their consent or
without. Physically securing these networks or even putting them in the
hands of the people (e.g. as a mesh network) can only be achieved on a
political level, though.

On a higher level, however, transmission typically resorts to a
*software service provider*, like various email providers, Facebook,
WhatsApp and Dropbox, who act as a middleman in the following way: The
sender will pass his message usually in an unencrypted fashion to this
middleman who in turn will store the data and make it available to the
actual recipient. While the individual connections between sender and
middleman and middleman and recipient are usually encrypted to prevent
tapping of the physical network connections, a message is usually not
encrypted end-to-end (i.e. so that only the final recipient can read it)
and is instead handed over to the middleman in plaintext. It is thus at
the point of the middleman where intelligence agencies gain another
access point to the data^[An access point which is very convenient,
considering the individual connections on the physical network are
encrypted.] – again, either with or without the provider's consent.
Furthermore, the middleman might also be interested in the analysis of
the user's messages himself, e.g. for the purpose of advertising and
manipulation (see the initial quote).

<!-- The middleman then either knowingly or unknowingly falls victim to
data scooping or -->

Even if the message is encrypted beforehand (as in the case of
PGP-encrypted emails), the middleman (and, thus, intelligence agencies)
will still observe who is communicating with whom and, therefore, the
social graph. This information is usually called *metadata*, suggesting
that it is not as valuable as "actual" data, although intelligence
agencies mostly rely on exactly this data to analyze social behavior and
to assess the potential risk an individual poses. Indeed, studies have
shown that knowledge of a person's social network is already enough to
draw various conclusions about him, such as his sexual orientation.
[@gaydar]

The point, and our idea, is therefore to eliminate the middleman
completely and have the sender pass his message on to the recipient
directly. While the message will still traverse cables and routers that
are controlled by the network providers mentioned above, we thereby
remove one big possibility for data scooping. Additional measures such
as encryption and *onion routing* are then taken to obfuscate both
content and metadata of a message for a 3rd party tapping the cable.


The goal
--------

The end goal of Digital Spring is thus a software which allows the user
to securely transmit a message to others using the same software. Here,
"security" refers to:

1. Confidentiality: The message is encrypted such that only someone in
   possession of the decryption key (i.e. the intended recipient) is
   able to read it.
2. Forward secrecy: Each message is encrypted using an (ephemeral)
   session key derived from a long-term key in such a way that a 3rd
   party getting hold of the long-term key at some point in the future
   is unable to decrypt any messages of the conversation that were sent
   prior to the time of compromise. Additionally, compromise of a
   session key should allow the attacker to only decrypt the single
   message the session key was used for, not any previous or subsequent
   messages (for which different session keys were used). This is
   essentially a way to mitigate damages when a key is lost or
   cracked.^[Note that Digital Spring is primarily concerned with secure
   *transmission*, not *storage*. This means that forward secrecy of the
   transmission protocol doesn't imply any assurance as to whether or
   how long a plaintext message is stored on the recipient's computer.
   Also see the discussion on the moderncrypto.org [messaging] mailing
   list:
   https://moderncrypto.org/mail-archive/messaging/2014/001025.html.]
3. Anonymity towards a 3rd party: Any party *not participating in a
   conversation* is unable to find out who is talking to whom. Note that
   this is not the same as a recipient not knowing who sent a message.
4. (Anonymity towards the recipient of a message: It should be possible
   for a sender to distribute messages anonymously.)^[This is a
   long-term goal and we will focus on pseudonymity first, where the
   pseudonym is simply the sender's public key.]
5. Authenticity: The recipient of a message can be sure it was the
   sender who sent the message.
6. Deniability: The previous item notwithstanding and similar to oral
   communication, the recipient technically cannot *prove* to another
   party that it was the sender who sent the message. The sender can
   therefore deny authorship of the message.^[Note that deniability does
   not prove that a sender did *not* send a message, it merely removes
   one way (namely digital signatures) to prove (with very high
   certainty) that he *did*. Thus, this technical feature becomes
   obsolete in court if there is other reason to believe he authored the
   message, e.g. if the number of recipients is large and all recipients
   testify independently and convincingly that they believe a certain
   person to be the sender of a message.]

A software providing security features like these must necessarily be
open source, as only then will the user be able to fully trust it.

While the above list mainly deals with best-possible *technical*
security, real-world privacy requirements (guaranteeing that people
actually *feel* safe) must also be taken into account. In particular,
notice that a sender's notion of privacy and confidentiality changes
depending on the number of people receiving his message (compare e.g. a
private message to a status message sent to all friends on Facebook) and
on whether he selected those recipients himself (e.g. for a private
message) or whether it was the recipients who selected him, i.e. who
decided to subscribe to him or the communication channel he is using
(e.g. a blog, an online forum).

More precisely, in situations where the senders does not *hand-select* a
*small* number of recipients, he certainly expects confidentiality and
especially forward secrecy to hold to a much lesser extent. Meanwhile,
deniability and anonymity might remain equally relevant or become even
more important, especially in the light of whistleblowing. On the other
hand, the sender might also opt for authenticity of his messages, e.g.
if he is a person of public interest such as a politician. This,
however, is fundamentally at odds with deniability^[Let alone anonymity
which, by definition, can never be given if authorship of a message can
be established.], as will be illustrated in the following examples:

Consider the media quoting a person of public interest who then,
however, denies what he was quoted with saying. Without further proof,
authenticity of the quote can never be established or disproved with
certainty. It is thus deniable. To a reader of the media report this is,
however, not of particular importance. He is used to this back and forth
between claims of one party and denial of the other party. Moreover,
being just one among millions of other readers, he doesn't know the
person that was quoted personally, so his day-to-day life and actions
will also not critically depend on whether one or the other party is
telling the truth.^[Contrast this with Alice somehow sending a message
in Bob's name to his best friend Carl and playing a prank on him.]

Compare this to the situation of authenticated messages: Today, a status
message on a popular and verified Twitter account, say \@BarackObama, is
almost as good as a written and signed statement or one recorded on
video: People will usually not doubt it was Barack Obama who authored
the message. (In turn, they will automatically doubt the authenticity of
a second Twitter account \@Barack_Obama.) While this authenticity
towards his audience is exactly what Barack Obama wished for, it also
prevents him from being able to deny any of the messages sent through
his account.^[Unless there's good evidence that his account was hacked.
He might also claim his press spokesman played a prank on him.]

Therefore, it seems there is a basic trade-off to be made between
authenticity and deniability with respect to a large group of
recipients: Unless there is a signature (or a audio / video tape) to
convince the audience of the authenticity of a message, the sender will
have a hard time proving his authorship to all recipients (in turn, he
will be able to deny it very easily). The crucial reason for this is
that, as he doesn't meet all recipients personally, the proof of
authenticity must be something that can be passed along with the message
from one recipient to the other and cannot be forged. Such a proof,
however, would then automatically prevent deniability as the latter
relies exactly on the fact that the proof could have been forged. Only
in private communication, e.g. oral conversations or hand-written
letters, immediate proof of authorship is (more or less automatically)
provided to all participants and it's only in personal conversations
where this proof, namely personal presence, is also ephemeral such that
it stills allows for deniability.^[In this sense, the (authenticated)
Diffie-Hellman key exchange, which is used to provide authenticity and
deniability at the same time, is the digital equivalent of a real-life
meet-up where secrets are being exchanged.] This insight is central to
many of the security considerations discussed in this paper.

Digital Spring is primarily concerned with private communication and the
transfer of private data, thus with data exchange among small to
middle-sized groups, up to a few thousand people. Drawing on the
previous examples, this could be restated as follows: Digital Spring is
a medium that allows for digital communication that is as close to
in-person conversations in terms of privacy implications as that is
possible. Although its principal architecture was designed in a way to
scale to very large groups just as well – if certain security promises
are given up where it makes sense^[As demonstrated, it is impossible to
fulfill authenticity *and* deniability for large audiences at the same
time. However, when it comes to large audiences with *either*
authenticity *or* deniability and even some mixed forms (where a group
of journalists attending a press conference cannot prove the
authenticity of a quote to their readers although they heard it loud and
clearly), the technology presented here covers these cases very
naturally.] –, the present paper focusses on the primary goal outlined
above.

<!--
Current State of Communication Systems
======================================

- Abgrenzung von TLS, welches Übertragungswege ganz allgemein sichert.
  - requires certificate agencies to solve the issue of key exchange =>
    compromised as well
-->


Architectural overview
----------------------

The proposed software is made up of several layers which build upon each
other and which are outlined in the coming chapters. It is attempted to
present the reasoning behind design decisions in the order in which the
corresponding questions naturally appear instead of following a more
formal approach where the results and decisions are presented first and
are justified later.

The layers and their corresponding functions are:

- Distributed Hash Table (DHT) layer: Provide a searchable data
  structure (namely a key-value store) which is distributed among all
  peers. Its primary purpose is ID resolution, i.e. finding the current
  IP address a peer can be reached under, given his ID.

- Unicast: Establish 1-to-1 connections between peers that are online.

- OfflineUnicast: Send short messages (e.g. notifications) to peers that
  are offline. The messages are stored in the DHT in a queue data
  structure such that they can be retrieved later by the recipient.

- Multicast: Provide efficient and (almost) reliable 1-to-$n$ data
  distribution from a sender to a group of recipients, whether they are
  online or offline.

- BMulticast: Multicast with backup peers, i.e. add additional peers to
  a multicast group that won't be able to read the transmitted messages
  but will provide additional resources to the group, i.e. they help
  with message distribution and thus stabilize the group in view of node
  failures.

Before describing the layers in detail, however, the next chapter will
give a short overview of some of the core paradigms and considerations
that led to this architecture in the first place.


Preliminaries
=============

TODO Anonymity implications of directed vs. undirected messaging
----------------------------------------------------------------

<!-- TODO Move the text from the unicast/anonymity section here and
explain why undirected messaging will not be used. -->


The publish / subscribe paradigm
--------------------------------

### The client-server architecture

Today, the architecture of most internet platforms is based on a
client-server architecture: Instead of having clients exchange data
between each other directly, servers form the central entity clients
communicate with. More specifically, they might both receive data from
clients (like an email to send to another recipient), but also get
requests from them for contents and updates (e.g. web pages, new emails,
app updates). They are thus the base for federated and centralized
approaches to client-to-client communication and constitute the
middleman that was mentioned in the first part of this introduction.

Some reasons for the asymmetry that is the client-server architecture
are:

- Servers use to have larger resources (CPU, storage, bandwidth), so it
  makes sense to outsource tasks from a client's device to the server.
- Centralized algorithms are easier to design than distributed
  algorithms.
- Clients are not constantly online and change their IP addresses which
  makes direct client-to-client communication difficult. A server, in
  contrast, is online 24/7.

Being the predominant architectural model on the internet and for the
sake of simplicity, the rest of this section will introduce terminology
with the server-client model in mind although most terminology can
actually be decoupled from this model. Indeed, in the end, the
transition from a server-client architecture to peer-to-peer networks
will be made.

<!-- The server-client architecture has nothing to do with the polling
approach! -->


### The request / response paradigm

Intimately connected with the server-client model is the
*request/response* paradigm. In this mechanism, a client will first send
a request for a piece of data to which the server will then respond with
the piece in question. In particular, this enables client applications
to request data *on demand*, i.e. upon user interaction. The most famous
example here is certainly the web, where a click on a link (a user
interaction) usually initiates a connection to the web server and a
subsequent request for the web page in question.

<!--
TODO:
- Introduce the publish / subscribe paradigm in contrast to requests on
  demand
- Introduce polling / pushing as the two common approaches to implement
  pubsub
-->

### Polling

Closely related to the request/response paradigm is *polling*. In this
case, requests are continuously^[I.e. in regular time intervals.] sent
by the client to ask for the status of a server application. The
subsequent status response by the server might generally comprise any
kind of data and might be as simple as a single bit value where "0"
stands for "no updates" (to a certain dataset) and "1" signifies a
change. In the latter case, the client application might decide to send
a separate request to see what these updates actually are. This provides
the advantage that the data volume of the status (which is, after all,
sent through the wire in regular intervals) is kept as small as possible
and the actual (possibly big) dataset is only sent upon the client's
explicit request. Put differently, polling is combined with requests on
demand.

Examples for polling are email applications that ask the mail server for
new messages every few minutes, a mobile app that polls the thermostat
outside the house for the current temperature, and modern web
applications that use AJAX to automatically load new content, such as
the newsfeeds on Twitter and Facebook.

One important feature of polling is its continuity which implies that
the client doing the polling must already know beforehand that he would
like to have the data in question (e.g. the temperature as a function of
time). This is in contrast to spontaneous (e.g. user-initiated)
requests that ask for data on demand.


### Pushing

The opposite of polling is *pushing*. There, the client receives new
data automatically when it becomes available, i.e. without having to ask
for it. Similarly to the polling mechanism, this requires the client to
make the decision beforehand that he would like to receive the data in
the first place.

Examples for the push paradigm include IRC, Jabber/XMPP and the
Blackberry Push Service that allows Blackberry users to receive emails
without having to poll for them. In all cases, a steady connection from
the client to a server is maintained through which the server will send
incoming/new data as soon as it arrives. Moreover, with the WebSocket
standard allowing an ongoing and fully bidirectional connection between
a browser and a web server, pushing data has now also found its way into
web applications.

In the past years, the push approach has also seen much support in terms
of the Apple Push Notification Service and Google Cloud Messaging (GCM).
Both services provide a unified way for internet platforms to notify
their users on their mobile (iOS or Android) devices about new content
automatically. Strictly speaking, though, both services actually combine
pushing with requests on demand as only a notification gets sent and an
app on the client's device still has to request the actual data
after being notified.



### Polling vs. pushing

<!-- TODO: Distinguish between (random) requests for data that are
initiated by user interaction and continuous polling (waiting) for
updates -->

For mobile devices, the obvious advantage of the push mechanism is the
fact that connections to the server are only established when there is
actually new data to be sent.^[In the case of Apple Push Notification
Service and Google Cloud Messaging Service, only a single connection is
maintained.] In contrast, polling would have the device establish a new
connection to every platform in regular time intervals, which would
drain the battery.

Yet, the polling approach is still predominant on the internet mostly
due to three facts:

- Clients are not constantly online and change their IP addresses, so a
  server wouldn't know where to send updates to.
- Servers use to have larger resources (CPU, storage, bandwidth).
  Polling allows to put load on the clients only when they actually want
  to consume the data, in the sense that they can decide when (and
  whether) to poll.
- Adding to the previous point in the case of the world wide web, a
  client's requests for web pages are mostly unpredictable as he is
  surfing the web. It would therefore be impossible to push web pages to
  him before he wants to consume them. (This technique is usually known
  as *preloading*.)

However, polling also has downsides:

- Polling puts load on the client.
- By sending a request, a client gives away the information that he
  wants to consume a certain piece of data and thus behavioral patterns.
- If data is requested and received on demand, latencies due to data
  transfers might impact user behavior and ultimately spoil the user
  experience.
- Without caching, data is never available when the client is offline.

<!--


Lately, mobile platforms have seen hybrid solutions.


Explain how pub/sub can be used to build almost all platforms we have
today.

Introduce multicasting as a way to make pushing more efficient. Mention
that recipients organize in multicast groups – a persistent structure on
top of the p2p network that enables more efficient transmission of
multiple messages sent to the same recipients. -->


Offline messaging
-----------------

As discussed in the previous chapters, Digital Spring breaks with the
traditional server-client approach and lets peers communicate with each
other directly. Naturally, the question comes up how the peers are
supposed to do that if one of them is offline. As an extreme example,
consider Alice who would like to send a message to Bob but Bob is
offline whenever Alice is online and vice versa. Obviously, by the very
definition of "offline", there is no way for Alice to deliver the
message to Bob directly. To arrive at a solution, an analogy can be
drawn to physical mail delivery: If the mailman cannot deliver a package
because the recipient is not at home (or not answering the bell), he
will either

a) put it into the mailbox (assuming it's sufficiently small),
b) give it to a neighbor or
c) bring it back to the post office and either try it again the next day
   or put a note into the recipient's mailbox to notify him that the
   package is waiting for him there.

In all cases, there is a place that is accessible round the clock where
the package is temporarily stored until the recipient comes to pick it
up or the package is successfully delivered. This suggests implementing
such a storage place in digital messaging, too. Indeed, this is one of
the roles servers have always been playing in server-based approaches to
communication – think, for instance, of mail servers, Facebook et
cetera. Now, this is not to mean that a provider of such storage
capabilities must necessarily take on the role of the intrusive
middleman that Digital Spring set out to eliminate. In fact, it is the
very goal of this project to implement the crucial feature of offline
messaging in a privacy-preserving manner. While this presents a
challenge in so far as p2p networks lack a natural place to store
messages temporarily, two options come to mind quite generally:

1. A peer could designate another peer to be his *mailbox* and announce
   this fact to all peers he communicates with (even directly or through
   an entry in the DHT). He would then always poll his mailbox for new
   messages after a having been offline for a while. However, as the
   peer providing the mailbox would certainly be offline at times, too,
   this would just only improve the offline availability statistically.
   To increase it even further, one could consider using several peers
   for a mailbox at the same time.

2. The sender could designate a peer who he forwards the (encrypted)
   message to and who he asks to deliver it to the recipient as soon as
   he comes back online. For the remainder of this section, this peer
   will be called a *mailman*. Clearly, the mailman might be offline at
   times, too, so once again, it'd make sense to have several peers
   share this responsibility.

In both cases, the question comes up how to choose the respective peers
and why they in turn should be willing to provide mailbox / mailman
functionality to other peers in the first place, considering that this
requires both traffic and storage resources. Again, there're multiple
options:

- The peers hosting a mailbox or acting as a mailman could be selected
  from the list of the peer's friends. This would have the advantage
  that friends are naturally inclined to help each other, so it should
  be comparatively easy to convince a user to share resources (traffic,
  storage) with his friends – as long as he is not put at a disadvantage
  and his friends do the same for him.

  Unfortunately, though, this approach also entails giving away part of
  the peer's social graph:

  In case of using friends as mailboxes, the peer would need to tell
  everyone, who he is in contact with, about these friends. His friends,
  in turn, will know who authored incoming (encrypted) messages, hence
  who the peer is (likely) communicating with.^[In all these cases, what
  is meant by "knowing a peer" is meant "knowing the identifier or IP
  address of the peer". This may or may not be a datum that is of actual
  value to the peer possessing it.]

  In the second case, where a peer's friend acts as mailman, delivering
  the peer's messages means these messages would be routed through him.
  Since the mailman would need to know who to deliver the message to,
  he'd again end up knowing know who the peer is in touch with.

  Finally, making the social graph an ingredient of the network topology
  might also mean that a passive (global) eavesdropper gets to observe
  this exact social graph as a peer frequently connects to his (closest)
  friends after an offline period.

  In all cases, these problems might be tackled by means of onion
  routing / obfuscating the identity of all peers (i.e. senders and
  recipients of messages and friends / mailboxes / mailmen).

- The peers providing mailbox / mailman capabilities could offer their
  service in exchange for a fee. Similarly to the previous option, this
  would result in them knowing who the peer is communicating with
  (unless further obfuscation is employed). This data could then also be
  connected with payment data.

- The peers could be selected randomly. Privacy implications are roughly
  the same as for the previous option with the exception that no payment
  data is available this time. The question remains, though, why peers
  would want to provide storage and traffic resources to other peers in
  the first place.

Clearly, the last option is the best in terms of costs and privacy
implications (provided that onion routing is used) but at the same time,
it lacks the necessary incentives.

<!-- TODO: Move this to one of the previous sections (or create a new
one) to make the distinction between non-directed (broadcast) and
directed messaging (unicast/multicast). (Actually, the section on
anonymity in the unicast chapter already discusses exactly this. It
might make sense to move it up.)

For the purposes of completeness, another option that hasn't been
mentioned so far will briefly be discussed: Consider again the
introductory example of Alice who wants to send a message to Bob. It was
assumed so far that Alice's message would have to take a more or less
direct path to Bob. (Even onion routing would merely add a detour to
this path.) There is, however, the option of simply broadcasting the
encrypted message to all peers in the network and hoping that it will
reach Bob.
-->

Now, it turns out that the privacy implications *due to offline
messaging*, i.e. the fact that mailbox / mailman providers get to
observe a peer's social graph, can be reduced to a minimum without a
*separate* layer of onion routing.^[Note that preventing a global
eavesdropper from learning about a peer's social graph by observing who
he connects to on a TCP/IP level will probably still require onion
routing. See the section on [anonymity][unicast-anonymity] of
[unicast][Unicast layer].] Moreover, multicast groups provide incentives
for peers to share storage and traffic resources with each other.

<!-- TODO Rewrite the following -->

It turns out, though, that further options exist that arise from Digital
Spring's specific architecture.

To assess those options carefully, it seems in order to first give a
short introduction to how Digital Spring delivers a message, which will
be elaborated on in later chapters. As mentioned earlier, Digital Spring
follows the pushing paradigm where a sender tries to transmit the
message to the recipients immediately.^[This is not only the natural
approach in a p2p network – in contrast to, e.g., having a peer poll
other peers continuously for whether they have any new messages for him
– but is also the most effective in the sense that data reaches a peer
as soon as it becomes available, not when he asks for it. Indeed, this
makes it possible for the peer to read a message later when he is
offline – provided, of course, he was online at the time the message was
sent.] Furthermore, recipients organize themselves in persistent
*multicast groups* which facilitate continued data transmission to the
same group of people. More specifically, members of a multicast group
help each other -->

<!--

- Explain how we multicast group largely solve the problem of incentives
  and resource sharing without any implications for privacy; possibility
  to extend this by adding backup peers to the multicast group (it might
  be difficult, though, to protect metadata then – especially if
  metadata is connected with payment data; *if* it's possible then such
  dead drops could be run by everyone similar to Tor nodes)
- 2 problems then:
  - How to notify Bob that a new message was sent to a group while he
    was offline? -> Polling not an option, considering he might be a
    member of thousands of groups.
  - What about the 1-to-1 case.
- Solution: Ability to store small messages in the DHT. (Use this for
  notification and (small) 1-to-1 messages)

-->



Current status of this paper
----------------------------




Distributed Hash Table (DHT) layer
==================================

Outline
-------

Digital Spring's technological foundation is a structured peer-to-peer
(p2p) network. Here, "p2p" refers to the fact that peers communicate
directly over the internet without requiring the usage of a middleman /
a central platform. "structured" means that peers do not connect to
arbitrary peers to stabilize the network but follow a certain geometry
as well as employ routing to distribute data efficiently. A distributed
hash table (DHT) is a key-value store that is distributed among the
peers of the network. It provides the essential tools to find peers and,
more generally, allocate and find resources on the network in a
structured manner.


Introduction
------------

On the internet, devices are usually identified by their (ephemeral) IP
addresses. However, a long-running p2p network such as ours has to
introduce a permanent identifier to be able to address the same peer by
the same ID even after some time has passed (and he has potentially
changed his IP address). While identifiers can – a priori – be of
arbitrary form, our goal of secure transmission (see above) makes it
inevitable that all peers be identified by their public keys in this
network.^[The underlying reason for this being that the authenticity of
a peer is usually verified by public/private key cryptography.] In this
sense, a public key *is* a peer's identify in the network.^[This already
has significant impacts on every possible user interface: Users
connecting with each other for the first time must be in possession of
each other's public key. In addition, "logging in" with an identity
means restoring the key pair from a backup.] In this way, the software
must also be able to translate a peer's public key back into the IP
address (or any other reachable network address – depending on the
underlying transport). This is done by means of a distributed hash table
(DHT).^[For a promising approach in our scenario of secure
communication, see @R5N, for a whole p2p network layer building upon the
latter see @CADET.] In short, a distributed hash table is a database
containing key-value pairs which are distributed among all peers such
that each peer stores only a small part of the database. Various
algorithms exist then to allow a peer to find and access any entry in
the database, even if it is stored with another, previously unknown peer
in the network. Usually, this is achieved by introducing a metric on the
common space of peer IDs^[These are not the identifiers mentioned
earlier, as will be explained below.] and keys and have a peer store a
routing table that contains other peers close or far away from him in
this metric. Then, to find a key and retrieve its associated value the
request is routed to the peer whose ID is closest to the key and who is
responsible for storing the value.

Elaborating on the way peers are identified, it is important to
distinguish between the ID of a peer on the DHT level and his ID on
upper layers. The DHT identifier's purpose is to establish an overlay
geometry among the peers and to enable routing in this geometry. It is
this ID that lies in the same space as DHT keys. In contrast, the IDs on
upper layers which were discussed in the beginning of this section and
which will be referred to as *user IDs* in this chapter represent the
user's preferences with respect to privacy. As will be discussed in
later chapters, the user might have several user IDs to take different
identities in different contexts, whereas he will usually have just one
ID on the DHT level, as the latter serves a purely technical purpose.


Bootstrapping
-------------

Since a p2p network lacks a central infrastructure participants can
automatically connect to, a mechanism must be provided to help peers
find other peers in the network when they connect to the network for the
very first time or after a temporary loss of connection.

To this end, each peer will store the routing table on disk such that
he's able to connect to his DHT neighbors again after a loss of
connection. For cases when the routing information has become
stale^[I.e. the peers in the table aren't reachable under the given IP
adresses anymore because, for example, the peer in possession of the
routing table had been offline for a long time.] or the peer connects to
the p2p network for the first time, he also stores a number of directory
servers from which he can then request a list of peers.


DHT algorithm
-------------

There are a number of DHT algorithms, including Chord, Tapestry and
Kademlia [TODO Insert references]. So far, it hasn't been decided which
algorithm will be used for Digital Spring. This is also due to the
unique constraints the project faces: Namely, given today's trends, a
large fraction of peers will be mobile clients that not only have
limited storage and battery life but also produce a high churn in the
network as they switch from one mobile network cell and one IP address
to another. Therefore, further research needs to be done.


Key features
------------

Independent of the exact DHT algorithm, the DHT layer needs to provide
several key features which will be important for upper layers and mostly
deal with security and access control, e.g. read and write protection of
entries in the DHT and their authenticity, and data structures such as
queues.


### Write protection and authenticity

In p2p networks whose DHTs are used to store content and make it
available to all peers, e.g. file sharing networks, DHT keys are usually
hashes of their associated values. In this way, once set, values cannot
be modified anymore and a peer requesting the value associated with a
DHT key just needs to compute the hash to make sure the value he
received is authentic. Put differently, the key cannot be set
arbitrarily but depends on the value. It must also be ḱnown to every
peer requesting the entry beforehand.

<!-- However, as Digital Spring follows a publish/subscribe approach rather
than one that is request-based^[See the chapter on the [multicast
layer].], it only employs the DHT to find resources (and peers) on the
network.
 -->

However, this is incompatible with the requirements imposed upon the DHT
by upper layers. Namely, a peer must be able to freely choose the key
but, at the same time, the DHT should still guarantee the authenticity
of its value.

As discussed before, the peer's identity is encoded in terms of a key
pair. Hence, the private key can be used to sign DHT values authored by
the peer and prove their authenticity. To further remove the requirement
that a key must be known beforehand^[I.e. the key would need to be
announced by the author of the DHT entry beforehand.], the author can
(but certainly doesn't have to) choose a generic name for the key to let
other peers find it easily. However, in order to avoid key collisions if
several peers choose the same generic key, the public key's hash will be
prepended to the key. To summarize:

~~~~~~~~~~~~~~~~~~~~~
key = hash(public key) || (user-chosen key)
value = signed(user-chosen value)
~~~~~~~~~~~~~~~~~~~~~

By contract, only the owner of the private key will be allowed to set a
value for any key starting with his public key's hash. (He will
therefore be called the *owner of the DHT key* in the following.) In
case the peer responsible for storing the DHT entry is malicious and
doesn't follow this convention but lets anyone set a value for a key,
peers requesting the key will be able to detect the malicious behavior
due to a wrong signature.


### Read protection

Read protection can be accomplished by encrypting an entry's value
either symmetrically or asymmetrically, depending on the use case.


### Queues

As will become clear in later chapters^[See the chapters on unicast and
multicast.], the DHT layer must provide a mechanism to associate a DHT
key with a queue data structure such that peers are able to store items
in the queue and retrieve them. Borrowing from UNIX file permissions,
there're two use cases to be distinguished:

- *U+W, O+R*: The creator of the queue, i.e. the owner (U) of the DHT
  entry, writes (+W) items to the queue for others (O) to read (+R). In
  this way, the queue is basically a 1-to-$n$ distribution mechanism. A
  peer will use this to make authenticated ephemeral Diffie-Hellman
  public keys available to other peers beforehand in case he is offline
  later.^[See https://whispersystems.org/blog/asynchronous-security/ for
  a more detailed explanation in the slightly different context of
  asynchronous client-client communication through a server.]

- *U+R, O+W*: All peers (O) are allowed to store items (+W) in the queue
  which the owner of the queue (O) will retrieve (+R) later. That way,
  the queue achieves $n$-to-1 message collection. This will later be
  used to store small (notification) messages for a peer in the DHT, in
  case he is offline.

In all cases, read protection – if necessary – will be accomplished
through encryption. Write protection will again be enforced by contract
and through signatures.

<!-- A distributed queue, just like any other message distribution
mechanism, usually has to deal with problems with respect to ordering,
reliability and synchronization. Fortunately, though, in our cases the
requirements are comparatively low:

- *U+W, O+R*: At-most-once delivery is desirable but not strictly
  necessary as delivering a prekey / DH public key more than once would
  simply increase the value of the private key. Ordering not critical.
- *U+R, O+W*: At-least-once delivery desirable; ordering not important.

Unfortunately, the exact algorithm for storing a queue in the DHT is out
of the scope of this paper. The reader is referred to [TODO Insert
reference] for one possible approach.

 -->


Security
--------

### Confidentiality, forward and future secrecy

Confidentiality on the transport level (i.e. between peers participating
in the DHT) is accomplished by a agreeing on a shared secret through a
Diffie-Hellman key exchange, from which a session key is then derived
that is used to encrypt transmitted data.^[In the following, it is
assumed that the reader is familiar with how a Diffie-Hellman key
exchange works.] Since the session key is ephemeral, i.e. a new key is
generated for every new connection and connections are generally
short-lived, forward and future secrecy are also guaranteed in this way.


### Authenticity

To prevent man-in-the-middle attacks when to peers connect to each other
it is also necessary to authenticate the ephemeral Diffie-Hellman public
keys, that are being exchanged, through some static public keys of the
involved parties.

However, on the DHT level, the notion of authenticity is a different one
than on other levels since the DHT has a purely technical purpose and
connections between peers on this level don't reflect social relations
between them. In particular, peers don't know each other's public keys
beforehand (which could then be used to make sure they're talking to the
right party). Rather, in a typical DHT operation like a key request,
Alice will connect to a peer Bob and will expect Bob to have a specific
DHT ID $x$, e.g. an ID that is closer to the key Alice is requesting.
Therefore, it is the DHT ID that is known beforehand. Now, to prevent
man-in-the-middle attacks and authenticate the static public keys, it
makes sense to bind Bob's DHT ID to his static public key and define it
to be the public key's hash. Then, by computing the hash of the public
key Bob announces to her, Alice can make sure this public key indeed
belongs to the peer with the DHT ID $x$.^[Using static, random DHT IDs
like these that do not depend on geographical information (e.g. IP
addresses) has additional advantages: 1. It makes it harder for
malicious peers to control a significant part of the DHT only by
positioning themselves in the respective geographical area. 2. At the
same time, the network becomes more failure-resistant against outages in
a some part of the world as they won't necessarily result in a loss of
DHT entries (assuming sufficient replication of DHT entries). 3. Mobile
clients, who change their IP addresses often, don't change they DHT IDs
so can still use their previous routing tables after switching cells or
recovering from a connection loss.] The situation is then very similar
to a client establishing a TLS connection to a server^[Of course, the
server's certificate (public key) is not verified by means of a
previously known hash but by following the chain of certificates back to
a trusted authority.]. As this is a solved problem, protocol details are
not discussed any further at this point and the protocol will try to
stay as close to the TLS protocol as possible.

<!--
<KEY AGREEMENT PROTOCOL PART 1/2> (Hidden because only Chuck Norris
rolls his own key agreement protocol)

To summarize: Alice ($A$) will connect to Bob ($B$), receive Bob's
public key and verify its hash, and then announce his own public key to
Bob, together with an ephemeral Diffie-Hellman public key<!- - and a
session token- ->, in a message that is encrypted with Bob's public key.
Bob can then decrypt the message and will reply with his own ephemeral
Diffie-Hellman public key<!- - and the session token- -> and encrypt the
whole message with Alice's public key. As soon as Alice receives the
message, the authenticated Diffie-Hellman key exchange is complete.

</KEY AGREEMENT PROTOCOL PART 1/2>
-->

<!--
<DEPRECATED>
(The following is deprecated because we don't need a session token
(Alice's ephemeral DH public key already serves as one, see below.))

The session token serves the following purpose: As $B$ doesn't
necessarily know $A$'s DHT ID beforehand, $A$ cannot authenticate
towards $B$ initially. Therefore, an active attacker could exchange
$A$'s key announcement message on its way to $B$ with his own message
(and his own public key), without $B$ noticing. Then, the attacker would
be able to decrypt $B$'s reply and replace the ephemeral DH public key
inside, before forwarding it to $A$. He therefore would've launched a
successful MITM attack on the key exchange protocol.

With a session token being sent back and forth, however, $A$ would
notice the attack as soon as he receives the reply from $B$: As the
attacker didn't know the session token, the malicious message he sent to
$B$ must have contained some other, wrong session token and, therefore,
$B$'s reply to $A$ will also contain the wrong session token. Hence, $A$
will notice the attack and abort the key exchange immediately.
Similarly, if the attacker were to intercept only $B$'s reply on its way
to $A$ (which he cannot decrypt as he doesn't know $A$'s private key),
he could replace $B$'s message with his own one and replace the
ephemeral DH public key inside. Again, a session token would give this
away.

</DEPRECATED>
-->


<!--
<KEY AGREEMENT PROTOCOL PART 2/2> (Hidden because only Chuck Norris
rolls his own key agreement protocol)

While an attacker could intercept and exchange these key agreement
messages sent from $A$ to $B$ and from $B$ to $A$ in an arbitrary
fashion, he will never be able to know Alice's ephemeral Diffie-Hellman
public key as $A$ encrypts it first before sending it. Therefore, if
Alice receives a messages that is encrypted (and MAC'd) with the correct
shared key (a key that is derived from her ephemeral DH public key), it
must have necessarily been authored by Bob, who is the only other person
who she gave her ephemeral DH public key to. If any message is not
encrypted with the correct key, Alice will reject it, notify Bob and
close the connection.

To make this more concrete, consider that, as soon as Alice and Bob
start encrypting their communication with their shared secret, one of
two things can happen:

- The attacker replaced Alice's initial DH key exchange message to Bob.
  In lack of Alice's ephemeral DH public key, Bob will therefore arrive
  at the wrong shared secret which he will encrypt his messages to Alice
  with and which Alice will notice. (Additionally, the attacker could
  also exchange Bob's messages to Alice but the messages that reach
  Alice in the end would still be encrypted with the wrong shared
  secret.)

- The attacker didn't replace Alice's initial DH key exchange message to
  Bob. Bob is therefore in possession of Alice's ephemeral DH public key
  and will encrypt his messages to Alice with the correct shared secret
  which the attacker will not be able to break. (Replacing Bob's
  messages to Alice will again lead to encryption with the wrong shared
  secret which Alice will notice again and notify Bob about.)

Obviously, when it comes to the notification message, the attacker could
also intercept it so that it doesn't reach Bob. But this doesn't provide
any benefit to him as any transmission of critical data (e.g., for a key
request, the key in question) on the DHT level is always initiated by
Alice: If her key request (encrypted with a shared secret derived from
her ephemeral DH public key, thus unbreakable for an attacker) gets
through to Bob, Bob will be able to decrypt it and, in turn, encrypt his
reply (the key and its associated value) with the same shared secret
that the attacker is not able to break. If the key request doesn't get
through, Bob won't reply with any critical data in the first
place.^[Here, by critical data, we mean data that is critical to Alice.
As Bob didn't know Alice previously, he doesn't have any interest in
sending her data that is critical to him, anyway.] In this sense, any
transmission of critical data is always linked to Alice's ephemeral DH
public key, which plays the role of a session key that only Alice and
Bob know about.

</KEY AGREEMENT PROTOCOL PART 2/2>
-->


<!--
<DETAILED KEY AGREEMENT PROTOCOL> (Hidden because only Chuck Norris
rolls his own key agreement protocol)

The above scheme can be simplified slightly by using Diffie-Hellman
public keys as static public keys, see
https://en.wikipedia.org/wiki/Diffie%E2%80%93Hellman_key_exchange#Public_key

The scheme:

Let (g^B, g, p) be B's static public key whose hash A can verify. A in
turn has the static public key (g^A, g, p). B and A also have ephemeral
DH public keys (g^a, g, p) and (g^b, g, p) respectively.

A connects to B.

B sends g^B.

A verifies hash(g^B) == DHT ID.

A sends: g^A || ENCRYPT&MAC(KDF(g^AB), message), where message = g^a
[Alternative: A sends: g^A || ENCRYPT&MAC(KDF(g^AB), msg=g^a || <session
token>) ]

B replies: ENCRYPT&MAC(KDF(g^AB), message), where message = g^b
[Alternative: B replies: g^b || ENCRYPT&MAC(KDF(g^ab), msg=<session
token>) ]

…and the key exchange is complete.

The attacker could intercept / exchange the messages A->B and B->A.
However, in this way, he could at most know g^b and replace it with g^b'
and replace (but not know!) g^a. Without g^a, though, he will never be
able to generate the correct ephemeral secret key g^ab (or g^ab') that A
will expect to be used when communicating with him.

</DETAILED KEY AGREEMENT PROTOCOL>
-->



### Metadata obfuscation and deniability

<!-- In this sense, the only purpose of the encryption and authentication
scheme for individual connections that was discussed earlier was to make
it difficult for a global eavesdropper, whether passive or active, to
observe how key requests are being routed through the network. With
encryption and authentication in place, he is forced to actively
participate in the network. -->

While confidentiality and authenticity of connections on the transport
level have so far been discussed extensively and prevent eavesdropping
by an attacker outside of the p2p network, an attacker could also decide
to actively participate in the network and the DHT mechanism.

More specifically, on the DHT level, peers don't send personal
information intended for a specific (trusted or known) peer but they
merely exchange routing information and key requests with arbitrary
peers that they don't necessarily trust in the first place. The
challenge therefore consists of not giving away any personal information
to any peer through key requests (e.g. who is asking for which key),
especially when there's a large number of malicious peers.

This can only be achieved in the following way: Consider that a key
request by Alice will, in most cases, not immediately reach Carl who is
responsible for the respective part of the DHT and is in possession of
the value associated with the key. This is because Alice only knows a
limited number of peers and will simply try to find a peer as close to
the key in question as possible. Therefore, Alice might send her request
to another peer Bob (whom she knows), first, who then forwards it to
Carl. Alternatively, Bob might also simply tell Alice about Carl, so
that she can connect to him directly. However, in this way, she will
give away to both Bob and Carl that she is looking for the key. It is
therefore desirable to have Bob forward the request to Carl, so that
Carl will not know about Alice. In fact, Bob cannot be sure the request
originated from Alice, either, as she might in turn be relaying the
request for someone else.^[This of course assumes that her DHT ID is not
too far away from the key because then it'd be very unlikely for her to
relay someone else's request for that key. To solve this, Alice could
choose the first relay in the chain randomly, so that the distance of
the first relay to the key becomes random, too, and the potentially
large distance of Alice to the key doesn't give anything away to Bob.]

As it takes $O(log(n))$ steps for Alice to find Carl with most DHT
algorithms, the ensuing chain of relays should protect Alice's metadata
(i.e. the fact that she is looking for the key) sufficiently from any
peers participating in the key-finding process.

This may of course not hold if the attacker has enough resources to run
a significant number of peers in the network, such that most of the
peers in the relay chain will belong to him and he will, in general, be
closer to Alice in the chain. (Such that it is more likely that the
request indeed originated from her.)

Another open problem concerns the fact that a global eavesdropper might
be able to follow the chain from Alice to Carl and infer, by connecting
to Carl and asking him for his DHT ID, approximately which key Alice
requested. (As mentioned, in most DHT algorithms, the key will be close
to Carl's DHT ID.) The situation would be even worse if Carl himself
participated in the the attack, too.

While these are valid issues, it is commonly known that the larger the
resources of attacker, the more dangerous he will generally be to the
security of any public distributed algorithm. While we hope to be able
to provide counter measures for the DHT in the future, it is not the
current focus of this whitepaper.


<!--
TODO (Byzantine) Failure resistance
-----------------------------------
 -->


Unicast layer
=============

Outline
-------

The unicast layer is responsible for setting up secure 1-to-1
connections between peers that are online at the same time.

<!--
On a more technical level, since payload transmission (e.g. sending of
text messages or files) is done by upper layers and several of such
transmissions might happen at the same time, the unicast layer must also
multiplex each connection to a peer in order to allow for multiple
(virtual) connections at once.
-->


Establishing a unicast connection
---------------------------------

Consider Alice who wants to send a message to Bob who is identified by
his peer ID (public key) $b$. To establish a unicast connection to him,
Alice will look up the IP address associated with the key $b$ (or some
hashed version of it) in the DHT. Bob updates this DHT entry to his
current IP address periodically as long as he is online. Assuming Alice
could find the key^[DHT keys aren't stored indefinitely but have a time
to live (TTL).] and Bob can still be reached under this IP, Alice will
then establish a direct TCP connection to Bob^[In case Bob is behind a
NAT, this is obviously more delicate and some kind of NAT hole punching
has to be used.] and is ready to transmit data to him.


Security
--------

### Confidentiality, forward secrecy, authenticity and deniability

Confidentiality on the unicast layer is achieved through end-to-end
encryption of data before it is transmitted over the physical network.
To this end and to provide forward secrecy, peers agree on ephemeral
session key by doing a Diffie-Hellman key exchange that is authenticated
by their respective public keys. These public keys are assumed to be
known prior to establishing a connection, so that trust in the session
keys can be chained back to the trust in each other's public key.
However, while both parties can be sure about the respective other
party's authenticity when receiving a message, by virtue of the
Diffie-Hellman key exchange, no party can actually prove to someone else
that the other party authored the message. In this way, deniability is
accomplished.


### Anonymity {#unicast-anonymity}

Direct data transmission between devices on the internet always exposes
their IP addresses (and, therefore, potentially their identity and
approximate geo location) to a 3rd party having access to the cables and
routers that their message passes. A p2p approach to secure
communication presents a particular challenge in this regard as both
endpoints of a data transmission always correspond to the actual sender
and recipient, so that the metadata of the message, i.e. the fact that
both parties are communicating with each other, is directly exposed to
the 3rd party. (This is in contrast to a centralized or a federated
model where one of the endpoints is the middleman / server, hence the
final recipient (or original sender) of a data packet can only be
determined by studying correlations between in- and outgoing connections
of the server or tapping the server itself.) While it might be argued
that intelligence agencies will certainly not have access to relevant
cables or routers in every case (especially when sender and recipient
are geographically close to each other and their data is not crossing
any central point of the internet infrastructure such as a backbone),
this is certainly not something to rely upon and care must be taken to
obfuscate the metadata.

Generally, there are two ways here:

1. Send the (encrypted) message towards the intended recipient but have
   it traverse other peers first who do not participate in the actual
   conversation, thereby hiding from the 3rd party monitoring the cable
   who is actually talking to whom. This approach is usually called
   *onion routing* and was made famous by the [Tor
   project](https://torproject.org) which currently seems to be the most
   widely spread and reliable (federated) network in this regard. As
   always when such "hopping" is done, particular care must be taken to
   prevent timing-based attacks from a 3rd party with extensive
   resources. In a p2p environment, in contrast to a federated network
   like Tor, this is particularly difficult as the average peer
   participating in the network might not forward enough messages in a
   certain time frame to make it impossible for the 3rd party to track
   one particular message, i.e. for the message to get lost among all
   the other messages. One way to address this might be to also send
   *decoy messages* to fake recipients.

2. Have peers distribute and forward messages randomly to their
   (arbitrarily chosen) neighbors and rely on the fact that,
   statistically, the message will reach the intended recipient at some
   point. This is the approach taken by projects such as [Ethereum
   Whisper](https://github.com/ethereum/wiki/wiki/Whisper-Overview) and
   (more or less) [BitMessage](https://bitmessage.org). However, in both
   cases, it seems the costs in terms of latency and bandwidth are
   rather high and high throughput is not feasible with this approach.

Concluding, as metadata obfuscation is quite difficult to implement
correctly, i.e. such that it provides sufficient anonymity, we will use
the Tor network as a first step and will later look into ways to take
advantage of the p2p network to replace this federated approach to onion
routing.


Multicast layer
===============

Introduction
------------

Being able to build upon the unicast layer which takes care of secure
1-to-1 connections between peers that are online at the same time, we
can then focus on enabling reliable 1-to-n communication, i.e. sharing
data with a whole group of peers some of whom might or might not be
online at the time of initial transmission.

Naively, it would certainly be possible to send the data in question to
each of the $n$ recipients separately. However, this approach clearly does
not scale well when considering hundreds or even thousands of recipients
(consider e.g. a Twitter or Wikileaks use case) as the sender's internet
link would need to stem n times the original amount of data. For this
reason, we resort to application-level multicast (in contrast to IP
multicast which is usually not supported by routers on the internet):
Receiving peers do not only receive the data but in turn also forward it
to other recipients. The emerging cascade of transmissions thereby
reduces the load at the point of the sender and distributes it among all
participants.

Obviously, the peers involved in this process (i.e. all the recipients
and the sender) necessarily have to know each other. It therefore makes
sense to establish the notion of a *multicast group* – a persistent list
of recipients that the sender addresses under a common name and shares
data with and who all help each other achieve the common goal: Receiving
the data. In this sense, a multicast group is also the fundamental
entity a user can employ to finetune his privacy settings: If he wishes
to share some data with a selected group of people, he sets up a
multicast group consisting of the desired recipients and sends the data
to this group. If any of the recipients must not know each other, i.e.
if they must not know that they're all receiving the data in question or
that the receiver is in touch with all of them, multiple groups have to
be created.

An important point concerns the type of data to be sent to the group and
its consequences for the way in which the distribution needs to happen.
For text messages and files, it's obviously critical that all data will
be received by the desired recipients with absolute confidence, i.e.
that the transmission is *reliable*. Meanwhile, delays in the
transmission of up to the order of seconds are not of particular
trouble. In contrast, for live broadcasting of audio and video it is
crucial for latencies to be minimized while single frames of a video can
certainly be dropped without causing a major deterioration in quality
(in fact, frame dropping serves to *maintain* the live quality of the
transmission). Hence, reliability of transmission is not a top priority.
At the same time, a live audio or video broadcast is usually of
temporary nature while a peer might decide to continuously share text
and documents with a multicast group over years. These fundamental
differences suggest that both cases must be treated in different ways.
For concreteness, we will focus on the reliable text messaging / file
sharing use case in the following.

The next sections discuss different aspects of the multicast layer and
explain the reasoning behind corresponding design decisions. An overview
of the protocol is finally given in the last section.


TODO General approach
---------------------

- Data shared with the group is separated into *messages*, which are
  continuously numbered.
- The group is identified in terms of a group ID which is the public
  part of a key pair that the sender uses to sign each message. As
  mentioned in the previous chapter, peers are identified by their
  public keys on the p2p layer. The group's public key is then *another*
  peer ID under which the same (physical) peer that is the sender can be
  reached. That is, the sender will have some general public key known
  to his friends and representing his identity and separate keys for
  each multicast group he creates.


### TODO On pub/sub

The communication model employed here follows a pattern commonly
referred to as *publish/subscribe* (pub/sub) – in contrast to a polling-
or query- based system. With the former, the receiving party subscribes
to a communication channel and is automatically notified of new content
while the latter requires the recipient to continuously poll the sender
for whether there is new content available.



Group membership {#membership}
------------------------------

### Introduction

So far it has remained unclear how group membership is verified and how
members of the group find and identify each other. While keeping a
complete list of all members on each member's or even only the sender's
computer is certainly possible, this approach doesn't scale well. For
this reason and because it provides additional benefits discussed later,
a different approach is used: The sender defines a shared secret and
distributes it to all members upon creation of the group.^[The question
of how designated members will ever know that they are members in the
first place if they are offline at the time of creation is discussed
[further below](#notifications).] Members of the group are then able to
verify each other's membership – without revealing the secret to each
other – by using the [socialist millionaire
protocol](https://en.wikipedia.org/wiki/Socialist_millionaire). Put
differently, a member of the group is *defined* to be a peer who is in
possession of the secret. Obviously, this does not prevent a malicious
member to share the secret (let alone any data sent to the group) with
another peer who was not selected to be a member of the group but, as
outlined in the introduction, Digital Spring is concerned with cases
where the sender selects the group's members by hand and neither aims
nor is able to prevent social engineering attacks.

While a shared secret allows membership verification, it does not solve
the issue of how a member finds other members for the purpose of data
distribution (see section [Multicast algorithm]). For this reason, each
member – including the sender – will store a subset of the full member
list, referred to as the member's *neighbors*.^[The neighbor
relationship is symmetric, so if A is a neighbor of B then B is also a
neighbor of A.]

The number $N$ of such neighbors stored at every peer must be chosen
sufficiently high to guarantee that the graph consisting of all members
that are online at one instant in time, with edges being drawn between
them if they are neighbors, is always connected. This serves to ensure
that whenever help of the rest of the group is needed, e.g. when a
message is being distributed or requested in hindsight, the *whole*
group is leveraged. Put into more concrete terms, this prevents that
some part of the group does not receive a new message because it's not
connected to the sender or any member connected to him. While a
situation like this can never be ruled out (think, for instance, of the
infamous IRC net splits), a high $N$ will reduce its likelihood. Digital
Spring also choses the neighbors randomly such that no additional
structuring reduces the chances of connectedness and the entropy for the
neighborship graph, given $N$, is at a maximum.


### Adjusting the member list, rekeying

If a new recipient is to be **added** to the group, the sender will
provide the new recipient via unicast with the shared secret as well as
a list of members he can contact to establish a neighbor relationship
with them.^[For cases when the new recipient is offline at the time of
adding, see the section on [offline messaging](#offline) below.]
Depending on the use case (see the next section on access control), i.e.
on whether the new member is supposed to have access to earlier messages
/ data (the *history* of the group), the sender can either choose to
keep the secret or change it. In the latter case, he will announce the
new secret to all members in a message before adding the new recipient.

<!-- - History not accessible: Change keys when new members are added or
  existing ones are removed.
- History accessible: Don't change keys when new members are added but
  still change them when existing ones leave. (As possession of the key
  is what makes up membership in the first place.)
 -->

If the sender wants to **remove** a recipient from the list of members
he will send a message to the group (except the member to be removed),
announcing the member to be removed and a new shared secret. All members
receiving the message will then remove the member in question from their
list of neighbors and will not forward the announcement to him, either.
The reason the member to be removed must not receive the announcement is
that informing him of his removal would leak personal information to him
in the sense of "The sender doesn't want to share any data with you
anymore.". Since this is critical only in some cases^[Consider Alice who
defriends Bob on Facebook or wants to hide her future status updates
from him because they have been out of touch for a long time but Alice
doesn't want Bob to be notified of this. In contrast to this, on the
IRC, it is common for a user to be notified when he gets kicked.], an
upper layer or an application using the multicast framework might still
decide to implement notifying the removed member.

Obviously, the solution presented here will lead to problems if many
recipients are removed at once. Not only might the corresponding message
be large (as each recipient is listed in terms of his public key or its
hash) but some of the remaining members might also end up with an empty
list of neighbors. In fact, they might not even receive the message
announcing the removal in the first place if all their neighbors are to
be removed and, thus, don't receive – let alone pass on – the message
either. For this reason, only a certain fraction $R$ of the number $N$
of neighbors to be stored with each member may be removed with a single
announcement such that the distribution of the message still works and
there's time for the graph of neighbors to be repaired.

Finally, formally joining and leaving a group at a member's request is
left for upper layers of the software to implement. There are many
possible scenarios (open groups, groups one can apply for,
invitation-only groups, closed groups et cetera) but, ultimately, it is
the sender who needs to decide who he would like to share data with, so
that is what the multicast layer aims to reflect.


### Access control

Despite being closely related, access to messages needs to be separated
from the concept of membership. To see this, consider the following
examples:

- A member of the group is offline when a new message is transmitted.
  Immediately after the transmission, he is removed from the group.
  Later, when he comes back online, he wants to request the message he
  missed (and should have received) despite not being a member anymore.
- The sender adds a new peer to the group and wants to give him access
  to earlier messages (the *history* of the group).

For this reason, the current group secret is included in the header of
each new message in order make sure the message is linked to this
specific iteration of the group. Upon receiving a request from any peer
for a specific message, a member of the group will then verify that this
peer is in possession of the corresponding secret (again by using the
socialist millionaire protocol), i.e. that he was a member of the group
at the time of transmission of the message (or later received the secret
from the sender to access the group's history as in the above example).


Multicast algorithm
-------------------

### Introduction

One crucial point of the multicast layer is how the data distribution
among the members of the group is done exactly. We refer to this
procedure as the *multicast algorithm*. While a number of research
papers on this topic [TODO: Insert references] have appeared since the
late 1990s, they mostly focused on corporate environments where the
multicast group is made up of servers, all belonging to the same
company. Here, however, we need to consider groups of end consumer
devices which typically aren't online round-the-clock and also cannot
necessarily be trusted from a security point of view. (I.e. there might
be some peer trying to disrupt the multicast group by not following the
protocol.) Furthermore, the network traffic to maintain a multicast
group over time needs to be close to zero as a single peer potentially
is a member in thousands of multicast groups at the same time, depending
on his and other peers' privacy settings. In particular, it is not
feasible for a multicast group to maintain continuous TCP connections
between its members. Rather, the connections have to be set up if data
needs to be sent and be closed thereafter. In this sense, the multicast
group is an offline concept that persists even when members are not
connected with each other (or when they are offline). This requirement
alone is incompatible with almost all approaches presented in the
aforementioned papers and forces us to follow a different, new approach,
in which the actual transmission phase is distinguished from an idle
phase. (One could also call this a hybrid approach since for each phase
there is a graph being maintained. In this sense, two multicast groups
with different properties are combined.)


### The idle phase

In this phase there're usually no connections between the group's
members, However, as mentioned, members persistently store a number $N$
of other members of the group, referred to as their *neighbors*. This
list of neighbors may change when new members join the group or leave
it. In this case, connections between the members do need to be
established during the idle phase. Another such case is when members
request an earlier message from other members of the group, see [offline
messaging](#offline).


### The transmission phase

If the owner of the group (the sender) wishes to share a message with
its other members, he will *activate* the group, that is announce to his
own $N$ neighbors that a transmission is going to take place, who in
turn will then notify their other $N-1$ neighbors – provided they are
online. In this way, the paths the activation signal takes provide a
good starting point for the *distribution graph* – and are actually used
as such – that determines who is going to forward the message to whom
and only consists of those members that are currently online. As users
might come online / go offline all the time, the graph needs to be
maintained continuously until the end of the transmission upon which it
will be teared down.

<!-- TODO: Specify exactly how graph maintenance works. -->

For the exact distribution graph a simple and quite flexible model is
chosen where member Bob tries to stay connected with $D$ other members
throughout the transmission phase. As mentioned above, the starting
point for those $D$ members are the $N$ neighbors he stored and tried to
activate (or was activated by). Upon receiving a chunk of data (a
*fragment* of the message) from one such member, Bob will notify all his
other $D-1$ connected peers and, afterwards, send the fragment to all
those peers that request it (i.e. those that haven't received the
fragment from another peer yet). This ensures that no peer receives a
fragment more than once. (Obviously, the fragment's size must be chosen
sufficiently large such that it's much cheaper to send a notification
than send the fragment right away.)

As his transmission capabilities are likely limited, Bob will prioritize
these transmissions depending on network latencies and his available
load and bandwidth.^[For the prototype, we do not adjust these
priorities continuously but set them once in the beginning by looking at
the times the activation signals come in.] More specifically, he will
strongly suppress any additional transmissions if the total number of
transmissions exceeds a certain threshold. That is, while each of the
$D-1$ peers would eventually receive the fragment from him after waiting
long enough, Bob will single out a number of peers he will supply with
incoming fragments preferably. He will also announce to each of the $D$
peers their respective priority such that they can optimize their
position in the distribution graph accordingly. Hence, while $D$ might
be a comparatively high number, the number of peers Bob will actually
send the fragment to will in practice be much lower because most of the
$D-1$ peers will receive the fragment from somewhere else in the
meantime. This serves three purposes:

1) All (online) members of the group are at least notified of a new
   message, so they can always request it later on if anything goes
   wrong during transmission.
2) Bob can choose how much bandwidth he wants to allocate to the group.
   However, if he chooses it too low and doesn't serve his peers well,
   his priority with these peers will drop, too.
3) Despite prioritization, there is no strict upper bound on the number
   of peers Bob forwards a fragment to. If member Alice is assigned a
   low priority by all other members (e.g. because their individual
   network connections to Alice are bad), she will still receive the
   fragment eventually. Members with better internet links are just
   given priority.

In first numerical simulations, this algorithm turned out to be quite
reliable and also comparably fast, though further research needs to be
done.


### Incentives

As peer-to-peer systems distribute load and resource use among multiple
peers, they are generally susceptible to resource exploitation where one
or multiple peers do not follow the protocol properly and don't provide
their resources to other peers. In a multicast setting this could, for
instance, consist of receiving a message from a peer, but not forwarding
a message to other peers. For this reason, members need to be
incentivized to participate in the group.

One way to achieve this in the present multicast algorithm is the
following: Consider Alice who forwards a fragment to Bob,^[As outlined
above, Alice will actually notify Bob of the fragment whereupon Bob will
request it from her if he hasn't received it from another member, yet.
We disregard these details in the following and simply refer to the
procedure as "forwarding".] who in turn forwards it to Carl. As Alice
sets the priority with which Bob gets fragments from her, she is also
the one to punish him if he doesn't follow the group protocol by not
forwarding the fragment himself. To achieve this, after successfully
transmitting a fragment to Carl, the latter will provide Bob with a
*proof of transmission* which states the group ID, message ID, fragment
ID as well as Bob's ID and is signed by their respective private key.
Bob can then send the proof to Alice to demonstrate he actively provided
resources to the group. Alice can then raise or lower his priority
accordingly (e.g. depending on how many proofs he provides). As she
might not know, though, whether Carl is really a member of the group
(Carl and Alice might not be neighbors), she might contact him to make
sure. (A better solution in this regard is the *proof of membership*
approach which is outlined in the section on [forward and future
secrecy]: Bob could then simply append Carl's proof of membership to the
proof of transmission he sends to Alice such that Alice wouldn't have to
contact Carl herself.)

Clearly, whether Bob is able to acquire any proofs of transmission
doesn't only depend on his willingness to forward fragments but also on
whether other members request the fragment from him in the first place.
If Bob's internet link is slower than his neighbors' links, his
neighbors might get the fragment before Bob is even able to offer it to
them. In this case, his priority with Alice will rightly decrease and
reflect his bad connection such that members who can provide better
resources in turn get the chance to rise in the hierarchy.


Offline messages & mailboxes {#offline}
---------------------------------------

### The core issue

The question arrises what a group member does if he missed a message due
to him having been offline at the time of transmission. One can rephrase
this question in terms of a real-life example that makes the answer both
obvious and inevitable: What does a mailman do if the recipient is not
at home (or answering the bell)? He puts the mail into the mailbox or
gives it to some neighbor where it can be picked up later. ^[Most of the
time, he won't even attempt to deliver it directly but will resort to
the mailbox immediately.] In any case, there must be another place where
the mail can be stored reliably until the recipient comes home.

The same is true for digital communication. In the case of multicast
groups, however, there are fortunately other members in the group that
also received the message. Thus, as soon as the member in question is
back online he will contact those other members who will then send him
the requested message. This is congruent with the initial idea that
members of a multicast group help each other to get the data. However,
it obviously requires other members to be online in the first place – at
the time of transmission and at the time the other member comes online
again. While this can certainly be taken for granted for large groups,
there are drastic limitations for small groups: What to do if the
multicast group consists of only two peers that are online in turns,
i.e. never at the same time?

As demonstrated above, it is inevitable that there must be some kind of
mailbox – in this case an additional mailbox since there is no other
member that can take this role. Several ways to implement such a mailbox
come to mind:

1.  Use the DHT to store the message.

    Advantages:

    - Distributed approach, thus failure resistant.^[At least as long as
      DHT entries are stored redudantly, i.e. one peer (and the entries
      stored with him) going offline does not cause any particular
      trouble.]
    - Does not require additional resources from the sender or the
      recipient.
    - The question of metadata leakage boils down to whether accessing
      and storing data in the DHT leaks any metadata (which must be
      prevented and thus should not be the case, anyway).

    Disadvantages:

    - Only suitable for small messages.
    - Requires an anti-spam mechanism, such as a *proof of work* (known
      from blockchain-/Bitcoin-related approaches).
    - Entries in the DHT have a TTL (time to live) after which they are
      automatically removed. Thus not suitable for cases in which the
      recipient is offline for a longer period of time. (The entry can
      be renewed by the sender, though.)
    - Might require further incentives for peers to participate in this
      DHT-based storage mechanism. (I.e. why should they store other
      people's messages in the first place and not simply drop them?)


2.  Use a distinct mailbox located at some peer.

    Advantages:

    - Suitable for messages of arbitrary size.
    - Messages can be stored indefinitely (as long as the peer providing
      the box is ok with this).
    - The mailbox could be offered for rent to the sender or the
      recipient or could be provided by one of their friends.

    Disadvantages:

    - Not as failure-resistant as using the DHT.
    - Potentially leaks metadata on the sender's or recipient's behavior
      to the peer providing the mailbox. This is especially true if the
      box is being paid for and the behavior can be linked to payment
      data. Hence, the mailbox provider must be trustworthy.
    - The mailbox must be known to sender and recipient beforehand.


In the remaining parts of the present chapter on offline messaging, the
second option is explored further:

<!-- While one might now think of several ways for recipients to define where
their mailbox is located for times when they are offline, this would, in
most cases, add an additional layer of complexity to the process of data
transmission. There is, however, one simple option in the context of
multicast groups, that adds only little overhead and provides additional
benefits:
 -->

Since a peer providing a mailbox is simply an alternative recipient of
the message, it makes sense to add him as a member of the group, as this
adds only little overhead. One might imagine adding peers to the group
that are online 24/7 (i.e. own or rented servers) or simply enough peers
belonging to friends such that the availability of the message is
guaranteed. (The latter approach goes back to the idea of a
friend-to-friend network where friends support each other.) In any case,
since these mailboxes were not the originally intended recipients and
must not see the message's content, it must be additionally encrypted
beforehand so that only the intended recipients can read it. Also, since
the sender is the one who is responsible for the message (in the sense
that he might be made responsible for its content if it leaks) and who
also determines the list of recipients, it makes sense to also have him
decide for and add those mailboxes as members to the group.

Another advantage of this approach, besides its little overhead, is the
fact that these additional mailboxes will also support the group during
the time of original transmission, i.e. speed up and stabilize the
transmission. By having the sender decide on additional mailboxes, he
thereby takes the responsibility for the reliability of the
transmission. (Which makes sense as it's in his own best interest to
have his message delivered reliably.)


### On leaking metadata

Adding a mailbox to the multicast group and having it participate in the
transmission process means that, in a naive approach, metadata such as
the group's behavior and its list of members is leaked to the provider
of the box. In particular, if the mailbox is rented by the sender, the
provider must provide the sender with some sort of authorization key or
login credentials for him to be able to store data in the box and will
then be able to link the sender's / group's behavior with the person
paying for the box.

This could be mitigated for in the following (combinable) ways:

1. Use a p2p currency such as Bitcoin to pay on a per-use basis, i.e.
   the sender would include a digitally signed transaction of a small
   fee to the provider's account (public key) with the message. The
   provider would then be free to redeem this transaction at his will.
   Thus, the sender would not need to store any account and payment data
   with the mailbox provider a priori. Further switching both payment
   accounts (Bitcoin keys) and mailboxes randomly will (hopefully) make
   the sender completely anonymous towards the provider and anyone
   watching the transactions.

2. Add so many additional mailboxes to the group that it becomes unclear
   for a mailbox provider who is actually in possession of the keys
   necessary to decrypt the group's messages (i.e. who is an actual
   member of the group) and who is just another mailbox.

Obviously, further research needs to be done. In the end, it should be
noted, though, that there's most certainly a trade-off to be made
between perfect security (metadata protection) and comfort (offline
messaging) in any case. Users requiring absolute protection of their
social graph thus might be well advised to avoid measures for offline
messaging in the first place.


### Notifying the offline member. {#notifications}

So far, it has remained unclear how the offline member is notified of
the missed message in the first place when he gets back online.
Considering the fact he might be a member of thousands of multicast
groups, it is certainly not feasible for him to poll all those multicast
groups for new messages at once. (At the same time, since connection
losses are rather the rule than the exception for mobile devices which
are increasingly common nowadays, this would also put the whole network
under considerable stress.) While one might now think of setting
different polling intervals depending on the groups' activity, this is
actually counter-productive when considering again a group consisting of
only two people, e.g. two old friends, that only talk to each other once
every few years, for instance to invite the other person to a golden
jubilee. Here, a polling interval too long might result in the invitee
not getting the invitation in time. While this example may appear
artificial, the exact choice of a polling interval remains a delicate
issue.

For this reason, we present a few ideas (other than polling) that still
need to be explored further:

1.  Storing a timestamp of the group's last activity / transmission in
    the DHT. This would however require the offline member to poll and
    traverse the DHT for every group which is probably not better but
    actually worse than contacting other members of the group in terms
    of load being put on the network. On top of that, one would need to
    make sure that data about the group's activity does not leak to a
    3rd party (e.g. the one being in control of the respective part of
    the DHT). This might be done by choosing a random key in the DHT
    that is only known to the group's members.

2.  Storing all (encrypted) notification messages (consisting of the
    group's ID and a timestamp) for one peer under a single entry in the
    DHT.

    Advantages: The peer only needs to consult a single entry in the DHT
    upon coming online.

    Disadvantages:

    - The number of notifications can potentially get huge and it is
      unreasonable to burden a single random 3rd party with them.
    - It is not clear how to secure the notifications cryptographically,
      e.g. how to prevent a 3rd party from just erasing them. (Any party
      who wants to notify the peer needs write access to the DHT entry,
      as well as the member itself who needs to reset the notifications
      when he gets back online).

3.  Storing all (encrypted) notification messages for one peer as a
    linked list in the DHT, with the first (and known) entry always
    being updated to the newest element (notification) in the list.

    Advantages:

    - The burden of storing the notifications is distributed among all
      peers in the network.
    - The peer must at first only consult one entry in the DHT when he
      gets online again and then follow the linked list. The complexity
      is thus of order O(N) and not of order O(G) where N is the number
      of notifications for this particular peer and G is the number of
      groups this peer is a member of (obviously N <= G).

    Disadvantages: It is unclear how to secure all the DHT entries
    cryptographically. (All groups the peer is a member of must have
    write access; the peer, however, as well.)

4.  Storing a notification message at a peer chosen (and trusted) by the
    sender (this might also be simply a member of the group as long as
    the group's size is sufficiently large, in particular larger than
    2). This peer will then continuously try to reach the offline member
    and notifiy him until he gets back online. While the polling might
    be expensive in general, its interval can be chosen at the sender's
    will, depending on the use case and urgency.

    Disadvantages: Leaks metadata to the peer in charge of notifying the
    offline member (if the former is not a member of the group in the
    first place).

5.  Storing a notification message at a peer ("notification box") chosen
    (and trusted) by the offline member / recipient. This is similar to
    the mailbox idea with the difference that the message's content is
    not stored and the recipient chooses this box. The notification
    box's ID might be stored with other members of the group (e.g. the
    offline member's neighbors) or in the DHT under the offline member's
    ID.

    Advantages: This approach does not leak any information to the
    notification box if the notification is encrypted.

    Disadvantages: Could lead to spam.

Concluding, the most promising way seems to be a combination of options
4 and 5 because it is in both the sender's and the recipient's interest
that the recipient gets notified.


Security
--------

### Confidentiality

Confidentiality on the application level is achieved by sending /
forwarding the plaintext message only to legitimate recipients which are
identified through a shared secret. Meanwhile, on the physical network
level, all data is encrypted when being passed from one peer to another
which provides confidentiality towards an attacker tapping the cables.


### Authenticity and deniability

Multicasting, i.e. the fact that recipients pass on a message to one
other, makes it difficult to provide authenticity and deniability at the
same time since the usual approach of an authenticated Diffie-Hellman
key exchange to agree on a shared secret is limited to only two parties.
The reason for this is that a shared secret (and the message
authentication code (MAC) that would be derived from it) only provides
authenticity if one party can be sure that this secret is only known to
the other party.^[Compare the introductory remarks on authentication and
deniability in many-recipients settings and on what, for a legitimate
recipient, makes up a proof of authenticity that could have still been
forged from the point of a 3rd party.] Therefore, a solution providing
authenticity and deniability in a multicast environment must necessarily
resort to pairwise authentication which is a challenge considering a
possibly large number of recipients.

As was mentioned earlier, a multicast group is identified by a public
key whose corresponding private key is in the hands of the sender. At
the same time, this public key also represents the sender himself within
the group as well as on the level of the p2p network, i.e. if a member
needs to get in touch with the sender he will simply establish a 1-to-1
connection to this public key. In this sense, the group's name / ID and
the sender are not only invariably linked, they are indeed identical.
However, as a peer will in general be the sender in a multitude of
multicast groups, he will have and be known under several corresponding
public keys. While it might make sense for him to define a separate key
pair as the pair which defines his "true" identity and which he uses to
authenticate all his group keys (using pairwise authenticated
Diffie-Hellman key exchanges so it's deniable) such that all his groups'
members can be sure it is "him", he certainly doesn't have to. It is
therefore up to him to reveal the true identity behind each of his
pseudonyms that are the group keys.

Now, in order for a member to be able to verify the authenticity of a
message sent to the group, the member must simply make sure that the
message was indeed authored by the peer in possession of the group's
private key, i.e. the sender. The obvious choice here is to have the
sender sign his message with the group's private key. This also achieves
deniability since the sender uses a new key pair for each group, so the
group's key could have easily been generated by someone else. As was
mentioned, his "true" identity – represented by some public key, if
existing at all – is not related to the group key in any way.^[Apart
from the fact that both keys might point to the same IP address in the
DHT. But this is certainly no proof as anybody could create a key pair
and link it to a false IP. On top of that, onion routing might add
another layer of obfuscation here.]

Alternatively, i.e. instead of using asymmetric cryptography and one
single key pair whose public part is known to all recipients to sign the
message, it would also be possible to agree on a separate shared secret
with each recipient individually and then include one corresponding MAC
for each recipient with the message to be multicasted.^[See
https://whispersystems.org/blog/private-groups/ for a more detailed
explanation.] However, the message's size would then scale with the
group's size which is why this approach is not considered any further.

At first glance, it might seem dubious that the sender will use the
*same* private key to sign *all* messages sent to the group and the
question arises whether this might compromise deniability. For instance,
if a single message included some secret (but not incriminating) piece
of information that is known to be only accessible to him as a person,
does this already demonstrate convincingly that he also authored all
other (possibly incriminating) messages signed with the same key? The
answer is *no*, though the underlying reason for this depends on the
size of the group:

Namely, the above situation would suggest (though not prove) that the
sender in fact communicated with the recipients in some way (due to him
being the only one with access to the secret piece of information) and
it'd prove that the party who signed all the messages was at one point
in possession of the secret piece of information as well as the content
of all other signed messages. If the group consisted of a single
(malicious) recipient (or if a sole recipient testified against the
sender), this would certainly be no problem as the recipient could have
simply stripped off the sender's signature from all received messages
(including the one with the secret piece of information), generated a
new key pair and used it to sign both the original messages as well as a
fake message he wants the sender to be associated with. However, in a
multicast environment where all recipients receive the same messages and
signatures there would be some orchestrating needed to distribute forged
messages with forged signatures and the original messages with forged
signatures among all of them after the fact, i.e. after the sender sent
his secret piece of information. Put differently, in order for the
sender to be able to convincingly deny having sent a message when all
recipients are testifying against him, it'd have to be conceivable that
these recipients are collaborating.^[As a matter of fact, a multicast
group facilitates this as it provides a means for fast 1-to-$n$ data
distribution from one malicious peer to all his collaborators.] This is
no different from a real-life scenario, though, in which several
witnesses testify against a suspect, whether rightfully or not, and
Digital Spring cannot provide a defense against this. In fact, this is
completely independent from the authorization scheme employed, because
even an unsigned forged message would require collaboration (or
extensive hacking) to be found on all recipient's devices. Thus, a
signature does not provide any *additional* proof in a many-recipients
scenario, anyway.

<!-- One way to mitigate this risk even further would be to have the
sender announce a separate *signing key pair*, which is used to sign the
messages, to each member of the group individually^[Again, pairwise
authenticated Diffie-Hellman key exchanges would be used to make this
announcement deniable.] and change it every $x$ messages.^[Additionally,
he might publish expired signing key pairs to the group so anyone could
then forge previous signatures but this would prevent member Alice from
retrieving an *authenticated* message from the member Bob later on, e.g.
if Alice was offline at the time of transmission.] Therefore, at most
$x$ messages could be associated with the same author. The cost of this,
however, would be $n$ Diffie-Hellman key exchanges every $x$ messages,
where $n$ is the number of members of the group, so it might not be
feasible in settings with a large number of recipients or where a large
fraction of members is offline all the time. -->


### Forward and future secrecy

Forward secrecy towards a 3rd party tapping the cable is already covered
on the network level by using ephemeral (Diffie-Hellman) keys:
Compromise of a single such key does not lead to a compromise of other
transmissions between the same parties – whether past or future.

The architecture of the multicast layer presented here gives rise to a
new attack vector, though: Namely, in case an attacker gets hold of the
group secret and thereby becomes a member of the group (by definition),
he will have access to any messages, future or past, sent to the
iteration of the group associated with the secret. He will also receive
any new group secrets and will thus retain membership status
indefinitely until he is explicitly removed from the group by the
sender.^[See the section on [group membership](#membership). It is very
unlikely, though, that the sender will actually remove the attacker as
long as the latter does not enlist as a neighbor of the sender and the
sender thus does not even realize there is an attacker in the first
place.] In this sense, both forward and future secrecy are broken in the
current draft.

There are several ways around this, e.g. periodically rolling the group
secret forward by applying a key derivation function to the old key
material, thereby achieving forward secrecy, or having the sender
periodically announce a completely new group secret to legitimate
members individually which ensures both forward and future secrecy. The
problem with periodically updating the group secret, though, is that it
is difficult to set the period appropriately, considering that multiple
multicast groups might heavily differ in terms of how many messages are
sent to each group per time interval.

Looking more closely, the issue underlying the mentioned attack vector
is that the credentials used to authorize as a member are not
personalized to each member but can be passed on to anyone, including an
attacker. While this also has great potential when it comes to large
groups (members can invite other peers to the group by giving the group
secret to them), small groups are likely better off with more extensive
security guarantees.

To reach those, as suggested the access credentials need to be
personalized. For instance, the sender could issue a *proof of
membership* to each member which would consist of the group's ID, the
member's ID and the group secret and be signed by the sender. Then, in
addition to making sure Bob is in possession of the group secret, Alice
would also verify Bob's proof of membership before granting him access
to a message. Therefre, apart from the group secret, an attacker would
also need Bob's proof of membership and private key to gain access,
making a successful attack much harder. On the other hand, this approach
would make it impossible for members to invite new members as the sender
would necessarily have to sign off on every single new member. In
addition, the sender would also need to issue new proofs of membership
to all members every time the group secret (i.e. the member list)
changes which scales as $O(M)$, $M$ being the number of members.

In a combined approach that is going to be incorporated into this
proposal in the future, the group secret, which is announced with every
message, will consist of a public key whose private counterpart will be
used to sign the proofs of membership. This way, the sender is free to
decide whether to share this private key with the group and thus enable
its members to invite new members and self-sign their proofs – at the
cost of giving up forward and future secrecy as outlined above – or to
keep the key to himself such that he needs to sign off on every new
member himself.

Clearly, allowing anyone in possession of the necessary credentials to
join the group, including an attacker, and approving every new member
personally are mutually exclusive options and there is a tradeoff to be
made. Instead of fixing the decision in the protocol, the combined
approach outlined above allows the sender to choose appropriately and
depending on the use case.


<!-- #### Device compromise -->

<!-- Obviously, one way for an attacker to still get hold of the group secret
and a member's private key and proof of membership would be to
compromise the respective member's device. While all of these can
certainly be stored in an encrypted fashion on the device, Digital
Spring ultimately cannot provide any meaningful security against
targeted attacks. -->

<!-- Due to the offline messaging capabilities, a device compromise would
also give the attacker access to any previous messages the member stored
so that other members could request it later. This can be solved by
putting another^[Apart from transport-level encryption] layer of
encryption in place: Namely, the sender could encrypt every message's
payload with a separate key which he also sends to the members. Members
could then safely store a previous message indefinitely by simply
throwing away the associated encryption key. That way, they (or an
attacker compromising their device) would not be able to decrypt the
message themselves anymore but any other member who requests it and
possesses the key would. This approach is indeed used in the multicast
layer with backup peers which is discussed in the [next
chapter](#bmulticast).
 -->


Limitations regarding large audiences
-------------------------------------

Obviously, the concept of membership employed here is only suitable for
use cases in which the sender knows the exact recipients beforehand.
Namely, he needs to:

- specify each recipient manually and
- authenticate to each recipient individually to allow for authenticity
  and deniability of his messages at the same time.

This is different from public or semi-public communication channels
which are not defined by their list of members but rather in terms of a
common topic of interest, i.e. channels to which recipients can
subscribe at their own discretion, such as online forums and blogs.^[At
the same time, these are also the communication channels whose audiences
will generally be the largest.] There, the sender doesn't know the exact
audience when sending his message and doesn't decide on each recipient
individually. However, as noted earlier, his notion of privacy will also
be different and he won't expect authenticity and deniability at the
same time.

Hence, to allow for large audiences, pairwise authentication could:

- be dropped to allow for deniability but no authenticity, or
- be replaced by signing the group's public key with the sender's peer
  ID as a first message to the group such there's authenticity but no
  deniability.^[Alternatively, the sender's peer ID could be used as the
  group ID directly. To allow the sender to control multiple multicast
  groups, the group ID could be augmented by some random value, each
  value representing a different group.]

Furthermore, if the sender does not want to specify all recipients
manually he might simply publish the group secret through a different
channel (together with a list of existing members that can be contacted
to establish neighbor relationships) or set it to some default value
such as "0000" such that everybody is able to participate in the group.
On top of that, the sender might also allow the members to forward all
messages to anyone they like (for instance as part of a separate
multicast group). While either authenticity or deniability of the
messages would again be lost (because the sender will either not
authenticate with those 3rd parties individually or will sign the group
key / ID with his own public key representing his identity), this would
effectively allow recipients to stay anonymous towards the sender by
hiding behind another peer. A disadvantage of this approach is clearly
that the peer forwarding the data will represent a single point of
failure.

<!-- If the number of recipients gets very large, one can savely assume that
it is not the sender anymore who decided on each recipient individually.
In this situation, the notion of privacy thus changes significantly and
the sender won't assume any special security anymore.
 -->


Protocol overview & summary
---------------------------

Group parameters (immutable):

- Group ID: The public part of the signing key pair that is used to
  verify a message's authenticity.
- N: The number of neighbors
- Time to live (TTL): The minmum time for which each member must keep a
  message in storage.
- Topic: An arbitrary bytestring. Can be used to associate multiple
  multicast groups with each other on an upper level (e.g. to implement
  n-to-n communication) or to declare the application that handles this
  multicast group.


Group state (mutable):

- Current group secret: The shared secret associated with the current
  iteration of the group's member list. Used by a member to verify
  another member's group membership. Every message's ciphertext is
  prepended with a hash of the shared secret valid at the time of
  transmission to specify the iteration of the group that is allowed to
  receive the message.
- Last message sent: The (integer) ID of the last message sent to the
  group.


Data stored with each member (apart from the group's parameters and
state):

- Neighbors: A list of $N$ members of the group.
- Messages: The messages (including headers and signature) that have not
  exceeded the TTL.



BMulticast: Multicast with backup peers {#bmulticast}
=====================================================
<!-- "backed-up multicast" -->

Security
--------

### Forward secrecy

Towards a mailbox provider: Achieved through changing ("ratcheting") the
session key for each new message. Deriving the session key from a
previous one using a one-way function achieves that if an attacker gets
hold of a session key this won't give him access to past session keys
(and, thus, past messages). We call this *backward-secure*.



Limitations regarding large audiences
-------------------------------------

Forward secrecy / ratcheting not feasible anymore but confidentiality is
not expected as much as with private and small groups, anyway.


n2n layer
=========


Persistent state layer
======================




Challenges
==========

Multicast algorithm
-------------------

Synchronization between multiple devices
----------------------------------------

Persistant channel state
------------------------


Related Work
============


Acknowledgments
===============

I would like to thank Carlo von Loesch, Daniel Reusche and Gabor Adam
Toth for initial ideas involving multicast and the pub/sub approach,
Sven Peter for hour-long discussions about offline messaging, network
protocols and the software's architecture (and probably many more things
I can't remember anymore) and Max Lautsch for a creating a simulation of
the multicast algorithm, his general support over the past year and
proof-reading this paper.


References
==========
