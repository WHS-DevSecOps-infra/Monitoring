import os
import json
import gzip
import boto3
import requests
from datetime import datetime
from requests_aws4auth import AWS4Auth

# AWS 인증 설정
session = boto3.session.Session()
credentials = session.get_credentials()
region = session.region_name or os.environ.get("AWS_REGION")

awsauth = AWS4Auth(
    credentials.access_key,
    credentials.secret_key,
    region,
    "es",
    session_token=credentials.token
)

OPENSEARCH_ENDPOINT = os.environ["OPENSEARCH_URL"]
HEADERS = {"Content-Type": "application/json"}


def extract_user_arn(user_identity: dict) -> str:
    """AssumedRole 및 기타 케이스 포함한 ARN 추출 로직"""
    if not isinstance(user_identity, dict):
        return ""
    
    if "arn" in user_identity:
        return str(user_identity["arn"])
    
    return str(
        user_identity.get("sessionContext", {})
                     .get("sessionIssuer", {})
                     .get("arn", "")
    )


def send_to_opensearch(record: dict):
    try:
        event_name = record.get("eventName", "unknown").lower()
        event_time = record.get("eventTime")

        if not isinstance(event_time, str) or "T" not in event_time:
            event_time = datetime.utcnow().isoformat() + "Z"

        user_identity = record.get("userIdentity", {})

        index = f"security-alerts-{event_name}"
        url = f"{OPENSEARCH_ENDPOINT}/{index}/_doc"

        doc = {
            "@timestamp": event_time,
            "eventName": str(event_name),
            "user": extract_user_arn(user_identity),
            "sourceIP": str(record.get("sourceIPAddress", "")),
            "awsRegion": str(record.get("awsRegion", "")),
            "accountId": str(record.get("recipientAccountId", ""))
        }

        resp = requests.post(url, auth=awsauth, headers=HEADERS, data=json.dumps(doc), timeout=(5, 30))
        resp.raise_for_status()
        print(f"[Info] Indexed to OpenSearch: {event_name}")

    except Exception as e:
        print(f"[Warning] Failed to index record: {e}")
        print(f"[Debug] Payload was: {json.dumps(record)[:500]}...")

        # 실패한 레코드를 fallback 인덱스로 저장
        try:
            fallback_url = f"{OPENSEARCH_ENDPOINT}/security-alerts-failed/_doc"
            fail_doc = {
                "@timestamp": datetime.utcnow().isoformat() + "Z",
                "error": str(e),
                "eventName": str(record.get("eventName")),
                "user": extract_user_arn(record.get("userIdentity", {})),
                "userType": str(record.get("userIdentity", {}).get("type", "")),
                "sourceIP": str(record.get("sourceIPAddress", "")),
                "accountId": str(record.get("recipientAccountId", ""))
            }
            fallback_resp = requests.post(fallback_url, auth=awsauth, headers=HEADERS, data=json.dumps(fail_doc))
            fallback_resp.raise_for_status()
            print(f"[Info] Fallback indexed to security-alerts-failed")
        except Exception as inner_e:
            print(f"[Error] Failed to index fallback: {inner_e}")


def lambda_handler(event, context):
    print("Received S3 PutObject event:", json.dumps(event, indent=2))

    detail = event.get("detail", {})
    bucket = detail.get("requestParameters", {}).get("bucketName")
    key = detail.get("requestParameters", {}).get("key")

    if not bucket or not key:
        print("Missing bucket/key in event")
        return {"statusCode": 400, "body": json.dumps({"error": "Invalid event"})}

    s3 = boto3.client("s3")
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

    for record in log_data.get("Records", []):
        if not record.get("eventName"):
            print("[Skip] Missing eventName, skipping record.")
            continue
        send_to_opensearch(record)

    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Indexed all records to OpenSearch"})
    }