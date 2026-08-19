## Context

Orders live in Salesforce as the standard `Order` object. No guest or
portal identity currently has any access to it — `ObjectPermissions` for
all three site guest profiles (Route Fix Temp, Customer Support Portal,
Spicerth) show zero grants on any object today. `Order` has no `Email`
field; the closest identity link is `ShipToContactId` → `Contact.Email`.
`Order` also has no tracking-related fields (no `TrackingNumber`,
`Carrier`, `EstimatedDeliveryDate`) — this business ships a single
shipment per order, so tracking is modeled as flat fields rather than a
child object. See proposal.md for motivation.

An authenticated portal path already exists in this org (login +
self-registration Aura/VF components, `Customer Community User` profile)
but is currently dormant (self-registration disabled org-wide, all sites
`DownForMaintenance`). This change does not use or modify that path.

## Goals / Non-Goals

**Goals:**
- Let an unauthenticated visitor confirm an order's status, key dates,
  shipping address, and tracking info using only the order number and the
  ship-to contact's email.
- Keep the guest's blast radius as small as possible: narrow sharing-rule
  criteria, minimal FLS, no generic API access into `Order`/`Contact`.

**Non-Goals:**
- Authenticated/portal-based order access (existing dormant login flow is
  untouched).
- Any write/update capability for guests — read-only.
- Supporting multiple shipments per order (confirmed: always one shipment
  per order in this business).
- Deciding which of the three existing Digital Experience sites hosts this
  (or whether a new one is created) — that's a deployment/rollout decision
  independent of the capability's requirements, left for tasks.md.

## Decisions

**1. Guest-accessible Screen Flow, no Apex controller**
The lookup reads `Order` directly via a Flow "Get Records" element filtered
on `OrderNumber` and `ShipToContact.Email`, rather than an Apex class. This
matches the requirement that "the read goes direct to the Order object."
Trade-off: no Apex means no code seam to add logic later (e.g. rate
limiting) without introducing a controller — acceptable for v1 given the
narrow scope.

**2. Guest User Sharing Rule scoped to `Status = 'Activated'`**
`Order.Status` is effectively `Draft` or `Activated` out of the box.
Excluding `Draft` from the guest sharing rule means an order that hasn't
been finalized is never visible to an unauthenticated visitor, regardless
of whether someone knows its order number and email. Alternative
considered: no status filter (share all orders) — rejected because it
maximizes what's exposed if the Flow's own filter is ever bypassed (see
Risks).

**3. Two-factor match is enforced at the query layer (Flow filter), not
just the UI**
`Get Records` with `WHERE OrderNumber = :input AND ShipToContact.Email =
:input` is a real server-side filter — a guess of the order number alone
returns nothing without the matching email. This protects anyone going
through the sanctioned Flow. It does **not** protect against a guest
session querying `Order` a different way (see Risks) — that gap is closed
by decision 4, not by this one.

**4. Guest API access ("Allow guest users to access public APIs") must
be enabled — revised from the original decision**
Originally decided as *disabled*, so the sharing rule's narrowness
wouldn't be the only thing standing between a guest identity and
`Order`/`Contact`. Reversed after implementation revealed the Flow LWR
component's own `startFlow` interaction call requires this preference
to succeed for a genuine (unauthenticated) guest session — without it,
the Flow itself returns 401 for real visitors, making the capability
non-functional. Verified before accepting the reversal that it doesn't
reopen the gap the original decision was meant to close: with the
preference on, the classic REST API (`/services/data/vXX.0/query`)
still returns 401 for a guest session (cookie-based auth isn't
accepted there — a session/access token is required, which a browser
guest session doesn't carry), and the LWR `webruntime/api/.../query`
passthrough returns 404 (no generic SOQL endpoint is exposed to
guests). In practice the preference only unlocks the specific
Salesforce-defined Connect API operations already wired for guest use
(this Flow's `startFlow` call, CMS media delivery) — not a general
`Order`/`Contact` query surface. The Flow remains the only functional
path into that data; confirmed live under a genuinely anonymous
session (see tasks.md 4.4 and 5.6).

**5. Flat tracking fields on `Order`, not a child object**
Confirmed: this business ships one shipment per order. `TrackingNumber__c`,
`Carrier__c`, `EstimatedDeliveryDate__c` as flat custom fields avoids
introducing a new object (and its own sharing/FLS surface) for a 1:1
relationship.

**6. Full shipping address exposed (not coarsened)**
Decided explicitly by the user over the coarser city/state-only
alternative. Accepted trade-off: full mailing address is exposed to anyone
who has both the order number and the correct ship-to email — see Risks.

## Risks / Trade-offs

- **[Risk]** A guest sharing rule's criteria govern *every* path into
  `Order` for that identity, not just the intended Flow — a broader rule
  than necessary would let someone bypass the email check entirely via
  direct API access.
  → **Mitigation**: decisions 2 and 4 together — narrow sharing-rule
  criteria, plus confirming (rather than assuming) that enabling guest
  API access per the revised decision 4 doesn't expose a generic query
  path — so there's no unguarded path in practice.

- **[Risk]** Full shipping address + a matched email is real PII exposure;
  anyone who legitimately has both an order number and the ship-to email
  (e.g. a former partner, a housemate, a data leak elsewhere) can see the
  current shipping address.
  → **Mitigation**: accepted trade-off per explicit decision; no further
  mitigation in this change. Worth a follow-up if abuse is observed.

- **[Risk]** `Contact.Email` FLS granted to the guest profile is a second
  object's exposure surface, easy to forget when auditing "what can guests
  see" if someone only checks `Order` permissions later.
  → **Mitigation**: call this out explicitly in tasks.md so it's not a
  silent side effect of the `Order` sharing rule.

- **[Risk]** All three existing sites are currently `DownForMaintenance`;
  standing this capability up doesn't by itself make it reachable.
  → **Mitigation**: site activation/hosting decision is explicitly
  deferred to tasks.md / rollout, not assumed here.

## Open Questions

- Whether the existing dormant authenticated portal should eventually offer
  the same order-status view to logged-in users (would likely reuse the
  same fields but with identity-based sharing instead of a sharing rule).
  Deferred — doesn't change this change's specs, approach, or tasks.
