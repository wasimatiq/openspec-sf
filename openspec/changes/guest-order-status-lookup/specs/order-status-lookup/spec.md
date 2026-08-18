## Purpose

Lets an external customer, without logging in, confirm the status of a
specific order by proving they know both its order number and the email
address it was shipped to.

## ADDED Requirements

### Requirement: Guest lookup requires order number and ship-to email to match
The system SHALL return order details only when a submitted order number
and email both match a single order's `OrderNumber` and
`ShipToContact.Email`. Neither value alone SHALL be sufficient.

#### Scenario: Correct order number and email returns the order
- **WHEN** a visitor submits an order number and email that both match an
  order's `OrderNumber` and `ShipToContact.Email`
- **THEN** the system returns that order's details

#### Scenario: Correct order number with wrong email returns nothing
- **WHEN** a visitor submits an order number that exists but an email that
  does not match that order's `ShipToContact.Email`
- **THEN** the system returns no result and does not reveal that the order
  number exists

#### Scenario: Non-existent order number returns nothing
- **WHEN** a visitor submits an order number that does not match any order
- **THEN** the system returns no result

### Requirement: Only activated orders are visible to guest lookup
The system SHALL exclude orders with `Status = 'Draft'` from guest lookup
results, even when the order number and email both match.

#### Scenario: Draft order is not returned
- **WHEN** a visitor submits an order number and email matching a `Draft`
  order
- **THEN** the system returns no result

#### Scenario: Activated order is returned
- **WHEN** a visitor submits an order number and email matching an
  `Activated` order
- **THEN** the system returns that order's details

### Requirement: Lookup result includes status, dates, shipping address, and tracking info
On a successful match, the system SHALL display the order's status, its key
dates, its full shipping address, and its tracking information (carrier,
tracking number, and estimated delivery date).

#### Scenario: Successful match displays the full result set
- **WHEN** a lookup matches an eligible order
- **THEN** the visitor sees the order's status, relevant dates, full
  shipping address (street, city, state, postal code, country), carrier,
  tracking number, and estimated delivery date

### Requirement: Guest access to Order and Contact data is restricted to the lookup path
The system SHALL NOT allow an unauthenticated visitor to read `Order` or
`Contact` data through any path other than the order status lookup itself.

#### Scenario: Direct API access does not return order data
- **WHEN** an unauthenticated visitor attempts to query `Order` or
  `Contact` data through a path other than the order status lookup (for
  example, a direct API call)
- **THEN** the request is denied
