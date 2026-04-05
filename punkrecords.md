# Rent Shield - Development Records

## Project Understanding
Rent Shield is a mobile app for rental move-in/move-out proof and deposit protection.
It helps tenants document property condition, save evidence, and prepare for deposit disputes.

## Phase 1 - Completed
**Goal:** Foundation & Data Backbone

### What Was Built
1. **Project Structure** - Clean feature-first architecture
2. **Core Architecture:** Riverpod + go_router + Hive
3. **Premium Design System:** Deep slate primary + warm caramel accent + Inter font
4. **Data Models:** Property, TenancyRecord, RoomTemplate, ChecklistTemplateItem
5. **Property Flow:** Create, list, view details, delete
6. **Tenancy Flow:** Add/edit tenancy for a property
7. **Home Screen:** Premium dashboard with stats, property cards, empty state
8. **Routing & Settings:** All Phase 1 routes wired

---

## Phase 2 - Completed
**Goal:** Move-in Inspection Workflow

### What Was Built

1. **Inspection Data Layer:**
   - Full `Inspection` model with status tracking (draft/completed), rooms, checklist items
   - `InspectionRoom` model with progress tracking, notes, photos, computed properties (progress, issue counts)
   - `InspectionChecklistItem` model with condition enum (unchecked/ok/minorDamage/majorDamage/missing), notes, photos
   - `InspectionRepository` for Hive CRUD operations
   - Riverpod providers: inspectionListProvider, inspectionsByPropertyIdProvider, inspectionByIdProvider

2. **Inspection Overview Screen:**
   - Progress card with percentage, items checked, room/issue/photo counts
   - Gradient header (primary for draft, green for completed)
   - Room list with RoomProgressCard widgets showing per-room progress, issue chips, photo counts
   - Completion button (enabled only when all rooms done)
   - Completed state display with date
   - Delete inspection from menu

3. **Room Inspection Screen:**
   - Room-level photo attachment (camera + gallery via image_picker)
   - Room-level notes
   - Checklist items grouped by category (Structure, Fixtures, Electrical, Plumbing, etc.)
   - Per-item condition selector (Good / Minor Issue / Major Issue / Missing)
   - Per-item expandable detail panel with photos and notes
   - Auto-save on every change (persists to Hive immediately)
   - Auto-save on back navigation via PopScope
   - Progress counter in app bar (e.g. "5/9")
   - Read-only mode for completed inspections

4. **Inspection Summary Screen:**
   - Stats grid (Good / Minor / Major / Missing counts)
   - Room-by-room breakdown cards
   - Consolidated issues list with condition badges
   - Photo count
   - "Mark as Completed" button
   - Confirmation note about official record

5. **Photo Support:**
   - Camera and gallery picker via image_picker package
   - Bottom sheet source selector (Camera / Gallery)
   - Photo thumbnails with remove button
   - Full-screen photo viewer with pinch-to-zoom (InteractiveViewer)
   - Photos at room level AND item level
   - Local file paths stored in inspection JSON

6. **Reusable Inspection Widgets:**
   - `ConditionSelector` - chip row for condition selection with visual states
   - `ConditionBadge` - inline badge for displaying conditions
   - `RoomProgressCard` - room card with progress bar, issue chips, completion indicator
   - `PhotoAttachmentBlock` - horizontal photo strip with add/remove/view
   - `conditionColor()` / `conditionIcon()` helper functions

7. **Property Details Updated:**
   - Replaced placeholder inspection section with real inspection list
   - Empty state CTA to start move-in inspection
   - Inspection cards show draft/completed status, progress bar, stats
   - Delete property now also cleans up associated inspections

8. **Home Screen Updated:**
   - Stats card shows draft inspection count
   - Property cards show inspection status badges (Inspected / Draft inspection)

9. **Navigation:**
   - `/inspections/:id` - Inspection overview
   - `/inspections/:id/rooms/:roomId` - Room inspection
   - `/inspections/:id/summary` - Completion summary

### Architecture Decisions (Phase 2)
- Entire inspection stored as single JSON document in Hive (atomic save/load)
- No separate media box - photo file paths embedded in inspection rooms/items
- Auto-save pattern: every user interaction triggers immediate Hive persist
- Draft/resume: user can leave at any time, all state persisted
- Condition enum approach: unchecked is default, tapping same condition toggles back to unchecked
- Room templates from Phase 1 DefaultTemplates used to seed new inspections
- image_picker supports both camera and gallery

