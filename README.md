# danoguer.dev — Cloud Portfolio

A minimal, serverless, high-performance static portfolio website deployed on AWS infrastructure using Infrastructure as Code (IaC) and automated CI/CD pipelines.

---

## 🏗️ Architecture

```text
[ Client ] ──( HTTPS )──► [ CloudFront CDN ] ──( OAC )──► [ Private S3 Bucket ]

    Storage: Private S3 Bucket storing static assets (index.html).

    Distribution: AWS CloudFront CDN providing HTTPS, edge caching, and global delivery.

    Security: Origin Access Control (OAC) restricting S3 access strictly to CloudFront requests.


🛠️ Tech Stack

Frontend: Vanilla HTML5, Modern CSS, JavaScript.

Infrastructure as Code: Terraform (aws provider).


CI/CD & Quality:

GitHub Actions for automated pipeline execution.

HTMLHint for HTML syntax validation.

Lychee for link and asset validation.

Commitlint enforcing Conventional Commits standard.


🚀 Local Infrastructure Deployment

To deploy or preview the infrastructure manually:

# 1. Navigate to terraform directory
cd terraform

# 2. Initialize provider and modules
terraform init

# 3. Preview planned changes
terraform plan

# 4. Provision AWS resources
terraform apply
