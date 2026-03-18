# tigris-file-uploads

Framework-agnostic file uploads, downloads, and serving with Tigris object storage.

## What It Covers

- **Next.js** — Server Actions, API Routes, `next/image` with `remotePatterns`, Vercel deployment
- **Remix** — Action functions, loaders, resource routes, Fly.io deployment
- **Express** — Multer middleware, streaming uploads, Docker deployment
- **Rails** — Active Storage with S3 service, direct uploads, image variants, Fly.io/Kamal deployment
- **Django** — django-storages with `tigris-boto3-ext`, FileField/ImageField, Fly.io deployment
- **Laravel** — Storage facade S3 disk, Livewire uploads, Forge/Vapor deployment
- **Client-side uploads** — Browser-direct via `handleClientUpload` (JS) or presigned URLs (all frameworks)
- **Presigned URLs** — Temporary access for downloads and uploads
- **Multipart uploads** — Large file handling with progress tracking

## Installation

**Claude Code:**

```bash
cp -r skills/tigris-file-uploads ~/.claude/skills/
```

**claude.ai:**

Add `skills/tigris-file-uploads` to project knowledge or paste `SKILL.md` contents into the conversation.

## Usage

This skill activates when you mention:

- "File upload", "upload file", "download file"
- "Next.js upload", "Remix upload", "Express upload"
- "Rails file upload", "Active Storage Tigris"
- "Django file upload", "Laravel file upload"
- "Client upload", "presigned URL", "direct upload"

## Example Prompts

```text
Add file uploads to my Next.js app using Tigris
```

```text
Set up Active Storage with Tigris in my Rails project
```

```text
Add client-side direct uploads to my Express app
```

```text
Configure django-storages to use Tigris for file uploads
```

## License

MIT
