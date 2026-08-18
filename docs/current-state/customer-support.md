# Customer Support Portal — Current-State Requirements

Documents observed behaviour of the Experience Cloud (Communities) login,
self-registration, password, and profile-management flows retrieved from
`orgfarm-f4c469b8a0-dev-ed`, as GIVEN/WHEN/THEN scenarios.

Source: `force-app/main/default/{classes,aura,pages}` (retrieved via
`manifest/package.xml`), cross-checked against live org config on
2026-08-18 via `sf data query` / `sf apex run` against
`orgfarm-f4c469b8a0-dev-ed.develop.lightning.force.com` (org ID
`00DdL00000yOEKIUA4`). Every scenario below states whether its precondition
was **confirmed live** or is **inferred from code** (not independently
verifiable without further retrieval).

## Scope note: three sites, ambiguous naming

The org has three Digital Experience (Network) sites, not one:

| Name                     | URL path prefix  | Status            | Self-reg enabled |
|--------------------------|-------------------|--------------------|-------------------|
| Route Fix Temp           | `customerportal`  | DownForMaintenance | false             |
| Customer Support Portal  | `RouteFixTemp`    | DownForMaintenance | false             |
| Spicerth                 | `spicerth`        | DownForMaintenance | false             |

**Observed anomaly:** the site named "Customer Support Portal" has the URL
path prefix `RouteFixTemp`, and the site named "Route Fix Temp" has the URL
path prefix `customerportal` — the display names and URL prefixes appear
swapped relative to what their names suggest. This document describes the
Apex/Aura/VF template code, which is shared across all three sites (there is
one set of controllers, not per-site variants). Where a scenario depends on
a specific site's config, the site is named explicitly.

## Confirmed live org state (as of 2026-08-18)

- All three sites have `Status = DownForMaintenance`.
- All three sites have `OptionsSelfRegistrationEnabled = false` and
  `SelfRegProfileId = null`.
- Live `Auth.AuthConfiguration` for all three networks (via anonymous Apex):
  `UsernamePasswordEnabled = true`, `SelfRegistrationEnabled = false`,
  `SelfRegistrationUrl = null`, `ForgotPasswordUrl = null`.
- One active portal user exists: "Jane Customer" (`CspLitePortal`,
  profile **Customer Community User**). A second, inactive "Jane Customer"
  record exists under the same profile.
- The only `User` field set in the org is `PersonalInfo_EPIM`, described as
  "Fieldset for PersonalInfo_EPIM Field Masking" — its name and description
  suggest it exists for a data-masking/sandbox-seeding tool, not for
  self-registration. No field set appears purpose-built for the
  `extraFieldsFieldSet` attribute used by `selfRegister.cmp`.
- No `FieldPermissions` rows exist for the **Customer Community User**
  profile on the `User` object — the identity/contact fields shown on My
  Profile (FirstName, LastName, Email, Phone, Street, City, etc.) are
  standard fields that are not FLS-controllable, so their edit/view access
  on that page is not gated by profile-level field permissions.
- No Lightning Web Components were retrieved (`lwc/` is empty) — the portal
  is built on Aura + Visualforce, not LWR (Lightning Web Runtime).

## Requirements

### 1. Portal availability

**REQ-1.1: Site unavailable while under maintenance**
_Confirmed live: all three sites currently have `Status = DownForMaintenance`._

```
GIVEN a Digital Experience site's Status is "DownForMaintenance"
WHEN an unauthenticated visitor requests any page under that site's URL prefix
THEN Salesforce serves the site's maintenance page instead of the requested page
```

### 2. Login

**REQ-2.1: Username/password login is enabled**
_Confirmed live via `Auth.AuthConfiguration.getUsernamePasswordEnabled()` = true
for all three networks._

```
GIVEN UsernamePasswordEnabled is true for the site's network
WHEN loginForm.cmp initializes
THEN the username/password form, submit button, and "Forgot your password?"
     link are rendered
```

**REQ-2.2: Login form renders nothing if username/password auth is disabled**
_Inferred from code (`loginForm.cmp` wraps the entire form in
`<aura:renderIf isTrue="{!v.isUsernamePasswordEnabled}">`); not exercised
live since it's currently true everywhere._

