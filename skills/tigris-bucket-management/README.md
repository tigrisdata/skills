# Tigris Bucket Management

A Claude skill for managing Tigris Storage buckets - creating, listing, inspecting, and deleting.

## About

Tigris buckets are containers for objects. This skill covers the complete bucket lifecycle:

- **Create** - New buckets with access controls and regions
- **List** - Enumerate all buckets with pagination
- **Inspect** - Get bucket metadata and configuration
- **Delete** - Remove buckets (with force option for non-empty)

## Installation

### Claude Code

```bash
cp -r skills/tigris-bucket-management ~/.claude/skills/
```

### claude.ai

Add the `SKILL.md` file to your project knowledge or paste its contents into the conversation.

## Usage

Trigger this skill when working with buckets:

- "Create a bucket named..."
- "List all my buckets"
- "Get bucket info"
- "Delete this bucket"

## Quick Reference

| Operation | Function | Key Parameters |
|-----------|----------|----------------|
| Create | `createBucket(name, options)` | name, access, region, enableSnapshot |
| List | `listBuckets(options)` | limit, paginationToken |
| Inspect | `getBucketInfo(name)` | bucketName |
| Delete | `removeBucket(name, options)` | bucketName, force |

## Example

```typescript
import { createBucket, listBuckets } from "@tigrisdata/storage";

// Create a private bucket
const result = await createBucket("my-app-data", {
  access: "private"
});

// List all buckets
const buckets = await listBuckets({ limit: 10 });
```

## License

MIT
