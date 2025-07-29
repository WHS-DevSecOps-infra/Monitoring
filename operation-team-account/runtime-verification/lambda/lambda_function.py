import json
import os
import urllib.request

SLACK_WEBHOOK_URL = os.environ.get('SLACK_WEBHOOK_URL', '')

def lambda_handler(event, context):
    print(json.dumps(event)) # 디버깅을 위해 전체 이벤트를 로그로 남깁니다.

    # Inspector 이벤트에서 필요한 정보 추출
    finding = event.get('detail', {})
    title = finding.get('title', 'N/A')
    severity = finding.get('severity', 'N/A')
    
    resources = finding.get('resources', [{}])
    resource_id = resources[0].get('id', 'N/A')
    
    region = event.get('region', 'N/A')
    finding_arn = finding.get('findingArn', '')
    console_url = f"https://{region}.console.aws.amazon.com/inspector/v2/findings/details?finding-arn={finding_arn}" if finding_arn else "#"

    # 슬랙 메시지 구성
    slack_message = {
        "text": f"*New High-Severity Inspector Finding*",
        "blocks": [
            { "type": "header", "text": { "type": "plain_text", "text": f"{severity}: {title}" } },
            { "type": "section", "text": { "type": "mrkdwn", "text": f"*Affected Resource:*\n```{resource_id}```" } },
            { "type": "actions", "elements": [{ "type": "button", "text": { "type": "plain_text", "text": "View Finding Details" }, "url": console_url, "style": "primary" }] }
        ]
    }
    
    if not SLACK_WEBHOOK_URL:
        print("Slack Webhook URL is not set.")
        return {'statusCode': 500}

    req = urllib.request.Request(SLACK_WEBHOOK_URL, data=json.dumps(slack_message).encode('utf-8'), headers={'Content-Type': 'application/json'})
    
    try:
        with urllib.request.urlopen(req) as response:
            print(f"Message posted to Slack, status: {response.status}")
    except urllib.error.HTTPError as e:
        print(f"Error posting to Slack: {e.code} {e.reason}")
    
    return {'statusCode': 200}