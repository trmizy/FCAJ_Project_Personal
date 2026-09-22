# Architecture Diagram Source

This folder contains the editable draw.io source file:

- `fitness-assistant-aws-architecture.drawio`

**Status: real diagram, not a placeholder.** It uses the actual AWS4 icon set (`mxgraph.aws4.*` shapes: EC2, RDS, Internet Gateway, ECR, IAM Role, Secrets Manager, CloudWatch, SNS) and matches the topology in [Proposal §12](../../../content/2-Proposal/_index.md) and [Workshop 5.2](../../../content/5-Workshop/5.2-Architecture/_index.md): custom VPC with public/private subnets, the 8 MVP application containers on a single EC2 host, RDS in the private subnets, and the monitoring/alerting path (CloudWatch → SNS → email). `chat-service` is deliberately absent (out of MVP scope).

**Before submitting:**

1. Open this file in [draw.io / diagrams.net](https://app.diagrams.net/) (desktop app, or the web app with "Open Existing Diagram" → this file).
2. Confirm every AWS icon actually rendered (a handful of `resIcon` names — ECR, IAM Role, Secrets Manager, CloudWatch, SNS — were typed from memory and should be double-checked against the current AWS4 shape library; if any box shows blank/no icon, use the left-hand shape search panel, type the service name, e.g. "Amazon ECR", and drag the correct icon onto the existing box — don't recreate the whole diagram).
3. Fill in `&lt;YOUR_AWS_REGION&gt;` in the "AWS Cloud" boundary label with the real region once chosen (see [Proposal §21](../../../content/2-Proposal/_index.md)).
4. Export as PNG (File → Export as → PNG, or `File → Export as → PNG…` in the desktop app) and save it to `static/images/workshop/architecture/fitness-assistant-aws-architecture.png`, replacing the placeholder there — see that folder's `README.md`.
