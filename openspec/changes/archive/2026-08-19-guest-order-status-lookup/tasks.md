## 1. Schema

- [x] 1.1 Add `TrackingNumber__c` (Text) to `Order`
- [x] 1.2 Add `Carrier__c` (Text or picklist) to `Order`
- [x] 1.3 Add `EstimatedDeliveryDate__c` (Date) to `Order`
- [x] 1.4 Confirm `ShipToContactId` is populated on orders this capability
      needs to serve (spot-check existing/representative order data)

## 2. Sharing & Security

- [x] 2.1 Create a Guest User Sharing Rule granting Read on `Order`, scoped
      to `Status = 'Activated'` (per design.md decision 2 — excludes
      `Draft`) — **note**: required changing `Order`'s org-wide default
      from `ControlledByParent` to `Private` first (sharing rules can't
      target an object whose OWD is Controlled By Parent); this is an
      org-wide change beyond just this capability. Verified live via
      `UserRecordAccess`: guest has `Read`/no-Edit on the Activated test
      order, zero access to the Draft one.
- [x] 2.2 Grant the hosting site's guest profile Read + field-level access
      on `Order`: `OrderNumber`, `Status`, relevant date fields,
      `ShippingStreet`/`City`/`State`/`PostalCode`/`Country`,
      `TrackingNumber__c`, `Carrier__c`, `EstimatedDeliveryDate__c` —
      **note**: `OrderNumber`/`Status`/`EffectiveDate` are not
      FLS-controllable (`permissionable: false` — automatically visible
      once object Read is granted, no explicit grant possible); shipping
      address is FLS-controlled as the single compound `ShippingAddress`
      field, not per sub-field. Final grant: `Order.ActivatedDate`,
      `Order.ShippingAddress`, `Order.TrackingNumber__c`,
      `Order.Carrier__c`, `Order.EstimatedDeliveryDate__c` (all Read-only).
      Also required: FLS Read on `Order.ShipToContactId` itself (the
      lookup field) — without it, relationship traversal to
      `ShipToContact.Email` fails with a misleading "No such relation"
      error rather than a clear permissions error.
- [x] 2.3 Grant the hosting site's guest profile Read + field-level access
      on `Contact.Email` only (needed for the `ShipToContact.Email` match —
      do not grant broader `Contact` field access). **Note**: `Contact`
      also had OWD `ControlledByParent` — changed to `Private`
      (internal + external), same as `Order`. `Contact` has no field of
      its own to scope a criteria-based guest rule as precisely as
      `Order`'s (no "is a ship-to on an activated order" field exists),
      so the guest rule (`ShareContactsWithGuestForOrderLookup`) is
      effectively unconditional (`LastName != <impossible value>`) —
      broader than `Order`'s rule, bounded by FLS being Email-only.
      Verified via `UserRecordAccess`: guest has `Read` on the test
      Contact. Full end-to-end confirmation (the relationship-traversal
      filter itself, from a real guest session) is still pending the
      actual Flow — see note on task 3.2.
- [x] 2.4 Disable default guest API access for the hosting site's profile
      (per design.md decision 4) so the lookup Flow is the only path into
      `Order`/`Contact` — **already satisfied, no change needed**: verified
      live that `PermissionsApiEnabled = false` on the guest profile's
      permission set, and it's the only permission set assigned to the
      guest user (no other assignment could override it). Confirmed
      `ApiEnabled` is the correct/authoritative permission name for this
      via Salesforce's own official sample
      (`propertyrentalapp_Guest_User_Api_Access.permissionset-meta.xml`
      in `forcedotcom/sf-skills`). LWR guest profiles created via
      `sf community create` don't get API access by default.
