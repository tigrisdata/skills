# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, Cursor, Copilot, etc.) when working with code in this repository.

## Repository Overview

A collection of skills for Claude.ai and Claude Code for working with Tigris object storage and writing Go table-driven tests. Skills are packaged instructions that extend Claude's capabilities.

## Skills Overview

| Skill                       | Description                                                       | Use When...                                                                     |
| --------------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `installing-tigris-storage` | Setting up @tigrisdata/storage in a new project                   | User mentions "install Tigris", "setup object storage", "@tigrisdata/storage"   |
| `tigris-bucket-management`  | Creating, listing, inspecting, and deleting Tigris buckets        | User mentions "bucket", "create bucket", "list buckets"                         |
| `tigris-object-operations`  | Uploading, downloading, deleting, listing objects, presigned URLs | User mentions "upload", "download", "put object", "get object", "presigned URL" |
| `tigris-snapshots-forking`  | Point-in-time recovery, bucket forking for testing                | User mentions "snapshot", "fork", "point-in-time recovery", "restore"           |
| `go-table-driven-tests`     | Writing Go table-driven tests following established patterns      | User mentions "Go test", "table-driven test", "test coverage" in Go codebase    |

## Creating a New Skill

### Directory Structure

```
skills/
{skill-name}/      # kebab-case directory name
SKILL.md           # Required: skill definition
```

### Naming Conventions

- **Skill directory**: `kebab-case` (e.g., `tigris-deploy`, `log-monitor`)
- **SKILL.md**: Always uppercase, always this exact filename
- Scripts (if any): `kebab-case.sh` (e.g., `deploy.sh`, `fetch-logs.sh`)

### SKILL.md Format

````markdown
---
name: { skill-name }
description:
  { One sentence describing when to use this skill. Include trigger phrases }
---

# {Skill Title}

{Brief description of what the skill does.}

## Overview

{High-level explanation of the concept}

## Quick Reference

| Operation | Function | Key Parameters |
| --------- | -------- | -------------- |
| ...       | ...      | ...            |

## Usage

```typescript
// Code examples
```
````

## Present Results to User

{Template for how Claude should format results when presenting to users}

## Troubleshooting

{Common issues and solutions}

````

### Best Practices for Context Efficiency

Skills are loaded on-demand — only the skill name and description are loaded at startup. The full `SKILL.md` loads into context only when the agent decides the skill is relevant. To minimize context usage:

- **Keep SKILL.md under 500 lines** — put detailed reference material in separate files
- **Write specific descriptions** — helps the agent know exactly when to activate the skill
- **Use progressive disclosure** — reference supporting files that get read only when needed
- **Include trigger phrases in description** — words users commonly say when they need this skill

### Content Guidelines

- **Code examples** - Show practical, copy-pasteable examples
- **Quick reference tables** - For API methods, operations, or parameters
- **Troubleshooting section** - Common errors and their solutions
- **Present Results section** - Template for how Claude should format output for users

### End-User Installation

Document these installation methods for users:

**Claude Code:**
```bash
cp -r skills/{skill-name} ~/.claude/skills/
````

**claude.ai:**
Add the skill to project knowledge or paste SKILL.md contents into the conversation.

## Contribution Guidelines

### Commit Guidelines

Commit messages follow **Conventional Commits** format:

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

- Add `!` after type/scope for breaking changes or include `BREAKING CHANGE:` in the footer
- Keep descriptions concise, imperative, lowercase, and without a trailing period
- Reference issues/PRs in the footer when applicable

### Attribution Requirements

AI agents must disclose what tool and model they are using in the "Assisted-by" commit footer:

```text
Assisted-by: [Model Name] via [Tool Name]
```

Example:

```text
Assisted-by: GLM 4.6 via Claude Code
```
