---
title: Why a shared group secret is not enough
author: Simon Hirscher
date: 2015-08-26
---

As I am working on the technical whitepaper (current revision:
969d9c4342237b1566f929d7496aa9acf157a1bd), today I took an in-depth look
at what promises Digital Spring can make in the current draft regarding
forward and future secrecy^[Following an article by [Whisper
Systems](https://whispersystems.org/blog/advanced-ratcheting/), *future
secrecy* is the property that an attacker cannot access future plaintext
messages indefinitely in case a single key gets compromised, i.e. the
property that the system will heal itself at some point.] on the
multicast level. Turns out, not too extensive ones. Let me
elaborate.^[Please excuse the break in style in the next paragraph and
in a few other spots where I switch to a more formal way of writing.
This is simply because I mostly copied what was originally meant to be
in the whitepaper and pasted it here. I may or may not revise the text
in the future in case I find the time.]

While transmissions between peers are automatically forward-secure on a
network level by virtue of Diffie-Hellman key exchanges, it always
bothered me that the way group membership worked would give rise to a
new attack vector: Namely, in case an attacker gets hold of the group
secret and thereby becomes a member of the group (by definition), he
will have access to any messages, future or past, sent to the iteration
of the group associated with the secret. He will also receive any new
group secrets and will thus retain membership status indefinitely until
he is explicitly removed from the group by the sender.^[See the section
on group membership in the whitepaper. It is very unlikely, though, that
the sender will remove the attacker as long as the attacker does not
enlist as a neighbor of the sender and the sender thus does not even
realize there is an attacker in the first place.] In this sense, both
forward and future secrecy are broken in the current draft.


Future secrecy
==============

To save future secrecy, the rather obvious approach is to replace the
(compromised) group secret by a new one in some way or the other, the
crucial point here being that the new secret must not be derivable from
the old one. I will quickly state the options here:

- Have the sender periodically^[I.e. every $x$ messages or after a
  certain time interval has passed.] issue a new group secret which is
  sent to the legitimate members individually (i.e. via unicast).

- Have the sender periodically issue a new group secret and send it
  together with the complete member list as a message to the group,
  except for the attacker: He will not receive the new secret because
  members will verify their neighbors' membership by looking at the list
  and remove any illegimate members, first. This approach would require
  the sender to store the complete member list, though, and would also
  lead to potentially large messages.


Forward secrecy
===============

Clearly, the reason that past messages are accessible to the attacker at
all comes down to the crucial need of keeping previous messages
available to allow for offline messaging. Again, to mitigate the risk of
an attack, the group secret could be changed periodically. This could
either be done in the way member list changes are announced^[Again, see
the section on group membership in the whitepaper, i.e. manually via a
multicast message that is protected by the old secret, or by rolling
("ratcheting") the group secret forward automatically in a predefined
fashion, i.e. by applying a key-derivation function (KDF) to the
previous key, or by sending the new secret to each legitimate member
individually just like upon group bootstrapping. While the latter
approach requires $O(M)$ effort by the sender, it is also the only
option among the three which guarantees future secrecy at the same time.


The solution: Change the way membership is defined
==================================================

Disregarding the possibility of frequently changing the group secret for
a moment, the fact that knowledge of the shared group secret alone is
enough to access messages can otherwise only be avoided by having the
sender state explicitly who is a legitimate member. More specifically,
the sender can either periodically announce the list of members to the
group as a multicast message or issue some signed and personalized proof
of membership to each member separately (i.e. via unicast).^[Such a
proof would, for instance, consist of signing a message containing the
group ID / public key, the group secret and the member's ID / public key
with the group's private key.] Both options provide forward and future
secrecy at the same time but while the first option scales with $O(M)$
with regard to link stress and needed storage on each member's device
($M$ being the number of members), handing out individual proof of
membership via unicast only puts an $O(M)$ burden on the sender (both in
terms of link stress and storage). This is also superior to the last
option discussed in the previous paragraph (namely, frequently changing
the group secret and announcing it via unicast) as the proofs of
membership need to be send only when the member list actually changes
and not as a measure of precaution every $x$ messages or $d$ days.

So here it is, the solution: Have signed proofs of membership in
addition to group secrets!

Why still keep group secrets, you ask? Well, let's consider Bob who was
a member of the group but later got removed. As mentioned in the
whitepaper, the fact alone that he got removed is a datum that the
sender might not wish to share with Bob, so the removal must happen
silently. Without a shared secret and the socialist millionaire protocol
in place, though, mutually verifying each other's membership would only
consist of exchanging the proofs of membership which must specify the
current group iteration in one way or the other (e.g. represent it by a
number or some random string, similar to a group secret). Therefore, Bob
could simply contact any member, attempt a mutual membership
verification with him (which would fail since Bob is not in possession
of an up-to-date proof of membership) and will notice the new group
iteration in the other member's proof and realize that he is not a
member of the group anymore.

Now, due to the $O(M)$ scaling, our solution obviously doesn't quite
work for large groups: While adding members might not even pose a
problem here (as it's rather done continuously considering the sender
really hand-selects the recipients), what about removing a member from
the group? In this case, $M$ proofs of membership would need to be
provided to the remaining members via unicast all at once. But: How
often is a member actually removed from a large group in practice,
considering they are often (semi-)public and the sender might not care
about who exactly receives his messages? ^[As discussed in the
whitepaper, the notion of privacy in a large group is a completely
different one compared to small and private groups.] So it might not
even make sense to pay a huge price for forward / future secrecy.
Rather, it'd be better to drop proofs of membership in this case
alltogether and stick with the present approach of group secrets.
