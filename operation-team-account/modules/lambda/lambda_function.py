import os
import json
import gzip
import boto3
import urllib.request
import urllib.error

def send_slack_alert(record: dict):
    webhook_url = os.environ['SLACK_WEBHOOK_URL']
    user       = record.get("userIdentity", {}).get("arn", "Unknown user")
    event_name = record.get("eventName", "Unknown event")
    source_ip  = record.get("sourceIPAddress", "Unknown IP")
    time       = record.get("eventTime", "Unknown time")
    region     = record.get("awsRegion", "Unknown region")
    account    = record.get("recipientAccountId", "Unknown account")

    slack_payload = {
        "blocks": [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": ":rotating_light: AWS Security Alert",
                    "emoji": True
                }
            },
            {
                "type": "section",
                "fields": [
                    {"type": "mrkdwn", "text": f"*Event:*\n`{event_name}`"},
                    {"type": "mrkdwn", "text": f"*User:*\n`{user}`"},
                    {"type": "mrkdwn", "text": f"*Source IP:*\n`{source_ip}`"},
                    {"type": "mrkdwn", "text": f"*Region:*\n`{region}`"},
                    {"type": "mrkdwn", "text": f"*Account:*\n`{account}`"},
                    {"type": "mrkdwn", "text": f"*Time:*\n`{time}`"}
                ]
            },
            {
                "type": "divider"
            }
        ]
    }

    data = json.dumps(slack_payload).encode('utf-8')
    req = urllib.request.Request(webhook_url, data=data, headers={'Content-Type': 'application/json'})

    try:
        with urllib.request.urlopen(req, timeout=5) as response:
            print("Slack message sent:", response.status)
    except Exception as e:
        print("Error sending Slack message:", str(e))


def lambda_handler(event, context):
    print("Received S3 PutObject event:", json.dumps(event, indent=2))

    # 1) EventBridge detail 로부터 버킷과 키 추출
    detail = event.get("detail", {})
    bucket = detail.get("requestParameters", {}).get("bucketName")
    key    = detail.get("requestParameters", {}).get("key")

    if not bucket or not key:
        print("Bucket or key missing in event detail")
        return {"statusCode": 400, "body": json.dumps({"error": "Invalid event"})}

    # 2) S3에서 gzip된 CloudTrail 로그 파일 다운로드 및 파싱
    s3  = boto3.client("s3")
    try:
        obj = s3.get_object(Bucket=bucket, Key=key)
    except Exception as e:
        print(f"Error fetching object {bucket}/{key}: {e}")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

    try:
        with gzip.GzipFile(fileobj=obj["Body"]) as gz:
            log_data = json.load(gz)
    except Exception as e:
        print(f"Error decompressing/parsing CloudTrail log: {e}")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

    # 3) 각 레코드별 필터링 및 Slack 알림
    alert_events = {
        "DeleteUser", "DeleteRole", "DeleteLoginProfile",
        "StopLogging", "DeleteTrail",
        "DeactivateMFADevice", "DeleteVirtualMFADevice",
        "AuthorizeSecurityGroupIngress", "RevokeSecurityGroupIngress",
        "AuthorizeSecurityGroupEgress", "RevokeSecurityGroupEgress",
        "AttachUserPolicy", "DetachUserPolicy",
        "PutUserPolicy", "DeleteUserPolicy",
        "CreatePolicy", "DeletePolicy",
        "RunInstances"
    }

    for record in log_data.get("Records", []):
        evt = record.get("eventName")
        # 실패한 로그인만
        if evt == "ConsoleLogin" and record.get("errorCode") != "Success":
            send_slack_alert(record)
        elif evt in alert_events:
            send_slack_alert(record)

    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Processed S3 log and sent alerts."})
    }