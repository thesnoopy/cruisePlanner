# Cruise Planner

This README documents app version `0.6.1+29`.

The app/product name used in the codebase and UI is **Cruise Planner**. The repository/internal project naming still uses identifiers such as `cruise_app` and the Flutter package name `cruiseplanner`.

Cruise Planner is a Flutter app for organizing cruise trips in one place. The current codebase supports cruise records with itinerary planning, shore excursions, travel logistics, linked documents, optional WebDAV sync, and native share intake for assigning incoming files to existing cruise data.

The app is built for people who want to keep cruise-related information structured across planning and travel: cruise details, route items, excursion payment status, transport and hotel bookings, and related files such as PDFs or images. The implementation is local-first and remains usable without cloud sync.

## Feature Overview

- Manage multiple cruises from a single home screen.
- Store cruise details such as title, ship, travel period, cabin, deck number, and deck name.
- Build an itinerary with port calls and sea days.
- Plan shore excursions with notes, stops, payment plans, payment status, and linked documents.
- Track travel logistics with typed items for flights, trains, transfers, rental cars, hotels, cruise check-in, and cruise check-out.
- Import, attach, detach, open, and sync linked documents for cruises, excursions, travel items, and port calls.
- Configure optional WebDAV sync for cruise data and documents.
- Review incoming shared files from Android/iOS and assign them to existing entities.
- Run in German and English based on the device locale.

## Functional Modules

- `Home`: lists cruises, creates cruises, opens WebDAV settings, triggers app sync, and surfaces pending shared items.
- `Cruise hub`: entry point for one cruise, with direct access to details, itinerary, excursions, and travel.
- `Cruise details`: read-only summary plus document section and edit entry.
- `Itinerary`: manages port calls and sea days.
- `Excursions`: manages excursion records, payment plans, stops, visited state, and excursion documents.
- `Travel`: manages typed travel items and travel documents.
- `Documents`: reusable document sections attached to multiple entity types.
- `Share intake`: reviews pending shared items and assigns supported file-based items to existing cruises, excursions, travel items, or port calls.
- `Settings`: stores WebDAV credentials and remote path locally.

## Screen Flow And Navigation Map

Navigation currently uses direct screen pushes with `MaterialPageRoute`; there is no centralized routing table in the current implementation.

- `HomeScreen` (`lib/screens/home_screen.dart`)
  - App entry screen.
  - Opens `CruiseHubScreen` for an existing cruise by `cruiseId`.
  - Creates a new cruise, persists it, then opens `CruiseHubScreen`.
  - Opens `WebDavSettingsScreen`.
  - Opens `PendingShareReviewScreen` when pending shared items exist.

- `CruiseHubScreen` (`lib/screens/cruise_hub_screen.dart`)
  - Main module selector for one cruise, addressed by `cruiseId`.
  - Opens `CruiseDetailsScreen`.
  - Opens `RouteListScreen`.
  - Opens `ExcursionListScreen`.
  - Opens `TravelListScreen`.

- `CruiseDetailsScreen` (`lib/screens/details/cruise_details_screen.dart`)
  - Read-only cruise summary plus cruise-level linked documents.
  - Opens `CruiseEditScreen`.

- `CruiseEditScreen` (`lib/screens/details/cruise_edit_screen.dart`)
  - Edits cruise core fields and cruise-level linked documents.

- `RouteListScreen` (`lib/screens/route/route_list_screen.dart`)
  - Lists route items for one cruise.
  - New-item flow starts with a bottom sheet for `Port` or `Sea Day`, creates a placeholder item, then opens `RouteEditScreen`.
  - Opens `PortCallDetailScreen` for port calls.
  - Opens `RouteEditScreen` directly for sea days.

- `PortCallDetailScreen` (`lib/screens/route/port_call_detail_screen.dart`)
  - Read-only port call details plus port-call documents.
  - Opens `RouteEditScreen`.

- `RouteEditScreen` (`lib/screens/route/route_edit_screen.dart`)
  - Edits either a port call or a sea day.
  - Port calls can edit date, arrival, departure, all-aboard time, notes, and linked documents.
  - Sea days edit date and notes.

- `ExcursionListScreen` (`lib/screens/excursions/excursion_list_screen.dart`)
  - Lists excursions for one cruise.
  - Creates a new excursion, persists it, then opens `ExcursionEditScreen`.
  - Opens `ExcursionDetailScreen`.

- `ExcursionDetailScreen` (`lib/screens/excursions/excursion_detail_screen.dart`)
  - Read-only excursion view with info, documents, payment summary, and stop checklist.
  - Opens `ExcursionEditScreen`.

