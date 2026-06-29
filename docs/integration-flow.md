# Project ARIA — Integration Flow

## Team Integration Contract

**Last Updated:** June 25, 2026  
**Team:** The Indomitables (Ivy, Lilian, Assa)  
**Account:** 364046406796 (shared)

---

## Overview

Project ARIA uses an event-driven, decoupled architecture where team members' components communicate through DynamoDB and DynamoDB Streams — never directly calling each other's functions.

---

## Data Flow
Lilian's Layer (Registration) │ ▼ ┌─────────────────────────┐ │ DynamoDB │ │ aria-patient-records │ │ (triage_ready = true) │ └─────────────────────────┘ │ ▼ (DynamoDB Stream) ┌─────────────────────────┐ │ Ivy's Layer │ │ aria-orchestrator │ │ (Triage + Consultation) │ └─────────────────────────┘ │ ▼ ┌─────────────────────────┐ │ SNS → Doctor │ │ WebSocket → Consultation│ └─────────────────────────┘


---

## DynamoDB Schema: aria-patient-records

**Partition Key:** `patient_id` (String)

| Field | Type | Written By | Description |
|---|---|---|---|
| `patient_id` | String (PK) | Lilian | Format: PAT-XXXX-PatientName |
| `full_name` | String | Lilian | Extracted from ID via Textract |
| `id_number` | String | Lilian | National ID number |
| `face_id` | String | Lilian | Rekognition FaceId |
| `language` | String | Lilian | Auto-detected language code (sw, ar, fr, en) |
| `original_text` | String | Lilian | Patient's words in original language |
| `translated_text` | String | Lilian | English translation of symptoms |
| `audio_s3_key` | String | Lilian | S3 path to audio recording |
| `triage_ready` | Boolean | Lilian | Set to `true` when transcription complete |
| `triage_status` | String | Ivy | "pending" → "complete" |
| `department` | String | Ivy | Assigned department (e.g., "Neurology") |
| `urgency` | String | Ivy | "low" / "medium" / "high" / "critical" |
| `assigned_doctor` | String | Ivy | Doctor name (e.g., "Dr. Amara") |
| `medical_entities` | Map | Ivy | Comprehend Medical extraction results |
| `triage_reasoning` | String | Ivy | Bedrock's reasoning explanation |
| `timestamp` | String | Lilian | ISO timestamp of registration |

---

## Trigger Mechanism

### What Triggers Ivy's Orchestrator?

1. Lilian's Lambda writes patient record to DynamoDB with `triage_ready: true`
2. DynamoDB Stream captures the INSERT/MODIFY event
3. Stream invokes `aria-orchestrator` Lambda automatically
4. Orchestrator checks: `if triage_ready == true AND triage_status != "complete"`
5. Orchestrator processes triage and writes results back to same record

### Stream Configuration

- **Table:** aria-patient-records
- **Stream enabled:** Yes
- **View type:** NEW_AND_OLD_IMAGES
- **Trigger:** aria-orchestrator Lambda

---

## Integration Rules

1. **Lilian NEVER calls Ivy's Lambda directly** — only writes to DynamoDB
2. **Ivy NEVER calls Lilian's Lambda directly** — only reads from DynamoDB Stream
3. **Both write to the SAME DynamoDB record** — different fields
4. **Ivy writes triage results back** — Lilian's HTML polls for these fields
5. **SNS notification is Ivy's responsibility** — triggered after triage completes

---

## Polling Contract (Lilian's HTML → DynamoDB)

After registration, Lilian's frontend polls the patient record every 3 seconds:

```javascript
// Polls for triage completion
GET /demo/identify?action=get_triage_status&patient_id=PAT-XXXX

// Returns when Ivy's orchestrator has written results:
{
  "triage_status": "complete",
  "department": "Neurology",
  "urgency": "high",
  "assigned_doctor": "Dr. Amara"
}
WebSocket Consultation Contract
After triage completes, the patient enters consultation via WebSocket:

Connection Parameters
wss://8ko3wl8l0c.execute-api.us-east-1.amazonaws.com/prod
  ?role=patient|doctor
  &patient_id=PAT-XXXX-Name
  &session_id=session-XXX
Message Format (Patient → Doctor)
json





{
  "action": "sendMessage",
  "text": "Nina maumivu ya kifua",
  "language": "sw"
}
Message Format (Received by Doctor)
json





{
  "from": "patient",
  "original": "Nina maumivu ya kifua",
  "translated": "I have chest pain",
  "language": "sw"
}
Environment Variables Required
aria-orchestrator (Ivy)
Table



Variable


Value


PATIENT_TABLE	aria-patient-records
SNS_TOPIC_ARN	arn:aws:sns:us-east-1:364046406796:project-aria-doctor-notifications.fifo
View more
aria-patient-identification (Lilian)
Table



Variable


Value


PATIENT_TABLE	aria-patient-records
S3_BUCKET	aria-registrations
FACE_COLLECTION	aria-patient-faces
View more
aria-ws-message (Ivy)
Table



Variable


Value


CONNECTIONS_TABLE	aria-ws-connections
WS_ENDPOINT	https://8ko3wl8l0c.execute-api.us-east-1.amazonaws.com/prod
View more
S3 Bucket Structure
aria-registrations (Lilian writes)
aria-registrations/
├── {patient_id}/
│   ├── face.jpg
│   ├── id_document.jpg
│   └── audio.webm
aria-clinical-notes (Ivy writes)
aria-clinical-notes/
├── {patient_id}/
│   └── {session_id}/
│       ├── triage_summary.json
│       └── consultation_transcript.json
Error Handling
Table



Scenario


Behavior


Orchestrator fails on stream event	DynamoDB Stream retries automatically (up to 3 times)
triage_ready set but not processed	triage_status remains "pending", frontend keeps polling
WebSocket connection drops	Client reconnects, connectionId updated in DynamoDB
SNS publish fails	Logged to CloudWatch, triage still completes for patient
View more
Deployment Order
DynamoDB table (shared resource — created once)
S3 buckets (shared resource — created once)
Lilian deploys: aria-patient-identification + API Gateway + CloudFront
Ivy deploys: aria-orchestrator + aria-sns-notify + WebSocket API + Lambda functions
Enable DynamoDB Stream → aria-orchestrator trigger
End-to-end test
