# SAMAL NAV project audit and PWA foundation

Audit date: 4 November 2026

## Existing project audit

### Implemented

- Flutter/Dart application with Material 3, named routes, a landing/authentication flow, tourist pages for home, planning, map, favorites and profile, plus establishment-owner, administrator and super-administrator dashboards.
- Four application roles are defined in `AppRole`. `RoleService` fetches the current role, guards routes and routes users to their role dashboard.
- Supabase is initialized from `SupabaseConfig` with the client anon key. Data access is separated into destination, establishment, administrator, super-administrator, role and audit services.
- Destination discovery uses Supabase with a short in-memory cache and an Overpass lookup path. The map and itinerary screens use the existing map, geolocation and HTTP dependencies.
- `MogaEngine` implements a multi-objective itinerary optimizer. It remains separate from widget presentation.
- SQL migrations define profile/role handling, dashboards, tourism records, itinerary/MOGA/self-healing/weather tables, and Row Level Security policies. Sample seed migrations are also present.
- Management dashboards already switch from bottom navigation to a side menu at tablet/desktop widths. Tourist navigation now uses a bottom bar on compact screens and a `NavigationRail` at 900 px and wider.
- The web folder already had 192/512 px regular and maskable icons and a manifest. The manifest and document metadata now identify SAMAL NAV and the install prompt is browser-driven.

### Incomplete or missing

- A versioned Hive box now persists JSON snapshots with their last-synced timestamp. Existing destination fetches are not yet wired to this store, and no sync/conflict policy or generated adapters are present. The destination cache remains process memory only until a service explicitly adopts the persistent cache.
- Flutter 3.41 no longer generates/manages a caching service worker by default. A custom service worker now precaches the stable Flutter shell entry points and caches same-origin Flutter static assets as they load.
- Browser installation prompting is supported only where the browser emits `beforeinstallprompt`. Other browsers keep the app usable and do not show a false installed state.
- No current implementation of the CARS engine or Dynamic Self-Healing re-optimization was found. MOGA exists, but tests for algorithm behavior are absent.
- Weather and OSRM endpoints/call sites are part of the UI integration, but the repository does not establish offline support for either.
- The schema and management UI include reservations and payments. These must be reviewed against the approved project scope before extending those flows; this foundation work leaves them untouched.

### Structural and security review notes

- The existing architecture is retained; no broad file moves or duplicate services were introduced.
- Two migrations have the `002_` prefix (`002_fix_current_user_role.sql` and `002_rbac_dashboard_tables.sql`). Confirm the intended application order in the deployment process.
- RLS is enabled and policies exist in the inspected migrations. Policies still need a separate role-by-role security review against the deployed schema and current Supabase project.
- `SupabaseConfig` contains the project URL and anon key, which are intended for client use. No service-role key was found in Flutter client configuration.
- Before this task, the project had no Hive dependency, dedicated offline cache service or dedicated algorithm/service/widget test suites. `hive_flutter` is now the only added direct dependency for browser/device persistence.

### Recommended next steps

1. Resolve migration ordering and review deployed RLS policy behavior for the four existing roles.
2. Define the exact records that may be cached, then connect selected data services to the Hive snapshot store with explicit stale-data/sync rules.
3. Add algorithm, service and responsive-widget tests, including offline startup and install behavior in supported browsers.
4. Review reservations/payment screens and schema against the approved scope before adding more functionality.
5. Implement CARS and self-healing only in a separately scoped task after their inputs, objectives and failure behavior are agreed.

## PWA and responsive implementation

- `web/manifest.json` declares SAMAL NAV, `SamalNav`, standalone display, `./` start URL, app colors, description and the existing icon variants.
- `web/index.html` includes viewport, description, theme color, Apple touch icon and app title metadata.
- The Install app button is hidden unless the browser supplies an install event, prompts only after a user click, and hides after installation or when running standalone.
- `web/service-worker.js` precaches the Flutter bootstrap/runtime and main bundle, caches same-origin Flutter static assets as they load, keeps an offline navigation fallback, and clears older SAMAL NAV shell caches. Cross-origin weather, routing, map tiles and Supabase requests are not cached by this worker.
- Tourist navigation adapts from bottom navigation on phone/tablet widths to a side rail on wide screens. The existing management dashboard already has compact and wide navigation modes.

## Build, installation and limitations

Build the deployable PWA shell with:

```sh
flutter build web --release --no-web-resources-cdn
```

Deploy the complete `build/web` directory from a host configured for HTTPS. Service workers and installability require a secure context (localhost is suitable for local development). Configure the host to serve `index.html` for app routes while serving missing static assets as real 404 responses.

- **Android:** open the HTTPS site in a supported browser such as Chrome. Use the in-app Install app button when the browser presents it, or the browser menu's Install app/Add to Home screen option.
- **Desktop:** open the HTTPS site in an install-capable browser such as Chrome or Edge and use Install app in the address bar/menu or the in-app button when offered.
- **Other browsers:** the site remains usable as a web app. If no browser install prompt API is available, this implementation does not show an install button or claim installation.
- **Offline:** after the shell has been fetched and cached successfully, Flutter application files can load offline. Same-origin Flutter assets are cached as they load; keeping Flutter's CanvasKit resources on the same origin is why the build command disables the CDN. The Hive JSON snapshot store is initialized and ready, but existing data services do not yet save or read from it. Supabase sync/auth, live weather, OSRM routing, external map tiles and uncached remote images still require network access.

Flutter's web documentation notes that newer Flutter releases do not create a caching service worker by default and points to custom service workers for offline caching: [Web FAQ](https://docs.flutter.dev/platform-integration/web/faq), [web initialization](https://docs.flutter.dev/platform-integration/web/initialization).

## Verification results

- Final `flutter analyze`: passed with **No issues found**.
- Final `flutter test`: passed; **1 test passed**. The baseline overflows in fixed-height landing feature cards and unhandled external image failures were addressed by making the cards content-sized and adding local color fallbacks.
- `flutter build web --release --no-web-resources-cdn`: passed. Flutter emitted a non-blocking Wasm dry-run notice because `geolocator_web` uses `dart:html`; the JavaScript release bundle completed successfully.
- The production bundle includes the custom service worker and local CanvasKit assets. Real-browser offline startup and browser-specific installation checks remain necessary.
