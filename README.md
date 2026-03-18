# Agent Skills

A collection of skills for AI coding agents. Skills are packaged instructions that extend agent capabilities for working with Tigris object storage and writing Go tests.

## Available Skills

### file-storage

Get started with Tigris file storage. CLI setup (bucket, access keys, environment) and `@tigrisdata/storage` SDK for application code.

**Use when:**

- "File storage", "upload file", "store files"
- "Tigris", "set up Tigris", "tigris bucket"
- "Client upload", "presigned URL"

**What's covered:**

- CLI setup: authenticate, create bucket, create and assign access keys
- SDK reference: `put`, `get`, `remove`, `list`, `head`, `getPresignedUrl`
- Client-side browser uploads via `handleClientUpload`
- Common patterns: avatar upload, API route file serving
- Critical rules and known issues prevention

### installing-tigris-storage

> **Superseded by `file-storage`.** This skill now redirects to `file-storage`, which covers everything this skill did and more.

**Upgrade:**

```bash
npx skills add https://github.com/tigrisdata/skills --skill file-storage
```

### tigris-bucket-management

Create, list, inspect, and delete Tigris Storage buckets with support for regions, access levels, and storage tiers.

**Use when:**
- "Create a bucket"
- "List my buckets"
- "Delete bucket"
- "Check bucket info"

**Operations covered:**
- `createBucket(name, options)` - with access, region, snapshot enablement
- `listBuckets(options)` - with pagination
- `getBucketInfo(name)` - inspect bucket metadata
- `removeBucket(name, options)` - including force delete

**Options supported:** public/private access, consistency levels, storage tiers (STANDARD/STANDARD_IA/GLACIER), regional deployment, and snapshot/fork source.

### tigris-object-operations

Upload, download, delete, list, and inspect objects in Tigris Storage. Generate presigned URLs for temporary access.

**Use when:**
- "Upload file"
- "Download object"
- "List files"
- "Get presigned URL"
- "Delete object"

**Operations covered:**
- `put(path, body, options)` - upload with progress tracking, multipart for large files
- `get(path, format, options)` - download as string/file/stream
- `remove(path, options)` - delete objects
- `list(options)` - list with prefix filtering and pagination
- `head(path, options)` - get object metadata
- `getPresignedUrl(path, options)` - generate temporary access URLs

### tigris-snapshots-forking

Point-in-time recovery and bucket forking for version control, testing, and developer sandboxes.

**Use when:**
- "Create snapshot"
- "Restore from snapshot"
- "Fork bucket"
- "Point-in-time recovery"

**What's covered:**
- `createBucketSnapshot(options)` - capture bucket state
- `listBucketSnapshots(sourceBucketName)` - view history
- Forking buckets from snapshots - instant, isolated copies
- Reading from snapshot versions
- Deletion protection patterns

**Use cases:** Developer sandboxes, AI agent environments, load testing with production data, pre-migration backups.

### go-table-driven-tests

Write Go table-driven tests following established patterns. Covers test structure, naming conventions, error handling, and integration test guards.

**Use when:**
- Writing tests in Go
- Creating test functions
- Adding test cases
- "Go test", "table-driven test"

**Patterns covered:**
- Table structure with `name`, input, `want`, `wantErr`, `errCheck`, `setupEnv` fields
- Environment guards for integration tests (`skipIfNoCreds`)
- Test helpers with `t.Helper()`
- Custom error validation
- Parallel testing with `t.Parallel()`

### tigris-file-uploads

File uploads, downloads, and serving across all major web frameworks with Tigris.

**Use when:**
- "File upload", "upload file", "download file"
- "Next.js upload", "Remix upload", "Express upload"
- "Rails file upload", "Django file upload", "Laravel file upload"
- "Client upload", "presigned URL", "direct upload"

**What's covered:**
- **Next.js** — Server Actions, API Routes, `next/image` with `remotePatterns`, Vercel deployment
- **Remix** — Action functions, loaders, resource routes, Fly.io deployment
- **Express** — Multer middleware, streaming uploads, Docker deployment
- **Rails** — Active Storage S3 service, direct uploads, image variants
- **Django** — django-storages with `tigris-boto3-ext`, FileField/ImageField
- **Laravel** — Storage facade S3 disk, Livewire uploads, Forge/Vapor deployment
- Client-side direct uploads, presigned URLs, multipart with progress

### tigris-image-optimization

Resize, crop, and optimize images stored in Tigris across all major frameworks.

**Use when:**
- "Image optimization", "resize images", "thumbnails"
- "Responsive images", "image CDN"

**What's covered:**
- Upload-time variant generation (Sharp, ImageMagick, Pillow, Intervention)
- Framework-specific: next/image, Active Storage variants, django-imagekit
- CDN delivery via Tigris public buckets

### tigris-static-assets

Deploy static assets (CSS, JS, fonts) to Tigris for global CDN delivery.

**Use when:**
- "Static assets", "deploy CSS/JS", "asset CDN"
- "Cache headers", "asset pipeline"

**What's covered:**
- Cache-Control headers, cache-busting strategies
- Framework integration: assetPrefix, collectstatic, Sprockets, Vite
- Upload scripts, immutable caching

### tigris-backup-export

