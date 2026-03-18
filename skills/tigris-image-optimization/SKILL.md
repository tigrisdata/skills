---
name: tigris-image-optimization
description: Use when resizing images, generating thumbnails, serving responsive images, or optimizing image delivery with Tigris — covers Next.js, Remix, Rails, Django, Laravel, Express
---

# Tigris Image Optimization

Resize, crop, and optimize images stored in Tigris. Generate thumbnails on upload, serve responsive images, and leverage Tigris's global CDN for fast delivery. Covers patterns for Next.js, Remix, Rails, Django, Laravel, and Express.

## Strategy Overview

| Approach | When to Use | Pros | Cons |
|----------|------------|------|------|
| Process on upload | Thumbnails, fixed sizes | Fast serving, predictable | Storage cost per variant |
| Process on request | Many size variations | Flexible, less storage | Latency on first request |
| Client-side resize | Before upload | Saves bandwidth, fast upload | Less control over quality |

**Recommended:** Process on upload for known sizes (avatar, thumbnail, cover). Use public buckets for CDN delivery — Tigris serves public files from the nearest global edge automatically.

---

## Upload-Time Processing (General Pattern)

Generate variants when a file is uploaded, store each variant as a separate object:

```
avatars/user-123.jpg          # original
avatars/user-123-thumb.jpg    # 100x100
avatars/user-123-medium.jpg   # 400x400
avatars/user-123-large.jpg    # 800x800
```

Use `access: "public"` for images that need fast, CDN-backed delivery.

---

## Next.js

### next/image with Tigris

```javascript
// next.config.js
module.exports = {
  images: {
    remotePatterns: [{ protocol: "https", hostname: "*.t3.storage.dev" }],
  },
};
```

```tsx
import Image from "next/image";
<Image src={tigrisUrl} alt="Photo" width={800} height={600} />;
```

`next/image` handles responsive sizing and format conversion (WebP/AVIF) automatically.

### Server-Side Processing with Sharp

```typescript
import sharp from "sharp";
import { put } from "@tigrisdata/storage";

async function uploadWithVariants(file: Buffer, basePath: string) {
  const variants = [
    { suffix: "thumb", width: 100, height: 100 },
    { suffix: "medium", width: 400, height: 400 },
  ];

  // Upload original
  await put(`${basePath}.jpg`, file, {
    access: "public",
    contentType: "image/jpeg",
  });

  // Generate and upload variants
  for (const v of variants) {
    const resized = await sharp(file)
      .resize(v.width, v.height, { fit: "cover" })
      .jpeg({ quality: 80 })
      .toBuffer();

    await put(`${basePath}-${v.suffix}.jpg`, resized, {
      access: "public",
      contentType: "image/jpeg",
    });
  }
}
```

---

## Remix

Same Sharp approach as Next.js for server-side processing. In action functions:

```typescript
import sharp from "sharp";
import { put } from "@tigrisdata/storage";

export async function action({ request }: ActionFunctionArgs) {
  const formData = await request.formData();
  const file = formData.get("image") as File;
  const buffer = Buffer.from(await file.arrayBuffer());

  // Generate thumbnail
  const thumb = await sharp(buffer)
    .resize(200, 200, { fit: "cover" })
    .webp({ quality: 80 })
    .toBuffer();

  await Promise.all([
    put(`images/${Date.now()}.jpg`, buffer, { access: "public", contentType: file.type }),
    put(`images/${Date.now()}-thumb.webp`, thumb, { access: "public", contentType: "image/webp" }),
  ]);

  return json({ success: true });
}
```

Serve with responsive `srcset`:

```html
<img
  src={thumbUrl}
  srcset={`${thumbUrl} 200w, ${mediumUrl} 400w, ${fullUrl} 800w`}
  sizes="(max-width: 400px) 200px, (max-width: 800px) 400px, 800px"
  alt="Photo"
/>
```

---

## Rails

### Active Storage Variants

```ruby
# Gemfile
gem "image_processing", "~> 1.2"
```

```erb
<%# Thumbnail %>
<%= image_tag user.avatar.variant(resize_to_fill: [100, 100]) %>

<%# Medium size %>
<%= image_tag user.avatar.variant(resize_to_limit: [400, 400]) %>

<%# WebP conversion %>
<%= image_tag user.avatar.variant(format: :webp, resize_to_limit: [800, 800]) %>
```

Variants are processed on first request and cached. For eager processing:

```ruby
user.avatar.variant(resize_to_fill: [100, 100]).processed
```

