# Install and prepare MinIO client (mc)
```bash
sudo apt update && sudo apt upgrade -y
wget https://dl.min.io/client/mc/release/linux-arm64/mc
sudo mv mc /usr/local/bin/
sudo chmod +x /usr/local/bin/mc
mc --version
```
# Verify MinIO is running locally
```bash
sudo systemctl status minio
curl http://localhost:9000
```
# Create local alias for your MinIO server
```bash
mc alias set local http://192.168.11.98:9000 minioadmin minioadmin123
```

# Create and configure Terraform bucket
```bash
mc mb --with-lock local/terraform-bucket
mc version enable local/terraform-bucket
mc retention set --default compliance 30d local/terraform-bucket
```
# (Optional) secure credentials and manage users
```bash
openssl rand -base64 32
mc admin user add local terraform paE3UbeF/lUGfCCWJaXqX0Rt9WfAYUjMEL26wbpJnlQ=
mc admin policy attach local readwrite --user terraform
```
# Verify setup
```bash
mc admin user list local
mc version info local/terraform-bucket

```