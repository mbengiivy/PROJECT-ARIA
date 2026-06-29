```python
```bash
#!/bin/bash
# ============================================
# Project ARIA — Registration API Test Script
# ============================================
# Tests the registration endpoint via API Gateway
# Covers: Face identification, new patient registration,
#         voice intake, and triage status polling
#
# Usage: bash tests/test_registration.sh
# ============================================

REGION="us-east-1"
API_URL="https://YOUR_API_ID.execute-api.${REGION}.amazonaws.com/demo"
TABLE="aria-patient-records"
S3_BUCKET="aria-registrations"
FACE_COLLECTION="aria-patient-faces"

echo "============================================"
echo "Project ARIA — Registration API Tests"
echo "============================================"
echo ""
echo "API URL: ${API_URL}"
echo "Table: ${TABLE}"
echo "S3 Bucket: ${S3_BUCKET}"
echo "Face Collection: ${FACE_COLLECTION}"
echo ""

# ============================================
# TEST 1: Health Check — API Gateway Reachable
# ============================================
echo "--- TEST 1: API Gateway Health Check ---"
echo ""

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" ${API_URL}/identify)
echo "Status Code: ${RESPONSE}"

if [ "$RESPONSE" == "200" ] || [ "$RESPONSE" == "400" ]; then
  echo "✅ API Gateway is reachable"
else
  echo "❌ API Gateway not reachable (got ${RESPONSE})"
  echo "   Check: Is the API deployed? Is the URL correct?"
fi
echo ""

# ============================================
# TEST 2: Identify Existing Patient (Face)
# ============================================
echo "--- TEST 2: Identify Patient (Face Recognition) ---"
echo ""
echo "Command:"
echo "curl -X POST ${API_URL}/identify \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{"
echo '    "action": "identify_patient",'
echo '    "image": "<base64_encoded_face_image>"'
echo "  }'"
echo ""
echo "Expected (known patient):"
echo '  { "status": "identified", "patient_id": "PAT-XXXX-Name", "full_name": "Amina Hassan" }'
echo ""
echo "Expected (unknown face):"
echo '  { "status": "not_found", "message": "No matching patient found" }'
echo ""

# ============================================
# TEST 3: Register New Patient
# ============================================
echo "--- TEST 3: Register New Patient ---"
echo ""
echo "Command:"
echo "curl -X POST ${API_URL}/identify \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{"
echo '    "action": "register_patient",'
echo '    "id_image": "<base64_encoded_id_document>",'
echo '    "face_image": "<base64_encoded_face_photo>"'
echo "  }'"
echo ""
echo "Expected:"
echo '  {'
echo '    "status": "registered",'
echo '    "patient_id": "PAT-XXXX-PatientName",'
echo '    "full_name": "Extracted Name",'
echo '    "id_number": "12345678"'
echo '  }'
echo ""
echo "What happens behind the scenes:"
echo "  1. Textract extracts name, ID number from document"
echo "  2. Rekognition indexes face in aria-patient-faces collection"
echo "  3. Face photo + ID document stored in S3"
echo "  4. Patient record created in DynamoDB"
echo ""

# ============================================
# TEST 4: Voice Intake (Record Audio)
# ============================================
echo "--- TEST 4: Voice Intake ---"
echo ""
echo "Command:"
echo "curl -X POST ${API_URL}/identify \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{"
echo '    "action": "record_audio",'
echo '    "patient_id": "PAT-0001-Amina",'
echo '    "audio": "<base64_encoded_audio>"'
echo "  }'"
echo ""
echo "Expected:"
echo '  {'
echo '    "status": "transcribed",'
echo '    "original_text": "Nina maumivu ya kifua",'
echo '    "language_detected": "sw",'
echo '    "translated_text": "I have chest pain",'
echo '    "triage_ready": true'
echo '  }'
echo ""
echo "What happens behind the scenes:"
echo "  1. Audio uploaded to S3 (aria-registrations/{patient_id}/audio.webm)"
echo "  2. Transcribe converts speech to text + auto-detects language"
echo "  3. Translate converts to English"
echo "  4. DynamoDB updated with transcript + triage_ready = true"
echo "  5. DynamoDB Stream triggers aria-orchestrator (Ivy's triage)"
echo ""

