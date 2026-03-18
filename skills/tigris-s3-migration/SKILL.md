---
name: tigris-s3-migration
description: Use when migrating from AWS S3, Google Cloud Storage, or Azure Blob to Tigris — shadow buckets, bulk copy, SDK endpoint swap, zero-downtime migration
---

# Migrate to Tigris from S3/GCS/Azure

Migrate your object storage to Tigris with zero downtime. Tigris is S3-compatible, so most apps need only an endpoint and credential swap. Shadow buckets enable transparent migration without moving data upfront.

## Prerequisites

**Before doing anything else**, install the Tigris CLI if it's not already available:

```bash
tigris help || npm install -g @tigrisdata/cli
```

If you need to install it, tell the user: "I'm installing the Tigris CLI (`@tigrisdata/cli`) so we can work with Tigris object storage."

## Migration Strategies

| Strategy | Downtime | Best For |
|----------|----------|----------|
| **Shadow bucket** | Zero | Production apps — Tigris reads from S3 on miss, backfills automatically |
| **Bulk copy** | Brief | Small datasets, clean cutover |
| **Incremental sync** | Zero | Large datasets, gradual migration |

---

## Shadow Bucket (Recommended)

Tigris reads from your existing S3 bucket on cache miss and gradually backfills data. No upfront data movement needed.

```bash
# Create a Tigris bucket that shadows your S3 bucket
tigris buckets create my-app-uploads \
  --shadow-source s3://my-existing-s3-bucket \
  --shadow-region us-east-1 \
  --shadow-access-key AKIA_YOUR_AWS_KEY \
  --shadow-secret-key YOUR_AWS_SECRET
```

**How it works:**

1. Requests go to Tigris
2. If the object exists in Tigris, it's served directly
3. If not, Tigris fetches it from S3, serves it, and caches it
4. Over time, all frequently accessed objects migrate automatically
5. Background backfill copies remaining objects

**After migration completes:**

```bash
# Verify object counts match
tigris ls t3://my-app-uploads --recursive | wc -l
aws s3 ls s3://my-existing-s3-bucket --recursive | wc -l

# Remove shadow source (makes Tigris the sole source)
tigris buckets update my-app-uploads --remove-shadow
```

---

## Bulk Copy

For smaller datasets or when you want a clean cutover:

```bash
# Copy all objects from S3 to Tigris
tigris cp s3://my-existing-bucket t3://my-app-uploads -r

# Or use AWS CLI pointed at Tigris
AWS_ENDPOINT_URL_S3=https://t3.storage.dev \
AWS_ACCESS_KEY_ID=tid_xxx \
AWS_SECRET_ACCESS_KEY=tsec_yyy \
aws s3 sync s3://my-existing-bucket s3://my-app-uploads
```

### From Google Cloud Storage

```bash
gsutil -m cp -r gs://my-gcs-bucket /tmp/migration/
tigris cp /tmp/migration/ t3://my-app-uploads/ -r
```

### From Azure Blob Storage

```bash
az storage blob download-batch -d /tmp/migration/ -s my-container
tigris cp /tmp/migration/ t3://my-app-uploads/ -r
```

---

## SDK Code Changes

Read the resource file for your language to see before/after migration examples:

- **Node.js / TypeScript** — Read `./resources/sdk-nodejs.md` for AWS SDK → Tigris SDK migration
- **Go** — Read `./resources/sdk-go.md` for AWS SDK → Tigris SDK migration
- **Python** — Read `./resources/sdk-python.md` for boto3 → tigris-boto3-ext migration
- **Ruby** — Read `./resources/sdk-ruby.md` for aws-sdk-s3 endpoint swap
- **PHP** — Read `./resources/sdk-php.md` for aws-sdk-php endpoint swap

---

## Environment Variable Changes

```bash
# Before (AWS)
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=us-east-1
S3_BUCKET=my-bucket

# After (Tigris)
AWS_ACCESS_KEY_ID=tid_xxx
AWS_SECRET_ACCESS_KEY=tsec_yyy
AWS_ENDPOINT_URL_S3=https://t3.storage.dev
AWS_REGION=auto
S3_BUCKET=my-bucket  # bucket name can stay the same
```

For frameworks with specific Tigris env vars:

```bash
TIGRIS_STORAGE_ACCESS_KEY_ID=tid_xxx
TIGRIS_STORAGE_SECRET_ACCESS_KEY=tsec_yyy
TIGRIS_STORAGE_ENDPOINT=https://t3.storage.dev
TIGRIS_STORAGE_BUCKET=my-bucket
```

---

## Verification Checklist

- [ ] Object count matches between source and Tigris
- [ ] Spot-check files: download a few and verify content/checksums
- [ ] Test presigned URL generation (endpoint must point to Tigris)
- [ ] Test CORS if using browser uploads (reconfigure on Tigris bucket)
- [ ] Test all upload/download code paths in staging
- [ ] Update CDN origin if using CloudFront/similar (point to Tigris)
- [ ] Update DNS if using custom domains

---

## Rollback Strategy

1. Keep source bucket read-only during migration (don't delete data)
2. Run both systems in parallel during verification
3. Only delete source data after confirming Tigris works fully
4. If using shadow bucket, removing the shadow source is the point of no return

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Forgot to update presigned URL endpoint | Presigned URLs must use Tigris endpoint, not S3 |
| CORS not configured on Tigris | Re-create CORS rules: `tigris buckets cors set` |
| Region hardcoded to `us-east-1` | Use `auto` for Tigris |
| `path_style` not set | Add `force_path_style: true` (Ruby/Rails) or `use_path_style_endpoint: true` (PHP) |
| Custom domain DNS still points to S3 | Update CNAME to point to Tigris |

---

## Related Skills

- **file-storage** — CLI setup and SDK reference
- **tigris-security-access-control** — CORS and access key setup

## Official Documentation

- S3 Compatibility: https://www.tigrisdata.com/docs/sdks/s3/
- Shadow Buckets: https://www.tigrisdata.com/docs/
