import os
import json
import boto3
import requests
from requests_aws4auth import AWS4Auth
from datetime import datetime

# 세션과 인증 정보 설정
session = boto3.Session()
credentials = session.get_credentials()
region = os.environ['AWS_REGION']

awsauth = AWS4Auth(
    credentials.access_key,
    credentials.secret_key,
    region,
    'es',
    session_token=credentials.token
)

# 환경 변수로부터 엔드포인트/웹훅 가져오기
OPENSEARCH_ENDPOINT = os.environ['OPENSEARCH_ENDPOINT']
SLACK_URL = os.environ['SLACK_WEBHOOK_URL']

# Slack 알림 채널 생성
def create_slack_destination():
    try:
        get_slack_destination_id()
        print("Slack destination already exists.")
        return
    except Exception:
        pass

    url = f"{OPENSEARCH_ENDPOINT}/_plugins/_notifications/configs"
    headers = {"Content-Type": "application/json"}
    payload = {
        "config": {
            "name": "slack-destination",
            "description": "Slack alerts",
            "config_type": "slack",
            "is_enabled": True,
            "slack": {
                "url": SLACK_URL
            }
        }
    }
    resp = requests.post(url, auth=awsauth, headers=headers, json=payload)
    print("Slack destination response:", resp.text)
    resp.raise_for_status()

def create_index_template():
    url = f"{OPENSEARCH_ENDPOINT}/_index_template/security-alerts-template"
    headers = {"Content-Type": "application/json"}
    payload = {
        "index_patterns": ["security-alerts-*"],
        "template": {
            "settings": {
                "number_of_shards": 1,
                "number_of_replicas": 0
            },
            "mappings": {
                "properties": {
                    "@timestamp": {"type": "date"},
                    "eventName": {"type": "keyword"},
                    "user": {"type": "keyword"},
                    "userType": {"type": "keyword"},
                    "sourceIP": {"type": "ip"},
                    "accountId": {"type": "keyword"},
                    "error": {"type": "text"}
                }
            }
        },
        "priority": 1
    }
    resp = requests.put(url, auth=awsauth, headers=headers, json=payload)
    print("Index Template response:", resp.text)
    resp.raise_for_status()

# Kibana 인덱스 패턴 생성
def create_index_pattern():
    url = f"{OPENSEARCH_ENDPOINT}/.kibana/_doc/index-pattern:security-alerts"
    headers = {"Content-Type": "application/json"}
    payload = {
        "type": "index-pattern",
        "index-pattern": {
            "title": "security-alerts-*",
            "timeFieldName": "@timestamp"
        }
    }
    resp = requests.post(url, auth=awsauth, headers=headers, json=payload)
    print("Index pattern response:", resp.text)
    resp.raise_for_status()

# Monitor 생성
def create_monitor(event_name, destination_id):
    index = f"security-alerts-{event_name.lower()}"
    headers = {"Content-Type": "application/json"}

    # 인덱스 존재 여부 확인
    check_url = f"{OPENSEARCH_ENDPOINT}/{index}"
    check_resp = requests.head(check_url, auth=awsauth)
    if check_resp.status_code == 404:
        print(f"[Info] Index '{index}' not found. Creating dummy doc...")
        dummy_doc = {
            "@timestamp": datetime.utcnow().isoformat() + "Z",
            "eventName": event_name,
            "user": "initializer",
            "sourceIP": "127.0.0.1",
            "awsRegion": region,
            "accountId": "initializer"
        }
        create_resp = requests.post(
            f"{OPENSEARCH_ENDPOINT}/{index}/_doc",
            auth=awsauth,
            headers=headers,
            json=dummy_doc
        )
        print(f"[Info] Dummy doc created: {create_resp.status_code} {create_resp.text}")
        create_resp.raise_for_status()

    # 🔔 Monitor 생성
    url = f"{OPENSEARCH_ENDPOINT}/_plugins/_alerting/monitors"
    body = {
        "type": "monitor",
        "name": f"{event_name} Monitor",
        "enabled": True,
        "schedule": { "period": { "interval": 1, "unit": "MINUTES" } },
        "inputs": [{
            "search": {
                "indices": [index],
                "query": {
                    "size": 1,
                    "query": {
                        "bool": {
                            "filter": [{
                                "range": {
                                    "@timestamp": {
                                        "gte": "now-1m",
                                        "lte": "now"
                                    }
                                }
                            }]
                        }
                    }
                }
            }
        }],
        "triggers": [{
            "name": f"{event_name} Trigger",
            "severity": "1",
            "condition": {
                "script": {
                    "source": "ctx.results[0].hits.total.value > 0",
                    "lang": "painless"
                }
            },
            "actions": [{
                "name": f"{event_name} Slack Alert",
                "destination_id": destination_id,
                "message_template": {
                    "source": (
                        f"🚨 *{event_name}* 이벤트 감지됨:\n\n"
                        "*• 사용자:* {{ctx.results.0.hits.hits.0._source.user}}\n"
                        "*• 발생 시간:* {{ctx.results.0.hits.hits.0._source['@timestamp']}}\n"
                        "*• IP:* {{ctx.results.0.hits.hits.0._source.sourceIP}}\n"
                        "*• AWS 리전:* {{ctx.results.0.hits.hits.0._source.awsRegion}}\n"
                        "*• 계정 ID:* {{ctx.results.0.hits.hits.0._source.accountId}}"
                    )
                }
            }]
        }]
    }

    resp = requests.post(url, auth=awsauth, headers=headers, json=body)
    print(f"[Monitor] {event_name} result: {resp.status_code} {resp.text}")
    resp.raise_for_status()

# Slack 채널 ID 조회
def get_slack_destination_id():
    url = f"{OPENSEARCH_ENDPOINT}/_plugins/_notifications/configs"
    headers = {"Content-Type": "application/json"}
    resp = requests.get(url, auth=awsauth, headers=headers)
    resp.raise_for_status()

    configs = resp.json().get("config_list", [])
    for config in configs:
        if config.get("config", {}).get("name") == "slack-destination":
            return config.get("config_id")

    raise Exception("Slack Destination not found")

# Lambda 핸들러
def lambda_handler(event, context):
    try:
        create_slack_destination()
        create_index_pattern()

        create_index_template()

        destination_id = get_slack_destination_id()
        for event_name in json.loads(os.environ["EVENT_NAMES"]):
            create_monitor(event_name, destination_id)

        return {"status": "success"}
    except Exception as e:
        print("Error:", str(e))
        raise