### Updated Data Model Overview
```
Inspection
  ├── id, propertyId, type (moveIn/moveOut), status (draft/completed)
  ├── createdAt, updatedAt, startedAt, completedAt
  └── rooms: List<InspectionRoom>
        ├── id, templateId, name, icon
        ├── notes, photos: List<String>
        └── items: List<InspectionChecklistItem>
              ├── id, templateId, name, category
              ├── condition (unchecked/ok/minorDamage/majorDamage/missing)
              ├── notes
              └── photos: List<String>
```

### Files Added/Changed in Phase 2
**New files:**
- `lib/features/inspection/data/inspection_repository.dart`
- `lib/features/inspection/providers/inspection_providers.dart`
- `lib/features/inspection/screens/inspection_overview_screen.dart`
- `lib/features/inspection/screens/room_inspection_screen.dart`
- `lib/features/inspection/screens/inspection_summary_screen.dart`
- `lib/features/inspection/widgets/condition_selector.dart`
- `lib/features/inspection/widgets/room_progress_card.dart`
- `lib/features/inspection/widgets/photo_attachment_block.dart`

**Modified files:**
- `pubspec.yaml` (added image_picker)
- `lib/core/database/hive_service.dart` (added inspections box)
- `lib/core/router/app_router.dart` (added inspection routes)
- `lib/features/inspection/data/inspection_model.dart` (replaced placeholder with full model)
- `lib/features/property/screens/property_details_screen.dart` (real inspection section)
- `lib/features/home/screens/home_screen.dart` (inspection status in cards + stats)

---

## Phase 3 - Completed
**Goal:** Move-out Inspection & Before/After Comparison

### What Was Built

1. **Inspection Model Updates:**
   - Added `linkedMoveInInspectionId` field to `Inspection` for linking move-out to move-in
   - Added `severity` getter to `ItemCondition` enum (unchecked=0, ok=1, minor=2, major=3, missing=4)
   - Updated `toJson`, `fromJson`, `copyWith` to include new field

2. **Comparison Domain Model (`comparison_model.dart`):**
   - `ChangeType` enum: unchanged, worsened, improved, newIssue, resolved (each with display label)
   - `ItemComparison` class: per-item comparison with moveIn/moveOut conditions, change type, notes/photo presence
   - `RoomComparison` class: per-room with item list, computed stats (changedItems, worsenedItems, improvedItems)
   - `InspectionComparison` class: full comparison with room list, overall stats (totalItems, changedItems, unchangedItems, worsenedItems, improvedItems, roomsWithChanges)
   - `computeComparison()` function: matches rooms/items by templateId
   - `_determineChangeType()` logic: same=unchanged, OK→issue=newIssue, issue→OK=resolved, severity up=worsened, severity down=improved

3. **Move-out Inspection Provider:**
   - `createMoveOut(propertyId, linkedMoveInId)` method clones room/item structure from linked move-in with fresh UUIDs
   - `comparisonProvider` (Provider.family) computes comparison for any move-out inspection

4. **Comparison Screen (`comparison_screen.dart`):**
   - `_ComparisonSummaryCard`: gradient header (red if issues, green if clean), worsened count, move-in/out dates
   - `_StatsGrid`: unchanged / worsened / improved stat boxes with icons and colors
   - `_FlaggedIssuesSection`: worsened items with room name, before→after condition badges, change badges
   - `_RoomComparisonCard`: expandable per-room cards with change summary, photo count diff
   - `_BeforeAfterItemRow`: per-item row showing In/Out conditions, change indicator, photo/notes presence
   - `_ChangeBadge`: visual badge for change type (trending_down for worsened, trending_up for improved)

5. **Property Details Updated:**
   - Inspections section now groups move-in and move-out separately with `_GroupLabel` headers
   - "Start Move-out Inspection" CTA appears when a completed move-in exists
   - Bottom sheet picker when multiple completed move-ins exist (user selects which to link)
   - "View Comparison" button on completed move-out inspection cards
   - Inspection cards support `showCompare` flag

6. **Inspection Overview Updated:**
   - "View Before & After Comparison" button for completed move-out inspections with linked move-in

7. **Home Screen Updated:**
   - Property cards show distinct badges: "Move-in done" / "Move-out done" / "Draft inspection"

