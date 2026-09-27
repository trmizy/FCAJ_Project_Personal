# AWS Clean-up Checklist (copyable)

Mirrors `content/5-Workshop/5.16-Cleanup/`. Check off each item only after it has actually been verified deleted in the AWS Console or via CLI.

- [ ] 1. Stop and remove containers (`docker compose down` on EC2)
- [ ] 2. Delete CloudWatch Alarms
- [ ] 3. Delete SNS subscription and topic
- [ ] 4. Delete CloudWatch Log Groups (if not needed for record-keeping)
- [ ] 5. Delete S3 objects and bucket (only if one was created for testing)
- [ ] 6. Delete ECR images and repositories
- [ ] 7. Delete RDS instance
- [ ] 8. Decide: final snapshot or not, before deleting RDS
- [ ] 9. Delete EC2 instance
- [ ] 10. Release Elastic IP
- [ ] 11. Delete Load Balancer and Target Group (if any)
- [ ] 12. Delete NAT Gateway (if any)
- [ ] 13. Delete custom route tables
- [ ] 14. Delete subnets
- [ ] 15. Delete Internet Gateway
- [ ] 16. Delete custom Security Groups
- [ ] 17. Delete the VPC
- [ ] 18. Delete Secrets Manager secret(s)
- [ ] 19. Delete self-created IAM policies/roles
- [ ] 20. Check Billing and Resource Explorer for leftover resources

Do not check an item off without confirming it in the AWS Console or via an `aws` CLI query.
