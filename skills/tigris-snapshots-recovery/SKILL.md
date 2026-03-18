---
name: tigris-snapshots-recovery
description: Use when recovering deleted or changed files from Tigris, restoring objects to a previous state, or setting up snapshot-enabled buckets for point-in-time recovery
---

# Tigris Snapshots & Point-in-Time Recovery

Recover deleted or changed files from any point in time. Tigris snapshot-enabled buckets automatically track every change — you can restore files without having explicitly taken a snapshot.

## Key Facts

- **Snapshots must be enabled at bucket creation time.** You cannot enable snapshots on an existing bucket. You must create a new bucket with snapshots enabled.
- **Every change is tracked automatically.** Even without explicitly taking a snapshot, every put, delete, and overwrite is preserved. You can recover any object from any point in time.
- **Explicit snapshots are optional bookmarks.** Taking a named snapshot just marks a point in time for easy reference. The data is already preserved regardless.
- **Snapshot buckets must use STANDARD storage tier.** Lifecycle transitions and TTL are not supported on snapshot-enabled buckets.

---

## Create a Snapshot-Enabled Bucket

### CLI

```bash
# New bucket with snapshots enabled
tigris buckets create my-bucket --snapshot

# ⚠ This will NOT work — cannot enable snapshots on existing bucket
# tigris buckets update my-bucket --snapshot  ← NOT SUPPORTED
```

### TypeScript SDK

```typescript
import { createBucket } from "@tigrisdata/storage";

const result = await createBucket("my-bucket", {
  enableSnapshot: true,
});
if (result.error) {
  console.error(result.error);
}
```

### Go SDK

```go
import "github.com/tigrisdata/storage-go/storage"

client, _ := storage.New(ctx)
err := client.CreateSnapshotBucket(ctx, "my-bucket")
```

### Python (tigris-boto3-ext)

```python
from tigris_boto3_ext import create_snapshot_bucket

create_snapshot_bucket(s3, "my-bucket")
```

### Migrating an Existing Bucket

If you need snapshots on an existing bucket, you must create a new snapshot-enabled bucket and copy the data:

```bash
# 1. Create new snapshot-enabled bucket
tigris buckets create my-bucket-v2 --snapshot

# 2. Copy all data
tigris cp t3://my-bucket/ t3://my-bucket-v2/ -r

# 3. Update your app to use the new bucket name

# 4. Delete the old bucket (when ready)
tigris buckets delete my-bucket
```

---

## How Automatic Tracking Works

Once snapshots are enabled, Tigris preserves every version of every object:

```
Timeline:
  T1: put("config.json", v1)        → v1 stored
  T2: put("config.json", v2)        → v2 stored, v1 still accessible
  T3: remove("config.json")         → deleted, but v1 and v2 still accessible
  T4: put("config.json", v3)        → v3 stored, v1, v2, and deletion all accessible
```

You can read the state of any object (or the entire bucket) at any of these timestamps — no explicit snapshot needed.

---

## Restore from a Snapshot Identifier

The most common recovery workflow: list your snapshots, pick one, and restore.

### Step 1: List Snapshots and Find the Right One

```typescript
import { listBucketSnapshots } from "@tigrisdata/storage";

const result = await listBucketSnapshots("my-bucket");
console.log(result.data);
// [
//   { name: "before-deploy-v2.3", version: "1751631910169675092", creationDate: 2026-03-17T14:00:00Z },
//   { name: "daily-2026-03-16",   version: "1751545510169675092", creationDate: 2026-03-16T02:00:00Z },
//   { name: "before-migration",   version: "1751459110169675092", creationDate: 2026-03-15T02:00:00Z },
// ]
```

```bash
# CLI
tigris snapshots list my-bucket
```

### Step 2: Find the Snapshot by Name

```typescript
// Find a specific snapshot by name
const snapshots = result.data ?? [];
const target = snapshots.find((s) => s.name === "before-deploy-v2.3");
if (!target) throw new Error("Snapshot not found");

const snapshotVersion = target.version;
console.log(`Restoring from snapshot: ${target.name} (${target.version})`);
```

### Step 3: Restore a Single File from That Snapshot

