# danoguer.dev — Cloud Portfolio

> Minimal, serverless portfolio deployed on AWS using Infrastructure as Code and automated CI/CD.

---

## Architecture

```text
[ Client ]
    │ HTTPS
    ▼
[ Route 53 ]
    │
    ▼
[ CloudFront ]
    │
    ├── Lambda@Edge
    │   └── Security headers & URL rewrites
    │
    └── OAC
         │
         ▼
[ Private S3 Bucket ]
```

* **Route 53** — DNS and custom domain routing.
* **CloudFront** — Global CDN, HTTPS and edge caching.
* **Lambda@Edge** — Edge logic for security headers and URL rewrites.
* **OAC** — Restricts S3 access to CloudFront.
* **S3** — Private static asset storage.

---

## Tech Stack

* HTML5 / CSS3 / JavaScript
* AWS: S3, CloudFront, Route 53, Lambda@Edge, ACM
* Terraform
* GitHub Actions
* HTMLHint / Lychee / Commitlint

---

## CI/CD

```text
Git Push
   │
   ▼
GitHub Actions
   ├── HTMLHint
   ├── Lychee
   ├── Commitlint
   └── Terraform
          │
          ▼
       AWS Deploy
```

---

## Deployment

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Infrastructure is fully managed through Terraform and version controlled alongside the application.
