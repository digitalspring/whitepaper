---
title: 'Digital Spring: Technical Whitepaper'
author: Simon Hirscher
date: Work in progress (present version from July 30, 2015)
abstract: |

  Digital Spring is a software library that solves one of the crucial
  problems of the Snowden era: Private and secure data transfer, be it
  private text messages or public status updates, file sharing or device
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
  of private communication, to allow for reliable and scalable 1-to-n
  data transmissions. Further care is taken to enable offline messaging,
  i.e. to make sure sender and recipient need not be offline at the same
  time. Finally, ideas for future work involving n-to-n conversations
  and a distributed key-value storage are presented.

bibliography: bibliography.bib
csl: harvard-imperial-college-london.csl
documentclass: report
links-as-notes: true
toc: true
toc-depth: 3
---


Introduction
============

> [For the first time] we have a microscope that not only lets us
> examine social behavior at a very fine level that we've never been
> able to see before, but [also] allows us to run experiments that
> millions of users are exposed to.
>
> -- *Cameron Marlow, Head of Data Science Team of Facebook, 2012*

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

Data scooping can either happen at the sender, at the time of
transmission from one machine to the other or at the point of the
recipient.

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
points of these providers' infrastructure – either with his consent or
without. Physically securing these networks or even putting them in the
hands of the people (e.g. as a mesh network) can only be achieved on a
political level, though.

On a higher level, however, transmission typically resorts to a
*software service provider*, like various email providers, Facebook,
WhatsApp and Dropbox, who act as a middleman in the following way: The
sender will pass his message usually in an unencrypted fashion to this
middleman who in turn will store the data and make it available to the
actual recipient. It is here where intelligence agencies then access the
data – either with or without the provider's consent. Furthermore, the
middleman might also be interested in the analysis of the user's
messages himself, e.g. for the purpose of advertising and manipulation
(see the initial quote).

<!-- The middleman then either knowingly or unknowingly falls victim to
data scooping or -->

Even if the message is encrypted beforehand, the middleman (and, thus,
intelligence agencies) will usually still observe who is communicating
with whom and, therefore, the social network. This information is
usually called "metadata", suggesting that it is not as valuable as
"actual" data, although intelligence agencies mostly rely on exactly
this data to analyze social behavior and to assess the potential risk an
individual poses. In addition, studies have shown that knowledge of a
person's social network is already enough to draw various conclusions
about him, such as his sexual orientation. [@gaydar]

The point, and our idea, is therefore to eliminate the middleman
completely and have the sender pass his message on to the recipient
directly. While the message will still traverse cables and routers that
are controlled by the network providers mentioned above, we thereby
remove one big possibility for data scooping. Additional measures such
as encryption and *onion routing* are then taken to obfuscate both
content and metadata of a message for a 3rd party tapping the cable.


The goal
========

The end goal of Digital Spring is thus a software which allows the user
to securely transmit a message to others using the same software. Here,
"security" refers to:

1. Encryption: The message is encrypted such that only someone in
   possession of the decryption key (i.e. the intended recipient) is
   able to read it.
2. Forward secrecy: Each message is encrypted using an (ephemeral)
   session key derived from a long-term key in such a way that a 3rd
   party getting hold of the long-term key at some point in the future
   is unable to decrypt any messages of the conversation that were sent
   prior to the time of compromise. Additionally, comprise of a session
   key should allow the attacker to only decrypt the single message the
   session key was used for, not any previous or subsequent messages
   (for which different session keys were used). This is essentially a
   way to mitigate damages when a key is lost or cracked.
3. Anonymity towards a 3rd party: Any party *not participating in a
   conversation* is unable to find out who is talking to whom. Note that
   this is not the same as a recipient not knowing who sent a message.
4. Anonymity towards the recipient of a message: It should be possible
   for a sender to distribute messages anonymously. ^[This is a
   long-term goal and we will focus on pseudonymity first.]
5. Authenticity: The recipient of a message can be sure it was the
   sender who sent the message.
6. Repudiation: The previous item notwithstanding and similar to spoken
   conversations, the recipient technically cannot *prove* to another
   party that it was the sender who sent the message.^[Note that this
   point might become obsolete if the number of recipients is large and
   all recipients testify in court that they believe a certain person to
   be the sender of a message.]

A software providing these features must necessarily be open source, as
only then will the user be able to fully trust it.


<!--
Current State of Communication Systems
======================================

- Abgrenzung von TLS, welches Übertragungswege ganz allgemein sichert.
  - requires certificate agencies to solve the issue of key exchange =>
    compromised as well
-->


Architecture
============

The software we envision is made up of several layers, building upon
each other:

Network layer
-------------

### Goal
Digital Spring's technological foundation is a peer-to-peer (p2p)
network. Here, "p2p" refers to the fact that peers communicate directly
over the internet without requiring the usage of a middleman / a central
platform. The network layer is responsible for setting up the p2p
network, i.e. creating secure network connections between participating
peers. By "secure" we mean that the connection fulfills the requirements
of the previous chapter for the data being transferred on the network
level from one peer to the other.