- [x] 2.5 Verify no other existing guest-accessible page, Flow, or
      permission set grants `Order` or `Contact` access outside this
      capability (per spec requirement: "Guest access to Order and Contact
      data is restricted to the lookup path"). Verified across all four
      guest profiles in the org:
      - `ObjectPermissions` on `Order`/`Contact`: only `Order Status
        Lookup Profile` has any (Read-only, as granted in 2.2/2.3) — the
        three pre-existing site profiles (Route Fix Temp, Customer
        Support Portal, Spicerth) still have zero object permissions on
        anything.
      - Apex class access (`SetupEntityAccess` where `SetupEntityType =
        'ApexClass'`): zero for all guest profiles — no guest can invoke
        any Apex, ruling out a `without sharing` bypass.
      - Flow access: zero for all guest profiles.
      - VF page access: `Customer Support Portal Profile` (a different
        site) has 16 pages granted — all from the pre-existing
        login/self-registration/error-page template (`SiteLogin`,
        `ForgotPassword`, `CommunitiesSelfReg`, etc.). Their controllers
        were read in full earlier this session; none query `Order` or
        `Contact`.

## 3. Lookup Flow

- [x] 3.1 Build a guest-accessible Screen Flow with an input screen for
      order number and email — built in Flow Builder: `Enter_Order_Details`
      screen with required `Order_Number` (Text) and `Email_Address`
      (Email) inputs. Flow label "Guest Order Status Lookup", API name
      `Guest_Order_Status_Lookup`, saved and **Activated**.
- [x] 3.2 Add a Get Records element filtered on
      `OrderNumber = {!input}` AND `ShipToContact.Email = {!input}` —
      **redesigned**: the Get Records filter-condition Field picker does
      not support relationship traversal (confirmed live in Flow
      Builder — no chevron to drill from Order into `ShipToContact`),
      so this is two sequential Get Records elements instead of one
      combined filter: `Find_Order` (Order, filtered on `OrderNumber`
      only) → `Order_Found?` decision → `Find_Ship_To_Contact` (Contact,
      filtered on `ContactId = Find_Order.ShipToContactId` AND
      `Email = Email_Address.Value`) → `Email_Matches?` decision.
      **Note**: an Apex-test-based diagnostic using
      `System.runAs(guestUser)` gave contradictory, unreliable results
      earlier and was discarded — end-to-end verification of this
      filter against a real guest session is still pending (see
      section 5).
- [x] 3.3 Add a Decision element: no record found → show a generic
      "no matching order" message (must not reveal whether the order
      number exists but the email didn't match) — both the
      `Order_Found?` "Order Not Found" outcome and the `Email_Matches?`
      "Email Does Not Match" outcome route to the same shared `No_Match`
      screen ("We couldn't find a matching order. Please check your
      order number and email and try again."), so neither path reveals
      which check failed.
- [x] 3.4 Build the results screen: status, key dates, full shipping
      address, carrier, tracking number, estimated delivery date —
      `Order_Status` screen with a Display Text component showing
      `Find_Order.Status`, `Find_Order.EffectiveDate`,
      `Find_Order.ActivatedDate`, the full shipping address
      (`ShippingStreet`/`ShippingCity`/`ShippingState`/
      `ShippingPostalCode`/`ShippingCountry`), `Find_Order.Carrier__c`,
      `Find_Order.TrackingNumber__c`, and
      `Find_Order.EstimatedDeliveryDate__c`.
- [x] 3.5 Grant the hosting site's guest profile ("Order Status Lookup
      Profile") access to run this Flow — Flow access is controlled
      separately from object/field permissions (`SetupEntityAccess`
      with `SetupEntityType = 'Flow'`), and per task 2.5 no guest
      profile has any Flow access yet. **Note**: hit a real platform
      gotcha — the Profile's "Enabled Flow Access" picker showed
      "--None--" (no available flows at all) until the Flow's own
      "Edit Access" was first set to "Override default behavior and
      restrict access to enabled profiles or permission sets" and
      saved (the guest profile itself never appears in *that* list —
      Spring '23 removed the "Run Flows" permission from Guest User
      profiles, so a flow must opt into the override before any
      profile's Enabled Flow Access list will offer it). Once that was
      saved, "Guest Order Status Lookup" appeared in the guest
      profile's Available Flows and was added. Verified: profile page
      now shows "Enabled Flow Access [1]".

## 4. Hosting & Rollout

- [x] 4.1 Decide which Digital Experience site hosts this capability
      (Route Fix Temp / Customer Support Portal / Spicerth, or a new one) —
      **decided: new site**, "Order Status Lookup" (Network Id
      `0DBdL000005ww2LWAQ`, template Build Your Own (LWR),
      AuthenticationType `AUTHENTICATED_WITH_PUBLIC_ACCESS_ENABLED`, public
      URL prefix `orderstatus`), created via `sf community create`
- [x] 4.2 Publish/activate the new site (currently `UnderConstruction` —
      this is the normal just-created state, not a problem; needs
      Experience Builder → Publish to go live) — verified live: site
      status is "Active · Published" in Workspaces already.
- [x] 4.3 Embed the lookup Flow on a page in the new site — added a
      Flow component to the site's Home page in Experience Builder,
      set to "Guest Order Status Lookup", and published the site.
- [x] 4.4 **Resolved**: verified live (fully logged out of the org,
      true anonymous browser session) that the Flow LWR component's
      `startFlow` interaction call returns 401 for a genuine guest
      visitor unless the site preference "Allow guest users to access
      public APIs" is enabled — true even though the guest profile
      already has explicit per-flow access granted via
      `SetupEntityAccess` (task 3.5) and even though the Flow's own
      object/field permissions and sharing rules are fully scoped down
      (tasks 2.1-2.3). This directly conflicted with design.md
      decision 4 / task 2.4's stated intent ("the lookup Flow is the
      only path into Order/Contact"), so it was raised to the user
      rather than resolved silently. **User decision: enable the
      preference.** Re-verified the actual exposure before finalizing:
      with the preference on and a true anonymous session, the classic
      REST API (`/services/data/vXX.0/query`) returns 401
      `INVALID_SESSION_ID` (cookie-based auth isn't accepted there),
      and the LWR `webruntime/api/.../query` passthrough returns 404
      (no generic SOQL endpoint is exposed to guests at all) — the
      preference only unlocks the specific Salesforce-defined Connect
      API operations already wired for guest use (the Flow's own
      `startFlow` call, CMS media delivery), not a generic
      Order/Contact query surface. The "single path into Order/Contact"
      intent holds in practice; confirmed via 5.6 below.

## 5. Verification

All scenarios verified live against the published site
(`https://orgfarm-f4c469b8a0-dev-ed.develop.my.site.com/orderstatus/`)
from a genuinely anonymous browser session (fully logged out of the
org, not just an unauthenticated-looking admin session — confirmed
the distinction matters, see task 4.4).

- [x] 5.1 Verify: correct order number + correct email returns the order
      (spec scenario: "Correct order number and email returns the order")
      — Order `00000101` + `test.shipto@example.com` returned the order.
- [x] 5.2 Verify: correct order number + wrong email returns nothing, with
      no signal that the order number exists (spec scenario: "Correct
      order number with wrong email returns nothing") — Order `00000101`
      + a wrong email returned the generic "couldn't find a matching
      order" message.
- [x] 5.3 Verify: nonexistent order number returns nothing (spec scenario:
      "Non-existent order number returns nothing") — order number
      `00099999` + correct email returned the same generic message.
- [x] 5.4 Verify: a `Draft` order with matching number + email is not
      returned (spec scenario: "Draft order is not returned") — Order
      `00000100` (Draft, same ShipToContact/email as `00000101`) + the
      matching email returned the generic message, not the order.
- [x] 5.5 Verify: an `Activated` order with matching number + email
      returns the full result set — status, dates, full shipping address,
      carrier, tracking number, estimated delivery date (spec scenario:
      "Successful match displays the full result set") — confirmed all
      fields render (Status, Order Date, Activated Date, full Shipping
      Address, Carrier, Tracking Number, Estimated Delivery Date).
      **Note**: test order `00000101` originally had null shipping
      address fields; populated `ShippingStreet`/`City`/`State`/
      `PostalCode`/`Country` on it to properly exercise this scenario.
- [x] 5.6 Verify: a direct API query as the guest user cannot read `Order`
      or `Contact` data (spec scenario: "Direct API access does not return
      order data") — see task 4.4: classic REST API returns 401, and no
      generic query endpoint is exposed via the LWR webruntime API either
      (404). The Flow is the only functioning path to this data.
