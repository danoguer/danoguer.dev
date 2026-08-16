# danoguer.me — Cloud & SRE Portfolio Infrastructure

> Production-grade, fully automated serverless portfolio hosted on AWS and provisioned strictly via Infrastructure as Code (Terraform).

🌐 **Live Site:** [https://danoguer.me](https://danoguer.me)

---

## 🏗️ Architecture Overview

The system is designed around immutable deployments, zero long-lived credentials, edge security, and serverless compute.

              [ Users (HTTPS) ]
                     │
                     ▼
            [ Route 53 + ACM ]
                     │
                     ▼
           [ CloudFront (CDN) ] ──(OAC)──► [ S3 Bucket (Private Origin) ]
                     │
 (Contact Form)      │
                     ▼
     [ Lambda Function URL (ARM64 / Go) ]
                     │
                     ▼
           [ Amazon SES / CloudWatch ]


### Key Components

- **Edge Delivery & CDN:** CloudFront distribution with HTTPS redirection, TLS 1.2+ minimum protocol, custom caching policy, and automatic cache invalidation on deployment.
- **Origin Isolation:** Private S3 bucket hosting static assets, fully blocked from public access via S3 Public Access Block and restricted strictly to CloudFront using **Origin Access Control (OAC)** with SigV4.
- **Serverless Backend:** Custom Go runtime (`provided.al2023` on **ARM64**) deployed on AWS Lambda with a public **Function URL**, CORS handling, and Amazon SES integration for contact submissions.
- **DNS & SSL/TLS:** Route 53 hosted zone managing DNS records (`A` and `AAAA` IPv6 alias) and ACM multi-region SSL certificates with automated DNS validation.
- **CI/CD & Security:** GitHub Actions integration using **OpenID Connect (OIDC)** federated identity, eliminating the need for long-lived AWS IAM access keys in repository secrets.
- **State Management:** Remote Terraform backend stored in an encrypted S3 bucket with native state locking.

---

## 🛠️ Tech Stack

| Domain | Technologies |
|---|---|
| **IaC / Automation** | Terraform, GitHub Actions (OIDC) |
| **Cloud (AWS)** | CloudFront, S3 (OAC), Route 53, ACM, Lambda, SES, IAM, DynamoDB, CloudWatch |
| **Backend / Runtime** | Go (Custom ARM64 Binary / `bootstrap`) |
| **Frontend** | Vanilla HTML5, CSS3 (Modern Design System), Vanilla JavaScript |

---

## 📁 Repository Structure

```text
.
├── infra/
│   ├── main.tf            # Core AWS resources (S3, CloudFront, Route53, ACM)
│   ├── lambda.tf          # Lambda backend, IAM roles, policies, and Function URL
│   ├── oidc.tf            # GitHub Actions OIDC provider & IAM roles
│   ├── state.tf           # Terraform S3 backend & locking table
│   └── variables.tf       # Region, project names, and domain variables
├── lambda/
│   └── bootstrap          # Compiled ARM64 Go binary for contact processing
└── src/
    ├── index.html         # Landing page
    ├── projects.html      # Systems & architecture archive
    ├── about.html         # Engineering journey & background
    └── images/            # Static assets & Open Graph previews

🚀 Deployment
Prerequisites

    Terraform >= 1.5.0

    AWS CLI configured with appropriate IAM permissions

Steps

    Initialize Terraform:
    Bash

    terraform init

    Review Execution Plan:
    Bash

    terraform plan

    Apply Infrastructure:
    Bash

    terraform apply

👤 Author

Daniel Nogueras Del Río

    Portfolio: danoguer.me

    GitHub: @danoguer

    LinkedIn: in/daniel-nogueras

    Email: danoguer.dev@gmail.com
