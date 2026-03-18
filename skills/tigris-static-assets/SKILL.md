---
name: tigris-static-assets
description: Use when deploying static assets (CSS, JS, fonts, build artifacts) to Tigris — asset pipelines, cache headers, CDN delivery, covers Next.js, Remix, Rails, Django, Laravel, Express
---

# Tigris Static Asset Hosting

Deploy CSS, JavaScript, fonts, and build artifacts to Tigris for global CDN delivery. Covers asset pipeline integration, cache-busting strategies, and `Cache-Control` configuration for all major frameworks.

## Overview

Tigris public buckets automatically serve files from the nearest global edge — no separate CDN configuration needed. Combined with content-hashed filenames and immutable cache headers, this gives you fast, cost-effective static asset delivery.

**Key pattern:**

1. Build assets with content hashes (e.g., `main-abc123.js`)
2. Upload to a public Tigris bucket
3. Set `Cache-Control: public, max-age=31536000, immutable`
4. Point your app's asset URL to the Tigris bucket

---

## Cache Headers

```bash
# For immutable, hashed assets (CSS, JS bundles)
Cache-Control: public, max-age=31536000, immutable

# For mutable assets (manifest files, index.html)
Cache-Control: public, max-age=0, must-revalidate

# For fonts
Cache-Control: public, max-age=31536000, immutable
```

### Setting Headers via CLI

```bash
tigris cp dist/main-abc123.js t3://my-assets/main-abc123.js \
  --cache-control "public, max-age=31536000, immutable" \
  --content-type "application/javascript"
```

### Setting Headers via SDK

```typescript
import { put } from "@tigrisdata/storage";

await put("assets/main-abc123.js", fileBuffer, {
  access: "public",
  contentType: "application/javascript",
});
```

---

## Upload Script (General)

A simple deploy script that syncs build output to Tigris:

```bash
#!/bin/bash
# scripts/deploy-assets.sh
BUCKET="my-app-assets"
BUILD_DIR="dist"

# Upload hashed assets with long cache
tigris cp "$BUILD_DIR/" "t3://$BUCKET/" -r \
  --cache-control "public, max-age=31536000, immutable"

echo "Assets deployed to t3://$BUCKET/"
```

---

## Next.js

### Custom Asset Prefix

```javascript
// next.config.js
module.exports = {
  assetPrefix:
    process.env.NODE_ENV === "production"
      ? "https://my-app-assets.t3.storage.dev"
      : undefined,
};
```

### Deploy Script

```bash
# After `next build`, upload _next/static to Tigris
tigris cp .next/static/ t3://my-app-assets/_next/static/ -r \
  --cache-control "public, max-age=31536000, immutable"
```

---

## Remix

### Vite Asset Configuration

```typescript
// vite.config.ts
export default defineConfig({
  build: {
    assetsDir: "assets",
  },
  // In production, set base to Tigris bucket URL
  base:
    process.env.NODE_ENV === "production"
      ? "https://my-app-assets.t3.storage.dev/"
      : "/",
});
```

```bash
# After build, upload to Tigris
tigris cp build/client/assets/ t3://my-app-assets/assets/ -r \
  --cache-control "public, max-age=31536000, immutable"
```

---

## Rails

### Sprockets / Propshaft Asset Sync

```ruby
# config/environments/production.rb
config.asset_host = "https://my-app-assets.t3.storage.dev"
```

> **Note:** No native Tigris Ruby SDK exists yet. Uses `aws-sdk-s3` pointed at Tigris.

```ruby
# lib/tasks/assets.rake
namespace :assets do
  desc "Upload compiled assets to Tigris"
  task upload: :environment do
    require "aws-sdk-s3"

    s3 = Aws::S3::Client.new(
      endpoint: "https://t3.storage.dev",
      region: "auto",
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
    )

    Dir.glob("public/assets/**/*").each do |file|
      next if File.directory?(file)
      key = file.sub("public/", "")
      s3.put_object(
        bucket: ENV["TIGRIS_ASSETS_BUCKET"],
        key: key,
        body: File.open(file),
        content_type: Marcel::MimeType.for(name: file),
        cache_control: "public, max-age=31536000, immutable",
        acl: "public-read",
      )
    end
    puts "Assets uploaded to Tigris"
  end
end
```

```bash
rails assets:precompile && rails assets:upload
```

---

## Django

### collectstatic with S3 Backend

> Uses `django-storages` with `tigris-boto3-ext` (install: `pip install django-storages tigris-boto3-ext`).

```python
# settings.py
STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3boto3.S3Boto3Storage",
    },
    "staticfiles": {
        "BACKEND": "storages.backends.s3boto3.S3StaticStorage",
    },
}

AWS_S3_ENDPOINT_URL = "https://t3.storage.dev"
AWS_STORAGE_BUCKET_NAME = "my-app-assets"
AWS_S3_CUSTOM_DOMAIN = "my-app-assets.t3.storage.dev"
AWS_DEFAULT_ACL = "public-read"
STATIC_URL = f"https://{AWS_S3_CUSTOM_DOMAIN}/static/"

AWS_S3_OBJECT_PARAMETERS = {
    "CacheControl": "public, max-age=31536000, immutable",
}
```

```bash
python manage.py collectstatic --noinput
```

**Comparison with WhiteNoise:** WhiteNoise serves static files from the app server. Use Tigris instead when you want global CDN delivery without adding load to your application server.

---

## Laravel

### Vite / Mix Asset Upload

```php
// config/filesystems.php
'disks' => [
    'assets' => [
        'driver' => 's3',
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => 'auto',
        'bucket' => env('TIGRIS_ASSETS_BUCKET'),
        'endpoint' => 'https://t3.storage.dev',
        'use_path_style_endpoint' => true,
        'visibility' => 'public',
    ],
],
```

```bash
# .env
ASSET_URL=https://my-app-assets.t3.storage.dev
```

Deploy script:

```bash
npm run build
tigris cp public/build/ t3://my-app-assets/build/ -r \
  --cache-control "public, max-age=31536000, immutable"
```

---

## Express

### Static Redirect Pattern

Instead of serving static files from Express, redirect to Tigris:

```typescript
// For development: serve locally
app.use("/assets", express.static("dist/assets"));

// For production: redirect to Tigris
app.use("/assets", (req, res) => {
  res.redirect(301, `https://my-app-assets.t3.storage.dev/assets${req.path}`);
});
```

Or upload after build:

```bash
# Build and deploy
npm run build
tigris cp dist/assets/ t3://my-app-assets/assets/ -r \
  --cache-control "public, max-age=31536000, immutable"
```

---

## Cache-Busting Strategies

| Strategy | Example | Use When |
|----------|---------|----------|
| Content hash in filename | `main-abc123.js` | Build tools generate hashed names (Vite, Webpack) |
| Query string | `main.js?v=abc123` | Legacy systems without hashed filenames |
| Directory versioning | `/v2/assets/main.js` | Major version changes |

Most modern build tools (Vite, Webpack, esbuild) generate content-hashed filenames by default. Use these with `immutable` cache headers for the best performance.

---

## Critical Rules

**Always:** Use a public bucket for static assets | Set `Cache-Control: immutable` on hashed assets | Use content-hashed filenames | Upload after build, not on every request

**Never:** Serve static assets through your app server in production (use Tigris CDN) | Set long cache times on mutable filenames | Forget to update asset URL configuration in your framework

---

## Related Skills

- **tigris-egress-optimizer** — Reduce bandwidth costs
- **tigris-lifecycle-management** — Clean up old asset versions

## Official Documentation

- Tigris: https://www.tigrisdata.com/docs/
