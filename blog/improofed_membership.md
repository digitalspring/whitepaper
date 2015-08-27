---
title: Improved proofs of membership
author: Simon Hirscher
date: 2015-08-27
---

Yesterday, I introduced proofs of membership as a way to guarantee
forward secrecy in the multicast setting where, in the previous
approach, compromise of a single group secret would have given an
attacker access to past as well as future messages.

While proofs of membership have the nice feature that they really only
give those people access to the group that the sender designated, this
is, at the same time, their biggest disadvantage when the group becomes
large: Not only does the sender have to issue new proofs to all members
upon every change of the member list (whether a peer is added or
removed) and this clearly doesn't scale well, it also removes the
possibility to have members of the group invite other people by simply
sharing the group secret with them.

Although I had initially hoped for the proof of membership to be
something that is *orthogonal* to the group secret approach – so that it
might be added on a higher layer above multicast and can be turned on
and off (e.g. for large groups) –, I realized this is not quite the
case: Proofs of membership must be verified at the beginning of all
interactions on the multicast level and, more importantly, changing the
member list works in a quite different way than with group secrets, as
was already mentioned above. So if I wanted to allow for seamlessly
switching proofs of membership on and off when the group becomes large
and, at the same time, keep the protocol simple and not distinguish
between multiple cases, I had to think of something else.

Having thought about this for some time, now, here is what I've come up
with:

Use a public key as the group secret and sign the proofs of membership
not with the sender's private key but with the private key belonging to
this secret public key. (Yeah, I know I should look for a term which is
a little less contradictory.)

In this way, access to each message – which contains the intended group
secret / iteration – is linked more directly to the members belonging to
that iteration. Nevertheless, proofs of membership can still be linked
all the way back to the sender's authenticity since the sender signs
each message along with its associated group secret.

More importantly, though, this opens up the possibility for the sender
to simply share the private key belonging to the group secret with the
group. Then, members of the group could also invite other peers (as well
as self-sign their proofs of membership when the member list and thus
the group secret is changed). The protocol wouldn't need to distinguish
between multiple cases and sharing the private key or not would be the
on/off switch we were looking for.

Not so fast, though. We still have two (actually four) ways of providing
members with the necessary credentials to access the group's messages:
Either share the private key associated with the group secret with the
group (as a multicast message) or with the members individually (as a
unicast message) and, in both cases, have the members self-sign their
proofs of membership. Or don't share the private key and instead send
the proofs to each member individually (as a unicast message) or to the
group (as a bulk multicast message). Which one should be used in the
generic case?

Clearly, only the unicast options open up the possibility to *remove* a
member because with the multicast approaches, the member to be removed
would also get access to the new group iteration or, in the case of
sending all proofs in a single bulk message, at least see that he is
being removed. The original (pre-proof of membership) solution here was
to explicitly name the member to be removed in the header of the
multicast message that announces the new iteration / secret and have all
other members not forward the message to the peer in question and
instead remove it from their list of neighbors. Now, it seems
questionable at least to abandon this approach, considering it's the
most efficient one. After all, it only scales with the number of
recipients to be removed, not the total size of the group.

So what's the solution? Of course, implement none of these options. The
fact that there're good reasons for each one of them, depending on the
situation, is a clear sign we're trying to solve too many things at once
and are thereby violating the Separation of Concerns principle.
Therefore, let's focus again on the one thing the multicast layer is
concerned with: Reliably transmitting a message to multiple recipients.
So, cut out everything related to access control beyond what's really
necessary. In fact, this was the very reason I initially went for the
shared group secret approach instead of member lists lying around on
each member's device. Not only is it simpler and easier to wrap your
head around but it's also much more flexible.

Now, as things have gotten more complicated, they need to be reduced to
the lowest common factor again.

I'm going to state in a nutshell how this is done. The general idea is
to replace the original concept of membership with the more generic
concept of access keys wherever possible.

1. As proposed in the beginning, have every message contain a shared
   secret in its header which we will call access key and which is the
   public part of a key pair. Its private counterpart is used to sign
   proofs of membership (now: proof of authorization) that are needed to
   access the message. There is no specific order enforced when it comes
   to the access keys – the access keys of subsequent messages may
   generally be chosen at will, may repeat or not repeat or any
   combinations of this.

2. The list of neighbors stored at a recipient will be a list of peers
   that are in possession of the credentials associated with the latest
   message the recipient received. In this way, there is no invariant
   that is conserved globally (e.g. "The neighbor lists of all members
   always contain only legitimate members.")^[This would be impossible
   anyway as we're in a distributed setting where some peers will always
   be out of sync.] but just a local invariant, i.e. "The neighbor list
   of each recipient always contains only legitimate members as seen
   from the recipient's perspective.".

3. As an exception to the first item, the access key of all messages
   sent within a single transmission phase must be the same and the
   sender will announce the access key upon activation of the group.
   Recipients will then verify their neighbors' proofs of authorization
   before activating them.

4. Following the fact there're several good ways to hand out the proofs
   of authorization to the members, pass the responsibility for this on
   to upper layers. In this sense, the multicast layer will *not* be
   self-contained anymore but be just the library that distributes the
   message to everyone in possession of the credentials, provided he is
   somehow connected to the sender through neighborship relations.

5. Add a field "exclude" to a message's headers which contains the IDs
   of any peers the message must never be sent / forwarded to. This
   field will not be used by the multicast layer itself and is only
   there for compatibility towards upper layers which may need this.

So far, I haven't incorporated all these thoughts into the whitepaper
yet and will postpone that to some other day. For the time being, I will
stick with the old approach of shared secrets (without any proofs of
membership).
