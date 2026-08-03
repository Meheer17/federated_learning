# Privacy-First AI Chat Assistant — Flutter + Federated Learning

## Overview

Build a **privacy-first AI chat assistant** using **Flutter** that runs a lightweight language model directly on the user's smartphone. The model personalizes to the user's communication style (tone, vocabulary, writing habits) via on-device fine-tuning. Raw chat data **never leaves the device**. With user consent, only encrypted model weight updates participate in **federated learning** rounds to improve a shared global model for all users.

---

## Tech Stack

### Mobile Application (Flutter)

| Layer | Technology | Rationale |
|:---|:---|:---|
| **Framework** | **Flutter 3.x** (Dart) | Compiles to native ARM code; smooth 120fps UI for streaming tokens; single codebase for Android + iOS |
| **LLM Inference** | **`flutter_llama`** (Dart FFI binding to `llama.cpp`) | Direct C interop via `dart:ffi` — no JavaScript bridge overhead; full access to GGUF inference + GPU/NNAPI/Metal delegates |
| **Base Model** | **SmolLM2-1.7B** quantized to Q4_K_M GGUF (~1 GB) | Small enough for most smartphones (≥4 GB RAM), strong instruction-following for its size |
| **On-Device Training** | **LoRA / QLoRA adapters** via native C++ module (`dart:ffi` to `llama.cpp` fine-tune API) | Only trains ~1–4 MB of adapter weights; feasible on-device during idle |
| **Chat UI** | **`flutter_chat_ui`** (Flyer Chat) + custom widgets | Modern, customizable chat interface with streaming support |
| **Local Storage** | **`sqflite_sqlcipher`** (SQLite + SQLCipher encryption) | AES-256 encrypted local database; fully offline-capable |
| **Encryption** | **`sodium_libs`** (libsodium via FFI) | NaCl public-key encryption for FL model updates |
| **HTTP Client** | **`dio`** | Interceptors, retry, progress tracking for model downloads and FL uploads |
| **State Management** | **`flutter_riverpod`** (Riverpod 2.x) | Compile-safe, testable, provider-based state management |
| **Navigation** | **`go_router`** | Declarative routing with deep-link support |
| **Background Tasks** | **`workmanager`** | Schedule LoRA training and FL round participation during idle |
| **Platform Channels** | **`dart:ffi`** (preferred) + Method Channels (fallback) | Direct C/C++ interop for ML workloads; no serialization overhead |

### Federated Learning Backend

| Layer | Technology | Rationale |
|:---|:---|:---|
| **FL Orchestrator** | **Flower (flwr)** | Industry-leading FL framework; custom strategies, simulation, gRPC transport |
| **API Server** | **FastAPI** (Python) | REST gateway for device registration, model distribution, FL coordination |
| **Aggregation Strategy** | **FedAvg** with **Secure Aggregation** masks | Standard FL aggregation with cryptographic masking of individual updates |
| **Differential Privacy** | **Opacus** + custom Gaussian noise injection | Adds calibrated noise to updates; tracks cumulative privacy budget (ε) |
| **Model Registry** | **MLflow** | Version-tracks global model checkpoints, adapter snapshots, training metrics |
| **Database** | **PostgreSQL** | Device registry, FL round metadata, aggregation logs (never raw chat data) |
| **Object Storage** | **MinIO** (S3-compatible) | Model artifacts, global checkpoints, encrypted update blobs |
| **Task Queue** | **Celery + Redis** | Async aggregation rounds, model validation, scheduled round triggers |
| **Containerization** | **Docker + Docker Compose** | Reproducible multi-service deployment |

### DevOps & Infrastructure

| Layer | Technology |
|:---|:---|
| **CI/CD** | GitHub Actions |
| **Container Orchestration** | Docker Compose (dev), Kubernetes (prod) |
| **Monitoring** | Prometheus + Grafana |
| **API Docs** | FastAPI auto-generated OpenAPI/Swagger |

---

## Architecture

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
│  │  • Encrypt adapter delta with libsodium            │ │
│  │  • SecAgg masking                                  │ │
│  └────────────────────────────┬───────────────────────┘ │
└───────────────────────────────┼──────────────────────────┘
                                │ Encrypted LoRA
                                │ delta only (≈1–4 MB)
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

## User Review Required

> [!IMPORTANT]
> **Platform Priority**: Flutter targets both Android and iOS. Should we prioritize **Android-first** (easier ML debugging) or build both simultaneously?

> [!IMPORTANT]
> **Model Selection**: The plan proposes **SmolLM2-1.7B (Q4, ~1 GB)** as default. Alternatively, **Gemma 2B (Q4, ~1.5 GB)** has better instruction-following but needs more RAM. Which model do you prefer?

