# HashiCorp Vault - Step-by-Step Setup Tutorial

## Install Vault

```bash
# Add HashiCorp repository
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install Vault
sudo apt update && sudo apt install vault

# Verify installation
vault version
```

## Create directories and TLS certificates

```bash
# Create required directories
sudo mkdir -p /opt/vault/data
sudo mkdir -p /opt/vault/tls
sudo mkdir -p /etc/vault.d

# Generate self-signed TLS certificate (replace 192.168.1.100 with your IP)
sudo openssl req -x509 -newkey rsa:4096 -sha256 -days 365 \
    -nodes -keyout /opt/vault/tls/tls.key -out /opt/vault/tls/tls.crt \
    -subj "/CN=192.168.1.100" \
    -addext "subjectAltName=DNS:vault.local,IP:192.168.1.100"
```

## Set up vault user and permissions

```bash
# Create vault system user
sudo useradd --system --home /etc/vault.d --shell /bin/false vault

# Set ownership
sudo chown -R vault:vault /opt/vault
sudo chown -R vault:vault /etc/vault.d

# Set proper permissions for TLS files
sudo chmod 600 /opt/vault/tls/tls.key
sudo chmod 644 /opt/vault/tls/tls.crt
```

## Create Vault configuration file

```bash
# Create configuration file (replace 192.168.1.100 with your IP)
sudo nano /etc/vault.d/vault.hcl
```

Paste this content:

```hcl
api_addr      = "http://192.168.1.100:8200"
cluster_addr  = "http://192.168.1.100:8201"
cluster_name  = "vault-cluster"
disable_mlock = true
ui            = true

storage "raft" {
  path    = "/opt/vault/data"
  node_id = "vault-node-1"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/opt/vault/tls/tls.crt"
  tls_key_file  = "/opt/vault/tls/tls.key"
}
```

## Create and start systemd service

```bash
# Create service file
sudo nano /etc/systemd/system/vault.service
```

Paste this content:

```ini
[Unit]
Description=HashiCorp Vault
Documentation=https://developer.hashicorp.com/vault/docs
Requires=network-online.target
After=network-online.target

[Service]
Type=notify
User=vault
Group=vault
ExecStart=/usr/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

```bash
# Reload systemd and start Vault
sudo systemctl daemon-reload
sudo systemctl enable vault
sudo systemctl start vault

# Verify Vault is running
sudo systemctl status vault
```

## Configure environment variables

```bash
# Set Vault address (replace 192.168.1.100 with your IP)
export VAULT_ADDR='https://192.168.1.100:8200'
export VAULT_SKIP_VERIFY=true

# Make permanent
echo 'export VAULT_ADDR="https://192.168.1.100:8200"' >> ~/.bashrc
echo 'export VAULT_SKIP_VERIFY=true' >> ~/.bashrc
source ~/.bashrc

# Verify connection
vault status
```

## Initialize Vault (ONE TIME ONLY!)

```bash
# Initialize Vault - generates 5 unseal keys and 1 root token
vault operator init

# ⚠️ CRITICAL: Save all 5 unseal keys and the root token securely!
# You'll see output like:
# Unseal Key 1: AbCdEf...
# Unseal Key 2: BcDeFg...
# Unseal Key 3: CdEfGh...
# Unseal Key 4: DeFgHi...
# Unseal Key 5: EfGhIj...
# Initial Root Token: hvs.XXXXXXXX...
```

## Unseal Vault

```bash
# Unseal with 3 of 5 keys
vault operator unseal
# Paste Unseal Key 1, press Enter

vault operator unseal
# Paste Unseal Key 2, press Enter

vault operator unseal
# Paste Unseal Key 3, press Enter

# Verify Vault is unsealed
vault status
# Look for "Sealed: false"
```

## Login to Vault

```bash
# Login with root token
vault login
# Paste your Initial Root Token, press Enter

# Verify authentication
vault token lookup
```

## Enable KV secrets engine

```bash
# Enable KV version 2 secrets engine
vault secrets enable -path=secret kv-v2

# Verify it's enabled
vault secrets list
```

## Test Vault - Store and retrieve secrets

```bash
# Store a test secret
vault kv put secret/test username='admin' password='secret123'

# Read the secret
vault kv get secret/test

# Get specific field
vault kv get -field=username secret/test

# List all secrets
vault kv list secret/
```

## Access Web UI

```bash
# Open browser to (replace with your IP):
# https://192.168.1.100:8200/ui

# Login with:
# Method: Token
# Token: Your Initial Root Token
```

## Create read-only policy for Terraform

```bash
# Create a read-only policy
vault policy write terraform-read - <<EOF
path "secret/data/production/*" {
  capabilities = ["read", "list"]
}
EOF

# Verify policy
vault policy read terraform-read
```

## Create AppRole for Terraform

```bash
# Enable AppRole authentication
vault auth enable approle

# Create AppRole for Terraform
vault write auth/approle/role/terraform \
    token_policies="terraform-read" \
    token_ttl=1h \
    token_max_ttl=24h

# Get Role ID (save this - it's like a username)
vault read auth/approle/role/terraform/role-id

# Get Secret ID (save this - it's like a password)
vault write -f auth/approle/role/terraform/secret-id

# Verify AppRole
vault list auth/approle/role
```

## (Optional) Enable audit logging

```bash
# Create log directory
sudo mkdir -p /var/log/vault
sudo chown vault:vault /var/log/vault

# Enable file audit logging
vault audit enable file file_path=/var/log/vault/audit.log

# Verify audit is enabled
vault audit list

# View logs
sudo tail -f /var/log/vault/audit.log | jq
```

## (Optional) Create application token instead of using root

```bash
# Create policy for your application
vault policy write app-policy - <<EOF
path "secret/data/app/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF

# Create token with this policy
vault token create -policy=app-policy -ttl=24h

# Use this token in your applications instead of root token
```

## Verify complete setup

```bash
# Check Vault status
vault status

# List enabled auth methods
vault auth list

# List policies
vault policy list

# List secrets engines
vault secrets list

# Test secret operations
vault kv put secret/production/test key=value
vault kv get secret/production/test
vault kv delete secret/production/test
```

## Daily workflow after container restart

```bash
# Check if Vault is running
sudo systemctl status vault

# Set environment variables
export VAULT_ADDR='https://192.168.1.100:8200'
export VAULT_SKIP_VERIFY=true

# Check seal status
vault status

# If sealed, unseal with 3 keys
vault operator unseal  # Key 1
vault operator unseal  # Key 2
vault operator unseal  # Key 3

# Login
vault login  # Enter root token

# Verify ready
vault status
```

## Common operations

```bash
# Store a secret
vault kv put secret/path/name username='user' password='pass'

# Update a secret
vault kv put secret/path/name username='user' password='newpass'

# Read a secret
vault kv get secret/path/name

# Get specific field
vault kv get -field=password secret/path/name

# List secrets in path
vault kv list secret/path/

# Delete a secret
vault kv delete secret/path/name

# Undelete a secret
vault kv undelete -versions=1 secret/path/name

# View secret metadata
vault kv metadata get secret/path/name
```

## Troubleshooting

```bash
# View Vault logs
sudo journalctl -u vault -f

# Test Vault connectivity
curl -k https://192.168.1.100:8200/v1/sys/health

# Check if port is listening
sudo ss -tulpn | grep 8200

# Verify file permissions
ls -la /opt/vault/data
ls -la /opt/vault/tls
ls -la /etc/vault.d

# Test configuration syntax
vault server -config=/etc/vault.d/vault.hcl -test

# Check service status
sudo systemctl status vault

# Restart Vault
sudo systemctl restart vault
```