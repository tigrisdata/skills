---
name: tigris-file-uploads
description: Use when adding file uploads, downloads, or file serving to any web framework — Next.js, Remix, Express, Rails, Django, or Laravel with Tigris
---

# File Uploads with Tigris

Upload, download, and serve files across all major web frameworks using Tigris object storage.

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

**Rails** (`config/storage.yml`):
```yaml
tigris:
  service: S3
  access_key_id: <%= ENV["TIGRIS_STORAGE_ACCESS_KEY_ID"] %>
  secret_access_key: <%= ENV["TIGRIS_STORAGE_SECRET_ACCESS_KEY"] %>
  endpoint: https://t3.storage.dev
  bucket: <%= ENV["TIGRIS_STORAGE_BUCKET"] %>
  region: auto
  force_path_style: true
```

**Django** (`settings.py`):
```python
STORAGES = {
    "default": {"BACKEND": "storages.backends.s3boto3.S3Boto3Storage"},
}
AWS_S3_ENDPOINT_URL = "https://t3.storage.dev"
AWS_ACCESS_KEY_ID = os.environ["TIGRIS_STORAGE_ACCESS_KEY_ID"]
AWS_SECRET_ACCESS_KEY = os.environ["TIGRIS_STORAGE_SECRET_ACCESS_KEY"]
AWS_STORAGE_BUCKET_NAME = os.environ["TIGRIS_STORAGE_BUCKET"]
AWS_S3_REGION_NAME = "auto"
AWS_S3_ADDRESSING_STYLE = "virtual"
```

**Laravel** (`config/filesystems.php`):
```php
'tigris' => [
    'driver' => 's3',
    'key' => env('TIGRIS_STORAGE_ACCESS_KEY_ID'),
    'secret' => env('TIGRIS_STORAGE_SECRET_ACCESS_KEY'),
    'region' => 'auto',
    'bucket' => env('TIGRIS_STORAGE_BUCKET'),
    'url' => env('TIGRIS_STORAGE_ENDPOINT'),
    'endpoint' => env('TIGRIS_STORAGE_ENDPOINT'),
    'use_path_style_endpoint' => true,
],
```

---

## Upload

### Next.js — Server Action

```typescript
"use server";
import { put } from "@tigrisdata/storage";

export async function uploadFile(formData: FormData) {
  const file = formData.get("file") as File;
  const result = await put(`uploads/${file.name}`, file, {
    contentType: file.type,
  });
  if (result.error) throw result.error;
  return result.data;
}
```

### Next.js — API Route

```typescript
// app/api/upload/route.ts
import { put } from "@tigrisdata/storage";
import { NextRequest, NextResponse } from "next/server";

export async function POST(request: NextRequest) {
  const formData = await request.formData();
  const file = formData.get("file") as File;
  const result = await put(`uploads/${file.name}`, file, {
    contentType: file.type,
  });
  if (result.error) return NextResponse.json({ error: result.error.message }, { status: 500 });
  return NextResponse.json(result.data);
}
```

### Remix — Action

```typescript
import { put } from "@tigrisdata/storage";
import { unstable_parseMultipartFormData, type ActionFunctionArgs } from "@remix-run/node";

export async function action({ request }: ActionFunctionArgs) {
  const formData = await unstable_parseMultipartFormData(request, async ({ name, data, filename, contentType }) => {
    if (name !== "file") return undefined;
    const chunks: Uint8Array[] = [];
    for await (const chunk of data) chunks.push(chunk);
    const buffer = Buffer.concat(chunks);
    const result = await put(`uploads/${filename}`, buffer, { contentType });
    if (result.error) throw result.error;
    return result.data?.url;
  });
  return { url: formData.get("file") };
}
```

### Express — Multer

```typescript
import express from "express";
import multer from "multer";
import { put } from "@tigrisdata/storage";

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 50 * 1024 * 1024 } });

app.post("/upload", upload.single("file"), async (req, res) => {
  const result = await put(`uploads/${req.file.originalname}`, req.file.buffer, {
    contentType: req.file.mimetype,
  });
  if (result.error) return res.status(500).json({ error: result.error.message });
  res.json(result.data);
});
```

### Express — Streaming (No Multer)

```typescript
import { put } from "@tigrisdata/storage";
import { Readable } from "stream";

app.post("/upload-stream", async (req, res) => {
  const filename = req.headers["x-filename"] as string;
  const contentType = req.headers["content-type"] ?? "application/octet-stream";
  const stream = Readable.from(req);
  const result = await put(`uploads/${filename}`, stream, { contentType, multipart: true });
  if (result.error) return res.status(500).json({ error: result.error.message });
  res.json(result.data);
});
```

### Rails — Active Storage

```ruby
# app/models/document.rb
class Document < ApplicationRecord
  has_one_attached :file
  validates :file, presence: true
end

# app/controllers/documents_controller.rb
class DocumentsController < ApplicationController
  def create
    @document = Document.new(document_params)
    if @document.save
      redirect_to @document
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
  def document_params = params.require(:document).permit(:file)
end
```

Set Active Storage service in `config/environments/production.rb`:
```ruby
config.active_storage.service = :tigris
```

### Django — View

```python
# models.py
from django.db import models

class Document(models.Model):
    file = models.FileField(upload_to="uploads/%Y/%m/")
    uploaded_at = models.DateTimeField(auto_now_add=True)

# views.py
from django.shortcuts import redirect
from .models import Document
from .forms import DocumentForm

def upload(request):
    if request.method == "POST":
        form = DocumentForm(request.POST, request.FILES)
        if form.is_valid():
            form.save()
            return redirect("document_list")
    else:
        form = DocumentForm()
    return render(request, "upload.html", {"form": form})
```