### How peers are identified
On the internet, devices are usually identified by their (ephemeral) IP
addresses. However, a long-running p2p network such as ours has to
introduce a permanent identifier to be able to address the same peer by
the same ID even after some time has passed (and he has potentially
changed his IP address). While identifiers can – a priori – be of
arbitrary form, our goal of secure transmission (see above) makes it
inevitable that all peers be identified by their public keys in this
network. ^[The underlying reason for this being that the authenticity of
a peer is usually verified by means involving public/private key
cryptography.] In this sense, a public key *is* a peer's identify in the
network. ^[This already has significant impacts on every possible user
interface: Users connecting with each other for the first time must be
in possession of each other's public key. In addition, "logging in" with
an identity means restoring the key pair from a backup.] In this way,
the network layer must also be able to translate a peer's public key
back into the IP address (or any other reachable network address –
depending on the underlying transport). This is done by means of a
distributed hash table (DHT). ^[For a promising approach in our scenario
of secure communication, see @R5N, for a whole p2p network layer
building upon the latter see @CADET.] In short, a distributed hash table
is a database containing key-value pairs which is distributed among all
peers such that each peer stores only a small part of the database.
Various algorithms exist to then allow a peer to find and access any
entry in the database, even if it is stored with another, previously
unknown peer in the network.

<!--
On a more technical level, since payload transmission (e.g. sending of
text messages or files) is done by upper layers and several of such
transmissions might happen at the same time, the network layer must also
multiplex each connection to a peer in order to allow for multiple
(virtual) connections at once.
-->

### On metadata obfuscation & anonymization
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
any central point of the infrastructure), this is certainly not
something to rely upon and care must be taken to obfuscate the metadata.

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
---------------

### Introduction

Being able to build upon the network layer which takes care of secure
1-to-1 connections between peers that are online at the same time, we
can then focus on enabling reliable 1-to-n communication, i.e. sharing
data with a whole group of peers some of whom might or might not be
online at the time of initial transmission.

Naively, it would certainly be possible to send the data in question to
each of the n recipients separately. However, this approach clearly does
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
to this group. If some of the recipients must not know each other, i.e.
if they must not know that they're all receiving the data in question,
multiple groups have to be created.

An important point concerns the type of data to be sent to the group and
its consequences for the way in which the distribution needs to happen.
For text messages and files / documents, it's obviously important that
all data be received by the desired recipients with absolute confidence,
i.e. that the transmission is *reliable*. Meanwhile, small to
middle-sized delays in the transmission are not of particular trouble.
In contrast, for live broadcasting of audio and video it is crucial for
latencies to be minimized while single frames of a video can certainly
be dropped without causing a major deterioration in quality (rather,
frame dropping serves to *maintain* the live quality of the
transmission) – hence, reliability of transmission is not a top
priority. At the same time, a live audio or video broadcast is usually
of temporary nature while a peer might decide to continuously share text
and documents with a multicast group over years. These fundamental
differences suggest that both cases must be treated in different ways.
For concreteness, we will focus on the reliable text messaging / file
sharing use case in the following.


### TODO Group membership

Through symmetric keys.

One question that arises immediately when talking about multicast groups
is how group membership is verified. How do peers of the group


### TODO Multicast algorithm

#### Introduction
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
aforementioned papers and forces us to follow a different, new approach.

Following the above considerations, our approach separates between two
phases:

#### The idle phase:
In this phase there're usually no connections between the group's
members, However, members persistently store a number N of other members
of the group, referred to as their "neighbors". (The neighbor
relationship is a symmetric one, so if A is a neighbor of B then B is
also a neighbor of A.) This list of neighbors may change when new
members join the group or leave it. Only in this case connections
between the members need to be established.

#### The transmission phase:
If the owner of the group (the sender) wishes to share data (a
*message*) with its other members, he will *activate* the group, that is
announce to his own N neighbors that a transmission is going to take
place, who in turn will then notify their neighbors – provided they are
online. In this way, the paths the activation message takes provide a
good starting point for the *distribution graph* – and are actually used
as such – that determines who is going to forward data to whom and only
consists of those members that are currently online. Hence, as users
might come online / go offline all the time, the graph needs to be
maintained continuously until the end of the transmission upon which he
will be teared down.

For the exact distribution graph we choose a simple and quite flexible
model where each member tries to stay connected with D other members
throughout the transmission phase. As mentioned above, the starting
point for those D members are the N neighbors he stored and tried to
activate. Upon receiving a chunk of data (a *fragment* of the message),
he will notify all D connected peers and, afterwards, send the fragment
to all those peers that request it (i.e. those that haven't received the
fragment from another peer, yet). He will, however, prioritize these
transmissions depending on network latencies and, in doing this,
strongly suppress any additional transmissions if the total number of
transmissions exceeds a certain threshold which is based upon his
available load and bandwidth. (For the prototype, we do not continously
optimize these priorities but set them just once in the beginning by
looking at the times the activation signals come in.)

In first numerical simulations, our algorithm turned out to be quite
reliable and also comparably fast, though further research needs to be
done.


### TODO On pub/sub

The communication model employed here follows a pattern commonly
referred to as *publish/subscribe* (pub/sub) – in contrast to a polling-
or query- based system. With the former, the receiving party subscribes
to a communication channel and is automatically notified of new content
while the latter requires the recipient to continuously poll the sender
for whether there is new content available.


### Offline messages & mailboxes

#### The core issue.
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


#### On leaking metadata.
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


#### On notifying the offline member.
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


n2n layer
---------


Persistent state layer
----------------------




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


References
==========
