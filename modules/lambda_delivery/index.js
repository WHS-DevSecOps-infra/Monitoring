const AWS = require("aws-sdk");
const { Client } = require("@opensearch-project/opensearch");
const createAwsOpensearchConnector = require("aws-opensearch-connector");
const zlib = require("zlib");

AWS.config.update({ region: process.env.AWS_REGION });
const s3 = new AWS.S3();

const rawEndpoint = process.env.OPENSEARCH_ENDPOINT;
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

exports.handler = async (event) => {
  const bucket = event.detail?.requestParameters?.bucketName;
  const key = event.detail?.requestParameters?.key;

  if (!bucket || !key) {
    console.error(
      "❌ Missing bucket or key in event:",
      JSON.stringify(event, null, 2)
    );
    return;
  }

  console.log("📥 Received S3 event:", { bucket, key });

  try {
    const obj = await s3.getObject({ Bucket: bucket, Key: key }).promise();
    console.log("📦 Retrieved object from S3 (size):", obj.ContentLength);

    const unzipped = zlib.gunzipSync(obj.Body).toString("utf-8");
    console.log("📂 Unzipped log preview:", unzipped.slice(0, 300));

    let payload;
    try {
      payload = JSON.parse(unzipped);
    } catch (err) {
      console.error("❌ JSON parse error:", err.message);
      return;
    }

    if (!Array.isArray(payload.Records)) {
      console.warn("⚠️ 'Records' is not an array or missing.");
      return;
    }

    const body = [];
    const getIndexName = (log) => {
      const date = new Date().toISOString().slice(0, 10);
      const source = log.eventSource;
      if (source === "wafv2.amazonaws.com") return `waf-logs-${date}`;
      return `cloudtrail-logs-${date}`;
    };

    payload.Records.forEach((log) => {
      body.push({ index: { _index: getIndexName(log) } });

      const logWithTimestamp = {
        ...log,
        "@timestamp": log.eventTime,
      };

      body.push(logWithTimestamp);
    });

    if (body.length > 0) {
      const result = await client.bulk({ refresh: true, body });
      if (result?.body?.errors) {
        console.error("❌ OpenSearch indexing errors:", result.body.items);
      } else {
        console.log(`✅ ${body.length / 2} logs indexed to OpenSearch`);
      }
    } else {
      console.log("⚠️ No valid logs to index. Skipping.");
    }
  } catch (err) {
    console.error("❌ Failed to process logs:", err.message || err);
  }
};
