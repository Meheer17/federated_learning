<p align="center">
  <h1 align="center">🛡️ FedChat</h1>
  <p align="center">
    <strong>A Privacy-First AI Chat Assistant with On-Device Learning & Federated Learning</strong>
  </p>
  <p align="center">
    Your conversations stay on your device. Your AI gets smarter everywhere.
  </p>
  <p align="center">
    <a href="#features">Features</a> •
    <a href="#architecture">Architecture</a> •
    <a href="#tech-stack">Tech Stack</a> •
    <a href="#getting-started">Getting Started</a> •
    <a href="#project-structure">Project Structure</a> •
    <a href="#privacy-model">Privacy Model</a> •
    <a href="#contributing">Contributing</a>
  </p>
</p>

---

## Overview

**FedChat** is an intelligent, personalized messaging assistant that runs entirely on your smartphone — no cloud required. It uses a lightweight on-device language model that learns your unique communication style (tone, vocabulary, writing habits) through local fine-tuning. Your raw messages **never leave your device**.

With your explicit consent, only tiny encrypted model updates (~1–4 MB) — not your conversations — can be shared through **federated learning** to improve the global AI model for all users while preserving everyone's privacy.

---

## Features

### 🤖 On-Device AI Chat
- Lightweight LLM (SmolLM2-1.7B) runs directly on your phone
- Streaming token-by-token response generation
- Fully functional **offline** — no internet needed for chat
- Fast inference via `llama.cpp` with GPU/NNAPI/Metal acceleration

### 🎨 Personalized to You
- **Style Analysis**: Learns your sentence length, emoji habits, formality level, vocabulary, and greeting patterns
- **Prompt-Based Personalization**: Dynamically adapts the AI's system prompt to match your tone
- **LoRA Fine-Tuning**: On-device adapter training during idle time for deeper personalization (~1–4 MB adapter, not the full model)

### 🔒 Privacy by Design
- **Zero data upload**: All chat history stays encrypted on-device (SQLCipher AES-256)
- **Federated Learning**: Only encrypted model weight deltas are shared — never your messages
- **Differential Privacy**: Calibrated noise added to updates before transmission
- **Secure Aggregation**: Server sees only the combined result, not individual contributions
- **Full user control**: Opt-in/opt-out at any time, delete all shared data instantly

### 📊 Privacy Dashboard
- See exactly what stays on your device vs. what's shared
- Privacy budget meter (ε tracker)
- FL participation history
- One-tap data deletion

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
│  │  • Public-key encryption (libsodium)               │ │
│  │  • Secure Aggregation masking                      │ │
│  └────────────────────────┬───────────────────────────┘ │
└───────────────────────────┼──────────────────────────────┘
                            │ Encrypted LoRA delta
                            │ only (~1–4 MB)
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

### Data Flow

```
User sends message
       │
       ▼
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Build prompt   │────▶│  LLM Inference   │────▶│ Stream response │
│  (+ style       │     │  (llama.cpp FFI) │     │  to chat UI     │
│   profile)      │     │  runs in Isolate │     │                 │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                                                          │
                                                          ▼
                                                 ┌─────────────────┐
                                                 │ Save to SQLite  │
                                                 │ (encrypted)     │
                                                 └────────┬────────┘
                                                          │
                              ┌────────────────────────── │ ──────────────────┐
                              │  Periodic (idle time)     ▼                   │
                              │  ┌────────────────────────────────────────┐   │
                              │  │ Style Analyzer: update user profile    │   │
                              │  │ LoRA Trainer: fine-tune adapter        │   │
                              │  └────────────────────┬───────────────────┘   │
                              │                       │                       │
                              │  ┌────────────────────▼───────────────────┐   │
                              │  │ FL Client (opt-in only):               │   │
                              │  │  1. Compute adapter delta              │   │
                              │  │  2. Clip gradients + add DP noise      │   │
                              │  │  3. Encrypt with server public key     │   │
                              │  │  4. Upload encrypted delta (~1-4 MB)   │   │
                              │  │  5. Download aggregated global adapter │   │
                              │  └────────────────────────────────────────┘   │
                              └───────────────────────────────────────────────┘
```

---

## Tech Stack

### Mobile App