> [!WARNING]
> **On-device LoRA training** via `llama.cpp`'s fine-tune API through `dart:ffi` is cutting-edge. A safer Phase 1 approach is **prompt-based personalization** (style profile → dynamic system prompt), adding true LoRA training in Phase 2. Recommended approach?

---

## Open Questions

1. **Minimum device spec**: Android 10+ / iOS 15+, ≥6 GB RAM? Or support lower-end devices with a cloud fallback?
2. **App distribution**: Play Store / TestFlight, or sideloading for now?
3. **FL server auth**: JWT/OAuth for devices, or anonymous UUID registration?
4. **Hosting**: AWS, GCP, self-hosted, or local Docker for development?
5. **Offline-first**: App should be 100% functional offline (FL is purely opt-in when connected)?

---

## Proposed Changes

### Phase 1 — Core Chat App with On-Device Inference (Weeks 1–3)

Build a fully functional, offline-capable chat assistant running an LLM locally.

---

#### Flutter App Foundation

##### [NEW] `pubspec.yaml`
- Flutter project configuration with dependencies: `flutter_llama`, `flutter_chat_ui`, `sqflite_sqlcipher`, `flutter_riverpod`, `go_router`, `dio`, `workmanager`, `sodium_libs`

##### [NEW] `lib/main.dart`
- App entry point: `ProviderScope` → `MaterialApp.router` with theme, navigation, initialization

##### [NEW] `lib/app/router.dart`
- `GoRouter` configuration: `/onboarding` → `/chats` → `/chat/:id` → `/settings` → `/privacy`

##### [NEW] `lib/app/theme.dart`
- Material 3 theme with dark/light mode, custom color scheme, typography (Google Fonts)

##### [NEW] `lib/screens/onboarding_screen.dart`
- Privacy explanation pageview, model download consent, permissions flow

##### [NEW] `lib/screens/chat_screen.dart`
- Main chat interface using `flutter_chat_ui`
- Streaming token display, typing indicators
- Connect to LLM engine for response generation

##### [NEW] `lib/screens/chat_list_screen.dart`
- Conversation list with last message preview, search, create/delete

##### [NEW] `lib/screens/settings_screen.dart`
- Model management, theme toggle, FL opt-in, training status, privacy link

---

#### LLM Inference Engine

##### [NEW] `lib/services/llm_service.dart`
- Singleton wrapping `flutter_llama` (dart:ffi → llama.cpp)
- `Stream<String> generateResponse(String prompt, List<Message> context)` — streaming tokens
- Model load/unload lifecycle, memory management
- System prompt management, context window (sliding window)

##### [NEW] `lib/services/model_manager.dart`
- Download GGUF model via `dio` with progress callback
- SHA-256 integrity verification
- Model storage in app documents directory
- Available model catalog, delete/update

##### [NEW] `lib/services/prompt_builder.dart`
- Conversation history → ChatML/Llama prompt format
- System prompt injection with user style profile
- Context window trimming, token counting

##### [NEW] `lib/native/llama_ffi_bindings.dart`
- `dart:ffi` bindings to `llama.cpp` C API
- Struct definitions, function signatures
- Inference session management

---

#### Local Data Layer

##### [NEW] `lib/database/database_helper.dart`
- SQLCipher-encrypted SQLite initialization
- Schema creation and migrations
- Tables: `conversations`, `messages`, `user_profile`, `training_logs`, `model_metadata`

##### [NEW] `lib/database/chat_repository.dart`
- CRUD: conversations and messages
- Paginated message queries, full-text search
- Training data export (local format)

##### [NEW] `lib/providers/chat_provider.dart`
- Riverpod providers: active conversation, message list, loading/generating states

##### [NEW] `lib/providers/app_provider.dart`
- Riverpod providers: model status, settings, onboarding state, FL consent

---

### Phase 2 — On-Device Personalization + FL Foundation (Weeks 4–7)

Add style learning, prompt-based personalization, LoRA training, AND lay the federated learning groundwork (both client and server).

---

#### Style Learning Engine

##### [NEW] `lib/services/style_analyzer.dart`
- Analyze user's sent messages:
  - Sentence length, vocabulary richness, emoji frequency
  - Common phrases, greeting/closing patterns
  - Formality score, response length preferences
- Store style profile in SQLite

##### [NEW] `lib/services/personalization_engine.dart`
- **Prompt-based mode**: Generate dynamic system prompts from style profile
- **LoRA-based mode**: Trigger on-device fine-tuning with conversation history
- A/B comparison toggle, user feedback (thumbs up/down)

##### [NEW] `lib/services/training_scheduler.dart`
- Monitor: battery level (>50%), charging, thermal state, screen off
- Schedule via `workmanager` during idle windows
- Progress tracking, automatic rollback on degradation