# ============================================
# TEST 5: Get Triage Status (Polling)
# ============================================
echo "--- TEST 5: Get Triage Status (Polling) ---"
echo ""
echo "Command:"
echo "curl -X POST ${API_URL}/identify \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{"
echo '    "action": "get_triage_status",'
echo '    "patient_id": "PAT-0001-Amina"'
echo "  }'"
echo ""
echo "Expected (before triage):"
echo '  { "triage_status": "pending" }'
echo ""
echo "Expected (after triage — ~5-10 seconds):"
echo '  {'
echo '    "triage_status": "complete",'
echo '    "department": "Cardiology",'
echo '    "urgency": "high",'
echo '    "assigned_doctor": "Dr. Amara"'
echo '  }'
echo ""

# ============================================
# TEST 6: Verify DynamoDB Record
# ============================================
echo "--- TEST 6: Verify DynamoDB Record ---"
echo ""
echo "Command:"
echo "aws dynamodb get-item \\"
echo "  --table-name ${TABLE} \\"
echo "  --key '{\"patient_id\": {\"S\": \"PAT-0001-Amina\"}}' \\"
echo "  --region ${REGION}"
echo ""
echo "Expected fields:"
echo "  patient_id, full_name, id_number, face_id,"
echo "  language, original_text, translated_text,"
echo "  triage_ready, triage_status, department,"
echo "  urgency, assigned_doctor, timestamp"
echo ""

# ============================================
# TEST 7: Verify S3 Uploads
# ============================================
echo "--- TEST 7: Check S3 Uploads ---"
echo ""
echo "Command:"
echo "aws s3 ls s3://${S3_BUCKET}/PAT-0001-Amina/ --region ${REGION}"
echo ""
echo "Expected files:"
echo "  face.jpg          — Patient face photo"
echo "  id_document.jpg   — ID document scan"
echo "  audio.webm        — Voice recording"
echo ""

# ============================================
# TEST 8: Verify Rekognition Collection
# ============================================
echo "--- TEST 8: Verify Face in Rekognition Collection ---"
echo ""
echo "Command:"
echo "aws rekognition list-faces \\"
echo "  --collection-id ${FACE_COLLECTION} \\"
echo "  --region ${REGION}"
echo ""
echo "Expected: FaceId matching the patient's indexed face"
echo ""

# ============================================
# TEST 9: Check CloudWatch Logs
# ============================================
echo "--- TEST 9: Check Registration Lambda Logs ---"
echo ""
echo "Command:"
echo "aws logs tail /aws/lambda/aria-patient-identification --since 5m --region ${REGION}"
echo ""

# ============================================
# TEST 10: Full End-to-End Flow
# ============================================
echo "============================================"
echo "FULL END-TO-END TEST (Manual)"
echo "============================================"
echo ""
echo "1. Open browser: https://YOUR_CLOUDFRONT_URL"
echo "2. Select language (e.g., Kiswahili)"
echo "3. Click 'Identify' tab → Open Camera → Take Photo"
echo "   - If known: Shows patient name, proceeds to voice"
echo "   - If unknown: Switch to 'Register' tab"
echo "4. (If registering) Scan ID → Take Face Photo → Review → Register"
echo "5. Record voice: Speak symptoms in any language"
echo "6. Wait for triage result (~5-10 seconds)"
echo "7. Verify: Department, urgency, doctor displayed"
echo "8. Proceed to consultation (WebSocket)"
echo ""
echo "============================================"
echo "END OF REGISTRATION TESTS"
echo "============================================"
