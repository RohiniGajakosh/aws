# AWS Provisioning Scripts

This repository houses a collection of bash utilities that automate the creation of a full AWS application stack: VPC networking, security groups, RDS, EC2, and user-data bootstrap for a PHP/Apache application backed by MySQL. It is intended for repeatable lab or demo environments using the AWS CLI.

---

## Contents

| File | Purpose |
| --- | --- |
| `subnet.sh` | Creates a VPC and five subnets (app/data/public) with tags. CLI pager is disabled so the script runs non-interactively. |
| `igw.sh` | Attaches an Internet Gateway to a VPC and updates route tables. |
| `aws.sh` | Utility placeholder (extend for additional AWS automation). |
| `infracomponet.sh` | Orchestrates VPC DNS settings, security groups, RDS instance, EC2 launch, and injects user data. |
| `userdatanew.sh` | Stand-alone user-data script that installs Apache/PHP, deploys the sample site, and performs health checks. |
| `.vscode/settings.json` | Enables auto-save in VS Code (workspace-specific). |

Keys and other secrets are deliberately excluded via `.gitignore`.

---

## Prerequisites

- AWS CLI v2 configured with credentials and default region (`us-east-1` by default here).
- Bash shell (tested under Fedora WSL) with `dnf`, `python3`, `curl`, and `jq` (optional) available.
- Network access from your environment to the AWS API endpoints used.
- IAM permissions for EC2, VPC, RDS, and IAM instance profiles.

> **Security note:** Never commit private keys. All `*.pem` and `*.ppk` files are ignored. If you accidentally commit a key, rotate it immediately and use history-rewrite steps similar to `git filter-branch` already applied here.

---

## Usage Workflow

1. **Prepare variables**
   - Edit `infracomponet.sh` and set VPC/SUBNET IDs, DB names, passwords, and key pair names to match your environment.
   - Update `userdatanew.sh` if you run it independently. Replace DB placeholders or export the appropriate environment variables before use.

2. **Run networking scripts**
   - `./subnet.sh` creates the VPC/subnet topology.
   - `./igw.sh` (if used) attaches the Internet Gateway and configures routing.

3. **Launch infrastructure**
   - Execute `./infracomponet.sh`. It will:
     1. Ensure VPC DNS attributes are enabled.
     2. Create/authorize an EC2 security group that allows all traffic for testing.
     3. Create (or reuse) the RDS subnet group and database.
     4. Wait for the database, fetch the endpoint, and render `user_data.sh` with that endpoint and credentials.
     5. Launch an EC2 instance with the generated user data.
     6. Print a summary with the EC2 public IP and RDS endpoint.

4. **Verify**
   - SSH using `ssh -i ~/.ssh/<key>.pem ec2-user@<public-ip>`.
   - Inspect bootstrap logs: `sudo tail -n 50 /var/log/user-data.log` and `sudo cat /var/log/cloud-init-output.log`.
   - Confirm Apache is serving the site: `curl http://127.0.0.1/` and browse `http://<public-ip>/`.
   - Check RDS connectivity from the instance; DNS must resolve the endpoint (ensure NAT/IGW paths are correct).

5. **Cleanup**
   - Delete the EC2 instance and RDS database when finished (`aws ec2 terminate-instances`, `aws rds delete-db-instance`).
   - Remove subnets, gateways, and VPC when no longer needed (`aws ec2 delete-subnet`, `aws ec2 detach-internet-gateway`, `aws ec2 delete-vpc`).

---

## Development Guidelines

- **Zero trust for secrets.** Keep PEM/PPK keys outside the repo. If a key touches history, rotate it and rewrite the history (`git filter-repo` or `git filter-branch`).
- **Idempotency.** Scripts attempt to skip existing resources when possible (e.g., subnet groups). Extend this pattern if you add features.
- **Logging.** User data logs to `/var/log/user-data.log` and performs health checks. Mirror this style in new automation.
- **Error Handling.** Network calls can fail (e.g., repo timeouts). Add retries or guardrails if you promote these scripts beyond labs.
- **Version control.** Run `shellcheck` and `set -euo pipefail` in new scripts. Commit with meaningful messages and ensure `.gitignore` stays updated.

---

## Troubleshooting

- **Cloud-init timeouts:** Usually caused by lack of outbound internet/NAT. Fix routing/security groups before rerunning user data.
- **HTTP 500 from Apache:** Check `/var/log/php-fpm/www-error.log` for PHP parse errors or database connection issues.
- **RDS connection failures:** Validate that the EC2 instance can resolve the RDS endpoint (DNS + security group) and that MySQL credentials are correct. For private subnets, set up a NAT gateway.
- **Security group deletion errors:** Ensure dependent resources (ENIs, instances) are removed before deleting the group.

---

## Future Enhancements

- Parameterize all inputs via environment variables or JSON manifests.
- Replace shell scripts with Terraform/CloudFormation for production-grade deployments.
- Integrate AWS VPC IPAM or `ipaddress` logic to auto-calculate subnet CIDRs.
- Add CI checks (linting, `shellcheck`, automated dry-run validations).

Contributions welcome—open an issue or PR with improvements.
