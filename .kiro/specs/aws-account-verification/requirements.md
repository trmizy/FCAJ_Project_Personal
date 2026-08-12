# Requirements Document

## Introduction

This document specifies requirements for completing AWS account verification and enabling CloudShell access for AWS Account ID 191798898985. The account was created on 2026-07-08 and is currently in verification pending status, blocking CloudShell access with the message: "Your account verification is in progress. This may take up to two days for new accounts." The account holder needs full service access, particularly CloudShell in ap-southeast-1 region, to begin the 12-week FCAJ (First Cloud Journey AWS) workshop for building a Fitness Assistant application.

## Glossary

- **Account_Holder**: The owner of AWS Account ID 191798898985 (TRAN MINH DUY)
- **AWS_Account**: AWS Account ID 191798898985 created on 2026-07-08
- **CloudShell_Service**: AWS CloudShell browser-based shell environment in ap-southeast-1 region
- **Verification_System**: AWS account verification and activation system
- **Support_Case**: AWS Support ticket submitted through Support Center
- **Payment_Method**: Valid payment instrument registered with AWS account
- **Contact_Information**: Phone number (+84 372246113), email, and physical address (Quận Gò Vấp, TP.HCM)
- **MFA_Device**: Multi-Factor Authentication device already enabled on the account
- **Service_Availability**: Status indicating whether an AWS service is accessible without restrictions
- **Verification_Status**: Current state of account verification (pending, verified, or blocked)
- **Support_Response**: Reply from AWS Support team regarding verification or service access

## Requirements

### Requirement 1: Account Verification Status Check

**User Story:** As an Account_Holder, I want to check the current verification status of my AWS_Account, so that I understand what verification steps remain incomplete.

#### Acceptance Criteria

1. WHEN the Account_Holder accesses AWS Account Settings, THE Verification_System SHALL display the current Verification_Status
2. WHEN the Account_Holder views Contact Information, THE Verification_System SHALL show whether phone number verification is complete
3. WHEN the Account_Holder views Billing Console, THE Verification_System SHALL show whether Payment_Method is verified
4. THE Verification_System SHALL display an estimated completion time for pending verification
5. WHEN verification is complete, THE Verification_System SHALL update Verification_Status to "verified" within 1 hour

### Requirement 2: Payment Method Verification

**User Story:** As an Account_Holder, I want to verify my Payment_Method is properly registered and validated, so that AWS can confirm my account is legitimate.

#### Acceptance Criteria

1. WHEN the Account_Holder accesses Billing Console, THE Payment_Method SHALL show as "Active" or "Verified"
2. IF Payment_Method shows as "Pending Verification", THEN THE Account_Holder SHALL receive instructions for completing verification
3. WHEN Payment_Method verification requires action, THE Verification_System SHALL send a notification to the registered email within 24 hours
4. THE Payment_Method SHALL have no outstanding verification holds or pending charges
5. WHEN Payment_Method is successfully verified, THE Verification_System SHALL update account status within 2 hours

### Requirement 3: Contact Information Verification

**User Story:** As an Account_Holder, I want to verify my Contact_Information is correct and validated, so that AWS can confirm account ownership.

#### Acceptance Criteria

1. THE Contact_Information SHALL include verified phone number (+84 372246113)
2. THE Contact_Information SHALL include verified email address
3. THE Contact_Information SHALL include complete physical address (Quận Gò Vấp, TP.HCM, Vietnam)
4. WHEN phone number verification is incomplete, THE Verification_System SHALL provide an option to resend verification code
5. WHEN Contact_Information is updated, THE Verification_System SHALL trigger reverification within 1 hour

### Requirement 4: AWS Support Case Creation

**User Story:** As an Account_Holder, I want to create a Support_Case to expedite account verification, so that I can begin my workshop without waiting the full 2-day period.

#### Acceptance Criteria

1. WHEN the Account_Holder creates a Support_Case, THE Support_Case SHALL include AWS_Account ID (191798898985)
2. THE Support_Case SHALL describe the CloudShell_Service access issue with exact error message
3. THE Support_Case SHALL reference account creation date (2026-07-08) and current verification duration (19 days)
4. THE Support_Case SHALL request verification of Payment_Method, Contact_Information, and MFA_Device status
5. WHEN Support_Case is submitted, THE Verification_System SHALL assign a case ID within 30 minutes
6. THE Account_Holder SHALL receive a Support_Response within 24 hours for Basic Support or 12 hours for Developer Support

### Requirement 5: CloudShell Service Access Verification

**User Story:** As an Account_Holder, I want to verify CloudShell_Service is accessible in ap-southeast-1 region, so that I can use it for the FCAJ workshop.

#### Acceptance Criteria

1. WHEN the Account_Holder navigates to CloudShell in ap-southeast-1 region, THE CloudShell_Service SHALL launch within 60 seconds
2. IF CloudShell_Service is blocked, THEN THE CloudShell_Service SHALL display a specific error message indicating the blocking reason
3. WHEN account verification is complete, THE CloudShell_Service SHALL be accessible without the "verification in progress" message
4. THE CloudShell_Service SHALL provide a functional bash environment with AWS CLI pre-installed
5. WHEN CloudShell_Service launches successfully, THE Account_Holder SHALL be able to execute "aws sts get-caller-identity" and receive valid account information

