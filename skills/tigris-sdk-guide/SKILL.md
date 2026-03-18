---
name: tigris-sdk-guide
description: Use when choosing between Tigris-native SDKs and AWS S3-compatible SDKs — covers which SDK to use per language, CLI preference, and when AWS SDKs are the only option
---

# Tigris SDK & CLI Guide

Always prefer Tigris-native SDKs and the Tigris CLI over AWS S3 SDKs. This guide explains what's available per language, when you must fall back to AWS SDKs, and how to configure them.

## Decision Table

| Language | Tigris SDK/Extension | Package | Use AWS SDK? |
|----------|:-:|---------|----------|
| TypeScript/JS | **Native SDK** | `@tigrisdata/storage` | No |
| Go | **Native SDK** | `github.com/tigrisdata/storage-go` | No |
| Python | **boto3 extension** | `tigris-boto3-ext` | No — use the extension |
| Ruby | None yet | — | Yes — `aws-sdk-s3` with Tigris endpoint |
| PHP | None yet | — | Yes — `aws-sdk-php` with Tigris endpoint |
| CLI | **Native CLI** | `@tigrisdata/cli` (`tigris` / `t3`) | No |

**Rule:** Always prefer Tigris-native SDKs, the boto3 extension, and the Tigris CLI. Only use raw AWS S3 SDKs for Ruby and PHP where no Tigris option exists.

---

## CLI: Always Use `tigris` / `t3`

Use the Tigris CLI instead of `aws s3` for all object storage operations.

```bash
# Install
npm install -g @tigrisdata/cli

# ✅ Do this
tigris cp local-file.txt t3://my-bucket/file.txt
tigris ls t3://my-bucket/
tigris rm t3://my-bucket/old-file.txt

# ❌ Not this
aws s3 cp local-file.txt s3://my-bucket/file.txt
aws s3 ls s3://my-bucket/
aws s3 rm s3://my-bucket/old-file.txt
```

**Why:** The Tigris CLI supports features the AWS CLI doesn't — forks, snapshots, and native authentication via `tigris login`.

### Tigris-Only CLI Features

```bash
# Forks (copy-on-write clones) — not in AWS CLI
tigris forks create my-bucket my-fork

# Snapshots — not in AWS CLI
tigris snapshots take my-bucket
tigris snapshots list my-bucket

# Native auth — no AWS credentials needed
tigris login
tigris whoami
```

---

## TypeScript / JavaScript — Use `@tigrisdata/storage`

```bash
npm install @tigrisdata/storage
```

```typescript
// ✅ Do this — Tigris SDK
import { put, get, remove, list, head, getPresignedUrl } from "@tigrisdata/storage";

await put("file.jpg", data, { contentType: "image/jpeg" });
const result = await get("file.jpg", "string");
await remove("file.jpg");

// ❌ Not this — AWS SDK
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
const s3 = new S3Client({ endpoint: "https://t3.storage.dev", region: "auto" });
await s3.send(new PutObjectCommand({ Bucket: "my-bucket", Key: "file.jpg", Body: data }));
```

**Why Tigris SDK is better:**
- No bucket/region boilerplate — reads from env vars automatically
- Simpler API: `put(path, body)` vs `new PutObjectCommand({Bucket, Key, Body})`
- Built-in client upload support: `handleClientUpload` + `upload()` from `@tigrisdata/storage/client`
- Built-in multipart with progress tracking
- Returns typed `TigrisStorageResponse` with error handling

### Client-Side Uploads

```typescript
// Server: handle presigned URL generation
import { handleClientUpload } from "@tigrisdata/storage";
const { data, error } = await handleClientUpload(requestBody);

// Client: upload directly to Tigris
import { upload } from "@tigrisdata/storage/client";
await upload(filename, file, {
  url: "/api/upload",
  multipart: true,
  onUploadProgress: ({ percentage }) => console.log(percentage),
});
```

### Environment Variables

```bash
TIGRIS_STORAGE_ACCESS_KEY_ID=tid_xxx
TIGRIS_STORAGE_SECRET_ACCESS_KEY=tsec_yyy
TIGRIS_STORAGE_ENDPOINT=https://t3.storage.dev
TIGRIS_STORAGE_BUCKET=my-app-uploads
```

---

## Go — Use `github.com/tigrisdata/storage-go`

```bash
go get github.com/tigrisdata/storage-go
```

Two packages available:

### simplestorage (High-Level)

```go
// ✅ Do this — Tigris SDK
import "github.com/tigrisdata/storage-go/simplestorage"

client, err := simplestorage.New(ctx)
err = client.PutObject(ctx, "my-bucket", "file.jpg", reader)
obj, err := client.GetObject(ctx, "my-bucket", "file.jpg")
```

### storage (Full S3 + Tigris Extras)

```go
// ✅ Full client with Tigris-specific features
import "github.com/tigrisdata/storage-go/storage"

client, err := storage.New(ctx)

// Standard S3 operations work
client.PutObject(ctx, &s3.PutObjectInput{...})

// Plus Tigris-specific features:
client.CreateBucketSnapshot(ctx, "my-bucket")
client.CreateBucketFork(ctx, "my-bucket", "my-fork")
client.RenameObject(ctx, "my-bucket", "old-key", "new-key")  // in-place, no copy!
```