8. **Navigation:**
   - Added `/inspections/:id/compare` route for comparison screen

### Architecture Decisions (Phase 3)
- Move-out clones room/item structure from move-in (same templateIds) so comparison matches 1:1
- Comparison is computed on-the-fly via Riverpod provider (no persisted comparison data)
- Severity-based change detection: numeric severity on ItemCondition enum enables simple comparison logic
- Bottom sheet for move-in selection when multiple exist (rare case but handled)

### Files Added/Changed in Phase 3
**New files:**
- `lib/features/inspection/data/comparison_model.dart`
- `lib/features/inspection/screens/comparison_screen.dart`

**Modified files:**
- `lib/features/inspection/data/inspection_model.dart` (linkedMoveInInspectionId, severity getter)
- `lib/features/inspection/providers/inspection_providers.dart` (createMoveOut, comparisonProvider)
- `lib/features/property/screens/property_details_screen.dart` (grouped inspections, move-out CTA, compare button)
- `lib/features/inspection/screens/inspection_overview_screen.dart` (compare CTA for move-out)
- `lib/features/home/screens/home_screen.dart` (move-in/move-out status badges)
- `lib/core/router/app_router.dart` (comparison route)

### Updated Data Model Overview
```
Inspection
  ├── id, propertyId, type (moveIn/moveOut), status (draft/completed)
  ├── createdAt, updatedAt, startedAt, completedAt
  ├── linkedMoveInInspectionId (for move-out only)
  └── rooms: List<InspectionRoom>
        ├── id, templateId, name, icon
        ├── notes, photos: List<String>
        └── items: List<InspectionChecklistItem>
              ├── id, templateId, name, category
              ├── condition (unchecked/ok/minorDamage/majorDamage/missing) [+ severity getter]
              ├── notes
              └── photos: List<String>

InspectionComparison (computed, not persisted)
  ├── moveIn: Inspection, moveOut: Inspection
  └── rooms: List<RoomComparison>
        ├── name, icon, templateId, notes/photos presence
        └── items: List<ItemComparison>
              ├── name, category, templateId
              ├── moveInCondition, moveOutCondition
              ├── changeType (unchanged/worsened/improved/newIssue/resolved)
              └── notes/photos presence
```

---

## Phase 4 - Completed
**Goal:** PDF Report Generation & Export/Share

### What Was Built

1. **Report Data Model (`report_model.dart`):**
   - `ReportType` enum: moveIn, moveOut, comparison (with display labels)
   - `ReportRecord` class: id, propertyId, reportType, filePath, fileName, createdAt, inspectionId, linkedInspectionId, fileSizeBytes
   - Full toJson/fromJson serialization
   - Stored in Hive `reports` box

2. **Report Repository (`report_repository.dart`):**
   - CRUD operations on Hive reports box (getAll, getByPropertyId, getById, save, delete)
   - Sorted by createdAt descending

3. **Report Data Builder (`report_data_builder.dart`):**
   - `ReportData` class: structured aggregation of all report data (property, tenancy, inspection stats, room data, comparison data, curated photos)
   - `ReportDataBuilder.buildSingleInspection()`: maps Inspection + Property + Tenancy into ReportData
   - `ReportDataBuilder.buildComparison()`: maps InspectionComparison + Property + Tenancy into ReportData
   - Curated photo selection: max 3 per room, max 2 per flagged item, max 30 total (prioritizes issue photos)
   - Structured room/item data classes: `ReportRoomData`, `ReportItemData`, `ReportComparisonItemData`, `ReportComparisonRoomData`

4. **PDF Generation Service (`pdf_report_generator.dart`):**
   - Uses `pdf` package (dart pure PDF generation, no native deps)
   - Produces polished, professional A4 PDFs with brand colors, typography, and layout
   - **Single Inspection Reports (Move-in / Move-out):**
     - Title block with gradient header (brand primary color)
     - Property & tenancy details section
     - Inspection overview (type, date, rooms, items, issues, photos)
     - Stats summary grid (Good / Minor / Major / Missing)
     - Room-by-room detail tables (item name, category, condition, notes)
     - Room notes section per room
     - Photo evidence grid (embedded local images)
   - **Comparison Reports:**
     - Title block with color-coded header (red if issues, green if clean)
     - Property & tenancy details
     - Move-in / Move-out dates side by side
     - Comparison stats grid (Unchanged / Worsened / Improved / Rooms Changed)
     - Flagged issues table (Room, Item, Move-in condition, Move-out condition, Change type)
     - Room-by-room comparison tables (Move-in vs Move-out per item)
     - Photo evidence grid
   - Page headers with "RENT SHIELD" branding and report type
   - Page footers with generation timestamp and page numbers
   - Missing/broken image files handled gracefully (skipped silently)
   - Files saved to `{appDocumentsDir}/rent_shield_reports/` with descriptive filenames

