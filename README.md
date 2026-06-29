# PROJECT-ARIA


> A multilingual, AI-powered patient triage and consultation system built for Mothobi
Healthcare Group — serving 200,000+ patients across 45 clinics in Africa.
![AWS](https://img.shields.io/badge/AWS-Cloud-orange?logo=amazonaws)
![Python](https://img.shields.io/badge/Python-3.14-blue?logo=python)
![Serverless](https://img.shields.io/badge/Architecture-Serverless-green)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen)
---
## Table of Contents📋
- [Overview](#-overview)
- [Problem Statement](#-problem-statement)
- [Architecture](#-architecture)
- [Patient Journey](#-patient-journey)
- [AWS Services Used](#-aws-services-used)
- [Project Structure](#-project-structure)
- [Setup & Deployment](#-setup--deployment)
- [Key Design Decisions](#-key-design-decisions)
- [Demo](#-demo)
- [Team](#-team)
- [Lessons Learned](#-lessons-learned)
- [Future Roadmap](#-future-roadmap)
---
## Overview🎯
**Project ARIA** (Accessible Real-time Intelligent Assistant) is a fully serverless,
event-driven healthcare system that enables patients to complete their entire clinic
journey — from check-in through discharge — in their preferred language, without reading
or speaking English.
Built in **5 days** during an AWS Cloud Engineering Build Week sprint.
### Key Capabilities
| Capability | What It Does | AWS Service |
|---|---|---|
| **SEES** | Identifies patients by face, reads ID documents | Rekognition, Textract |
| **LISTENS** | Transcribes voice in 30+ languages | Transcribe, Translate |
| **THINKS** | Triages symptoms, assigns urgency & doctor | Comprehend Medical, Bedrock |
| **GUIDES** | Real-time translated consultation + spoken navigation | WebSocket API,
Polly |
---
## Problem Statement🚨
Mothobi Healthcare Group operates **45 clinics across Africa** serving **200,000+
patients annually**:
- **70%** are non-native English speakers
- **30%** have low literacy
- Current intake is manual, slow, and language-dependent
- Patients who can't communicate effectively receive delayed or incorrect care
**ARIA eliminates the language barrier entirely.**
---
## Architecture🏗️
![Project ARIA Architecture](docs/architecture/project_aria_architecture.png)
### High-Level Flow
```
Patient → CloudFront → API Gateway → Lambda → AI Services → DynamoDB
↓
DynamoDB Stream
(triage_ready = true)
↓
Orchestrator → Bedrock + Comprehend Medical
↓
SNS → Doctor Notification
↓
WebSocket API ↔ Real-time Translated Consultation
↓
Bedrock → Polly → Patient Discharge
```
### Architecture Principles
- **Event-driven** — DynamoDB Streams trigger triage automatically, no polling
- **Serverless** — Zero idle cost, infinite scale, no servers to patch
- **Decoupled** — Registration and Triage layers are independent, connected only by data
- **Secure** — IAM least-privilege, KMS encryption, X-Ray tracing
---
## Patient Journey🚶
```
┌─────────────┐ ┌──────────────┐ ┌─────────────┐ ┌──────────────┐
┌──────────────┐ ┌───────────────┐
│ 1. CHECK-IN │─── │ 2. VOICE │─── │ 3. TRIAGE │─── │ 4. NOTIFY │─── │ 5.▶ ▶ ▶ ▶
CONSULT │─── │ 6. NAVIGATE │▶
│ │ │ INTAKE │ │ │ │ DOCTOR │ │
│ │ & DISCHARGE │
│ Face ID │ │ Speak in any │ │ AI extracts │ │ SNS alert │ │ WebSocket
│ │ Bedrock │
│ ID Scan │ │ language │ │ symptoms & │ │ with triage │ │ real-time
│ │ directions │
│ Rekognition │ │ Transcribe │ │ assigns │ │ summary │ │ translated
│ │ Polly speaks │
│ Textract │ │ Translate │ │ doctor │ │ │ │ chat
│ │ to patient │
└─────────────┘ └──────────────┘ └─────────────┘ └──────────────┘
└──────────────┘ └───────────────┘
```
**Example:** A patient walks in speaking Kiswahili. They are identified by face, speak
their symptoms, get triaged automatically, consult with a doctor (who speaks English) via
real-time translation, and receive spoken directions to the pharmacy — all without ever
needing to read or speak English.
---
## AWS Services Used☁️
| Category | Service | Purpose |
|---|---|---|
| **Compute** | AWS Lambda (Python 3.14) | Orchestration, business logic |
| **AI/ML** | Amazon Rekognition | Facial biometric identification |
| | Amazon Textract | ID document OCR extraction |
| | Amazon Transcribe | Speech-to-text + auto language detection |
| | Amazon Translate | Bidirectional translation |
| | Amazon Comprehend Medical | Medical entity extraction |
| | Amazon Bedrock (Claude) | Triage reasoning, navigation generation |
| | Amazon Polly | Text-to-speech in patient's language |
| | Amazon Lex V2 | Conversational interface |
| **API** | API Gateway REST | Registration endpoint |
| | API Gateway WebSocket | Real-time consultation |
| **Storage** | Amazon DynamoDB | Patient records, connection registry |
| | Amazon S3 | Audio, photos, IDs, transcripts, clinical notes |
| **Messaging** | Amazon SNS | Doctor triage notifications |
| **Security** | AWS IAM + KMS | Least-privilege roles, encryption at rest |
| **Monitoring** | AWS X-Ray | Distributed tracing |
| | Amazon CloudWatch | Logging and alerting |
| **Hosting** | Amazon CloudFront | Global CDN for web app |
---
## Project Structure📁
```
project-aria/
│
├── infrastructure/
│ └── cloudformation-template.yaml
│
├── lambda/
│ ├── aria-orchestrator/
│ │ └── lambda_function.py
│ ├── aria-sns-notify/
│ │ └── lambda_function.py
│ ├── aria-patient-identification/
│ │ └── lambda_function.py
│ ├── aria-document-textract/
│ │ └── lambda_function.py
│ ├── aria-ws-connect/
│ │ └── lambda_function.py
│ ├── aria-ws-disconnect/
│ │ └── lambda_function.py
│ └── aria-ws-message/
│ └── lambda_function.py
│
├── frontend/
│ └── index.html
│
├── docs/
│ ├── architecture/
│ │ ├── project_aria_architecture.png
│ │ └── mermaid_diagram.md
│ ├── integration-flow.md
│ ├── trade-off-document.md
│ └── echo-companion-report.md
│
├── tests/
│ └── test_websocket.sh
│
└── README.md
```
---
## Setup & Deployment🚀
### Prerequisites
- AWS Account with access to Bedrock (Claude), Rekognition, Comprehend Medical
- AWS CLI configured
- Python 3.14 runtime
### Deploy Infrastructure
```bash
aws cloudformation deploy \
--template-file infrastructure/cloudformation-template.yaml \
--stack-name project-aria \
--capabilities CAPABILITY_NAMED_IAM \
--region us-east-1
```
### Deploy Frontend
```bash
aws s3 sync frontend/ s3://aria-patient-app/ --delete
aws cloudfront create-invalidation \
--distribution-id YOUR_DIST_ID \
--paths "/*"
```
### Test WebSocket
```bash
# Terminal 1 — Connect as patient
npx wscat -c "wss://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod?
role=patient&patient_id=PAT-0001-Test&session_id=session-001"
# Terminal 2 — Connect as doctor
npx wscat -c "wss://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod?
role=doctor&patient_id=PAT-0001-Test&session_id=session-001"
# Send message from patient terminal
{"action": "sendMessage", "text": "Nina maumivu ya kifua", "language": "sw"}
```
---
## Key Design Decisions⚖️
| Decision | Chose | Over | Why |
|---|---|---|---|
| Triage Trigger | DynamoDB Streams | REST polling | Event-driven, decoupled, automatic |
| Intent Handling | Bedrock direct | Amazon Lex | Simpler orchestration, fewer moving
parts |
| Consultation | WebSocket API | REST polling | Real-time bidirectional, sub-second
latency |
| Language Detection | Transcribe auto-detect | Comprehend detect | Already processing
audio, no extra call |
| Polly Responses | Hybrid | All one approach | Standard directions hardcoded, dynamic
routes generated |
| Team Collaboration | Shared account + IAM roles | Separate accounts | Faster
integration, no merge conflicts |
| Entity Extraction | Comprehend Medical direct | Separate Lambda | Fewer cold starts,
simpler orchestrator |
| Monitoring | X-Ray + CloudWatch | CloudWatch only | Distributed tracing across Lambda
chain |
---
## Demo🎬
### Working End-to-End
- Patient facial recognition (returning patients)✅
- ID document scanning + OCR (new patients)✅
- Voice intake with auto language detection✅
- Automatic triage via DynamoDB Stream → Bedrock reasoning✅
- Doctor notification via SNS with formatted summary✅
- Real-time WebSocket consultation with live translation✅
- Post-consultation navigation with Polly speech output✅
- Full patient journey in Kiswahili, Arabic, or French✅
### Supported Languages
| Language | Code | Status |
|---|---|---|
| English | en | |✅
| Kiswahili | sw | |✅
| Arabic | ar | |✅
| French | fr | |✅
---
## Team👥
**The Indomitables**
| Member | Role | Layer | Key Services |
|---|---|---|---|
| **Ivy Mbengi** | Captain | Orchestrator + Triage + Consultation | Lambda, Bedrock,
Comprehend Medical, WebSocket API, SNS, X-Ray |
| **Lilian** | Builder | Registration | Rekognition, Textract, Transcribe, Translate, S3,
CloudFront |
| **Assa** | Builder | Conversational Interface | Lex V2, Bedrock, Lambda, DynamoDB |
---
## Lessons Learned📚
**1. Start with the patient journey, not the services.**
Mapping the human experience first made service selection obvious.
**2. Event-driven architecture requires clear data contracts.**
DynamoDB Streams only work when both teams agree on the exact schema and trigger
conditions.
**3. IAM is the hardest part of AWS.**
Cross-account roles, PassRole permissions, and least-privilege policies took more
debugging time than any AI service.
**4. WebSocket APIs are simpler than they look.**
Three Lambda functions and a DynamoDB table. The hardest part was remembering to create
the stage.
**5. Bedrock replaces multiple services.**
What would have required Lex + custom intent logic + response templates became a single
Bedrock prompt with system instructions.
---
## Future Roadmap🔮
- [ ] AWS HealthScribe for automated clinical note generation
- [ ] Step Functions for workflow orchestration
- [ ] QuickSight dashboards for clinic analytics
- [ ] HIPAA compliance review and audit logging
- [ ] Physical kiosk hardware deployment
- [ ] Multi-clinic routing and load balancing
---
## Security🔐
| Layer | Implementation |
|---|---|
| **Identity** | IAM least-privilege roles per Lambda |
| **Encryption** | KMS at rest (DynamoDB, S3) |
| **Tracing** | X-Ray distributed tracing |
| **Monitoring** | CloudWatch logs + metrics |
| **Credentials** | No hardcoded secrets — IAM roles only |
| **Infrastructure** | Serverless — no OS, no patches, no ports |
---
## Blog Post📝
Read the full write-up: [Thinking Like a Solutions Architect: Building a Multilingual AI
Healthcare System on AWS](#)
---
## License📄
This project was built as part of an AWS Cloud Engineering program. All AWS services used
are subject to AWS pricing and terms.
---
*Built with on AWS | June 2026*☁️