- `ExcursionEditScreen` (`lib/screens/excursions/excursion_edit_screen.dart`)
  - Edits excursion data, payment plan, stops, and linked documents.
  - Supports payment modes for full payment, deposit plus dated remainder, and deposit/full payment on site.

- `TravelListScreen` (`lib/screens/travel/travel_list_screen.dart`)
  - Lists travel items for one cruise.
  - New-item flow starts with a bottom sheet for item type, creates a typed placeholder item, then opens `TravelEditScreen`.
  - Opens `TravelDetailScreen`.
  - For hotel items with an address, offers map-app launch via `showMapAppPicker`.

- `TravelDetailScreen` (`lib/screens/travel/travel_detail_screen.dart`)
  - Read-only typed travel view plus travel-item documents.
  - Opens `TravelEditScreen`.

- `TravelEditScreen` (`lib/screens/travel/travel_edit_screen.dart`)
  - Edits typed travel items by `travelItemId`.
  - Field sets vary by travel kind.
  - Includes linked travel documents.

- `PendingShareReviewScreen` (`lib/screens/share/pending_share_review_screen.dart`)
  - Reviews persisted pending shared batches captured from native platforms.
  - Opens `PendingShareAssignmentScreen` for file-based items only.

- `PendingShareAssignmentScreen` (`lib/screens/share/pending_share_assignment_screen.dart`)
  - Lists assignable targets grouped by cruise.
  - Can assign to cruise, excursion, travel item, or port call.
  - Prompts for a document title before importing file-based items.

- `WebDavSettingsScreen` (`lib/screens/settings/webdav_settings_screen.dart`)
  - Stores WebDAV base URL, username, password, and remote path in secure storage.

## Tech Stack

- Flutter with Material 3 UI.
- Dart `^3.9.2`.
- Localization via `flutter_localizations`, `intl`, ARB files, and generated `AppLocalizations`.
- Local structured persistence via `shared_preferences`.
- Secure storage for WebDAV credentials via `flutter_secure_storage`.
- WebDAV client integration via `webdav_client`.
- Local document file storage via `path_provider`, `path`, and `dart:io`.
- File import and attachment via `file_picker`, document opening via `open_filex`.
- Native and platform-aware sharing/navigation helpers via `url_launcher`, `map_launcher`, and custom share-intake bridges.
- Responsive grid layout support via `flutter_staggered_grid_view`.

## Project Architecture

The codebase follows a mostly ID-driven, local-first structure:

- Screens stay focused on presentation, form editing, and navigation.
- `CruiseStore` in `lib/store/cruise_store.dart` is the main source of truth for cruises and nested entities.
- Domain data is model-based under `lib/models/`.
- IO-heavy behavior is pushed into services under `lib/services/` and sync code under `lib/sync/`.
- Navigation usually passes IDs rather than whole model objects, and screens reload from the store when returning from detail/edit flows.
- Documents are handled as a separate subsystem with:
  - metadata in `DocumentStore`
  - local file authority in `DocumentFileStore`
  - remote WebDAV behavior in `DocumentRemoteStore`

## Data Storage And Sync

### Local storage

- Cruise data is stored in `SharedPreferences` under schema-based JSON payloads managed by `CruiseStore`.
- Current cruise persistence schema version is `3`.
- The store still reads older keys and normalizes legacy payloads through `lib/sync/cruise_persistence_migration.dart`.
- Entities use `updatedAtUtc` and `deletedAtUtc` metadata for sync and soft-delete handling.
- WebDAV settings are stored separately in secure storage by `WebDavSettingsStore`.

### Cruise sync

- App-level sync is coordinated by `AppSyncService`.
- Cruise JSON sync uses `CruiseSyncService` plus `WebDavSync`.
- The merge is three-way:
  - baseline from the last successful sync
  - current local cruises
  - current remote cruises
- Conflict resolution is timestamp-aware when `updatedAtUtc` or `deletedAtUtc` is available.
- When both sides change the same entity and timestamps do not decide the winner, the legacy field merge preserves remote values by default and applies local values only for fields changed locally against the baseline.
- Deletions are modeled as soft deletes, not immediate removal from persisted data.
- Remote cruise uploads create a timestamped backup copy in an `old/` folder before overwriting the main remote file.
- Sync is skipped when WebDAV settings are missing or incomplete.

### Document sync

- Document sync is executed after cruise sync by `DocumentSyncExecutionService`.
- Remote document storage lives alongside the configured cruise JSON path, using a sibling `documents/` structure for:
  - metadata JSON
  - per-document stored files
