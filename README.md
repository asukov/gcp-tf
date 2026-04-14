# Data-Driven Terraform Architecture (GitOps)

This repository uses a **Data-Driven (GitOps) Terraform pattern** to manage Google Cloud Platform (GCP) infrastructure. 

Instead of writing complex Terraform HCL (HashiCorp Configuration Language) code for every new resource, this architecture completely separates the **Data (what we want to build)** from the **Logic (how it is built)**. 

Developers and cloud users only need to interact with a simple `config.yaml` file to deploy and manage infrastructure.

## Repository Structure

This architecture relies on two separate codebases for maximum safety, versioning, and reusability:

1. **Main Project Repository (This Repo):** Contains the actual data (`config.yaml`), environment variables (`terraform.tfvars`), and the root orchestrator (`main.tf`).
2. **Modules Repository (Git Submodules):** Contains the reusable, logic-heavy Terraform modules (e.g., Google's Fabric FAST modules and our custom IAM module) that are incorporated as Git submodules (`.gitmodules`).

```text
gcp-tf-projects/                 
├── .gitmodules                         # Links to our shared module repositories
├── .gitignore                          # Gitignore file
├── sample-project/
│   ├── config.yaml                     # THE SINGLE SOURCE OF TRUTH (Your infrastructure data)
│   ├── main.tf                         # The Orchestrator: reads the YAML and calls modules
│   ├── variables.tf                 
│   ├── terraform.tfvars                # Environment-specific variables (Project ID, Deployer SA)
│   ├── backend.conf                    # GCS State Bucket configuration
│   ├── output.tf                       # Terraform Output configuration
│   └── providers.tf                    # Terraform providers
├── gcp-tf-templates/modules/           # Custom internal modules (e.g., dynamic IAM)
└── cloud-foundation-fabric/modules/    # Official Google Cloud Foundation FAST modules
```

## How It Works

### **1.** `config.yaml` **(The Data)**
The `config.yaml` file acts as the declarative ledger for your project. To deploy a new Virtual Machine, Cloud Run service, or Cloud SQL database, you simply add a dictionary block to this file. 

```yaml
vms:
  my-linux-vm:
    zone: "europe-west1-b"
    machine_type: "e2-medium"
    network: "my-vpc-network"
    subnetwork: "my-subnet"

cloud_runs:
  my-hello-app:
    region: "europe-west1"
    image: "us-docker.pkg.dev/cloudrun/container/hello"
```

### **2.** `main.tf` **(The Orchestrator)**
The root `main.tf` file reads the `config.yaml` using Terraform's native `yamldecode()` function. It then uses `for_each` loops to dynamically call the appropriate external modules for every item defined in the YAML file.

If a block (like `vms:`) does not exist in the YAML, the `try(..., {})` function safely returns an empty map, and the VM module is bypassed without errors.

### **3. Implicit IAM Toggling**
To enforce the **Principle of Least Privilege**, the deployer service account (`tf-rw`) is only granted the administrative permissions it absolutely needs, exactly when it needs them.

Our custom IAM module uses the `length()` of the YAML dictionaries to determine if permissions should be enabled.

 - Example: If you add a Cloud Run service to the YAML, `length(local.config.cloud_runs) > 0` evaluates to `true`. Terraform automatically grants the deployer the `roles/run.admin` role and generates the necessary dedicated Service Accounts for the microservices.
 - If you delete all Cloud Run services from the YAML, the permissions are **automatically revoked** from the deployer.

## Usage Guide
### Deploying a New Resource
1. Open `config.yaml`.
2. Add your new resource under the appropriate category (e.g., `vms:`, `cloud_runs:`, `databases:`).
3. Commit your changes and Push the changes.
4. Provision the resources using `terraform apply`

### Removing a Resource
1. Open `config.yaml`. 
2. Delete or comment out the resource block.
3. Commit and push.
4. Deprovision the resources using `terraform apply`

## Output Generation

Because this architecture uses a `for_each` loop to deploy resources dynamically based on the `config.yaml`, the Terraform outputs are also generated dynamically. 

Instead of a flat list of individual attributes, the outputs are grouped into maps that mirror the structure of `config.yaml` file. 

This means whether you deploy 1 Virtual Machine or 100, the output remains clean and organized by the resource names you defined.

### Example Output Structure

When you run `terraform apply`, you will receive grouped blocks of information:

```text
Outputs:

vms = {
  "my-linux-vm" = {
    "id"         = "projects/.../zones/europe-west1-b/instances/my-linux-vm"
    "private_ip" = "10.0.0.5"
    "ssh_login"  = "gcloud compute ssh my-linux-vm --zone=europe-west1-b"
  }
}
cloud_runs = {
  "my-hello-app" = {
    "uri" = "https://my-hello-app-abc123def-ew.a.run.app"
  }
}
databases = {
  "my-pg-database" = {
    "instance_name" = "my-pg-database-xyz987"
    "ip_address"    = "10.10.0.4"
  }
}
```

### Retrieving Sensitive Data (Passwords)

By design, Terraform hides sensitive values (like auto-generated Cloud SQL user passwords) from the standard console output to prevent them from being exposed in CI/CD logs. When you run `terraform apply`, they will simply appear as `<sensitive>`.

To view the actual plaintext passwords after a successful deployment, you must explicitly request the output in JSON format.

**1. View all database passwords:**
Run the following command to print the entire JSON object containing all generated passwords:
```bash
terraform output -json database_passwords
```
**2. Extract a specific password (using `jq`):**
Because our data-driven architecture groups outputs by the resource name, the resulting JSON is a nested map. You can use a command-line JSON processor like `jq` to extract exactly the string you need.

For example, to get the password for `user1` on the database named my-pg-database:
```bash
terraform output -json database_passwords | jq -r '."my-pg-database".user1'
```

## Security Notes
- **No Secrets in Code**: Passwords and sensitive data must never be hardcoded in the `config.yaml`. Rely on tools like Google Secret Manager, `random_password` Terraform resources, or inject them securely via your CI/CD pipeline or Environmental variables.
- **State File**: The `.tfstate` file is stored securely in an encrypted GCS bucket defined in `backend.tf`.