```
GIVEN UsernamePasswordEnabled is false for the site's network
WHEN loginForm.cmp initializes
THEN no form fields, error area, or links are rendered — the component is empty
```

**REQ-2.3: Successful login redirects to the start URL**
_Inferred from code (`LightningLoginFormController.login` /
`SiteLoginController.login`, both call `Site.login(username, password, startUrl)`)._

```
GIVEN a visitor enters a valid username and password
WHEN they submit the login form
THEN Site.login() authenticates them and redirects to startUrl (or the
     community default landing page if startUrl is not set)
```

**REQ-2.4: Failed login surfaces an inline error**
_Inferred from code (`LightningLoginFormController.login` catches
`Exception` and returns `ex.getMessage()` to the Aura controller, which sets
`showError`/`errorMessage`)._

```
GIVEN a visitor enters an invalid username or password
WHEN they submit the login form
THEN the form re-renders with showError = true and the exception message
     displayed, and no redirect occurs
```

**REQ-2.5: Landing redirect routes by auth state**
_Inferred from code (`CommunitiesLandingController.forwardToStartPage` calls
`Network.communitiesLanding()`, a platform API whose exact routing rules are
not visible in retrieved metadata)._

```
GIVEN a visitor requests the community landing page
WHEN CommunitiesLandingController.forwardToStartPage runs
THEN Network.communitiesLanding() sends them to the login page (if
     unauthenticated) or the community home page (if authenticated) —
     exact routing logic is platform-controlled, not app code
```

### 3. Self-registration

**REQ-3.1: Self-registration is currently disabled on all three sites**
_Confirmed live: `OptionsSelfRegistrationEnabled = false` and
`SelfRegProfileId = null` for all three networks; `Auth.AuthConfiguration
.getSelfRegistrationEnabled()` also returns false for all three._

```
GIVEN OptionsSelfRegistrationEnabled is false for the site's network
WHEN loginForm.cmp initializes
THEN the "Not a member?" self-register link is not rendered, regardless of
     whether username/password login is enabled
```

**REQ-3.2: Self-registration flow, if enabled (not currently exercised live)**
_Inferred from code (`LightningSelfRegisterController.selfRegister`,
`selfRegister.cmp`); cannot be exercised against this org today since it's
disabled on all three sites._

```
GIVEN self-registration is enabled and includePasswordField is false
WHEN a visitor submits first name, last name, and email on the self-register form
THEN Site.createPortalUser() creates a new portal user with a system-generated
     password, and the visitor is redirected to regConfirmUrl
```

```
GIVEN self-registration is enabled and includePasswordField is true
WHEN a visitor submits matching password and confirmPassword values
THEN the new user is created, logged in immediately via Site.login(), and
     redirected to startUrl
```

```
GIVEN self-registration is enabled and includePasswordField is true
WHEN a visitor submits non-matching password and confirmPassword values
THEN registration is rejected with Label.site.passwords_dont_match and no
     user is created
```

**REQ-3.3: Self-registration "extra fields" have no confirmed field-set binding**
_Partially confirmed live, partially unresolved: the only `User` field set
in the org (`PersonalInfo_EPIM`) is described as being for data masking, not
registration. The `extraFieldsFieldSet` attribute on `selfRegister.cmp` is
only ever set on a concrete Experience Builder page placement — that page
config (`ExperienceBundle`/site metadata) was not in scope for this retrieve,
so which field set (if any) is actually bound could not be confirmed._

```
GIVEN extraFieldsFieldSet is set to a valid User field set API name
WHEN selfRegister.cmp initializes
THEN LightningSelfRegisterController.getExtraFields returns each field's
     label, API path, type, and required-ness, and the component renders one
     input per field
```

**REQ-3.4: Legacy self-registration controllers are unconfigured template code**
_Confirmed from code inspection (not a live-org check — these are literal
placeholders left in the source)._

```
GIVEN SiteRegisterController.PORTAL_ACCOUNT_ID is hardcoded to the literal
     template value '001x000xxx35tPN'
WHEN SiteRegisterController.registerUser() runs
THEN the created user is associated with an Account Id that is not a real
     record in this org — this path is not production-configured
```

