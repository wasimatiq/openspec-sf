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

- [ ] 3.1 Build a guest-accessible Screen Flow with an input screen for
      order number and email
- [ ] 3.2 Add a Get Records element filtered on
      `OrderNumber = {!input}` AND `ShipToContact.Email = {!input}` —
      **important**: this is the first real test of the relationship
      filter against a genuine guest session (an Apex-test-based
      diagnostic using `System.runAs(guestUser)` gave contradictory,
      unreliable results — do not trust that technique; verify this
      Flow directly once built)
- [ ] 3.3 Add a Decision element: no record found → show a generic
      "no matching order" message (must not reveal whether the order
      number exists but the email didn't match)
- [ ] 3.4 Build the results screen: status, key dates, full shipping
      address, carrier, tracking number, estimated delivery date

## 4. Hosting & Rollout

- [x] 4.1 Decide which Digital Experience site hosts this capability
      (Route Fix Temp / Customer Support Portal / Spicerth, or a new one) —
      **decided: new site**, "Order Status Lookup" (Network Id
      `0DBdL000005ww2LWAQ`, template Build Your Own (LWR),
      AuthenticationType `AUTHENTICATED_WITH_PUBLIC_ACCESS_ENABLED`, public
      URL prefix `orderstatus`), created via `sf community create`
- [ ] 4.2 Publish/activate the new site (currently `UnderConstruction` —
      this is the normal just-created state, not a problem; needs
      Experience Builder → Publish to go live)
- [ ] 4.3 Embed the lookup Flow on a page in the new site

## 5. Verification

- [ ] 5.1 Verify: correct order number + correct email returns the order
      (spec scenario: "Correct order number and email returns the order")
- [ ] 5.2 Verify: correct order number + wrong email returns nothing, with
      no signal that the order number exists (spec scenario: "Correct
      order number with wrong email returns nothing")
- [ ] 5.3 Verify: nonexistent order number returns nothing (spec scenario:
      "Non-existent order number returns nothing")
- [ ] 5.4 Verify: a `Draft` order with matching number + email is not
      returned (spec scenario: "Draft order is not returned")
- [ ] 5.5 Verify: an `Activated` order with matching number + email
      returns the full result set — status, dates, full shipping address,
      carrier, tracking number, estimated delivery date (spec scenario:
      "Successful match displays the full result set")
- [ ] 5.6 Verify: a direct API query as the guest user cannot read `Order`
      or `Contact` data (spec scenario: "Direct API access does not return
      order data")
