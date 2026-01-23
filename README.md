# Agent Skills

A collection of skills for AI coding agents. Skills are packaged instructions that extend agent capabilities for working with Tigris object storage and writing Go tests.

## Available Skills

### installing-tigris-storage

Get started with Tigris Storage by installing the package, creating account resources, and configuring authentication.

**Use when:**
- "Install Tigris"
- "Setup object storage"
- "Configure @tigrisdata/storage"
- "Set up bucket access"

**What's covered:**
- Package installation (`npm install @tigrisdata/storage`)
- Account setup at https://storage.new
- Environment configuration with `.env`
- Per-request configuration overrides

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
