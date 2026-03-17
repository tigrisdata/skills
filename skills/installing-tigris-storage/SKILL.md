---
name: installing-tigris-storage
description: Use when setting up @tigrisdata/storage in a new project or configuring authentication and bucket access
---

# Installing Tigris Storage

> **This skill has been superseded by the `file-storage` skill**, which covers CLI setup, SDK usage, uploads, downloads, presigned URLs, and client-side uploads in a single skill.

## Install the Updated Skill

```bash
npx skills add https://github.com/tigrisdata/skills --skill file-storage
```

## Quick Start

```bash
# 1. Install CLI & authenticate
npm install -g @tigrisdata/cli
tigris login

# 2. Create bucket and access key
tigris buckets create my-app-uploads
tigris access-keys create "my-app-uploads-key"
# ⚠ Save the Secret Access Key — shown only once
tigris access-keys assign tid_xxx --bucket my-app-uploads --role Editor

# 3. Install SDK
npm install @tigrisdata/storage
```

```bash
# .env
TIGRIS_STORAGE_ACCESS_KEY_ID=tid_xxx
TIGRIS_STORAGE_SECRET_ACCESS_KEY=tsec_yyy
TIGRIS_STORAGE_ENDPOINT=https://t3.storage.dev
TIGRIS_STORAGE_BUCKET=my-app-uploads
```

```typescript
import { put } from "@tigrisdata/storage";

// Files are private by default — only authenticated requests can access them
const result = await put("avatars/user-123.jpg", file);
if (result.error) throw result.error;
console.log(result.data?.url);
```

For full SDK reference, presigned URLs, client-side uploads, and troubleshooting — use the **`file-storage`** skill.
