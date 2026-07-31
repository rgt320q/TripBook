# Implementation Plan - Resolve Backend Secret Conflict

The goal is to fix the deployment error `Secret environment variable overlaps non secret environment variable`. This is caused by a naming conflict between the old "String" configuration and the new "Secret Manager" configuration.

## User Review Required

> [!IMPORTANT]
> **Secret Name Change:** To bypass this conflict, I am renaming the backend secret to **`MAPS_PROXY_KEY`**. You will need to run the `secrets:set` command with this new name.

## Proposed Changes

### 1. Backend - Firebase Functions
#### [MODIFY] [functions/index.js](file:///C:/Users/cetin/Projects/TripBook/functions/index.js)
- Rename `GOOGLE_MAPS_API_KEY` to **`MAPS_PROXY_KEY`**.
- Update all references and the `secrets` list to use the new name.

## Verification Plan

### Automated Checks
- Verify successful deployment via terminal.

### Manual Verification
- Test search and geocoding on Web to ensure the new secret is working correctly.

## Action Required by User
1. Run: `firebase functions:secrets:set MAPS_PROXY_KEY` and provide the key ending in `...y92uQ`.
2. Run: `cd functions; firebase deploy --only functions`.
3. If successful, you can clean up the old secret: `firebase functions:secrets:prune`.
