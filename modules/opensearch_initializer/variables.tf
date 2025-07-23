variable "opensearch_url" {
  type = string
}

variable "slack_webhook_url" {
  type = string
}

variable "detect_event_names" {
  type    = list(string)
  default = [
    "DeleteUser", "DeleteRole", "DeleteLoginProfile",
    "StopLogging", "DeleteTrail",
    "DeactivateMFADevice", "DeleteVirtualMFADevice",
    "AuthorizeSecurityGroupIngress", "RevokeSecurityGroupIngress",
    "AuthorizeSecurityGroupEgress", "RevokeSecurityGroupEgress",
    "AttachUserPolicy", "DetachUserPolicy",
    "PutUserPolicy", "DeleteUserPolicy",
    "CreatePolicy", "DeletePolicy",
    "RunInstances"
  ]
}

variable "opensearch_domain_arn" {
  type        = string
  description = "ARN of the OpenSearch domain (for least privilege access)"
}