#!/bin/bash
# ============================================
# Project ARIA — WebSocket API Test Script
# ============================================
# Prerequisites: npm (for npx wscat)
# Usage: bash tests/test_websocket.sh
# ============================================

# Configuration
API_ID="8ko3wl8l0c"
REGION="us-east-1"
STAGE="prod"
WS_URL="wss://${API_ID}.execute-api.${REGION}.amazonaws.com/${STAGE}"

PATIENT_ID="PAT-0001-TestAmina"
SESSION_ID="session-test-001"

echo "============================================"
echo "Project ARIA — WebSocket API Tests"
echo "============================================"
echo ""
echo "WebSocket URL: ${WS_URL}"
echo "Patient ID: ${PATIENT_ID}"
echo "Session ID: ${SESSION_ID}"
echo ""

# ============================================
# TEST 1: Patient Connection
# ============================================
echo "--- TEST 1: Patient Connection ---"
echo "Run in Terminal 1:"
echo ""
echo "npx wscat -c \"${WS_URL}?role=patient&patient_id=${PATIENT_ID}&session_id=${SESSION_ID}\""
echo ""
echo "Expected: Connected (use Ctrl+C to disconnect)"
echo ""

# ============================================
# TEST 2: Doctor Connection
# ============================================
echo "--- TEST 2: Doctor Connection ---"
echo "Run in Terminal 2:"
echo ""
echo "npx wscat -c \"${WS_URL}?role=doctor&patient_id=${PATIENT_ID}&session_id=${SESSION_ID}\""
echo ""
echo "Expected: Connected (use Ctrl+C to disconnect)"
echo ""

# ============================================
# TEST 3: Patient Sends Message (Kiswahili)
# ============================================
echo "--- TEST 3: Patient → Doctor (Kiswahili → English) ---"
echo "In Patient terminal, type:"
echo ""
echo '{"action": "sendMessage", "text": "Nina maumivu ya kifua kwa siku tatu", "language": "sw"}'
echo ""
echo "Expected in Doctor terminal:"
echo '{"from": "patient", "original": "Nina maumivu ya kifua kwa siku tatu", "translated": "I have chest pain for three days", "language": "sw"}'
echo ""

# ============================================
# TEST 4: Doctor Sends Message (English)
# ============================================
echo "--- TEST 4: Doctor → Patient (English → Kiswahili) ---"
echo "In Doctor terminal, type:"
echo ""
echo '{"action": "sendMessage", "text": "When did the pain start? Is it constant or intermittent?", "language": "en"}'
echo ""
echo "Expected in Patient terminal:"
echo '{"from": "doctor", "original": "When did the pain start? Is it constant or intermittent?", "translated": "Maumivu yalianza lini? Je, ni ya kudumu au ya vipindi?", "language": "en"}'
echo ""

# ============================================
# TEST 5: Patient Sends Message (Arabic)
# ============================================
echo "--- TEST 5: Patient → Doctor (Arabic → English) ---"
echo "In Patient terminal, type:"
echo ""
echo '{"action": "sendMessage", "text": "عندي صداع شديد منذ أسبوع", "language": "ar"}'
echo ""
echo "Expected in Doctor terminal:"
echo '{"from": "patient", "original": "عندي صداع شديد منذ أسبوع", "translated": "I have had a severe headache for a week", "language": "ar"}'
echo ""

# ============================================
# TEST 6: Patient Sends Message (French)
# ============================================
echo "--- TEST 6: Patient → Doctor (French → English) ---"
echo "In Patient terminal, type:"
echo ""
echo '{"action": "sendMessage", "text": "J'\''ai des douleurs abdominales depuis hier soir", "language": "fr"}'
echo ""
echo "Expected in Doctor terminal:"
echo '{"from": "patient", "original": "J'\''ai des douleurs abdominales depuis hier soir", "translated": "I have had abdominal pain since last night", "language": "fr"}'
echo ""

# ============================================
# TEST 7: Disconnect
# ============================================
echo "--- TEST 7: Disconnect ---"
echo "Press Ctrl+C in both terminals"
echo "Check DynamoDB aria-ws-connections table — should be empty after disconnect"
echo ""

# ============================================
# VERIFICATION COMMANDS
# ============================================
echo "============================================"
echo "VERIFICATION COMMANDS"
echo "============================================"
echo ""
echo "# Check connections table:"
echo "aws dynamodb scan --table-name aria-ws-connections --region ${REGION}"
echo ""
echo "# Check CloudWatch logs (connect):"
echo "aws logs tail /aws/lambda/aria-ws-connect --since 5m --region ${REGION}"
echo ""
echo "# Check CloudWatch logs (message):"
echo "aws logs tail /aws/lambda/aria-ws-message --since 5m --region ${REGION}"
echo ""
echo "# Check CloudWatch logs (disconnect):"
echo "aws logs tail /aws/lambda/aria-ws-disconnect --since 5m --region ${REGION}"
echo ""
echo "============================================"
echo "END OF TESTS"
echo "============================================"
