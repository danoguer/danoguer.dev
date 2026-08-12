# danoguer.dev — Cloud Portfolio

> A minimal, serverless, high-performance portfolio deployed on AWS and managed entirely through Infrastructure as Code.

---

## Overview

`danoguer.dev` is a static portfolio designed around a simple principle:

**keep the application layer minimal and let the infrastructure do the work.**

The website is delivered globally through Amazon CloudFront, backed by a private Amazon S3 bucket. Infrastructure is provisioned with Terraform and changes are validated and deployed through GitHub Actions.

The result is a fully automated, low-maintenance and globally distributed static website without publicly exposing the S3 origin.

---

## Architecture

```text
                         HTTPS
                           │
                           ▼
                    ┌─────────────┐
                    │   Route 53  │
                    │     DNS     │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  CloudFront │
                    │     CDN     │
                    └──────┬──────┘
                           │
                        OAC │
                           ▼
                    ┌─────────────┐
                    │ Private S3  │
                    │    Bucket   │
                    └─────────────┘
