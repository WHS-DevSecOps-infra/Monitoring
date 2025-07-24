const AWS = require("aws-sdk");
const { Client } = require("@opensearch-project/opensearch");
const createAwsOpensearchConnector = require("aws-opensearch-connector");

AWS.config.update({ region: process.env.AWS_REGION });

const rawEndpoint = process.env.OPENSEARCH_ENDPOINT;

if (!rawEndpoint) {
  throw new Error("Missing OPENSEARCH_ENDPOINT environment variable");
}

const endpoint = rawEndpoint.startsWith("https://")
  ? rawEndpoint
  : `https://${rawEndpoint}`;

const client = new Client({
  ...createAwsOpensearchConnector(AWS.config),
  node: endpoint,
  ssl: {
    rejectUnauthorized: false,
  },
});

exports.handler = async () => {
  try {
    const existingDestinations = await client.transport.request({
      method: "GET",
      path: "/_plugins/_notifications/configs",
    });

    const existingSlack = existingDestinations.body.config_list.find(
      (config) => config.config.name === "slack-destination"
    );

    let destinationId;
    if (existingSlack) {
      destinationId = existingSlack.config_id;
    } else {
      const destination = await client.transport.request({
        method: "POST",
        path: "/_plugins/_notifications/configs",
        body: {
          config: {
            name: "slack-destination",
            description: "Slack alerts",
            config_type: "slack",
            is_enabled: true,
            slack: {
              url: process.env.SLACK_WEBHOOK_URL,
            },
          },
        },
      });
      destinationId = destination.body.config_id;
    }

    const monitorBody = {
      type: "monitor",
      name: "security_event_monitor",
      enabled: true,
      schedule: {
        period: {
          interval: 1,
          unit: "MINUTES",
        },
      },
      inputs: [
        {
          search: {
            indices: ["cloudtrail-logs-*"],
            query: {
              size: 1,
              collapse: {
                field: "eventID.keyword",
              },
              query: {
                bool: {
                  must: [
                    {
                      terms: {
                        "eventName.keyword": [
                          "DeleteUser",
                          "DeleteRole",
                          "DeleteLoginProfile",
                          "StopLogging",
                          "DeleteTrail",
                          "DeactivateMFADevice",
                          "DeleteVirtualMFADevice",
                          "AuthorizeSecurityGroupIngress",
                          "RevokeSecurityGroupIngress",
                          "AuthorizeSecurityGroupEgress",
                          "RevokeSecurityGroupEgress",
                          "AttachUserPolicy",
                          "DetachUserPolicy",
                          "PutUserPolicy",
                          "DeleteUserPolicy",
                          "CreatePolicy",
                          "DeletePolicy",
                          "RunInstances",
                        ],
                      },
                    },
                    {
                      range: {
                        eventTime: {
                          gte: "now-5m",
                          lt: "now",
                        },
                      },
                    },
                  ],
                },
              },
            },
          },
        },
      ],
      triggers: [
        {
          name: "security_event_trigger",
          severity: "1",
          condition: {
            script: {
              source: "ctx.results[0].hits.total.value > 0",
              lang: "painless",
            },
          },
          actions: [
            {
              name: "slack_action",
              destination_id: destinationId,
              message_template: {
                source: `{{#ctx.results.0.hits.hits}}
:rotating_light: *AWS Security Alert*

*Event:*   {{_source.eventName}}
*User ARN:*   {{_source.userIdentity.arn}}
*Source IP:*   {{_source.sourceIPAddress}}
*Region:*   {{_source.awsRegion}}
*Account:*   {{_source.userIdentity.accountId}}
*Time (UTC):*   {{_source.eventTime}}
{{/ctx.results.0.hits.hits}}`,
              },
            },
          ],
        },
      ],
    };

    await client.transport.request({
      method: "POST",
      path: "/_plugins/_alerting/monitors",
      body: monitorBody,
    });

    const indexPatterns = [
      {
        id: "index-pattern:cloudtrail-logs",
        title: "cloudtrail-logs-*",
      },
      {
        id: "index-pattern:waf-logs",
        title: "waf-logs-*",
      },
    ];

    for (const pattern of indexPatterns) {
      await client.transport.request({
        method: "POST",
        path: `/.kibana/_doc/${pattern.id}`,
        body: {
          type: "index-pattern",
          "index-pattern": {
            title: pattern.title,
            timeFieldName: "@timestamp",
          },
        },
      });
    }

    console.log("✅ Alerting rules and index patterns successfully created.");
  } catch (error) {
    console.error("❌ Failed to create alerting rules or index patterns:");
    console.error("Message:", error.message);
    console.error("Meta:", JSON.stringify(error.meta?.body || {}, null, 2));
    throw error;
  }
};
