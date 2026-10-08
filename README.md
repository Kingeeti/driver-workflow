# HaulFlow driver workflow demo

A Flutter demonstration of a long-haul shipment shared by two drivers. It is intentionally a local, mock-data prototype so the workflow can be reviewed before Firebase is introduced.

## What is included

- Driver onboarding form
- Individual driver and team-lead demo login/logout
- One shared 48-hour shipment (`SHP-2048`)
- Alternating driver schedule with current/resting status
- Driver handoff request and acceptance flow
- Shared activity log and team-lead overview

## Demo accounts

| Account | Email | Password |
| --- | --- | --- |
| Driver A — Alex Morgan | `alex@haulflow.demo` | `driver123` |
| Driver B — Taylor Reed | `taylor@haulflow.demo` | `driver123` |
| Team lead — Jordan Lee | `lead@haulflow.demo` | `lead123` |

## Run it on this computer

Flutter is installed at `C:\Users\kinge\development\flutter`. From the project folder, run:

```powershell
C:\Users\kinge\development\flutter\bin\flutter.bat --no-version-check run -d windows
```

For the browser version, use `-d chrome` after Chrome is available to Flutter. `--no-version-check` avoids an optional Flutter update check that this machine's GitHub connection currently stalls on.

## Suggested demo sequence

1. Sign in as Alex and select **Request handoff**.
2. Log out, sign in as Taylor, then select **Accept handoff**.
3. Log out, sign in as Jordan to show the completed shared timeline and activity log.

## Next build phase

Split the prototype into feature folders, connect Firebase Authentication and Firestore, add team-lead assignment creation, and introduce Android/iOS targets for device testing.