```typescript
import { get, put } from "@tigrisdata/storage";

// Read the file as it existed at the snapshot
const old = await get("config.json", "string", { snapshotVersion });

if (old.error) {
  console.log("File did not exist at this snapshot");
} else {
  // Write it back as the current version
  await put("config.json", old.data, { contentType: "application/json" });
  console.log("File restored from snapshot");
}
```

### Step 4: Or Restore the Entire Bucket from That Snapshot

```typescript
import { list, get, put } from "@tigrisdata/storage";

async function restoreFromSnapshot(bucketName: string, snapshotVersion: string) {
  // List all objects as they were at the snapshot
  const allFiles = [];
  let page = await list({ snapshotVersion, limit: 100, config: { bucket: bucketName } });
  allFiles.push(...(page.data?.items ?? []));

  while (page.data?.hasMore) {
    page = await list({
      snapshotVersion,
      limit: 100,
      paginationToken: page.data.paginationToken,
      config: { bucket: bucketName },
    });
    allFiles.push(...(page.data?.items ?? []));
  }

  console.log(`Restoring ${allFiles.length} files from snapshot ${snapshotVersion}...`);

  for (const file of allFiles) {
    const old = await get(file.path, "file", {
      snapshotVersion,
      config: { bucket: bucketName },
    });
    if (!old.error) {
      await put(file.path, old.data, {
        contentType: file.contentType,
        config: { bucket: bucketName },
      });
    }
  }

  console.log("Restore complete");
}

// Usage: find snapshot and restore
const snapshots = await listBucketSnapshots("my-bucket");
const target = snapshots.data?.find((s) => s.name === "before-deploy-v2.3");
await restoreFromSnapshot("my-bucket", target!.version);
```

---

## Restore a Specific Prefix from a Snapshot

Restore just a subdirectory (e.g., only `uploads/`) instead of the entire bucket:

```typescript
async function restorePrefixFromSnapshot(
  bucketName: string,
  prefix: string,
  snapshotVersion: string,
) {
  const allFiles = [];
  let page = await list({ prefix, snapshotVersion, limit: 100, config: { bucket: bucketName } });
  allFiles.push(...(page.data?.items ?? []));

  while (page.data?.hasMore) {
    page = await list({
      prefix,
      snapshotVersion,
      limit: 100,
      paginationToken: page.data.paginationToken,
      config: { bucket: bucketName },
    });
    allFiles.push(...(page.data?.items ?? []));
  }

  for (const file of allFiles) {
    const old = await get(file.path, "file", {
      snapshotVersion,
      config: { bucket: bucketName },
    });
    if (!old.error) {
      await put(file.path, old.data, {
        contentType: file.contentType,
        config: { bucket: bucketName },
      });
    }
  }

  console.log(`Restored ${allFiles.length} files under ${prefix}`);
}

// Restore just the uploads directory from a named snapshot
const target = snapshots.data?.find((s) => s.name === "before-migration");
await restorePrefixFromSnapshot("my-bucket", "uploads/", target!.version);
```

---

## Recover Without an Explicit Snapshot (Using Timestamps)

Even if you never took a named snapshot, every change is tracked. Use any timestamp:

```typescript
// Convert a date to a snapshot version (nanoseconds since Unix epoch)
const targetDate = new Date("2026-03-17T14:00:00Z");
const snapshotVersion = String(targetDate.getTime() * 1_000_000);

// Now use this version exactly like a named snapshot version
const old = await get("config.json", "string", { snapshotVersion });
```

This works because snapshot versions are nanosecond timestamps. Named snapshots just record a specific timestamp for convenience.

---

## Recover a Changed File (Undo an Overwrite)

Same approach — read the old version from a snapshot and write it back:

```typescript
import { get, put, listBucketSnapshots } from "@tigrisdata/storage";

// Find the snapshot taken before the bad change
const snapshots = await listBucketSnapshots("my-bucket");
const target = snapshots.data?.find((s) => s.name === "before-deploy-v2.3");

// Read what the file looked like at that snapshot
const old = await get("data/users.json", "string", {
  snapshotVersion: target!.version,
});

if (!old.error) {
  await put("data/users.json", old.data, { contentType: "application/json" });
  console.log("Reverted to previous version");
}
```