5. **Report Providers (`report_providers.dart`):**
   - `reportRepositoryProvider`: provides ReportRepository
   - `reportListProvider`: StateNotifierProvider for report list with reload
   - `reportsByPropertyIdProvider`: filtered reports per property
   - `reportGenerationProvider`: StateNotifier managing generation lifecycle
   - `ReportGenerationState`: idle / generating / success / error with filePath and report record
   - `generateSingleReport(inspectionId)`: builds and saves move-in/move-out PDF
   - `generateComparisonReport(moveOutInspectionId)`: builds and saves comparison PDF
   - File deletion when deleting report records

6. **Report Generation Screen (`report_generation_screen.dart`):**
   - Automatic generation on screen load
   - Three visual states:
     - **Generating**: centered spinner with progress indicator and descriptive text
     - **Success**: check icon, file info card (name, size, date), Share + Regenerate buttons
     - **Error**: error icon, error message, Try Again button
   - Share via platform share sheet (share_plus)
   - Regenerate button to re-create the PDF

7. **Report History Widget (`report_history_section.dart`):**
   - `ReportHistorySection`: embeddable ConsumerWidget for property details
   - Shows only when reports exist (no empty state clutter)
   - Report tiles with PDF icon, type label, date, file size
   - Share button per report (if file exists)
   - Delete button with confirmation dialog
   - Handles missing files gracefully (shows "File no longer available")
   - File deletion from disk when report record is deleted

8. **UI Integration:**
   - **Inspection Overview Screen**: "Generate [Type] Report" button on completed inspections
   - **Comparison Screen**: "Generate Comparison Report" button at bottom
   - **Property Details Screen**: Report history section below inspections
   - **Router**: `/inspections/:id/report/:type` route for report generation

### Architecture Decisions (Phase 4)
- `pdf` package (pure Dart) chosen over `printing` to avoid native UI dependencies and keep generation simple
- `share_plus` for cross-platform share sheet (replaces manual file open)
- `path_provider` for app documents directory (persistent across sessions)
- Report metadata stored in Hive, PDF files stored on disk in app documents
- Photo selection is budget-based: prioritizes flagged issue photos, caps total at 30
- Report data builder creates a clean intermediate layer between domain models and PDF rendering
- Generation is fire-and-forget with state notification (not blocking UI thread)
- Reports stored as local files with Hive metadata records for history/resharing

### Files Added/Changed in Phase 4
**New files:**
- `lib/features/report/data/report_model.dart`
- `lib/features/report/data/report_repository.dart`
- `lib/features/report/data/report_data_builder.dart`
- `lib/features/report/data/pdf_report_generator.dart`
- `lib/features/report/providers/report_providers.dart`
- `lib/features/report/screens/report_generation_screen.dart`
- `lib/features/report/widgets/report_history_section.dart`

**Modified files:**
- `pubspec.yaml` (added pdf, path_provider, share_plus)
- `lib/core/database/hive_service.dart` (added reports box)
- `lib/core/router/app_router.dart` (added report generation route)
- `lib/features/inspection/screens/inspection_overview_screen.dart` (generate report CTA)
- `lib/features/inspection/screens/comparison_screen.dart` (generate comparison report CTA)
- `lib/features/property/screens/property_details_screen.dart` (report history section)

### Updated Data Model Overview
```
ReportRecord (persisted in Hive)
  ├── id, propertyId, reportType (moveIn/moveOut/comparison)
  ├── filePath, fileName, fileSizeBytes
  ├── createdAt
  ├── inspectionId
  └── linkedInspectionId (for comparison reports)

ReportData (computed, not persisted - intermediate for PDF)
  ├── reportType, propertyName, propertyAddress, propertyType
  ├── tenancy details (landlord, rent, deposit, dates)
  ├── inspection stats (rooms, items, issues, photos, condition counts)
  ├── rooms: List<ReportRoomData> (for single reports)
  ├── comparisonRooms: List<ReportComparisonRoomData> (for comparison reports)
  ├── flaggedItems: List<ReportComparisonItemData>
  └── selectedPhotoPaths: List<String> (curated, max 30)
```

