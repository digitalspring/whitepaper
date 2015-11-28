The following text used to be a part of the chapter on multicasting.
Most of the ideas here made it into the new chapter "Preliminaries /
Offline messaging" but some didn't. They might still turn out to be
valuable at some point, though, which is why they are kept in a separate
file for the time being.


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