#!/usr/bin/env python3
import boto3
import os

#os.makedirs("infra-data", exist_ok=True)

s3 = boto3.client(
    's3',
    endpoint_url=os.getenv('AWS_ENDPOINT_URL_S3', 'http://pbsnas.homelab.local:9000'),
    aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
    aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'),
    region_name=os.getenv('AWS_REGION', 'us-east-1')
)

# Download inventory to infra-data/inventory/
inventory_dir = "../inventory"
os.makedirs(inventory_dir, exist_ok=True)
s3.download_file('ansible-bucket', 'inventory/inventory.ini', f'{inventory_dir}/inventory.ini')
print("Inventory downloaded to", f'{inventory_dir}/inventory.ini')

# Download DNS records to infra-data/dns/
dns_dir = "../dns"
os.makedirs(dns_dir, exist_ok=True)
s3.download_file('ansible-bucket', 'dns-records/dns-records.txt', f'{dns_dir}/dns-records.txt')
print("DNS records downloaded to", f'{dns_dir}/dns-records.txt')