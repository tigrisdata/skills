# Django File Uploads with Tigris

> Uses `tigris-boto3-ext` (install: `pip install django-storages tigris-boto3-ext`).

## Configuration

```python
# settings.py
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

## Upload — View

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

## Download / Serve

```python
from django.http import FileResponse

def download(request, pk):
    doc = Document.objects.get(pk=pk)
    return FileResponse(doc.file.open(), as_attachment=True, filename=doc.file.name.split("/")[-1])
```

## Presigned Upload URL (Client-Side Upload)

```python
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

Browser client for presigned uploads:

```javascript
const { url } = await fetch("/api/presigned-upload", { method: "POST", body: JSON.stringify({ filename, contentType }) }).then(r => r.json());
await fetch(url, { method: "PUT", body: file, headers: { "Content-Type": file.type } });
```

## Presigned Download URL

```python
url = s3.generate_presigned_url("get_object",
    Params={"Bucket": BUCKET, "Key": path},
    ExpiresIn=3600,
)
```

## Multipart

```python
# django-storages handles multipart via boto3 transfer config
AWS_S3_MAX_MEMORY_SIZE = 10 * 1024 * 1024  # 10MB threshold for multipart
```
