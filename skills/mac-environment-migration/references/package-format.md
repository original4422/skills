# Package and Execution Records

Use this format for source export, target ingestion, and resumption. Store
structured inventories as UTF-8 JSON and user summaries as Markdown. The
package is a handoff format, not an executable script.

## Portable package

```text
mac-migration-<timestamp-or-short-id>/
  manifest.json
  summary.md
  configs/          # Only approved, reviewed text configurations
```

Exclude target backups, sensitive execution history, and installers. Count the
10,000,000-byte default limit against total uncompressed size. The summary
reports actual size, contents, exclusions, missing information, and how to
continue on the target. Record capture time so an old package is not mistaken
for current source state.

## manifest.json v1

Required top-level fields:

| Field | Contents |
| --- | --- |
| `schema_version` | Number `1`. Explain or convert unsupported versions before use; do not guess their meaning. |
| `migration_id` | Collection identifier, not a device serial number or user account. |
| `captured_at` | ISO 8601 timestamp with time zone. |
| `source` | `macos_version`, `architecture`, and necessary hardware capabilities; no serial number. |
| `selected_sections` | Nonempty subset of `settings`, `software`, and `environment`. |
| `items` | Inventory entries using the common fields below. |
| `app_restore_hints` | Application restoration metadata; an empty list if none. |
| `omissions` | Unreadable, excluded, or redacted information with reasons; an empty list if none. |
| `files` | Included file inventory; an empty list if none. |

Common item fields:

- `id`: unique, stable identifier connecting inventory, plan, execution, and
  backup records.
- `section`: one of the selected sections.
- `name`: readable item name.
- `observed`: actual source value, version, or configuration summary; `null`
  when unknown.
- `evidence`: observation method or source location and verification limits;
  no raw sensitive values.
- `compatibility_notes`: known architecture, system-version, or path constraints.

Add relevant type-specific details, leaving unknown values empty:

- **Settings:** category, preference domain and key or UI location, value type,
  and applicable hardware. Verify write methods on the target; do not store
  commands intended for direct execution.
- **Software:** bundle ID or other reliable identity, developer, version,
  installation origin, candidate formula/cask identity, official links, and
  whether it is directly used. A candidate package is not installation approval.
- **Environment:** tool or configuration purpose, version manager, original
  version, configuration-file references, roles of original paths, and fields
  to recompute on the target. Avoid full process-environment dumps.

Each `app_restore_hints` entry identifies the application, configuration
locations, plugin names and versions when observable, official sync/import
methods, additional source data required, and limitations. Store only metadata
by default. For accounts, record that user sign-in is required, not credentials
or sessions.

Each `files` entry records its package-relative path, byte count, SHA-256,
purpose, associated item IDs, and intended destination role. Include contents
only after sensitive-content review and approval. Explain placeholders such as
`${USER_HOME}` and resolve them during target planning; do not directly expand
or execute package text. Do not claim a missing file is included.

On ingestion, verify field types, unique item IDs, file sizes, and checksums.
Package file references must not use absolute paths, `..` traversal, or
symlinks escaping the package. Verify identity and paths before planning writes.
A matching hash proves consistency, not trust in the source.

## Target-local records

Keep one run's `plan.json`, `run.json`, and, only when needed, `backups/` together
in the workspace or agreed location. Keep this directory separate from the
portable package and show its location to the user.

`plan.json` records migration and run IDs, target system and architecture,
selected sections, acceptance mode, per-item differences and actions, origins,
dependencies, verification methods, the approved item set, and plan version.
Record only approval actually received. Version changed actions and identify
which items need renewed approval.

Keep `run.json` compact:

- Run identifier, start time, last update time, and associated plan version.
- Item status: `planned / approved / running / verified / failed / blocked /
  manual / skipped`. Record user acceptance separately as `pending / accepted /
  deferred`; automatic verification is not user acceptance.
- Actual changes, verification results, concise errors, and next actions.
  Record necessary recovery values only after review; secrets belong solely
  in protected local backups.
- Backup index: `path` (absolute), `purpose`, `item_ids`, `bytes`, and `status`
  (`retained / removed`). If no backup is needed, record why rather than creating
  an empty backup.
- Final assessment: exact recommended deletion or retention paths and reasons,
  actual cleanup approval, and results. Never mark unreceived approval as granted.

Avoid lengthy terminal transcripts, full environment dumps, and duplicate
configuration. Present the backup index as **path | purpose**, adding size and
recommendation for cleanup assessment. Save redacted diagnostic logs only when
needed.

Retain enough original and written-state information to detect restoration
conflicts. Source values cannot substitute for the target's actual pre-change
values. After interruption, reconcile records against the device; do not assume
an uncertain operation succeeded or rerun it blindly.
