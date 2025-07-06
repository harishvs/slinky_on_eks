#!/bin/bash
set -e

# Run Terraform apply
echo "Running terraform apply..."
terraform apply -auto-approve

# Run the EKS access entry cleanup script
echo "Cleaning up EKS Access Entry..."
./delete-eks-access-entry.sh

echo "All done!" 