### Laravel — Controller

```php
// app/Http/Controllers/DocumentController.php
public function store(Request $request)
{
    $request->validate(['file' => 'required|file|max:51200']);
    $path = $request->file('file')->store('uploads', 'tigris');
    return response()->json(['path' => $path]);
}
```

---

## Download / Serve

### Next.js / Remix / Express (Tigris SDK)

```typescript
import { get } from "@tigrisdata/storage";

// Serve inline (images, PDFs in browser)
const result = await get("uploads/photo.jpg", "file", { contentDisposition: "inline" });

// Force download
const result = await get("uploads/report.pdf", "file", { contentDisposition: "attachment" });

// Stream large files (Express)
const result = await get("uploads/video.mp4", "stream");
result.data.pipe(res);
```

### Rails

```ruby
# Inline display
redirect_to @document.file.url(expires_in: 1.hour)

# Force download
redirect_to @document.file.url(expires_in: 1.hour, disposition: "attachment")
```

### Django

```python
from django.http import FileResponse

def download(request, pk):
    doc = Document.objects.get(pk=pk)
    return FileResponse(doc.file.open(), as_attachment=True, filename=doc.file.name.split("/")[-1])
```

### Laravel

```php
// Inline
return Storage::disk('tigris')->response($path);

// Download
return Storage::disk('tigris')->download($path, $filename);
```

---

## Client-Side Direct Uploads (Browser → Tigris)

Skip your server for file bytes. Available for JS frameworks via the Tigris SDK.

### Server Endpoint (Next.js / Remix / Express)

```typescript
import { handleClientUpload } from "@tigrisdata/storage";

// Next.js API Route / Remix Action / Express Route
const body = await request.json();
const { data, error } = await handleClientUpload(body);
if (error) return Response.json({ error: error.message }, { status: 500 });
return Response.json({ data });
```

### Browser Client

```typescript
import { upload } from "@tigrisdata/storage/client";

const result = await upload(file.name, file, {
  url: "/api/upload",
  access: "private",
  multipart: true,
  onUploadProgress: ({ percentage }) => console.log(`${percentage}%`),
});
```

### Rails — Active Storage Direct Upload

```erb
<%= form.file_field :file, direct_upload: true %>
```

Requires `@rails/activestorage` JS and CORS configured on the Tigris bucket.

### Django / Laravel — Presigned Upload URL

For non-JS frameworks, generate a presigned PUT URL on the server and upload from the client:

```python
# Django — presigned upload endpoint
import boto3
from botocore.config import Config

s3 = boto3.client("s3",
    endpoint_url="https://t3.storage.dev",
    region_name="auto",
    config=Config(s3={"addressing_style": "virtual"}),
)

def presigned_upload(request):
    url = s3.generate_presigned_url("put_object",
        Params={"Bucket": BUCKET, "Key": f"uploads/{filename}", "ContentType": content_type},
        ExpiresIn=600,
    )
    return JsonResponse({"url": url})
```

```php
// Laravel — presigned upload endpoint
$url = Storage::disk('tigris')->temporaryUploadUrl("uploads/{$filename}", now()->addMinutes(10));
return response()->json(['url' => $url]);
```

Browser client for presigned uploads:
```javascript
const { url } = await fetch("/api/presigned-upload", { method: "POST", body: JSON.stringify({ filename, contentType }) }).then(r => r.json());
await fetch(url, { method: "PUT", body: file, headers: { "Content-Type": file.type } });
```

---

## Presigned URLs (Temporary Access)

### Tigris SDK (Next.js, Remix, Express)

```typescript
import { getPresignedUrl } from "@tigrisdata/storage";

// Download link (1 hour)
const { data } = await getPresignedUrl("reports/q4.pdf", { operation: "get", expiresIn: 3600 });

// Upload link (10 minutes)
const { data } = await getPresignedUrl("uploads/photo.jpg", { operation: "put", expiresIn: 600 });
```

### Rails

```ruby
@document.file.url(expires_in: 1.hour)
```

### Django

```python
url = s3.generate_presigned_url("get_object",
    Params={"Bucket": BUCKET, "Key": path},
    ExpiresIn=3600,
)
```

### Laravel

```php
$url = Storage::disk('tigris')->temporaryUrl($path, now()->addHour());
```

---

## Image Serving

### Next.js — next/image

```typescript
// next.config.ts
const nextConfig = {
  images: {
    remotePatterns: [{ protocol: "https", hostname: "*.t3.storage.dev" }],
  },
};
```

```tsx
import Image from "next/image";
<Image src={imageUrl} alt="Photo" width={800} height={600} />
```

### Rails — Image Variants

```ruby
<%= image_tag @document.file.variant(resize_to_limit: [800, 600]) %>
```

---

## Multipart Uploads (Large Files)

### Tigris SDK (Next.js, Remix, Express)

```typescript
const result = await put("videos/demo.mp4", fileStream, {
  multipart: true,
  onUploadProgress: ({ loaded, total, percentage }) => {
    console.log(`${percentage}%`);
  },
});
```

### Rails

Active Storage handles multipart automatically for large files.

### Django

```python
# django-storages handles multipart via boto3 transfer config
AWS_S3_MAX_MEMORY_SIZE = 10 * 1024 * 1024  # 10MB threshold for multipart
```

### Laravel — Livewire Upload with Progress

```php
// app/Livewire/FileUpload.php
use Livewire\WithFileUploads;

class FileUpload extends Component
{
    use WithFileUploads;
    public $file;

    public function save()
    {
        $this->validate(['file' => 'file|max:51200']);
        $this->file->store('uploads', 'tigris');
    }
}
```

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