---

## Django

### django-imagekit

```bash
pip install django-imagekit
```

```python
from django.db import models
from imagekit.models import ImageSpecField
from imagekit.processors import ResizeToFill, ResizeToFit

class Photo(models.Model):
    original = models.ImageField(upload_to="photos/")
    thumbnail = ImageSpecField(
        source="original",
        processors=[ResizeToFill(100, 100)],
        format="JPEG",
        options={"quality": 80},
    )
    medium = ImageSpecField(
        source="original",
        processors=[ResizeToFit(400, 400)],
        format="JPEG",
        options={"quality": 85},
    )
```

```html
<img src="{{ photo.thumbnail.url }}" alt="Thumbnail" />
<img src="{{ photo.medium.url }}" alt="Medium" />
```

### Manual Processing with Pillow

```python
from PIL import Image
from io import BytesIO
from django.core.files.base import ContentFile

def create_thumbnail(image_field, size=(100, 100)):
    img = Image.open(image_field)
    img.thumbnail(size, Image.LANCZOS)
    buffer = BytesIO()
    img.save(buffer, format="JPEG", quality=80)
    return ContentFile(buffer.getvalue())
```

---

## Laravel

### Intervention Image

```bash
composer require intervention/image
```

```php
use Intervention\Image\Laravel\Facades\Image;
use Illuminate\Support\Facades\Storage;

public function uploadWithThumbnail(Request $request)
{
    $file = $request->file('image');
    $name = pathinfo($file->getClientOriginalName(), PATHINFO_FILENAME);

    // Original
    Storage::disk('tigris')->put(
        "images/{$name}.jpg",
        $file->getContent(),
        'public'
    );

    // Thumbnail
    $thumb = Image::read($file)->cover(100, 100)->toJpeg(80);
    Storage::disk('tigris')->put("images/{$name}-thumb.jpg", $thumb, 'public');

    // Medium
    $medium = Image::read($file)->scale(width: 400)->toJpeg(85);
    Storage::disk('tigris')->put("images/{$name}-medium.jpg", $medium, 'public');
}
```

---

## Express

### Sharp Middleware

```typescript
import sharp from "sharp";
import multer from "multer";
import { put } from "@tigrisdata/storage";

const upload = multer({ storage: multer.memoryStorage() });

app.post("/upload-image", upload.single("image"), async (req, res) => {
  const file = req.file!;
  const base = `images/${Date.now()}`;

  // Process variants in parallel
  const [thumb, medium] = await Promise.all([
    sharp(file.buffer).resize(100, 100, { fit: "cover" }).jpeg({ quality: 80 }).toBuffer(),
    sharp(file.buffer).resize(400, 400, { fit: "inside" }).jpeg({ quality: 85 }).toBuffer(),
  ]);

  await Promise.all([
    put(`${base}.jpg`, file.buffer, { access: "public", contentType: "image/jpeg" }),
    put(`${base}-thumb.jpg`, thumb, { access: "public", contentType: "image/jpeg" }),
    put(`${base}-medium.jpg`, medium, { access: "public", contentType: "image/jpeg" }),
  ]);

  res.json({ original: `${base}.jpg`, thumb: `${base}-thumb.jpg` });
});
```

---

## CDN Delivery

Tigris public buckets serve files from the nearest global edge — no separate CDN setup needed.

**Cache headers for images:**

```typescript
await put("images/hero.jpg", buffer, {
  access: "public",
  contentType: "image/jpeg",
  // Set via S3 SDK metadata if needed:
  // CacheControl: "public, max-age=31536000, immutable"
});
```

For immutable content-hashed filenames (e.g., `hero-abc123.jpg`), use long cache times. For mutable paths, use shorter TTLs or ETags.

---

## Critical Rules

**Always:** Use `access: "public"` for images served to users (enables CDN) | Generate thumbnails at upload time for known sizes | Use WebP/AVIF for smaller file sizes | Set explicit `contentType`

**Never:** Process images on every request without caching | Store only originals if you always serve thumbnails | Resize in the browser after downloading full-size images

---

## Related Skills

- **tigris-nextjs-file-uploads** — Full Next.js upload patterns
- **tigris-rails-file-uploads** — Active Storage setup
- **tigris-egress-optimizer** — Reduce bandwidth costs from image serving

## Official Documentation

- Tigris SDK: https://www.tigrisdata.com/docs/sdks/tigris/
- Sharp: https://sharp.pixelplumbing.com/