---

## Phase 5 - Completed
**Goal:** MVP/Beta Launch Readiness

### What Was Built

1. **Onboarding Flow (`onboarding_screen.dart`):**
   - 3-screen PageView onboarding: Welcome, Document Everything, Generate Reports
   - First-launch detection via Hive `settings` box (`onboardingCompleted` flag)
   - Premium visuals with brand icon circles, animated page dots, Skip/Next/Get Started CTAs
   - Router checks `HiveService.hasCompletedOnboarding` for initial route
   - Shown only once per install

2. **Settings Screen Upgrade:**
   - **Data & Backup section**: Export Backup (JSON), Storage stats dialog
   - **General section**: How It Works (4-step guide), About dialog, Privacy dialog
   - Version display updated to "1.0.0 (Beta)"
   - All tiles use consistent design language

3. **Edit Property Flow:**
   - `CreatePropertyScreen` now accepts optional `editPropertyId` parameter
   - Pre-fills all fields (name, address, type, notes) from existing property
   - Uses existing `PropertyListNotifier.update()` for saving edits
   - Edit button added to property details popup menu
   - Route: `/properties/:id/edit`

4. **Data Backup & Export (`backup_service.dart`):**
   - Exports all Hive boxes (properties, tenancies, inspections, reports) as structured JSON
   - Includes metadata: app name, version, export timestamp
   - Saves to app documents directory with timestamped filename
   - Shares via platform share sheet (share_plus)
   - `getStorageStats()` utility for settings screen

5. **Safe Deletion Improvements:**
   - Delete property confirmation now shows impact: tenancy, inspection count, reports
   - Cascade delete now includes reports (file + record) in addition to inspections and tenancy
   - All associated data cleaned up on property deletion

6. **Sync-ready Architecture Foundations:**
   - `SyncStatus` enum added to `property_model.dart` (pending/synced/modified)
   - `syncStatus` and `lastSyncedAt` fields on `Property` model with JSON serialization
   - `syncStatus` string field on `Inspection` model (pending/modified)
   - `copyWith` sets syncStatus to 'modified' on updates
   - All backward-compatible: defaults for existing data

7. **Dead Code Cleanup:**
   - Removed `media_item.dart` (unused Phase 1 placeholder — photos stored inline in inspection JSON)
   - No other dead imports or unused code found

8. **Code Quality:**
   - `dart analyze`: 0 issues
   - All routes compile and navigate correctly
   - No broken navigation or stub handlers
   - Consistent Riverpod patterns across all features

### Architecture Decisions (Phase 5)
- Onboarding uses Hive `settings` box (dynamic-typed) separate from domain data boxes
- Backup exports raw Hive JSON maps (not domain objects) for maximum fidelity
- Sync metadata added as passive fields — no sync logic, just structure for future backend
- Edit property reuses CreatePropertyScreen with optional editPropertyId (no new screen)
- Cascade delete order: reports → tenancy → inspections → property (least dependent first)

### Files Added/Changed in Phase 5
**New files:**
- `lib/features/onboarding/screens/onboarding_screen.dart`
- `lib/core/services/backup_service.dart`

**Modified files:**
- `lib/core/database/hive_service.dart` (settings box, onboarding helpers)
- `lib/core/router/app_router.dart` (onboarding route, edit property route, initial route logic)
- `lib/features/property/screens/create_property_screen.dart` (edit mode support)
- `lib/features/property/screens/property_details_screen.dart` (edit menu, cascade delete with reports)
- `lib/features/property/data/property_model.dart` (SyncStatus, sync fields)
- `lib/features/inspection/data/inspection_model.dart` (syncStatus field)
- `lib/features/settings/screens/settings_screen.dart` (complete rebuild with backup, storage, about, how-it-works)

**Deleted files:**
- `lib/features/inspection/data/media_item.dart` (unused placeholder)

### Hive Boxes (Updated)
```
properties  - Box<Map>  - Property records
tenancies   - Box<Map>  - TenancyRecord records
inspections - Box<Map>  - Inspection records
reports     - Box<Map>  - ReportRecord records
settings    - Box       - App preferences (onboardingCompleted, etc.)
```

---