##### [NEW] `lib/native/lora_trainer_ffi.dart`
- `dart:ffi` bindings to `llama.cpp` fine-tune API
- Accept: training data path, LoRA rank, alpha, epochs, learning rate
- Output: adapter weights file (~1–4 MB)
- Progress callback via `NativeCallable`

##### [NEW] `native/lora_trainer.cpp`
- C++ implementation wrapping `llama.cpp` training
- Called from Dart via FFI, runs in isolate to avoid UI jank

---

#### Federated Learning Client (Mobile)

##### [NEW] `lib/services/federated_client.dart`
- Device registration with FL server (on first opt-in)
- Poll for active FL round
- Compute LoRA adapter delta (current - baseline)
- Apply differential privacy (clip + noise via `PrivacyGuard`)
- Encrypt delta with server public key (libsodium)
- Upload encrypted delta, download aggregated adapter
- Merge global adapter with local adapter
- Background execution via `workmanager`
- Exponential backoff, retry, connectivity checks

##### [NEW] `lib/services/privacy_guard.dart`
- L2 gradient clipping
- Gaussian noise injection (calibrated to target ε)
- Privacy budget tracker (cumulative ε across rounds)
- Privacy report generation for dashboard

##### [NEW] `lib/services/crypto_service.dart`
- Wrapper around `sodium_libs`
- Key generation, public-key encryption/decryption
- Secure random number generation for DP noise
- SecAgg mask generation

---

#### Federated Learning Server

##### [NEW] `server/pyproject.toml`
- Python project: `fastapi`, `uvicorn`, `flwr`, `sqlalchemy`, `alembic`, `mlflow`, `celery[redis]`, `pydantic`, `opacus`, `numpy`

##### [NEW] `server/main.py`
- FastAPI app: CORS, middleware, health check, router registration

##### [NEW] `server/config.py`
- Environment-based config: FL hyperparams (min_clients, rounds, LR), DP epsilon/delta, server secrets

##### [NEW] `server/models.py`
- SQLAlchemy: `Device`, `FLRound`, `ModelVersion`, `UpdateSubmission`

##### [NEW] `server/flower_server.py`
- Flower `ServerApp` with custom `FedAvg`:
  - Weighted averaging by dataset size
  - Min client threshold, validation against held-out set
  - Early stopping on model degradation

##### [NEW] `server/aggregation.py`
- Secure Aggregation: pairwise masking, dropout resilience
- DP noise injection on aggregated result
- Privacy budget accounting

##### [NEW] `server/api/routes/devices.py`
- `POST /api/v1/devices/register` — anonymous UUID registration
- `GET /api/v1/devices/{id}/status` — FL participation status
- `POST /api/v1/devices/{id}/heartbeat`

##### [NEW] `server/api/routes/rounds.py`
- `GET /api/v1/rounds/current` — active round info
- `POST /api/v1/rounds/{id}/join` — declare participation
- `POST /api/v1/rounds/{id}/submit` — upload encrypted delta
- `GET /api/v1/rounds/{id}/result` — download aggregated adapter

##### [NEW] `server/api/routes/models.py`
- `GET /api/v1/models/latest` — latest global adapter
- `GET /api/v1/models/{version}/download` — specific version
- `GET /api/v1/models/catalog` — available base models

##### [NEW] `server/Dockerfile` & `server/docker-compose.yml`
- Services: api, flower-server, postgres, redis, minio, mlflow

---

### Phase 3 — FL Integration Testing & Privacy Dashboard (Weeks 8–10)

End-to-end FL validation and user-facing privacy controls.

---

#### FL Simulation & Validation

##### [NEW] `server/simulation/sim_config.toml`
- Flower simulation config: 10–100 virtual clients, non-IID data distribution

##### [NEW] `server/simulation/run_simulation.py`
- Simulate full FL rounds with synthetic data
- Measure convergence, validate SecAgg + DP correctness
- Output metrics to MLflow

##### [NEW] `server/tests/test_aggregation.py`
- Unit tests: FedAvg math, SecAgg masking/unmasking, DP noise calibration
- Dropout resilience tests (kill clients mid-round)

##### [NEW] `server/tests/test_api.py`
- API endpoint tests: registration, round lifecycle, model download

---

#### Privacy Dashboard (Mobile)

##### [NEW] `lib/screens/privacy_dashboard_screen.dart`
- Data residency visualization (what stays on-device)
- FL participation history (rounds, dates, bytes uploaded)
- Privacy budget meter (ε spent / total budget)
- Data comparison chart (chat data size vs. uploaded adapter deltas)
- Opt-in/opt-out toggle with confirmation
- "Delete all FL data" button (revoke consent)

