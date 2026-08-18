## Why

External customers currently have no way to check an order's status without
contacting support. Orders live in Salesforce as the standard `Order`
object, and no authentication mechanism (guest or portal) currently has any
access to it. Adding a self-service, no-login lookup reduces support load
for a simple, high-frequency question ("where's my order?").

## What Changes

- Add a guest-accessible order status lookup: a visitor supplies an order
  number and the order's ship-to email; on a match, they see the order's
  status, key dates, shipping address, and tracking info.
- Add three new fields to `Order` to support tracking: `TrackingNumber__c`,
  `Carrier__c`, `EstimatedDeliveryDate__c` (flat fields — this business
  ships a single shipment per order, so no child object is needed).
- Add a Guest User Sharing Rule granting Read on `Order` scoped narrowly to
  `Status = 'Activated'` (excludes `Draft` orders from guest visibility).
- Grant the guest profile Read + field-level access to `Order` (the fields
  above, `OrderNumber`, `Status`, dates, shipping address) and to
  `Contact.Email` via `ShipToContactId` (needed for the email match).
- Disable default guest API access for the profile(s) this ships on, so the
  lookup Flow is the only path into `Order` for unauthenticated users.
- Implementation is a guest-accessible Screen Flow (Get Records element
  filtered on `OrderNumber` + `ShipToContact.Email`) — no Apex controller
  layer.

## Capabilities

### New Capabilities
- `order-status-lookup`: guest (unauthenticated) lookup of an order's
  status, dates, shipping address, and tracking info by order number +
  ship-to email.

### Modified Capabilities
(none — no existing specs)

## Impact

- **Schema**: 3 new fields on `Order` (`TrackingNumber__c`, `Carrier__c`,
  `EstimatedDeliveryDate__c`).
- **Sharing/security**: new Guest User Sharing Rule on `Order`; guest
  profile FLS changes on `Order` and `Contact`; guest API access setting
  for the hosting site's profile(s).
- **UI**: new guest-accessible Screen Flow, embedded on a Digital
  Experience page (which of the three existing sites — Route Fix Temp /
  Customer Support Portal / Spicerth — hosts this is not yet decided; all
  three are currently `DownForMaintenance`).
- **Out of scope for this change**: authenticated portal access to orders
  (the existing dormant `Customer Community User` login/self-registration
  flow is unaffected); the shipping-address exposure level (full address
  vs. coarser city/state) is still an open decision — see design.md.
