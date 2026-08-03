# 🏗️ FedChat System Architecture & Technical Specifications

## 1. System Overview Diagram

```
┌──────────────────────────────────────────────────────────┐
│                   SMARTPHONE (Device)                     │
│                                                          │
│  ┌────────────┐  ┌────────────────┐  ┌────────────────┐ │
│  │  Chat UI   │──│  LLM Engine    │──│  LoRA Trainer  │ │
│  │ (Flutter)  │  │ (dart:ffi →    │  │ (dart:ffi →    │ │
│  │            │  │  llama.cpp)    │  │  llama.cpp)    │ │
│  └────────────┘  └────────────────┘  └───────┬────────┘ │
│       │                │                      │          │
│  ┌────▼──────┐   ┌─────▼───────┐   ┌────────▼────────┐ │
│  │  SQLite   │   │ Base Model  │   │  LoRA Adapter   │ │
│  │(SQLCipher) │   │ (GGUF Q4)  │   │  Weights (.bin) │ │
│  └───────────┘   └─────────────┘   └────────┬────────┘ │
│                                              │          │
│  ┌───────────────────────────────────────────▼────────┐ │
│  │  Privacy Layer (Dart)                              │ │
│  │  • Gradient clipping + Gaussian noise (DP)         │ │
│  │  • Public-key encryption (libsodium)               │ │
│  │  • Secure Aggregation masking                      │ │
│  └────────────────────────┬───────────────────────────┘ │
└───────────────────────────┼──────────────────────────────┘
                            │ Encrypted LoRA delta (~1–4 MB)
                            ▼
┌──────────────────────────────────────────────────────────┐
│                 FEDERATED LEARNING SERVER                  │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────┐ │
│  │   FastAPI    │──│   Flower     │──│  Aggregation   │ │
│  │   Gateway    │  │   Server     │  │  (FedAvg+SA)   │ │
│  └──────────────┘  └──────────────┘  └──────┬─────────┘ │
│                                              │           │
│  ┌──────────┐  ┌──────────┐  ┌──────────────▼─────────┐ │
│  │PostgreSQL│  │  Redis   │  │   MLflow + MinIO       │ │
│  │(metadata)│  │ (queue)  │  │   (model registry)     │ │
│  └──────────┘  └──────────┘  └────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

---

## 2. Component Specifications

### 2.1 Mobile Application Layer (Flutter 3.x)
- **State Management**: `flutter_riverpod` (Riverpod 2.x compile-safe providers).
- **Navigation**: `go_router` (declarative URL-style routing).
- **Chat Interface**: `flutter_chat_ui` (Flyer Chat widget) supporting token streaming.
- **Inference Engine**: `llama.cpp` dynamic library via `dart:ffi` C-interop running in a dedicated Dart Isolate.
- **Storage**: `sqflite_sqlcipher` with AES-256 CBC encryption.
- **Background Tasks**: `workmanager` scheduling training sessions during idle charging states.

### 2.2 Server Architecture (Python 3.12 / FastAPI / Flower)
- **API Server**: FastAPI with OpenAPI swagger auto-docs.
- **FL Framework**: Flower (`flwr`) managing round lifecycles and gRPC channels.
- **Database**: PostgreSQL 16 storing device registration, round status, and model versions (zero chat text).
- **Storage & Caching**: MinIO S3 object storage for global GGUF checkpoints; Redis 7 for message queueing.
- **Monitoring**: Prometheus metrics + Grafana dashboards.

---

## 3. Data Flow Sequences

1. **User Message**: User inputs text in `ChatScreen` $\rightarrow$ `PromptBuilder` constructs ChatML prompt $\rightarrow$ `LlmService` streams tokens via `LlamaFfiBindings` $\rightarrow$ Message persisted in SQLCipher DB.
2. **Idle Style Analysis & Fine-Tuning**: `TrainingScheduler` checks battery ($>50\%$) & charging state $\rightarrow$ Exports local JSONL $\rightarrow$ Native C++ `lora_trainer.cpp` fine-tunes adapter weights.
3. **FL Participation Round**: `FederatedClient` fetches active round $\rightarrow$ `AdapterManager` computes weight delta $\rightarrow$ `PrivacyGuard` applies L2 clipping + DP Gaussian noise $\rightarrow$ `CryptoService` encrypts blob $\rightarrow$ Uploaded to FastAPI server $\rightarrow$ Server runs `FedAvgWithSecAgg` $\rightarrow$ Global adapter distributed back to clients.