- The document sync flow includes upload/download planning, local file recovery, soft-delete propagation, and hard-delete cleanup phases.
- Failures in document sync are surfaced back through the app sync result.

## Documents And Attachments

Documents are implemented as first-class records with both metadata and file storage.

- Metadata model: `lib/models/documents/document_record.dart`
- Metadata store: `lib/store/document_store.dart`
- Local file store: `lib/services/documents/document_file_store.dart`
- Remote file/metadata store: `lib/services/documents/document_remote_store.dart`

Implemented behavior:

- Documents can be linked to:
  - cruises
  - excursions
  - travel items
  - port calls
- Imported files are copied into the app documents directory under `documents/<documentId>/original.<ext>`.
- Each document record stores title, original filename, mime type, extension, relative local path, byte size, content hash, timestamps, and deleted state.
- Duplicate detection is content-hash based during import.
- Existing documents can be linked without re-importing.
- Unlink/delete behavior is soft-delete aware and reference-count aware through `DocumentReferenceCleanupService`.
- UI support exists for importing new files, attaching existing documents, detaching, and opening linked documents.

Current scope boundaries visible in code:

- The share-assignment flow currently supports file-based shared items for document import/linking.
- Shared text and URLs are captured into the pending queue, but assignment is intentionally disabled for non-file items.

## Localization

- Supported locales: German (`de`) and English (`en`).
- Localization files live in `lib/l10n/`.
- Generation is configured through `lib/l10n.yaml`.
- `template-arb-file` is currently `app_de.arb`.
- `flutter: generate: true` is enabled in `pubspec.yaml`.

Developer note:

- New UI strings should be added through ARB files and accessed via `AppLocalizations`.
- The repository already contains generated localization files, so the README does not assume an extra manual generation step beyond normal Flutter generation support.

## Getting Started

### Prerequisites

- A Flutter SDK installation compatible with the project’s Dart SDK constraint (`^3.9.2`).
- Platform toolchains as needed for the target you want to run.
- Optional WebDAV credentials if you want to use cloud sync.

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

The app is usable without WebDAV sync. WebDAV is optional and, when needed, is configured through the in-app `WebDavSettingsScreen`.

### Platform notes supported by the repository

- Android and iOS include native share-intake wiring.
- iOS includes a dedicated Share Extension under `ios/Share Extension/`.
- Desktop and web platform folders are present (`android`, `ios`, `linux`, `macos`, `windows`, `web`).

## Developer Notes

- Keep business logic in stores and services rather than in widgets.
- Prefer ID-based navigation and reload entities from `CruiseStore` inside screens.
- When extending persisted models, update serialization and copy helpers consistently.
- If a field affects sync behavior, also consider timestamp handling and soft-delete semantics.
- Cruise-level changes should usually flow through `CruiseStore`; nested entities are updated via `upsertExcursion`, `upsertTravelItem`, and `upsertRouteItem`.
- New document-related behavior should reuse the existing document services instead of creating parallel import or storage paths.
- If you add a new entity that can own documents, follow the existing pattern used by cruise, excursion, travel, and port-call document section services.
- WebDAV sync changes should be conservative: they affect merge behavior, baseline handling, and document lifecycle cleanup.
- New screens should fit the current pattern of:
  - list screen for one cruise area
  - optional detail screen
  - edit screen that persists via store/service and returns to the previous screen

## Project Structure

```text
lib/
  main.dart                         App entry point
  models/                           Domain models for cruises, route, travel, excursions, documents, share payloads
  screens/                          Main app screens and user flows
  services/                         Document services, share-intake services, helpers
  settings/                         WebDAV settings model and secure store
  store/                            Cruise and document persistence stores
  sync/                             Cruise sync, migration, WebDAV transport, app sync coordination
  widgets/                          Reusable widgets including document sections and dialogs
  l10n/                             ARB files and generated localization classes
assets/                             App assets and launcher icons
android/, ios/                      Mobile platform integration, including share intake
web/, linux/, macos/, windows/      Additional platform shells
agent.md                            Repository-specific maintainer/agent guidance
pubspec.yaml                        Dependencies, Flutter config, app version
```

## Status And Current Limitations

- Navigation uses direct `MaterialPageRoute` pushes rather than a centralized routing table.
- Some settings UI text is still hard-coded in German even though the app otherwise has localization support.
- File-based shared items are supported in the implemented assignment/import flow. Shared text and URLs may be captured and shown in review, but they are not fully assignable in the current flow.
- The README intentionally documents only flows that are directly visible in the current source; helper widgets and non-user-facing internal utilities are not described as standalone features.