Back up databases and export data to Tigris with automated pipelines.

**Use when:**
- "Backup database", "database dump"
- "Scheduled backup", "data export"

**What's covered:**
- pg_dump/mysqldump with compression
- Framework schedulers: node-cron, whenever, celery-beat, Laravel Scheduler
- Retention policies via lifecycle rules, restore workflows

### tigris-s3-migration

Migrate from AWS S3, GCS, or Azure Blob to Tigris with zero downtime.

**Use when:**
- "Migrate from S3", "switch to Tigris"
- "Shadow bucket", "S3 compatible"

**What's covered:**
- Shadow buckets (zero-downtime automatic backfill)
- Bulk copy via CLI, SDK endpoint swaps (Node.js, Python, Ruby, PHP)
- Verification checklist, rollback strategy

### tigris-egress-optimizer

Diagnose and fix excessive storage bandwidth costs.

**Use when:**
- "Egress costs", "high storage bill"
- "Bandwidth optimization", "reduce data transfer"

**What's covered:**
- 4-step framework: diagnose, analyze, fix, verify
- Anti-patterns: server proxying, missing cache headers, no CDN
- Fixes: public buckets (built-in CDN), presigned URLs, thumbnails

### tigris-security-access-control

Configure access keys, CORS, bucket policies, and security for Tigris.

**Use when:**
- "CORS", "access key rotation"
- "Security audit", "bucket permissions"

**What's covered:**
- Access key lifecycle, Editor/ReadOnly roles
- CORS configs (dev, production, permissive)
- Presigned URL security, audit checklist, key compromise response

### tigris-lifecycle-management

Automate object expiration, storage tier transitions, and cleanup.

**Use when:**
- "Lifecycle rules", "auto-delete"
- "Storage tiers", "TTL", "expiration"

**What's covered:**
- Lifecycle rule JSON format and CLI
- Patterns: temp cleanup, log archival, backup retention
- Storage tiers (STANDARD, IA, GLACIER), cost modeling

### tigris-snapshots-recovery

Point-in-time recovery for deleted or changed files in Tigris.

**Use when:**
- "Recover deleted file", "undo delete"
- "Point-in-time recovery", "restore from snapshot"
- "Enable snapshots", "revert to previous version"

**What's covered:**
- Snapshot-enabled buckets (must enable at creation, not after)
- Automatic change tracking — every put/delete preserved without explicit snapshots
- Recover single files, bulk restore prefixes, revert overwrites
- TypeScript, Go, and Python examples

### tigris-sdk-guide

Guide for choosing between Tigris-native SDKs and AWS S3-compatible SDKs.

**Use when:**
- "Which SDK", "Tigris SDK vs AWS SDK"
- "boto3 Tigris", "storage-go"
- Setting up Tigris in a new language

**What's covered:**
- Decision table: native SDK (TS, Go) vs AWS SDK fallback (Python, Ruby, PHP)
- CLI: `tigris`/`t3` instead of `aws s3`
- S3-compatible configuration (endpoint, region, path style)
- Tigris-only features not available through AWS SDKs

### conventional-commits

Structured commit message format for clear project history, automated changelog generation, and semantic versioning.

**Use when:**
- Creating git commits
- Writing commit messages
- Following version control workflows

**Commit types:**
- `feat` - New feature (MINOR version)
- `fix` - Bug fix (PATCH version)
- `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert` - PATCH version
- Breaking changes marked with `!` or `BREAKING CHANGE:` footer

**Requirements:**
- Imperative mood, lowercase, no trailing period
- AI attribution in footer: `Assisted-by: Model via Tool`
- Use `--signoff` flag when committing

## Installation

**Quick install (all skills):**

```bash
npx skills add tigrisdata/skills
```

Browse skills at [https://skills.sh/tigrisdata/skills](https://skills.sh/tigrisdata/skills)

**Claude Code (manual install):**

```bash
cp -r skills/{skill-name} ~/.claude/skills/
```

**claude.ai:**

Add individual skill directories to project knowledge or paste `SKILL.md` contents into the conversation.

## Usage

Skills are automatically available once installed. The agent will use them when relevant tasks are detected.

**Examples:**

```
Install Tigris storage in my Next.js project
```

```
Create a bucket called my-app-assets with public access
```

```
Upload this file to Tigris
```

```
Write a Go test for this function
```

```
Commit these changes
```

## Skill Structure

Each skill contains:

- `SKILL.md` - Instructions for the agent (required)
- `README.md` - User-facing documentation (optional)
- `scripts/` - Helper scripts for automation (optional)
- `references/` - Supporting documentation (optional)

## Creating New Skills

See [AGENTS.md](AGENTS.md) for guidance on creating new skills in this repository.

**Directory structure:**

```
skills/
{skill-name}/
  SKILL.md           # Required: agent instructions
  README.md          # Optional: user documentation
```

**Naming conventions:**
- Skill directory: `kebab-case` (e.g., `tigris-deploy`)
- SKILL.md: Always uppercase, exact filename

**Best practices:**
- Keep SKILL.md under 500 lines for context efficiency
- Write specific descriptions with trigger phrases
- Use progressive disclosure for detailed reference
- Include code examples and quick reference tables

## License

MIT
