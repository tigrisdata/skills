---
name: tigris-file-uploads
description: Use when adding file uploads, downloads, or file serving to any web framework — Next.js, Remix, Express, Rails, Django, or Laravel with Tigris
---

# File Uploads with Tigris

Upload, download, and serve files across all major web frameworks using Tigris object storage.

## Prerequisites

**Before doing anything else**, install the Tigris CLI if it's not already available:

```bash
tigris help || npm install -g @tigrisdata/cli
```

If you need to install it, tell the user: "I'm installing the Tigris CLI (`@tigrisdata/cli`) so we can work with Tigris object storage."

## SDK Quick Reference

| Framework | SDK | Install |
|-----------|-----|---------|
| Next.js, Remix, Express | `@tigrisdata/storage` (native) | `npm install @tigrisdata/storage` |
| Rails | `aws-sdk-s3` (no native Ruby SDK yet) | `gem "aws-sdk-s3"` |
| Django | `tigris-boto3-ext` + `django-storages` | `pip install django-storages tigris-boto3-ext` |
| Laravel | `league/flysystem-aws-s3-v3` (no native PHP SDK yet) | `composer require league/flysystem-aws-s3-v3` |

---

## Environment Variables

All frameworks need these credentials:

```bash
# .env
TIGRIS_STORAGE_ACCESS_KEY_ID=tid_xxx
TIGRIS_STORAGE_SECRET_ACCESS_KEY=tsec_yyy
TIGRIS_STORAGE_ENDPOINT=https://t3.storage.dev
TIGRIS_STORAGE_BUCKET=my-app-uploads
```

---

## Framework Guides

Read the resource file for your framework:

- **Next.js** — Read `./resources/nextjs.md` for Server Actions, API Routes, next/image, client uploads
- **Remix** — Read `./resources/remix.md` for action functions, loaders, client uploads
- **Express** — Read `./resources/express.md` for Multer, streaming uploads, client uploads
- **Rails** — Read `./resources/rails.md` for Active Storage, direct uploads, image variants
- **Django** — Read `./resources/django.md` for FileField, django-storages, presigned URLs
- **Laravel** — Read `./resources/laravel.md` for Storage facade, Livewire uploads, presigned URLs

---

## Public vs Private Access

| Level | Who can access | How to set |
|-------|---------------|------------|
| **Private** (default) | Authenticated requests or presigned URLs only | Default — no flag needed |
| **Public** | Anyone with the URL | SDK: `access: "public"` / Bucket: `--public` flag |

**Rule:** Default to private. Only use public for assets that anonymous users need to access directly (avatars, product images, static assets).

---

## Deployment

| Framework | Platform | Set env vars with |
|-----------|----------|-------------------|
| Next.js | Vercel | Dashboard → Settings → Environment Variables |
| Remix | Fly.io | `fly secrets set TIGRIS_STORAGE_ACCESS_KEY_ID=... ...` |
| Express | Docker | `-e` flags or `.env` in Compose |
| Rails | Fly.io / Kamal | `fly secrets set` or `kamal env push` |
| Django | Fly.io | `fly secrets set` |
| Laravel | Forge / Vapor | Dashboard → Environment or `vapor env:pull` |

---

## Critical Rules

**Always:**
- Check `result.error` before `result.data` (JS SDK)
- Upload as `private` by default
- Use `handleClientUpload` for browser uploads in JS frameworks (don't route bytes through server)
- Use `multipart: true` for files over 100MB (JS SDK)
- Sanitize filenames — use structured paths like `uploads/{userId}/{timestamp}-{name}`
- Set `contentType` explicitly when it matters

**Never:**
- Expose access keys to the client
- Use generic paths like `file.jpg`
- Skip error checking
- Hard-code credentials — always use environment variables

---

## Known Issues

| Problem | Fix |
|---------|-----|
| "Access denied" on upload | Key not assigned to bucket. Run `tigris access-keys assign tid_xxx --bucket <name> --role Editor` |
| "Bucket not found" | Wrong bucket name in env. Verify with `tigris buckets list` |
| Upload hangs on large files | Add `multipart: true` (JS) or check `AWS_S3_MAX_MEMORY_SIZE` (Django) |
| CORS errors on client upload | Configure CORS on bucket — see `tigris-security-access-control` skill |
| Rails direct upload fails | Ensure CORS allows PUT from your domain and `@rails/activestorage` JS is loaded |
| Files not publicly accessible | Bucket/object is private. Use `access: "public"` or presigned URLs |

---

## Related Skills

- **file-storage** — CLI setup and full `@tigrisdata/storage` SDK reference
- **tigris-image-optimization** — Resize, crop, and optimize images per framework
- **tigris-security-access-control** — CORS, key rotation, bucket policies
- **tigris-sdk-guide** — Which SDK to use per language

## Official Documentation

- SDK: https://www.tigrisdata.com/docs/sdks/tigris/
- Client Uploads: https://www.tigrisdata.com/docs/sdks/tigris/client-uploads/