## Pending - Phase 6 and Beyond
- Cloud sync backend (Firebase/Supabase)
- Authentication
- Delete individual photos from disk when removing from inspection
- Advanced animations and page transitions
- Monetization / subscription
- Report customization (select which rooms/photos to include)
- Report preview before generation
- Data restore from backup JSON
- Multi-language support
- Dark mode

## Bug Fixes

### share_plus MissingPluginException (Fixed)
**Symptom:** `MissingPluginException(No implementation found for method shareFiles on channel dev.fluttercommunity.plus/share)` at runtime when sharing PDFs/backups.

**Root Cause (Deep Diagnosis):**
1. Windows Developer Mode is NOT enabled on this machine
2. `flutter pub get` exits with code 1: "Building with plugins requires symlink support"
3. This prevents the Flutter tool from auto-regenerating `GeneratedPluginRegistrant.java`
4. The file was stale — only registered 3 plugins (lifecycle, image_picker, path_provider), missing `SharePlusPlugin`
5. Even though `.flutter-plugins-dependencies` IS generated correctly (listing share_plus with `native_build: true`), the Java registrant file is NOT regenerated due to the early exit

**Key findings from investigation:**
- `.flutter-plugins` file: NOT generated (newer Flutter doesn't use it — uses `.flutter-plugins-dependencies` instead)
- Gradle `native_plugin_loader.gradle.kts`: reads `.flutter-plugins-dependencies` to include native plugin builds ✓
- `share_plus-10.1.4/pubspec.yaml`: declares `pluginClass: SharePlusPlugin` for Android ✓
- Gradle `debugRuntimeClasspath`: includes `:share_plus` project dependency ✓
- share_plus Dart side: `MethodChannelShare` invokes `shareFiles` on channel `dev.fluttercommunity.plus/share` ✓
- share_plus native side: `SharePlusPlugin.kt` registers on same channel and handles `shareFiles` ✓
- Everything is correct EXCEPT the registrant wasn't regenerated

**Fix Applied:**
- Added `dev.fluttercommunity.plus.share.SharePlusPlugin` registration to `GeneratedPluginRegistrant.java`
- This manual edit is STABLE: `flutter pub get` cannot overwrite it because the symlink error causes early exit before file regeneration. `flutter clean` doesn't touch the android source tree.
- Verified with `flutter clean && flutter pub get && flutter build apk --debug` — build succeeds, APK includes share_plus native code

**Files Changed:**
- `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` (added share_plus plugin registration)

**IMPORTANT — Follow-up Required:** Enable Windows Developer Mode (`Settings → System → For Developers → Developer Mode → On`) to fix the underlying issue. Without it:
- `flutter pub get` always exits code 1 (plugins warning)
- New native plugins (e.g., if you add `url_launcher` or `camera`) will require manual registrant edits
- The Flutter team requires symlinks for proper plugin integration on Windows

### Regenerate Button UI Polish (Fixed)
**Issue:** The "Regenerate" and "Share Report" buttons were in a side-by-side Row with unequal flex (1:2), causing the Regenerate text to wrap/truncate on narrow screens. Looked unbalanced and cheap.

**Fix:** Changed the action button layout from horizontal Row to a stacked Column:
- **Share Report**: Full-width primary ElevatedButton (52px height) — the main CTA
- **Regenerate Report**: Full-width secondary OutlinedButton (48px height) below — subtler, never truncated
- Premium, balanced look on all screen widths

**Files Changed:**
- `lib/features/report/screens/report_generation_screen.dart` (action buttons redesigned, lines 219–256)

---

## Technical Notes
- Flutter SDK 3.41.2 (Dart 3.11.0)
- Dart analysis: 0 issues
- **Developer Mode on Windows: NOT enabled — `flutter pub get` exits code 1 with symlink warning. Enable for proper builds.**
- All data stored locally via Hive (5 boxes: properties, tenancies, inspections, reports, settings)
- INR currency formatting used (Indian market focus)
- image_picker: supports camera + gallery, images compressed to 1920px max, 85% quality
- pdf package: pure Dart, no native dependencies, generates professional A4 PDFs
- share_plus 10.x: uses Share.shareXFiles API for sharing files
- path_provider: PDFs saved to app documents dir under rent_shield_reports/
- Report photo budget: max 3/room, 2/flagged item, 30 total
- Sync-ready metadata on Property (SyncStatus enum) and Inspection (syncStatus string)