```
GIVEN CommunitiesSelfRegController and MicrobatchSelfRegController both set
     `profileId = null // to be filled in by customer`
WHEN either registerUser() method runs
THEN Site.createExternalUser() / Network.createExternalUserAsync() is called
     with a null ProfileId — this will fail or behave unpredictably; these
     two controllers are template scaffolding, not active integrations
```

### 4. Forgot / change password

**REQ-4.1: Forgot-password request**
_Inferred from code (`LightningForgotPasswordController.forgotPassword`,
`ForgotPasswordController.forgotPassword`, both call `Site.forgotPassword`)._

```
GIVEN a visitor enters a username on the forgot-password form
WHEN they submit the form
THEN Site.forgotPassword(username) triggers a reset email (if the username
     is valid) and the visitor is redirected to the check-email confirmation page
```

**REQ-4.2: Invalid username on forgot-password**
_Inferred from code (`LightningForgotPasswordController` checks
`Site.isValidUsername` after calling `forgotPassword`, which reads as a
latent bug — the redirect to checkEmailUrl happens before this validity
check can prevent it)._

```
GIVEN a visitor enters a username that is not valid
WHEN they submit the forgot-password form
THEN Label.Site.invalid_email is returned as the error message, but note:
     Site.forgotPassword() and the redirect PageReference are constructed
     before the validity check runs, so this may not block the redirect as
     intended — behaviour should be verified interactively, not assumed
```

**REQ-4.3: Change password (authenticated portal user only)**
_Inferred from code (`ChangePasswordController.changePassword` calls
`Site.changePassword(newPassword, verifyNewPassword, oldPassword)`)._

```
GIVEN an authenticated portal user submits old password, new password, and
     confirmation on the Change Password page
WHEN ChangePasswordController.changePassword() runs
THEN Site.changePassword() validates the old password and password policy,
     and updates the user's password if valid
```

### 5. My Profile

**REQ-5.1: Guest users cannot access My Profile**
_Confirmed from code (`MyProfilePageController` constructor throws
`NoAccessException` when `user.usertype == 'GUEST'`)._

```
GIVEN the current user's UserType is "GUEST"
WHEN MyProfilePage.page loads
THEN MyProfilePageController's constructor throws NoAccessException and the
     page does not render
```

**REQ-5.2: Authenticated portal users can view and edit their profile**
_Confirmed live: the "Customer Community User" profile (used by the one
active portal user, "Jane Customer") has no `FieldPermissions` rows on
`User`, meaning the identity/contact fields below are standard fields not
subject to profile-level FLS — visibility/editability on this page is
effectively unconditional for any non-guest user, not gated per-profile._

```
GIVEN an authenticated non-guest portal user loads My Profile
WHEN the page renders in view mode
THEN username, timezone, locale, language, community nickname, email,
     first/last name, title, phone, street, city, state, postal code,
     country, extension, fax, and mobile phone are displayed via
     apex:outputField
```

```
GIVEN an authenticated non-guest portal user clicks "Edit" on My Profile
WHEN they change one or more fields and click "Save"
THEN MyProfilePageController.save() updates the User record; a DmlException
     (e.g. a genuinely FLS- or validation-restricted field) is surfaced via
     ApexPages.addMessages and the page stays in edit mode
```

## Open questions / follow-up verification needed

1. **Which self-registration path is actually live?** No `ExperienceBundle`
   or site page-layout metadata was retrieved, so it's not confirmed
   whether any Experience Builder page actually places `selfRegister.cmp`,
   `SelfRegister.page`, or `MicrobatchSelfReg.page` — or whether none of
   them are placed anywhere (consistent with self-registration being
   disabled org-wide today).
2. **Name/URL-prefix swap** between "Route Fix Temp" and "Customer Support
   Portal" — worth confirming with whoever manages the org whether this is
   intentional or a leftover from a rename.
3. **REQ-4.2** — the apparent redirect-before-validation-check ordering in
   `LightningForgotPasswordController.forgotPassword` should be verified
   interactively (e.g. submit an invalid username in a sandbox) rather than
   assumed from reading the code.
4. Both "Jane Customer" user records (one active, one inactive) share the
   same profile — worth confirming whether the inactive one is leftover
   test data.
