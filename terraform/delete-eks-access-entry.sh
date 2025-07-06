#!/bin/bash
set -e

CLUSTER_NAME="eks-slinky"
PRINCIPAL_ARN="arn:aws:iam::043632497353:user/harishrao"
POLICY_ARN="arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"

echo "Deleting EKS Access Entry for $PRINCIPAL_ARN in cluster $CLUSTER_NAME..."
aws eks delete-access-entry --cluster-name "$CLUSTER_NAME" --principal-arn "$PRINCIPAL_ARN" || echo "Access entry not found or already deleted."

echo "Disassociating EKS Access Policy for $PRINCIPAL_ARN in cluster $CLUSTER_NAME..."
aws eks disassociate-access-policy --cluster-name "$CLUSTER_NAME" --principal-arn "$PRINCIPAL_ARN" --policy-arn "$POLICY_ARN" || echo "Policy association not found or already deleted."

echo "Done." 