**Tigris-only Go features not in AWS SDK:**
- `CreateBucketSnapshot` / `ListBucketSnapshots`
- `CreateBucketFork` / `ListBucketForks`
- `RenameObject` (in-place rename, no copy+delete needed)

### Environment Variables

```bash
AWS_ACCESS_KEY_ID=tid_xxx
AWS_SECRET_ACCESS_KEY=tsec_yyy
AWS_ENDPOINT_URL_S3=https://t3.storage.dev
AWS_REGION=auto
```

---

## Python — Use `tigris-boto3-ext`

The Tigris boto3 extension extends `boto3` with Tigris-specific features (snapshots, forks, renaming). Always install it alongside `boto3`.

```bash
pip install tigris-boto3-ext
```

### Basic Operations

```python
import boto3
from botocore.client import Config

s3 = boto3.client(
    "s3",
    endpoint_url="https://t3.storage.dev",
    aws_access_key_id="tid_xxx",
    aws_secret_access_key="tsec_yyy",
    region_name="auto",
    config=Config(s3={"addressing_style": "virtual"}),
)

# Upload
s3.put_object(Bucket="my-bucket", Key="file.jpg", Body=data)

# Download
response = s3.get_object(Bucket="my-bucket", Key="file.jpg")
content = response["Body"].read()

# Presigned URL
url = s3.generate_presigned_url(
    "get_object",
    Params={"Bucket": "my-bucket", "Key": "file.jpg"},
    ExpiresIn=3600,
)
```

### Tigris-Only Features (via extension)

```python
from tigris_boto3_ext import TigrisSnapshot, TigrisFork

# Snapshots — point-in-time recovery
with TigrisSnapshot(s3, "my-bucket") as snapshot:
    # Work with snapshot version
    obj = snapshot.get_object(Key="file.jpg")

# Forks — isolated copy-on-write clones
with TigrisFork(s3, "my-bucket", "my-fork") as fork:
    # Write to fork without affecting original
    fork.put_object(Key="test.txt", Body=b"experimental data")
```

**Framework integration:**
- Django: `django-storages` with `S3Boto3Storage` backend + `tigris-boto3-ext`
- Flask/FastAPI: `tigris-boto3-ext` directly

---

## Ruby — aws-sdk-s3 (No Native SDK Yet)

There is no native Tigris Ruby SDK. Use `aws-sdk-s3` pointed at Tigris.

```ruby
# Gemfile
gem "aws-sdk-s3"
```

```ruby
require "aws-sdk-s3"

s3 = Aws::S3::Client.new(
  endpoint: "https://t3.storage.dev",
  region: "auto",
  access_key_id: ENV["AWS_ACCESS_KEY_ID"],
  secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
  force_path_style: true,
)

# Upload
s3.put_object(bucket: "my-bucket", key: "file.jpg", body: File.open("file.jpg"))
```

**Framework integration:**
- Rails: Active Storage with S3 service — set `endpoint` and `force_path_style: true` in `storage.yml`

---

## PHP — aws-sdk-php (No Native SDK Yet)

There is no native Tigris PHP SDK. Use `aws-sdk-php` or `league/flysystem-aws-s3-v3` pointed at Tigris.

```php
$s3 = new Aws\S3\S3Client([
    'endpoint' => 'https://t3.storage.dev',
    'region' => 'auto',
    'version' => 'latest',
    'use_path_style_endpoint' => true,
    'credentials' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
    ],
]);
```

**Framework integration:**
- Laravel: S3 disk driver in `filesystems.php` — set `endpoint` and `use_path_style_endpoint: true`

---

## S3-Compatible Configuration (All Languages)

When using any AWS SDK with Tigris, always set:

| Setting | Value | Why |
|---------|-------|-----|
| `endpoint` | `https://t3.storage.dev` | Tigris endpoint |
| `region` | `auto` | Tigris handles routing |
| `force_path_style` / `use_path_style_endpoint` | `true` | Required for Rails, PHP |

Environment variables for S3-compatible tools:

```bash
AWS_ENDPOINT_URL_S3=https://t3.storage.dev
AWS_REGION=auto
AWS_ACCESS_KEY_ID=tid_xxx
AWS_SECRET_ACCESS_KEY=tsec_yyy
```

---

## Critical Rules

**Always:**
- Use `tigris` / `t3` CLI instead of `aws s3`
- Use `@tigrisdata/storage` for TypeScript/JavaScript
- Use `github.com/tigrisdata/storage-go` for Go
- Use `tigris-boto3-ext` for Python (not raw `boto3`)
- Set `region: auto` and the Tigris endpoint when using AWS SDKs (Ruby, PHP)

**Never:**
- Use `@aws-sdk/client-s3` in JS/TS when `@tigrisdata/storage` is available
- Use the AWS Go SDK when `storage-go` is available
- Use raw `boto3` without `tigris-boto3-ext` when Tigris features are needed
- Forget `force_path_style: true` for Ruby and PHP
- Hardcode a specific AWS region (always use `auto`)

---

## Related Skills

- **file-storage** — Full `@tigrisdata/storage` SDK reference
- **tigris-s3-migration** — Migrating from AWS S3 SDKs to Tigris

## Official Documentation

- TypeScript SDK: https://www.tigrisdata.com/docs/sdks/tigris/
- Go SDK: https://pkg.go.dev/github.com/tigrisdata/storage-go
- S3 Compatibility: https://www.tigrisdata.com/docs/sdks/s3/