### Requirement 6: Service Availability Confirmation

**User Story:** As an Account_Holder, I want to confirm all required AWS services are accessible without restrictions, so that I can complete the 12-week FCAJ workshop.

#### Acceptance Criteria

1. THE Service_Availability for EC2 SHALL be "fully accessible" in ap-southeast-1 region
2. THE Service_Availability for RDS SHALL be "fully accessible" in ap-southeast-1 region
3. THE Service_Availability for S3 SHALL be "fully accessible" globally
4. THE Service_Availability for VPC SHALL be "fully accessible" in ap-southeast-1 region
5. THE Service_Availability for IAM SHALL be "fully accessible" globally
6. THE Service_Availability for Lambda SHALL be "fully accessible" in ap-southeast-1 region
7. THE Service_Availability for CloudWatch SHALL be "fully accessible" in ap-southeast-1 region
8. WHEN checking Bedrock service, THE Service_Availability SHALL indicate whether service quotas or restrictions apply
9. WHEN all required services are accessible, THE Account_Holder SHALL be able to create resources within service limits

### Requirement 7: Verification Timeline Tracking

**User Story:** As an Account_Holder, I want to track verification progress and estimated completion time, so that I can plan workshop start date accordingly.

#### Acceptance Criteria

1. THE Verification_System SHALL provide an estimated completion date for pending verification
2. WHEN verification duration exceeds 2 business days from account creation, THE Verification_System SHALL automatically escalate for review
3. WHEN verification is complete, THE Account_Holder SHALL receive email notification within 1 hour
4. THE Verification_System SHALL maintain a verification event log showing each verification step completion time
5. WHEN Account_Holder checks verification status, THE Verification_System SHALL show elapsed time since account creation (currently 19 days)

### Requirement 8: Account Security Validation

**User Story:** As an Account_Holder, I want to ensure my account security settings meet AWS verification requirements, so that verification is not blocked by security issues.

#### Acceptance Criteria

1. THE MFA_Device SHALL be enabled and active on the root account
2. THE AWS_Account SHALL have at least one IAM user with AdministratorAccess policy attached
3. WHEN security best practices are not met, THE Verification_System SHALL provide specific remediation steps
4. THE AWS_Account SHALL have no security holds or fraud flags in Account Settings
5. WHEN security validation passes, THE Verification_System SHALL mark security requirements as complete

### Requirement 9: Billing and Cost Validation

**User Story:** As an Account_Holder, I want to verify there are no billing issues blocking account verification, so that verification can proceed without payment-related delays.

#### Acceptance Criteria

1. THE AWS_Account SHALL have a current billing amount less than $1.00
2. THE AWS_Account SHALL have no overdue invoices or payment failures
3. THE Payment_Method SHALL have no expired credit card or invalid banking information
4. WHEN billing information is incomplete, THE Verification_System SHALL provide specific fields requiring update
5. THE AWS_Account SHALL have a valid tax address matching Contact_Information

### Requirement 10: Post-Verification Testing

**User Story:** As an Account_Holder, I want to test all critical services after verification is complete, so that I can confirm readiness for the FCAJ workshop.

#### Acceptance Criteria

1. WHEN verification is complete, THE Account_Holder SHALL successfully launch CloudShell_Service in ap-southeast-1 region within 60 seconds
2. THE Account_Holder SHALL successfully execute "aws s3 ls" in CloudShell_Service and receive either a bucket list or empty result without errors
3. THE Account_Holder SHALL successfully execute "aws ec2 describe-regions" in CloudShell_Service and receive a list of available regions
4. THE Account_Holder SHALL successfully create a test S3 bucket and delete it without errors
5. WHEN testing Bedrock service, THE Account_Holder SHALL receive either successful access or clear quota limit messages (not verification errors)
6. THE Account_Holder SHALL verify IAM user with AdministratorAccess can perform all required operations
7. WHEN all tests pass, THE AWS_Account SHALL be ready for FCAJ workshop deployment

## Notes

**Timeline Expectations:**
- Account created: 2026-07-08 (19 days ago as of request date)
- Standard verification: 1-2 business days for new accounts
- Current status: Significantly overdue (19 days vs 2 days expected)
- With Support_Case: Expected resolution within 24-48 hours
- Without Support_Case: Resolution timeline uncertain

**Critical Success Factors:**
1. Payment_Method must be valid and verified
2. Contact_Information must be complete and match billing information
3. MFA_Device must remain enabled throughout verification
4. No suspicious activity or billing issues on account
5. Support_Case may be necessary given the 19-day delay

**Out of Scope:**
- AWS Organizations setup or multi-account strategy
- Support plan upgrades (Developer, Business, or Enterprise)
- Workshop implementation (separate spec required)
- Service quota increases beyond default limits
- Custom IAM policies for workshop deployment
