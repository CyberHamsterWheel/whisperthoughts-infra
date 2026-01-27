# Scalable Web Infrastructure with K3s & Terraform
A production-ready infrastructure project deploying a containerized Flask application on AWS. This repository manages the "Ops" side of a hybrid CI/CD workflow, utilizing K3s for orchestration and Traefik for automated SSL termination. The frontend repo remains private.

:link: **Link to Full Article:** Read the technical deep-dive on how i built this project.  
:link: **Link to Live Demo:** whisperthoughts.com  

## :rocket: Architecture Highlights
- **Infrastructure:** Terraform-managed AWS EC2, Route53, and Custom Security Groups.  
- **Orchestration:** K3s (Lightweight Kubernetes) on Ubuntu.  
- **Networking:** Traefik Ingress Controller with automated Let's Encrypt SSL via Cert-Manager.  
- **CI/CD:** Hybrid workflow using GitHub Actions for static analysis and local terminal for final deployment state management.  

## :open_file_folder: Repository Structure
<pre>
.  
├── terraform/          # Infrastructure as Code
│   ├── main.tf         # EC2, Route53, and Security Group resources  
│   ├── variables.tf    # Parameterized configs  
│   ├── provider.tf     # AWS Provider configuration  
│   └── outputs.tf      # Public IP  
├── k3s/  
│   └── manifests/      # K8s Resources  
│       ├── web-ingress.yml       # Traefik routing & SSL SAN config  
│       ├── web-deployment.yml    # Flask app with 2 replicas  
│       ├── web-service.yml       # Internal Load Balancer  
│       ├── traefik-redirect.yml  # HTTP to HTTPS logic  
│       ├── staging-issuer.yml    # Let's Encrypt Staging Issuer  
│       └── pro-issuer.yml        # Let's Encrypt Prod Issuer    
├── scripts/  
│   └── setup_host.sh   # Bash script for initial K3s/Docker server prep  
└── .github/workflows/  
    └── infra-ci.yml    # GitHub Actions: Terraform Validate & Kube-Linter  
</pre>

## :gear: **The Hybrid CI/CD Workflow**
This project uses a split-responsibility model to balance automation with cost-efficiency:  

### 1. Application Updates (Automated)  
- Changes are pushed to my private app repository.  
- GitHub Actions builds the Docker image and updates the **web-deployment.yml** in **this repo** with the new image SHA.  
- The cluster pulls the new image automatically, ensuring zero-downtime updates.


### 2. Infrastructure Updates (Hybrid)
- **Remote:** GitHub Actions triggers on every push to this repo to run `terraform validate`, `fmt`, and `kube-linter` on manifests.  
- **Local:** Once validated, I run `terraform apply` and `kubectl apply` from my local terminal.  
- **Decision:** This avoids the overhead/cost of managing remote S3/DynamoDB state backends for a single-contributor project.

## :hammer_and_wrench: Key Configurations
### Dynamic Load Balancing Visibility  
The Flask application utilizes the Kubernetes **Downward API** to display the specific Pod ID in the browser. This provides a visual confirmation of Traefik's RoundRobin load balancing between the 2 replicas.
```
pod_name = os.getenv('MY_POD_NAME', 'Local-Machine')
```

### Automated SSL (SAN Certificate)
The Ingress manifest is configured to handle both the root and `www` domains under a single SSL certificate provided by Let's Encrypt.
```
tls:
  - hosts:
      - whisperthoughts.com
      - www.whisperthoughts.com
    secretName: whisperthoughts-tls-cert
```

## :package: Prerequisites
* **Terraform** (v1.14.3)  
* **AWS CLI** configured with appropriate IAM permissions.  
* **kubectl** for remote cluster management.  
* **K3s** installed on the target EC2 instance.

## :bulb: Challenges & Solutions
- **x509 Certificate Issues:**
  - Copied the secret access key in `/etc/rancher/k3s/k3s.yaml`
  - `mkdir -p ~/.kube && touch ~/.kube/config` in local terminal and pasted the secret access key with the `https://127.0.0.1` changed to the public IP address of my EC2 instance
  - Modified `/etc/rancher/k3s/config.yaml` in the EC2 instance by adding the instance's public IP address
    ```
    tls-san:
      - my-ec2-public-ip
    ```
- **Cross-Repository Sync:**
  - Automated the "hand-off" between the private App repo and public Infra repo to avoid manual image tag updates.
  - Used a **GitHub PAT** and `sed` within a GitHub Actions workflow to programmatically inject the new image SHA into web-deployment.yml.
  - Achieved a seamless CI/CD flow while maintaining total isolation between private application logic and public infrastructure code.
- **Resource & Cost Optimization:**
  - Attempted an initial deployment on a **t2.micro** (1GB RAM) but identified that the cumulative overhead of the K3s control plane and the **Metrics Server** led to instance instability.
  - Optimized the cluster by disabling non-essential services like **Klipper (servicelb)** and **local storage** to reduce the memory footprint.
  - Migrated to a t3.small (2GB RAM) to provide the necessary headroom for stable metrics scrapingand consistent performance of the Traefik Ingress controller.

- **Security Resilience:** Shifted from "Default Security Groups" to Custom Terraform-managed Security Groups to ensure ingress rules (80, 443, 22, 6443) are version-controlled and reproducible.  
