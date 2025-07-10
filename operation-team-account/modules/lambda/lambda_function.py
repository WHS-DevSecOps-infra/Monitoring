import os
import json
import urllib.request
import urllib.error
import datetime


def send_slack_alert_block(event: dict):
    webhook_url = os.environ['SLACK_WEBHOOK_URL']
    detail = event.get("detail", {})
    user = detail.get("userIdentity", {}).get("arn", "Unknown user")
    event_name = detail.get("eventName", "Unknown event")
    source_ip = detail.get("sourceIPAddress", "Unknown IP")
    time = event.get("time", "Unknown time")
    region = event.get("region", "Unknown region")
    account = detail.get("recipientAccountId", "Unknown account")

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
    print("Received event:", json.dumps(event, indent=2))

    try:
        send_slack_alert_block(event)
        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Slack alert sent successfully."})
        }
    except Exception as e:
        print(f"Error processing event: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
