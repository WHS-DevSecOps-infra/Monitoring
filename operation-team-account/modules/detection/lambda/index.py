import json
import os
import requests
from datetime import datetime
from opensearchpy import OpenSearch, RequestsHttpConnection
from requests_aws4auth import AWS4Auth
import boto3

region = os.environ['AWS_REGION']
host = os.environ['OPENSEARCH_ENDPOINT']
slack_webhook_url = os.environ['SLACK_WEBHOOK_URL']

credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(
    credentials.access_key,
    credentials.secret_key,
    region,
    'es',
    session_token=credentials.token
)

client = OpenSearch(
    hosts=[{'host': host, 'port': 443}],
    http_auth=awsauth,
    use_ssl=True,
    verify_certs=True,
    connection_class=RequestsHttpConnection
)

def lambda_handler(event, context):
    print("Received event:", json.dumps(event, indent=2))

    detail = event.get("detail", {})
    detail_type = event.get("detail-type", "Unknown Event")
    event_name = detail.get("eventName", "N/A")
    user_identity = detail.get("userIdentity", {}).get("arn", "Unknown User")
    source_ip = detail.get("sourceIPAddress", "Unknown IP")
    time = event.get("time", datetime.utcnow().isoformat())

    # Slack message formatting
    slack_message = {
        "text": (
            f"🚨 *Security Alert Detected* 🚨\n"
            f"*Type:* {detail_type}\n"
            f"*Event:* `{event_name}`\n"
            f"*User:* `{user_identity}`\n"
            f"*IP:* `{source_ip}`\n"
            f"*Time:* `{time}`"
        )
    }

    try:
        requests.post(
            slack_webhook_url,
            data=json.dumps(slack_message),
            headers={'Content-Type': 'application/json'}
        )
        if response.status_code != 200:
            raise Exception(f"Slack returned status code {response.status_code}, body: {response.text}")
    except Exception as e:
        print(f"Error posting to Slack: {e}")

    # Index to OpenSearch
    try:
        index_name = "security-events-" + datetime.utcnow().strftime("%Y-%m-%d")
        response = client.index(
            index=index_name,
            body=event  # Store full event for auditing
        )
        print(f"Indexed to OpenSearch: {response}")
    except Exception as e:
        print(f"Error indexing to OpenSearch: {e}")

    return {
        'statusCode': 200,
        'body': 'Processed event successfully'
    }