##### [NEW] `lib/widgets/privacy_budget_gauge.dart`
- Animated circular gauge showing cumulative ε usage

##### [NEW] `lib/widgets/data_comparison_chart.dart`
- Bar chart: local data size vs. bytes shared with server

---

### Phase 4 — Polish & Production Readiness (Weeks 11–13)

---

#### UI/UX Polish

##### [NEW] `lib/widgets/` (various)
- Loading skeletons, shimmer effects
- Animated transitions between screens
- Haptic feedback widgets
- Accessibility: semantics labels, dynamic font scaling

##### [NEW] `assets/` (app icon, splash)
- App icon (adaptive icon for Android, iOS assets)
- Splash screen with `flutter_native_splash`

#### Documentation

##### [NEW] `README.md`
- Project overview, setup, architecture diagram

##### [NEW] `docs/PRIVACY_POLICY.md`
- Technical privacy documentation, GDPR/CCPA notes

##### [NEW] `docs/ARCHITECTURE.md`
- Detailed architecture with data flow diagrams

##### [NEW] `docs/DEPLOYMENT.md`
- Docker deployment guide for FL server

#### CI/CD

##### [NEW] `.github/workflows/flutter-ci.yml`
- `flutter analyze`, `flutter test`, `flutter build apk --debug`

##### [NEW] `.github/workflows/server-ci.yml`
- `ruff check`, `mypy`, `pytest`, Docker build

##### [NEW] `.github/workflows/fl-simulation.yml`
- Run Flower simulation on merge to main

#### Monitoring (Server)

##### [NEW] `server/monitoring/`
- Prometheus metrics endpoint
- Grafana dashboard configs (FL rounds, API metrics)

---

## How the AI Agent Will Build This

### Phase 1 (Agent can fully build):
1. **Create Flutter project** — `flutter create` with proper org and structure
2. **Install all pub dependencies** — `flutter_llama`, `flutter_chat_ui`, `sqflite_sqlcipher`, `riverpod`, `go_router`, `dio`, etc.
3. **Build FFI bindings** — `dart:ffi` wrapper for `llama.cpp` inference
4. **Build all screens** — Onboarding, ChatList, Chat, Settings
5. **Implement LLM service** — Model download, loading, streaming inference
6. **Build encrypted database** — SQLCipher schema, repository, migrations
7. **Verify end-to-end** — Chat loop works fully offline on emulator

### Phase 2 (Agent builds both mobile + server):
1. **Build StyleAnalyzer** — Pure Dart analysis of user messages
2. **Implement prompt personalization** — Dynamic system prompt from style profile
3. **Write LoRA trainer FFI bindings** — C++ module called from Dart isolate
4. **Build training scheduler** — `workmanager` integration for idle-time training
5. **Scaffold FastAPI + Flower server** — Full FL backend with all endpoints
6. **Build FL client** — `FederatedClient` + `PrivacyGuard` + `CryptoService` in Dart
7. **Docker Compose** — Full server stack (API, Flower, Postgres, Redis, MinIO, MLflow)

### Phase 3 (Agent builds + validates):
1. **Run Flower simulation** — Validate FL round lifecycle with 10+ virtual clients
2. **Test SecAgg + DP** — Unit tests for cryptographic aggregation
3. **Build Privacy Dashboard** — Flutter screen with gauges and charts
4. **End-to-end integration** — Mobile FL client ↔ server round trip

### Phase 4 (Agent builds; some items need manual validation):
1. **Polish UI** — Animations, skeletons, haptics, accessibility
2. **CI/CD pipelines** — GitHub Actions for Flutter + server
3. **Documentation** — README, privacy policy, architecture docs
4. **Monitoring** — Prometheus + Grafana for FL server

> [!NOTE]
> **What the agent CAN'T do directly**: Physical device testing, app store submission, real multi-device FL rounds. Flower's **simulation mode** will validate FL logic end-to-end on a single machine.

---

## Verification Plan

### Automated Tests
```bash
# Flutter (unit + widget tests)
cd mobile && flutter test --coverage

# Server (pytest)
cd server && pytest tests/ -v --cov=server

# FL Simulation (Flower)
cd server && python simulation/run_simulation.py

# Lint
cd mobile && flutter analyze
cd server && ruff check .
```

### Manual Verification
- **Chat inference**: Load GGUF model on Android emulator, send messages, verify streaming responses
- **Personalization**: Use app for 20+ messages, observe style-adapted responses
- **FL round**: Run Flower simulation with 10 virtual clients, verify aggregated model improves
- **Privacy**: Inspect network traffic to confirm only encrypted adapter deltas transmitted
- **Offline mode**: Airplane mode → full chat functionality verified
- **Battery/thermal**: Profile LoRA training impact on physical device