---

## Compare Current vs Snapshot

Check what changed between now and a specific snapshot:

```typescript
import { get, listBucketSnapshots } from "@tigrisdata/storage";

const snapshots = await listBucketSnapshots("my-bucket");
const target = snapshots.data?.find((s) => s.name === "before-deploy-v2.3");

// Current version
const current = await get("config.json", "string");

// Version at snapshot
const atSnapshot = await get("config.json", "string", {
  snapshotVersion: target!.version,
});

if (current.data !== atSnapshot.data) {
  console.log("File has changed since snapshot");
  // Diff, log, or restore as needed
}
```

---

## Taking Explicit Snapshots (Optional Bookmarks)

While every change is tracked automatically, named snapshots make it easier to find specific points in time:

```typescript
import { createBucketSnapshot } from "@tigrisdata/storage";

// Before a deploy
await createBucketSnapshot("my-bucket", {
  name: "before-deploy-v2.3",
});

// Before a data migration
await createBucketSnapshot("my-bucket", {
  name: "before-user-data-migration",
});
```

```bash
# CLI
tigris snapshots take my-bucket --name "before-deploy-v2.3"
```

**When to take explicit snapshots:**
- Before deployments or migrations
- Before bulk data operations
- Daily/weekly as bookmarks for easy reference
- Before any risky operation

**When you don't need explicit snapshots:**
- For recovering a single file — just use a timestamp
- For routine changes — automatic tracking covers this

---

## Go SDK Examples

```go
import (
    "github.com/tigrisdata/storage-go/storage"
)

client, _ := storage.New(ctx)

// Create snapshot-enabled bucket
client.CreateSnapshotBucket(ctx, "my-bucket")

// Take named snapshot
version, _ := client.CreateBucketSnapshot(ctx, "my-bucket")

// Read object at snapshot version
obj, _ := client.GetObjectAtVersion(ctx, "my-bucket", "config.json", version)

// List snapshots
snapshots, _ := client.ListBucketSnapshots(ctx, "my-bucket")
```

---

## Python Examples (tigris-boto3-ext)

```python
from tigris_boto3_ext import TigrisSnapshot, create_snapshot_bucket

# Create snapshot-enabled bucket
create_snapshot_bucket(s3, "my-bucket")

# Read object at a point in time
with TigrisSnapshot(s3, "my-bucket", version="1751631910169675092") as snap:
    obj = snap.get_object(Key="config.json")
    content = obj["Body"].read()

# Take explicit snapshot
from tigris_boto3_ext import create_snapshot
version = create_snapshot(s3, "my-bucket", name="before-deploy")
```

---

## Critical Rules

**Always:**
- Enable snapshots when creating the bucket — you cannot add it later
- Use STANDARD storage tier for snapshot-enabled buckets
- Test recovery on a non-production bucket first
- Remember that any nanosecond timestamp works as a snapshot version

**Never:**
- Assume you can enable snapshots on an existing bucket (you must create a new one)
- Rely on explicit snapshots alone — automatic tracking means you can recover from any timestamp
- Use lifecycle rules or TTL on snapshot-enabled buckets (not supported)
- Forget to paginate when restoring many files

---

## Known Issues

| Problem | Fix |
|---------|-----|
| "Snapshots not enabled" error | Bucket was created without `--snapshot` / `enableSnapshot: true`. Create a new bucket and copy data. |
| Can't find the right timestamp | Take explicit named snapshots before risky operations for easy reference |
| Restore is slow for many files | Batch restores with concurrency limits; consider forking instead for full-bucket recovery |
| Snapshot bucket won't transition tiers | Snapshot buckets must use STANDARD tier — lifecycle transitions are not supported |

---

## Related Skills

- **tigris-snapshots-forking** — Forking buckets for dev sandboxes and testing
- **file-storage** — SDK reference for `get`, `put`, `list`
- **tigris-backup-export** — Complementary backup strategy with database dumps

## Official Documentation

- Snapshots: https://www.tigrisdata.com/docs/buckets/snapshots-and-forks/
