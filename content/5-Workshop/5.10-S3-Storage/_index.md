---
title: "5.10 S3 Storage"
date: 2026-07-15
weight: 10
chapter: false
pre: " <b> 5.10. </b> "
---

{{% notice warning %}}
**Status: Planned, not Implemented.** The `fitness-assistant` source code currently stores uploaded files (InBody photos, profile photos, PT application documents) on local disk via `multer`, in a Docker volume (`user_uploads`) in local development. No AWS S3 client (`aws-sdk` / `@aws-sdk/*`) exists anywhere in the current source code. Everything in this section describes a **planned** integration that requires an actual code change to `user-service` before it can be marked Implemented.
{{% /notice %}}

### Why This Section Exists

Even though S3 is not yet wired into the application, documenting the planned design here makes the gap explicit and gives a concrete starting point for implementing it later, rather than leaving file storage as an unaddressed risk.

### Current Behavior (Verified)

- `backend/services/user-service/src/routes/inbody.routes.ts`, `profile.routes.ts`, and `pt_application.routes.ts` use `multer` to write uploaded files to a local `uploads/` directory.
- The production Dockerfile bakes `mkdir -p uploads/pt-applications` into the image; on EC2 this means uploaded files live only on the container's (or host-mounted) filesystem, not in durable, replicated storage.
- In local development, a Docker named volume (`user_uploads`) keeps files across container restarts; on a single EC2 host, the same approach only survives as long as that one host exists.

### Planned Bucket

```bash
aws s3api create-bucket \
  --bucket <YOUR_BUCKET_NAME> \
  --region <YOUR_AWS_REGION>
```

### Block Public Access

```bash
aws s3api put-public-access-block \
  --bucket <YOUR_BUCKET_NAME> \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

### Encryption

```bash
aws s3api put-bucket-encryption \
  --bucket <YOUR_BUCKET_NAME> \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

### Versioning

Recommended if accidental overwrites of InBody photos or PT documents are a concern; adds storage cost, so weigh against the [Proposal](../../2-Proposal/#21-cost-estimate) cost estimate.

### CORS (If the Frontend Uploads Directly)

Only needed if the frontend is changed to upload directly to S3 (e.g. via a presigned URL) instead of through `user-service`. TODO: decide and document the actual upload flow before configuring CORS.

### IAM Role for S3 Access

See [`/files/policies/s3-access-policy.example.json`](/files/policies/s3-access-policy.example.json) for a least-privilege example policy scoped to a single bucket ARN, to attach to the `user-service` container's execution identity once implemented.

### Planned Upload / Download Flow

1. `user-service` receives the upload via `multer` (as it does today).
2. Instead of writing to local disk, `user-service` would upload the buffer to S3 using the AWS SDK, then store the S3 object key in its database instead of a local file path.
3. Downloads/previews would either proxy through `user-service` or use a presigned URL — TODO: decide once implemented.

### Presigned URLs

TODO: not yet designed. Would apply to either direct browser uploads or time-limited download links, if adopted.

### Testing

Not applicable — this feature does not exist in the deployed application yet. Do not mark any S3-related test case as `PASS` in [5.13 Testing and Validation](../5.13-Testing-Validation/).

### Clean-up

If a bucket is created for testing this design, delete all objects and the bucket itself during [5.16 Cleanup](../5.16-Cleanup/) if it is not going to be used going forward.