| Component | Technology |
|:---|:---|
| Framework | **Flutter 3.x** (Dart) |
| LLM Inference | **llama.cpp** via `dart:ffi` |
| Base Model | **SmolLM2-1.7B** (GGUF Q4_K_M, ~1 GB) |
| On-Device Training | **LoRA adapters** via llama.cpp fine-tune API |
| Chat UI | **flutter_chat_ui** (Flyer Chat) |
| State Management | **Riverpod 2.x** |
| Navigation | **GoRouter** |
| Database | **sqflite_sqlcipher** (AES-256 encrypted SQLite) |
| Encryption | **sodium_libs** (libsodium FFI) |
| HTTP | **Dio** |
| Background Tasks | **workmanager** |

### Federated Learning Server

| Component | Technology |
|:---|:---|
| FL Framework | **Flower (flwr)** |
| API Server | **FastAPI** (Python) |
| Aggregation | **FedAvg + Secure Aggregation** |
| Privacy | **Differential Privacy** (Opacus) |
| Model Registry | **MLflow** |
| Database | **PostgreSQL** |
| Object Storage | **MinIO** (S3-compatible) |
| Task Queue | **Celery + Redis** |
| Containers | **Docker + Docker Compose** |

---

## Getting Started

### Prerequisites

- **Flutter** 3.x ([install guide](https://docs.flutter.dev/get-started/install))
- **Android Studio** or VS Code with Flutter/Dart plugins
- **Python** 3.12+ (for FL server)
- **Docker & Docker Compose** (for FL server infrastructure)
- **Android device/emulator** with ≥6 GB RAM (for on-device inference)

### 1. Clone the Repository

```bash
git clone https://github.com/Meheer17/federated_learning.git
cd federated_learning
```

### 2. Mobile App Setup

```bash
# Install Flutter dependencies
flutter pub get

# Verify setup
flutter doctor

# Run on Android emulator or connected device
flutter run
```

> **Note**: On first launch, the app will guide you through downloading the LLM model (~1 GB). Ensure you have sufficient storage and a stable connection.

### 3. FL Server Setup (Development)

```bash
cd server

# Copy environment template
cp .env.example .env
# Edit .env with your configuration

# Start all services
docker compose up -d

# Run database migrations
docker compose exec api alembic upgrade head

# Verify server is running
curl http://localhost:8000/health
```

### 4. Running Tests

```bash
# Flutter tests
flutter test

# Flutter analysis
flutter analyze

# Server tests
cd server && pytest tests/ -v

# FL simulation (validates federated learning pipeline)
cd server && python simulation/run_simulation.py
```

---

## Project Structure

```
federated/
│
├── lib/                          # Flutter app source
│   ├── app/                      # App config, routing, theme
│   │   ├── router.dart           # GoRouter configuration
│   │   ├── theme.dart            # Material 3 theme (dark/light)
│   │   └── constants.dart        # App-wide constants
│   │
│   ├── screens/                  # Full-page screens
│   │   ├── onboarding_screen.dart
│   │   ├── chat_screen.dart
│   │   ├── chat_list_screen.dart
│   │   ├── settings_screen.dart
│   │   └── privacy_dashboard_screen.dart
│   │
│   ├── widgets/                  # Reusable UI components
│   │   ├── privacy_budget_gauge.dart
│   │   └── data_comparison_chart.dart
│   │
│   ├── services/                 # Business logic
│   │   ├── llm_service.dart      # LLM inference (dart:ffi → llama.cpp)
│   │   ├── model_manager.dart    # Model download & lifecycle
│   │   ├── prompt_builder.dart   # Prompt construction & formatting
│   │   ├── style_analyzer.dart   # User style profiling
│   │   ├── personalization_engine.dart  # Style → system prompt
│   │   ├── training_scheduler.dart     # Idle-time LoRA training
│   │   ├── adapter_manager.dart        # LoRA adapter versioning
│   │   ├── federated_client.dart       # FL round participation
│   │   ├── privacy_guard.dart          # DP noise, gradient clipping
│   │   └── crypto_service.dart         # Encryption (libsodium)
│   │
│   ├── providers/                # Riverpod state management
│   │   ├── chat_provider.dart
│   │   └── app_provider.dart
│   │
│   ├── database/                 # Local data persistence
│   │   ├── database_helper.dart  # SQLCipher init & migrations
│   │   └── chat_repository.dart  # CRUD operations
│   │
│   ├── models/                   # Dart data classes
│   │   ├── conversation.dart
│   │   ├── message.dart
│   │   ├── user_profile.dart
│   │   └── model_info.dart
│   │
│   ├── native/                   # FFI bindings
│   │   ├── llama_ffi_bindings.dart    # llama.cpp inference bindings
│   │   └── lora_trainer_ffi.dart      # llama.cpp training bindings
│   │
│   ├── utils/                    # Helpers & extensions
│   │
│   └── main.dart                 # App entry point
│
├── native/                       # C/C++ native code
│   └── lora_trainer.cpp          # LoRA training wrapper
│
├── server/                       # Federated Learning backend
│   ├── api/
│   │   ├── routes/
│   │   │   ├── devices.py        # Device registration & heartbeat
│   │   │   ├── rounds.py         # FL round lifecycle
│   │   │   └── models.py         # Model distribution
│   │   └── schemas.py            # Pydantic request/response models
│   │
│   ├── core/
│   │   └── config.py             # Environment-based configuration
│   │
│   ├── models/
│   │   └── database.py           # SQLAlchemy ORM models
│   │
│   ├── services/
│   │   ├── flower_server.py      # Flower ServerApp + FedAvg strategy
│   │   └── aggregation.py        # SecAgg + Differential Privacy
│   │
│   ├── simulation/
│   │   ├── sim_config.toml       # Simulation parameters
│   │   ├── run_simulation.py     # FL simulation runner
│   │   └── synthetic_data.py     # Fake user data generator
│   │
│   ├── tests/                    # pytest test suite
│   │   ├── test_api.py
│   │   ├── test_aggregation.py
│   │   └── test_flower.py
│   │
│   ├── main.py                   # FastAPI entry point
│   ├── celery_app.py             # Async task workers
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── pyproject.toml
│
├── docs/
│   ├── PRIVACY_POLICY.md         # Technical privacy documentation
│   ├── ARCHITECTURE.md           # System architecture deep-dive
│   └── DEPLOYMENT.md             # Server deployment guide
│
├── .github/workflows/            # CI/CD pipelines
│   ├── flutter-ci.yml
│   ├── server-ci.yml
│   └── fl-simulation.yml
│
├── tasks.md                      # Development task tracker
├── pubspec.yaml                  # Flutter dependencies
└── README.md                     # ← You are here
```

---

## Privacy Model

FedChat is built on a **zero-trust privacy architecture**. Here's exactly what happens with your data:

### What Stays on Your Device (Always)

| Data | Storage | Encryption |
|:---|:---|:---|
| All chat messages | SQLite | AES-256 (SQLCipher) |
| Conversation history | SQLite | AES-256 (SQLCipher) |
| User style profile | SQLite | AES-256 (SQLCipher) |
| Base LLM model | App storage | — |
| LoRA adapter weights | App storage | — |
| Training logs | SQLite | AES-256 (SQLCipher) |

### What Can Be Shared (Opt-In Only)

| Data | Size | Protection |
|:---|:---|:---|
| LoRA adapter **delta** (weight differences) | ~1–4 MB | Differential Privacy noise + libsodium public-key encryption + Secure Aggregation masking |

### What the Server Sees

| Can See | Cannot See |
|:---|:---|
| Aggregated model update (sum of all participants) | Individual user's model update |
| Number of participants per round | Any chat messages |
| Device UUID (anonymous) | User identity |
| Dataset size (message count) | Message content |

### Privacy Guarantees

- **Differential Privacy (DP)**: Each update has calibrated Gaussian noise (ε-DP). Even if an attacker obtains your encrypted update, they cannot reverse-engineer your messages.
- **Secure Aggregation (SecAgg)**: The server only decrypts the **sum** of all updates. Individual contributions are masked with pairwise cryptographic secrets.
- **Privacy Budget**: The app tracks cumulative privacy loss (ε). Once the budget is exhausted, FL participation automatically stops.
- **User Control**: Opt out at any time. "Delete All FL Data" instantly wipes all adapter deltas and revokes consent.

---

## Federated Learning: How It Works

```
Round Lifecycle:
                                                          
  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
  │ Device A │    │ Device B │    │ Device C │    │ Device D │
  │ LoRA Δ_A │    │ LoRA Δ_B │    │ LoRA Δ_C │    │ LoRA Δ_D │
  └────┬─────┘    └────┬─────┘    └────┬─────┘    └────┬─────┘
       │               │               │               │
       ▼               ▼               ▼               ▼
  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
  │ + DP     │    │ + DP     │    │ + DP     │    │ + DP     │
  │  noise   │    │  noise   │    │  noise   │    │  noise   │
  └────┬─────┘    └────┬─────┘    └────┬─────┘    └────┬─────┘
       │               │               │               │
       ▼               ▼               ▼               ▼
  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
  │ Encrypt  │    │ Encrypt  │    │ Encrypt  │    │ Encrypt  │
  │ + Mask   │    │ + Mask   │    │ + Mask   │    │ + Mask   │
  └────┬─────┘    └────┬─────┘    └────┬─────┘    └────┬─────┘
       │               │               │               │
       └───────────────┼───────────────┼───────────────┘
                       │               │
                       ▼               ▼
              ┌─────────────────────────────┐
              │     Flower Server           │
              │     Σ masked updates        │
              │     (masks cancel out)      │
              │     ───────────────         │
              │     FedAvg(Δ_A+Δ_B+Δ_C+Δ_D)│
              │     = Global Adapter v(n+1) │
              └──────────────┬──────────────┘
                             │
                             ▼
              ┌─────────────────────────────┐
              │  Distribute updated global  │
              │  adapter to all devices     │
              └─────────────────────────────┘
```

1. **Local Training**: Each device fine-tunes a LoRA adapter on its private conversation data
2. **Delta Computation**: The difference between the current and baseline adapter is computed
3. **Privacy Protection**: Gradients are clipped + Gaussian noise is added (Differential Privacy)
4. **Encryption**: The noisy delta is encrypted with the server's public key and masked (SecAgg)
5. **Aggregation**: The server sums all masked updates — individual masks cancel out — revealing only the aggregate
6. **Distribution**: The improved global adapter is sent back to all devices

---

## Development Roadmap

| Phase | Timeline | Focus |
|:---|:---|:---|
| **Phase 1** | Weeks 1–3 | Core chat app + on-device LLM inference (offline-capable) |
| **Phase 2** | Weeks 4–7 | Style personalization + LoRA training + FL server + FL client |
| **Phase 3** | Weeks 8–10 | FL simulation, integration testing, privacy dashboard |
| **Phase 4** | Weeks 11–13 | UI polish, CI/CD, documentation, production hardening |

See [tasks.md](tasks.md) for the detailed task breakdown.

---

## Configuration

### Mobile App

Key settings are configured in `lib/app/constants.dart`:

```dart
const kDefaultModel = 'SmolLM2-1.7B-Q4_K_M';
const kMaxContextTokens = 2048;
const kDefaultTemperature = 0.7;
const kDefaultTopP = 0.9;
const kTrainingMinBattery = 0.5;    // 50%
const kDPEpsilon = 1.0;             // Privacy budget per round
const kDPClipNorm = 1.0;            // Gradient clipping bound
const kFLServerUrl = 'https://fl.fedchat.app/api/v1';
```

### FL Server

Environment variables (see `server/.env.example`):

```env
# Database
DATABASE_URL=postgresql+asyncpg://user:pass@postgres:5432/fedchat

# Redis
REDIS_URL=redis://redis:6379/0

# MinIO
MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin

# Federated Learning
FL_MIN_CLIENTS=3
FL_ROUNDS=10
FL_LEARNING_RATE=0.001
FL_ROUND_TIMEOUT=3600

# Differential Privacy
DP_EPSILON=1.0
DP_DELTA=1e-5
DP_CLIP_NORM=1.0
```

---

## Contributing

Contributions are welcome! Please read the following before submitting:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Guidelines

- Run `flutter analyze` and fix all warnings before committing
- Add tests for new features (`flutter test`)
- Follow [Effective Dart](https://dart.dev/effective-dart) style guidelines
- Server code must pass `ruff check` and `mypy`
- Update documentation for any API changes

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- [llama.cpp](https://github.com/ggerganov/llama.cpp) — On-device LLM inference engine
- [Flower](https://flower.ai/) — Federated learning framework
- [SmolLM2](https://huggingface.co/HuggingFaceTB/SmolLM2-1.7B) — Lightweight language model
- [Flutter](https://flutter.dev/) — Cross-platform mobile framework
- [FastAPI](https://fastapi.tiangolo.com/) — Modern Python web framework

---

<p align="center">
  <strong>Your messages. Your device. Your privacy.</strong>
</p>
