```python
```bash
#!/bin/bash
# ============================================
# Project ARIA — Triage Pipeline Test Script
# ============================================
# Tests the full triage flow:
# DynamoDB write → Stream → Orchestrator → Comprehend → Bedrock → SNS
#
# Usage: bash tests/test_triage.sh
# ============================================

REGION="us-east-1"
TABLE="aria-patient-records"
PATIENT_ID="PAT-TEST-$(date +%s)"

echo "============================================"
echo "Project ARIA — Triage Pipeline Test"
echo "============================================"
echo ""
echo "Patient ID: ${PATIENT_ID}"
echo "Table: ${TABLE}"
echo "Region: ${REGION}"
echo ""

# ============================================
# TEST 1: Write patient record (triggers stream)
# ============================================
echo "--- TEST 1: Writing patient record to DynamoDB ---"
echo "(This should trigger DynamoDB Stream → aria-orchestrator)"
echo ""

aws dynamodb put-item \
  --table-name ${TABLE} \
  --region ${REGION} \
  --item '{
    "patient_id": {"S": "'${PATIENT_ID}'"},
    "full_name": {"S": "Amina Hassan"},
    "language": {"S": "sw"},
    "original_text": {"S": "Nina maumivu ya kifua kwa siku tatu na homa"},
    "translated_text": {"S": "I have chest pain for three days and fever"},
    "triage_ready": {"BOOL": true},
    "triage_status": {"S": "pending"},
    "timestamp": {"S": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}
  }'

if [ $? -eq 0 ]; then
  echo "✅ Patient record written successfully"
else
  echo "❌ Failed to write patient record"
  exit 1
fi
echo ""

# ============================================
# TEST 2: Wait for orchestrator to process
# ============================================
echo "--- TEST 2: Waiting for triage processing ---"
echo "DynamoDB Stream → aria-orchestrator → Comprehend → Bedrock → SNS"
echo ""

for i in {1..6}; do
  echo "  Waiting... (${i}/6 — checking every 5 seconds)"
  sleep 5

  # Check if triage is complete
  STATUS=$(aws dynamodb get-item \
    --table-name ${TABLE} \
    --region ${REGION} \
    --key '{"patient_id": {"S": "'${PATIENT_ID}'"}}' \
    --projection-expression "triage_status" \
    --output text 2>/dev/null | grep -o "complete")

  if [ "$STATUS" == "complete" ]; then
    echo ""
    echo "✅ Triage completed!"
    break
  fi

  if [ $i -eq 6 ]; then
    echo ""
    echo "⚠️  Triage not completed after 30 seconds. Check orchestrator logs."
  fi
done
echo ""

# ============================================
# TEST 3: Check triage results
# ============================================
echo "--- TEST 3: Checking triage results ---"
echo ""

RESULT=$(aws dynamodb get-item \
  --table-name ${TABLE} \
  --region ${REGION} \
  --key '{"patient_id": {"S": "'${PATIENT_ID}'"}}' \
  --projection-expression "triage_status, department, urgency, assigned_doctor, triage_reasoning")

echo "$RESULT" | python3 -m json.tool 2>/dev/null || echo "$RESULT"

echo ""
echo "Expected:"
echo "  triage_status  = 'complete'"
echo "  department     = (e.g., 'Cardiology' or 'Internal Medicine')"
echo "  urgency        = (e.g., 'high')"
echo "  assigned_doctor = (e.g., 'Dr. Amara')"
echo ""

# ============================================
# TEST 4: Check orchestrator CloudWatch logs
# ============================================
echo "--- TEST 4: Checking aria-orchestrator logs ---"
echo ""

aws logs tail /aws/lambda/aria-orchestrator --since 2m --region ${REGION} 2>/dev/null | head -30

if [ $? -ne 0 ]; then
  echo "⚠️  No logs found. Check if stream trigger is configured."
fi
echo ""

# ============================================
# TEST 5: Check SNS notification was sent
# ============================================
echo "--- TEST 5: Checking aria-sns-notify logs ---"
echo ""

aws logs tail /aws/lambda/aria-sns-notify --since 2m --region ${REGION} 2>/dev/null | head -15

if [ $? -ne 0 ]; then
  echo "⚠️  No SNS notify logs found."
fi
echo ""

# ============================================
# TEST 6: Verify X-Ray trace
# ============================================
echo "--- TEST 6: X-Ray Trace Verification ---"
echo ""
echo "Run this to see the full trace:"
echo "aws xray get-trace-summaries --start-time \$(date -d '2 minutes ago' +%s) --end-time \$(date +%s) --region ${REGION}"
echo ""
echo "Or check the X-Ray console: Service Map → aria-orchestrator"
echo ""

# ============================================
# TEST 7: Test with different languages
# ============================================
echo "--- TEST 7: Additional Test Cases ---"
echo ""
echo "Arabic patient:"
echo "aws dynamodb put-item --table-name ${TABLE} --region ${REGION} --item '{"
echo '  "patient_id": {"S": "PAT-TEST-AR-001"},'
echo '  "full_name": {"S": "Fatima Al-Rashid"},'
echo '  "language": {"S": "ar"},'
echo '  "original_text": {"S": "عندي صداع شديد منذ أسبوع وغثيان"},'
echo '  "translated_text": {"S": "I have had a severe headache for a week and nausea"},'
echo '  "triage_ready": {"BOOL": true},'
echo '  "triage_status": {"S": "pending"},'
echo '  "timestamp": {"S": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}'
echo "}'"
echo ""
echo "French patient:"
echo "aws dynamodb put-item --table-name ${TABLE} --region ${REGION} --item '{"
echo '  "patient_id": {"S": "PAT-TEST-FR-001"},'
echo '  "full_name": {"S": "Marie Dupont"},'
echo '  "language": {"S": "fr"},'
echo '  "original_text": {"S": "J'\''ai des douleurs abdominales depuis hier soir et de la fièvre"},'
echo '  "translated_text": {"S": "I have had abdominal pain since last night and fever"},'
echo '  "triage_ready": {"BOOL": true},'
echo '  "triage_status": {"S": "pending"},'
echo '  "timestamp": {"S": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}'
echo "}'"
echo ""

# ============================================
# CLEANUP
# ============================================
echo "============================================"
echo "CLEANUP"
echo "============================================"
echo ""
echo "To delete test records:"
echo "aws dynamodb delete-item --table-name ${TABLE} --key '{\"patient_id\": {\"S\": \"${PATIENT_ID}\"}}' --region ${REGION}"
echo "aws dynamodb delete-item --table-name ${TABLE} --key '{\"patient_id\": {\"S\": \"PAT-TEST-AR-001\"}}' --region ${REGION}"
echo "aws dynamodb delete-item --table-name ${TABLE} --key '{\"patient_id\": {\"S\": \"PAT-TEST-FR-001\"}}' --region ${REGION}"
echo ""
echo "============================================"
echo "END OF TRIAGE PIPELINE TEST"
echo "============================================"
