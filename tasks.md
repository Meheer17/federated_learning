# 🛡️ Privacy-First AI Chat Assistant — Task Tracker

> **Project**: Flutter + Federated Learning On-Device LLM Chat Assistant  
> **Tech Stack**: Flutter (Dart) · llama.cpp (dart:ffi) · Flower (flwr) · FastAPI · Docker  
> **Status**: 📋 Planning  
> **Last Updated**: 2026-08-03

---

## Phase 1 — Core Chat App with On-Device Inference (Weeks 1–3)

### 1.1 Project Scaffolding
- [ ] Create Flutter project (`flutter create --org com.federated --project-name federated_chat ./`)
- [ ] Configure `analysis_options.yaml` with strict linting rules
- [ ] Set up project folder structure:
  ```
  lib/
  ├── app/           # router, theme, constants
  ├── screens/       # full-page screens
  ├── widgets/       # reusable UI components
  ├── services/      # business logic (LLM, training, FL)
  ├── providers/     # Riverpod providers
  ├── database/      # SQLite helper, repositories
  ├── models/        # Dart data models
  ├── native/        # dart:ffi bindings
  └── utils/         # helpers, extensions
  ```
- [ ] Install core dependencies in `pubspec.yaml`:
  - [ ] `flutter_riverpod` (state management)
  - [ ] `go_router` (navigation)
  - [ ] `flutter_chat_ui` / `flutter_chat_types` (Flyer Chat)
  - [ ] `sqflite_sqlcipher` (encrypted SQLite)
  - [ ] `dio` (HTTP client)
  - [ ] `workmanager` (background tasks)
  - [ ] `google_fonts` (typography)
  - [ ] `flutter_secure_storage` (secure key storage)
  - [ ] `path_provider` (file paths)
  - [ ] `uuid` (unique IDs)
- [ ] Set up `flutter_llama` or custom `dart:ffi` bindings to `llama.cpp`
- [ ] Verify project builds on Android emulator (`flutter run`)

### 1.2 App Shell & Navigation
- [ ] Create `lib/main.dart` — `ProviderScope` → `MaterialApp.router`
- [ ] Create `lib/app/router.dart` — `GoRouter` with routes:
  - [ ] `/onboarding` (first-launch)
  - [ ] `/chats` (conversation list — home)
  - [ ] `/chat/:id` (chat screen)
  - [ ] `/settings` (settings)
  - [ ] `/privacy` (privacy dashboard)
- [ ] Create `lib/app/theme.dart`
  - [ ] Material 3 `ThemeData` with `ColorScheme` (dark + light)
  - [ ] Custom typography using Google Fonts (Inter or Outfit)
  - [ ] Reusable component themes (cards, buttons, inputs)
- [ ] Create `lib/app/constants.dart` — app-wide constants

### 1.3 Onboarding Flow
- [ ] Build `lib/screens/onboarding_screen.dart`
  - [ ] `PageView` with privacy explanation slides:
    - [ ] Slide 1: "Your data stays on your device"
    - [ ] Slide 2: "AI that learns your style locally"
    - [ ] Slide 3: "Optional: Help improve AI for everyone (FL opt-in)"
  - [ ] Model download consent button
  - [ ] Storage permission request
  - [ ] Initial user preferences (name, tone preference)
- [ ] Persist onboarding completion in `SharedPreferences`

### 1.4 LLM Engine Integration (dart:ffi → llama.cpp)
- [ ] Create `lib/native/llama_ffi_bindings.dart`
  - [ ] Define FFI struct bindings: `llama_context_params`, `llama_model_params`, etc.
  - [ ] Bind core functions: `llama_model_load`, `llama_new_context`, `llama_decode`, `llama_token_to_piece`
  - [ ] Session lifecycle: init → load → generate → cleanup
  - [ ] Run inference in Dart `Isolate` to keep UI thread free
- [ ] Create `lib/services/model_manager.dart`
  - [ ] Model catalog: list available GGUF models (SmolLM2-1.7B Q4, etc.)
  - [ ] Download model from HuggingFace via `dio` with:
    - [ ] Progress callback (for download progress bar)
    - [ ] Resume support (range headers)
    - [ ] SHA-256 integrity check after download
  - [ ] Model storage in `getApplicationDocumentsDirectory()/models/`
  - [ ] Delete model, check available storage
  - [ ] Model metadata persistence in SQLite
- [ ] Create `lib/services/llm_service.dart`
  - [ ] Singleton service wrapping FFI bindings
  - [ ] `Stream<String> generateResponse(String prompt, {int maxTokens})` — streaming tokens
  - [ ] Load/unload model lifecycle (manage ~1 GB memory)
  - [ ] System prompt injection
  - [ ] Context window management (sliding window over last N messages)
  - [ ] Temperature, top-p, repetition penalty controls
  - [ ] Error handling: OOM, corrupted model, generation timeout
- [ ] Create `lib/services/prompt_builder.dart`
  - [ ] Convert `List<Message>` → formatted prompt (ChatML / Llama-3 format)
  - [ ] Inject system prompt (base + personalization)
  - [ ] Context window trimming (fit within model's max context)
  - [ ] Token counting utility

### 1.5 Local Database (Encrypted)
- [ ] Create `lib/database/database_helper.dart`
  - [ ] Initialize SQLCipher-encrypted SQLite
  - [ ] Key derivation from `flutter_secure_storage`
  - [ ] Schema creation:
    - [ ] `conversations` (id TEXT PK, title TEXT, created_at INTEGER, updated_at INTEGER)
    - [ ] `messages` (id TEXT PK, conversation_id TEXT FK, role TEXT, content TEXT, timestamp INTEGER)
    - [ ] `user_profile` (key TEXT PK, value TEXT) — style preferences
    - [ ] `training_logs` (id INTEGER PK, started_at INTEGER, completed_at INTEGER, epochs INTEGER, loss REAL, adapter_path TEXT)
    - [ ] `model_metadata` (id TEXT PK, name TEXT, path TEXT, size_bytes INTEGER, sha256 TEXT, downloaded_at INTEGER)
  - [ ] Migration support (version tracking)
- [ ] Create `lib/database/chat_repository.dart`
  - [ ] Create/read/update/delete conversations
  - [ ] Insert/fetch messages by conversation (paginated)
  - [ ] Full-text search across messages
  - [ ] Export messages as training-ready JSONL (local only)
  - [ ] Count messages per conversation (for FL weight calculation)

### 1.6 Data Models
- [ ] Create `lib/models/conversation.dart` — `Conversation` class
- [ ] Create `lib/models/message.dart` — `ChatMessage` class (role, content, timestamp)
- [ ] Create `lib/models/user_profile.dart` — `StyleProfile` class
- [ ] Create `lib/models/model_info.dart` — `ModelInfo` class (name, path, size, status)

### 1.7 State Management (Riverpod)
- [ ] Create `lib/providers/chat_provider.dart`
  - [ ] `conversationListProvider` — all conversations, sorted by updated_at
  - [ ] `activeConversationProvider` — current conversation
  - [ ] `messagesProvider(conversationId)` — messages for a conversation
  - [ ] `isGeneratingProvider` — whether LLM is currently generating
- [ ] Create `lib/providers/app_provider.dart`
  - [ ] `modelStatusProvider` — download/loaded/unloaded/error
  - [ ] `settingsProvider` — theme, FL consent, training preferences
  - [ ] `onboardingCompleteProvider` — whether onboarding done

### 1.8 Chat Screen
- [ ] Build `lib/screens/chat_screen.dart`
  - [ ] Integrate `flutter_chat_ui` (`Chat` widget)
  - [ ] Custom message bubbles with streaming text animation
  - [ ] Typing indicator while model generates
  - [ ] Connect "send" to LLM: send message → build prompt → stream response → display
  - [ ] Persist all messages to SQLite on send/receive
  - [ ] Message actions: copy, retry, delete
  - [ ] Auto-scroll to bottom on new message
  - [ ] Keyboard handling, auto-resize input

### 1.9 Chat List Screen
- [ ] Build `lib/screens/chat_list_screen.dart`
  - [ ] `ListView` of conversations with:
    - [ ] Conversation title (auto-generated from first message)
    - [ ] Last message preview + timestamp
    - [ ] Unread indicator
  - [ ] FAB to create new conversation
  - [ ] Swipe-to-delete with undo snackbar
  - [ ] Search bar to filter conversations

### 1.10 Settings Screen
- [ ] Build `lib/screens/settings_screen.dart`
  - [ ] **Model** section: download status, storage used, switch/delete model
  - [ ] **Appearance**: dark/light/system theme toggle
  - [ ] **Privacy & FL**: opt-in toggle (placeholder, wired in Phase 2)
  - [ ] **Training**: status indicator (placeholder)
  - [ ] **About**: version, licenses, privacy policy link

### 1.11 Phase 1 Testing & Validation
- [ ] Unit tests: `PromptBuilder`, `ChatRepository`, Riverpod providers
- [ ] Widget tests: ChatScreen, ChatListScreen, OnboardingScreen
- [ ] Integration test: full chat loop (send → generate → display → persist)
- [ ] Test on Android emulator with downloaded GGUF model
- [ ] Verify fully offline operation (airplane mode)
- [ ] Memory profiling: model load/unload, generation (no OOM on 6 GB device)
- [ ] `flutter analyze` passes with zero issues

---

## Phase 2 — On-Device Personalization + FL Foundation (Weeks 4–7)

### 2.1 Style Analysis
- [ ] Create `lib/services/style_analyzer.dart`
  - [ ] Analyze user's sent messages for:
    - [ ] Average sentence length (words per sentence)
    - [ ] Average message length (words per message)
    - [ ] Vocabulary richness (unique words / total words)
    - [ ] Emoji frequency and top-used emojis
    - [ ] Punctuation habits (!, ..., ?, capitalization)
    - [ ] Common greeting phrases ("hey", "hi", "hello" vs. "dear", "good morning")
    - [ ] Common closing phrases ("bye", "ttyl", "cya" vs. "regards", "thanks")
    - [ ] Formality score (0.0 casual → 1.0 formal)
    - [ ] Preferred response length bucket (short/medium/long)
  - [ ] Store `StyleProfile` in SQLite `user_profile` table
  - [ ] Re-analyze periodically (every 20 new messages)
  - [ ] Expose profile via Riverpod provider

### 2.2 Prompt-Based Personalization
- [ ] Create `lib/services/personalization_engine.dart`
  - [ ] Generate dynamic system prompt from `StyleProfile`:
    ```
    "You are a chat assistant. Match the user's style: casual tone, 
    frequent emoji use (especially 😂🔥), short messages (under 30 words), 
    informal greetings like 'hey' and 'yo'."
    ```
  - [ ] Inject personalized system prompt into `PromptBuilder`
  - [ ] Toggle: personalized vs. default mode
  - [ ] User feedback: thumbs up/down on each response → adjust style weights

### 2.3 On-Device LoRA Training
- [ ] Create `native/lora_trainer.cpp`
  - [ ] C++ wrapper around `llama.cpp` fine-tune API
  - [ ] Functions: `start_lora_training(data_path, config)`, `get_training_progress()`, `cancel_training()`
  - [ ] Hyperparameters: LoRA rank (8), alpha (16), epochs (1–3), learning rate (1e-4)
  - [ ] Output: adapter weights file (~1–4 MB `.bin`)
  - [ ] Progress reporting via callback
  - [ ] Graceful cancellation
- [ ] Create `lib/native/lora_trainer_ffi.dart`
  - [ ] `dart:ffi` bindings to `lora_trainer.cpp`
  - [ ] `NativeCallable<Void Function(Float)>` for progress callbacks
  - [ ] Run training in separate `Isolate`
- [ ] Create `lib/services/training_scheduler.dart`
  - [ ] Register `workmanager` periodic task
  - [ ] Check device conditions before training:
    - [ ] Battery > 50% (`battery_plus` plugin)
    - [ ] Charging status (prefer plugged in)
    - [ ] Thermal state (abort if hot)
    - [ ] Screen off / app in background
  - [ ] Prepare training data:
    - [ ] Export recent user messages as instruction-response JSONL
    - [ ] Data cleaning: remove duplicates, normalize
    - [ ] Train/validation split (90/10)
  - [ ] Launch training, track progress, store adapter
  - [ ] Rollback: if new adapter produces worse responses, revert to previous

### 2.4 LoRA Adapter Management
- [ ] Create `lib/services/adapter_manager.dart`
  - [ ] Save/load adapter weights from local storage
  - [ ] Version tracking (keep last 3 adapters)
  - [ ] Merge adapter with base model for inference
  - [ ] Compute adapter delta (current - baseline) for FL
  - [ ] Delete old adapters to manage storage

### 2.5 Federated Learning Server (Backend)
- [ ] Initialize Python project (`server/`)
  - [ ] Create `server/pyproject.toml` with:
    - [ ] `fastapi`, `uvicorn[standard]`, `flwr[simulation]`
    - [ ] `sqlalchemy`, `alembic`, `asyncpg`
    - [ ] `mlflow`, `celery[redis]`, `pydantic-settings`
    - [ ] `opacus`, `numpy`, `torch`
  - [ ] Create directory structure:
    ```
    server/
    ├── api/routes/        # FastAPI route handlers
    ├── core/              # config, security, deps
    ├── models/            # SQLAlchemy models
    ├── services/          # business logic
    ├── simulation/        # Flower simulation scripts
    ├── tests/             # pytest tests
    └── main.py            # FastAPI entrypoint
    ```
- [ ] Create `server/core/config.py`
  - [ ] Pydantic `Settings` class with env vars:
    - [ ] `DATABASE_URL`, `REDIS_URL`, `MINIO_*`
    - [ ] FL: `MIN_CLIENTS_PER_ROUND`, `FL_ROUNDS`, `FL_LEARNING_RATE`
    - [ ] DP: `DP_EPSILON`, `DP_DELTA`, `DP_CLIP_NORM`
    - [ ] `SECRET_KEY`, `ROUND_TIMEOUT_SECONDS`
- [ ] Create `server/models/database.py`
  - [ ] SQLAlchemy models:
    - [ ] `Device` (uuid, public_key, registered_at, last_seen, total_rounds)
    - [ ] `FLRound` (id, status, started_at, completed_at, num_participants, config_json, global_metrics)
    - [ ] `ModelVersion` (id, version, round_id, artifact_path, metrics_json, created_at)
    - [ ] `UpdateSubmission` (id, device_id, round_id, encrypted_blob_path, dataset_size, received_at)
- [ ] Set up Alembic migrations
  - [ ] `alembic init`, configure `env.py`
  - [ ] Create initial migration
- [ ] Create `server/main.py`
  - [ ] FastAPI app with CORS, exception handlers
  - [ ] `GET /health` endpoint
  - [ ] Include API routers

### 2.6 FL API Endpoints
- [ ] Create `server/api/routes/devices.py`
  - [ ] `POST /api/v1/devices/register`
    - [ ] Accept: device UUID, public key
    - [ ] Return: server public key, device confirmed
  - [ ] `GET /api/v1/devices/{device_id}/status`
    - [ ] Return: FL eligibility, active round (if any)
  - [ ] `POST /api/v1/devices/{device_id}/heartbeat`
    - [ ] Update `last_seen`, return pending round invitation
- [ ] Create `server/api/routes/rounds.py`
  - [ ] `GET /api/v1/rounds/current`
    - [ ] Return: active round info or 204 if none
  - [ ] `POST /api/v1/rounds/{round_id}/join`
    - [ ] Register device as participant for this round
  - [ ] `POST /api/v1/rounds/{round_id}/submit`
    - [ ] Accept: encrypted LoRA delta blob, dataset size
    - [ ] Store in MinIO, create `UpdateSubmission` record
    - [ ] If all participants submitted → trigger aggregation
  - [ ] `GET /api/v1/rounds/{round_id}/status`
    - [ ] Return: round status, participants count, completion %
  - [ ] `GET /api/v1/rounds/{round_id}/result`
    - [ ] Return: aggregated adapter download URL
- [ ] Create `server/api/routes/models.py`
  - [ ] `GET /api/v1/models/latest`
    - [ ] Return: latest global adapter metadata + download URL
  - [ ] `GET /api/v1/models/{version}/download`
    - [ ] Stream adapter file from MinIO
  - [ ] `GET /api/v1/models/catalog`
    - [ ] Return: list of available base models with download URLs
- [ ] Create Pydantic request/response schemas (`server/api/schemas.py`)

### 2.7 Flower FL Integration
- [ ] Create `server/services/flower_server.py`
  - [ ] Configure Flower `ServerApp`
  - [ ] Custom `FedAvgWithSecAgg` strategy:
    - [ ] `configure_fit()`: select eligible devices, send round config
    - [ ] `aggregate_fit()`: weighted averaging by dataset size
    - [ ] Minimum client threshold (skip round if < N)
    - [ ] Server-side validation against held-out test data
    - [ ] Early stopping if global metrics degrade
  - [ ] Round lifecycle: CREATED → ACCEPTING → TRAINING → AGGREGATING → COMPLETED
  - [ ] gRPC communication setup
- [ ] Create `server/services/aggregation.py`
  - [ ] Secure Aggregation (SecAgg):
    - [ ] Pairwise secret sharing for mask generation
    - [ ] Each client masks their update with sum of pairwise masks
    - [ ] Server sums masked updates → masks cancel out → reveal aggregate
    - [ ] Dropout resilience: reconstruct missing masks from surviving clients
  - [ ] Differential Privacy post-aggregation:
    - [ ] Gaussian mechanism: add N(0, σ²) noise to aggregated weights
    - [ ] σ calibrated from target ε, δ, sensitivity (clip norm)
    - [ ] Privacy budget accounting: track cumulative ε across rounds

### 2.8 FL Client (Mobile Side)
- [ ] Create `lib/services/crypto_service.dart`
  - [ ] Initialize `sodium_libs`
  - [ ] Generate keypair (stored in `flutter_secure_storage`)
  - [ ] `Uint8List encrypt(Uint8List data, Uint8List serverPublicKey)`
  - [ ] `Uint8List decrypt(Uint8List encrypted, Uint8List serverPublicKey)`
  - [ ] Secure random bytes for DP noise
- [ ] Create `lib/services/privacy_guard.dart`
  - [ ] `clipGradients(Map<String, Tensor> delta, double clipNorm)` — L2 norm clipping
  - [ ] `addNoise(Map<String, Tensor> clipped, double sigma)` — Gaussian noise
  - [ ] Privacy budget tracker:
    - [ ] Track ε spent per round
    - [ ] Cumulative ε (using composition theorems)
    - [ ] Refuse participation if budget exceeded
  - [ ] Generate privacy report (for dashboard)
- [ ] Create `lib/services/federated_client.dart`
  - [ ] `register()` — POST device UUID + public key to server
  - [ ] `checkForRound()` — GET current round, heartbeat
  - [ ] `participateInRound(roundId)`:
    1. Compute adapter delta (current adapter - baseline adapter)
    2. Apply `PrivacyGuard.clipGradients()` → `addNoise()`
    3. Encrypt delta via `CryptoService.encrypt()`
    4. POST encrypted blob to `/rounds/{id}/submit`
    5. Poll for round completion
    6. Download aggregated adapter from `/rounds/{id}/result`
    7. Merge with local adapter via `AdapterManager`
  - [ ] Background execution via `workmanager` task
  - [ ] Connectivity check before participation
  - [ ] Exponential backoff on failures
  - [ ] Respect user consent toggle

### 2.9 Infrastructure (Docker)
- [ ] Create `server/Dockerfile`
  - [ ] Python 3.12 slim base
  - [ ] Install dependencies from `pyproject.toml`
  - [ ] Run with `uvicorn`
- [ ] Create `server/docker-compose.yml`
  - [ ] Services:
    - [ ] `api` — FastAPI server (port 8000)
    - [ ] `flower` — Flower gRPC server (port 8080)
    - [ ] `postgres` — PostgreSQL 16 (port 5432)
    - [ ] `redis` — Redis 7 (port 6379)
    - [ ] `minio` — MinIO S3 (port 9000/9001)
    - [ ] `mlflow` — MLflow tracking (port 5000)
  - [ ] Volumes for persistent data
  - [ ] Health checks, restart policies
  - [ ] `.env.example` with all env vars
- [ ] Create `server/celery_app.py`
  - [ ] Celery workers with Redis broker
  - [ ] Tasks: `start_round`, `process_submission`, `run_aggregation`, `validate_model`
  - [ ] Beat schedule: check for enough eligible devices → start round

### 2.10 Phase 2 Testing
- [ ] Unit tests: `StyleAnalyzer`, `PersonalizationEngine`, `PrivacyGuard`
- [ ] Server tests: all API endpoints (pytest + httpx)
- [ ] Server tests: aggregation math (FedAvg, SecAgg, DP noise)
- [ ] Integration: FL client ↔ server round trip (local Docker)
- [ ] Verify encrypted blobs cannot be decrypted without correct key
- [ ] Verify DP noise calibration matches target ε

---

## Phase 3 — FL Simulation, Integration Testing & Privacy Dashboard (Weeks 8–10)

### 3.1 Flower Simulation
- [ ] Create `server/simulation/sim_config.toml`
  - [ ] Number of clients: 10, 50, 100
  - [ ] Data distribution: non-IID (realistic for personalized models)
  - [ ] Rounds: 5–20
  - [ ] DP parameters: ε=1.0, δ=1e-5
- [ ] Create `server/simulation/run_simulation.py`
  - [ ] Generate synthetic "user style" data for each virtual client
  - [ ] Run full FL simulation via Flower's simulation engine
  - [ ] Log metrics to MLflow: per-round loss, accuracy, convergence curve
  - [ ] Validate SecAgg correctness (aggregate matches sum of unmasked)
  - [ ] Validate DP (verify noise distribution)
- [ ] Create `server/simulation/synthetic_data.py`
  - [ ] Generate fake conversation data with distinct "styles"
  - [ ] Non-IID partitioning across clients

### 3.2 Comprehensive Server Tests
- [ ] `server/tests/test_aggregation.py`
  - [ ] FedAvg with equal weights
  - [ ] FedAvg with unequal weights (by dataset size)
  - [ ] SecAgg: mask/unmask with all clients alive
  - [ ] SecAgg: mask/unmask with N-1 client dropout
  - [ ] DP noise: mean ≈ 0, variance ≈ σ² (statistical test)
  - [ ] Privacy budget: ε accumulates correctly over rounds
- [ ] `server/tests/test_api.py`
  - [ ] Device registration happy path + duplicate
  - [ ] Round lifecycle: create → join → submit → aggregate → result
  - [ ] Model download endpoints
  - [ ] Error cases: submit to wrong round, join after deadline, etc.
- [ ] `server/tests/test_flower.py`
  - [ ] Custom strategy: min clients threshold enforced
  - [ ] Weighted averaging produces correct result
  - [ ] Validation callback fires after aggregation

### 3.3 Privacy Dashboard (Mobile)
- [ ] Build `lib/screens/privacy_dashboard_screen.dart`
  - [ ] **Data Residency** card: "100% of your messages stay on this device"
  - [ ] **FL Status** card: opt-in toggle, participation count, last round date
  - [ ] **Privacy Budget** gauge: circular progress showing ε used / ε total
  - [ ] **Data Comparison** chart: bar chart comparing:
    - [ ] Total chat data on device (MB)
    - [ ] Total data shared with server (KB — only adapter deltas)
  - [ ] **FL History** list: rounds participated with dates and bytes uploaded
  - [ ] "Delete All FL Data" button → confirmation → wipe adapter deltas + revoke consent
- [ ] Create `lib/widgets/privacy_budget_gauge.dart`
  - [ ] Animated `CustomPaint` circular gauge
  - [ ] Color gradient: green (low ε) → yellow → red (near budget)
- [ ] Create `lib/widgets/data_comparison_chart.dart`
  - [ ] Simple bar chart (custom painted or `fl_chart` package)
  - [ ] Shows dramatic size difference between local data and shared data

### 3.4 End-to-End Integration
- [ ] Mobile ↔ Server round trip test:
  - [ ] Start Docker Compose stack
  - [ ] Flutter app registers device with server
  - [ ] Server creates FL round
  - [ ] App detects round, prepares delta, encrypts, uploads
  - [ ] Server aggregates (simulated with 2+ submissions)
  - [ ] App downloads aggregated adapter
  - [ ] Verify adapter is applied to model
- [ ] Network traffic inspection:
  - [ ] Verify HTTPS for all traffic
  - [ ] Verify uploaded blobs are encrypted (not plaintext weights)
  - [ ] Verify no chat messages in any request payload

### 3.5 Phase 3 Testing
- [ ] Run FL simulation with 10, 50, 100 clients → verify convergence
- [ ] Dropout test: kill 30% of clients mid-round → verify round completes
- [ ] Load test: 100 concurrent submissions → verify server handles gracefully
- [ ] Widget tests for Privacy Dashboard components
- [ ] Integration test: privacy budget exhaustion → FL participation refused

---

## Phase 4 — Polish & Production Readiness (Weeks 11–13)

### 4.1 UI/UX Polish
- [ ] Loading states and skeleton screens (`shimmer` package)
- [ ] Page transition animations (`Hero`, `SlideTransition`)
- [ ] Haptic feedback on key interactions (`HapticFeedback`)
- [ ] Empty states with illustrations (no conversations, no model, etc.)
- [ ] Error states with retry actions
- [ ] Pull-to-refresh on conversation list
- [ ] Animated model download progress (circular + percentage)
- [ ] Accessibility:
  - [ ] `Semantics` labels on all interactive elements
  - [ ] Dynamic font scaling (`MediaQuery.textScaleFactor`)
  - [ ] Sufficient color contrast (WCAG AA)

### 4.2 App Assets
- [ ] Design app icon (adaptive icon for Android, iOS assets)
- [ ] Splash screen (`flutter_native_splash`)
- [ ] In-app illustrations for onboarding slides

### 4.3 Documentation
- [ ] `README.md` — project overview, prerequisites, setup, architecture diagram, screenshots
- [ ] `docs/PRIVACY_POLICY.md` — technical privacy documentation
  - [ ] What data is collected (none) vs. generated on-device
  - [ ] What is transmitted (encrypted adapter deltas only, with consent)
  - [ ] Data flow diagrams
  - [ ] GDPR / CCPA compliance notes
- [ ] `docs/ARCHITECTURE.md` — detailed system architecture
  - [ ] Component diagrams
  - [ ] Data flow: message → inference → personalization → FL
  - [ ] Security model: encryption, DP, SecAgg
- [ ] `docs/DEPLOYMENT.md` — FL server deployment guide
  - [ ] Docker Compose (development)
  - [ ] Kubernetes (production)
  - [ ] Environment configuration
- [ ] `docs/API.md` — server API documentation (supplement to auto-generated Swagger)

### 4.4 CI/CD Pipelines
- [ ] `.github/workflows/flutter-ci.yml`
  - [ ] Trigger: push to `main`, PRs
  - [ ] Steps: `flutter analyze`, `flutter test`, `flutter build apk --debug`
- [ ] `.github/workflows/server-ci.yml`
  - [ ] Trigger: push to `main`, PRs
  - [ ] Steps: `ruff check`, `mypy server/`, `pytest tests/`, Docker build
- [ ] `.github/workflows/fl-simulation.yml`
  - [ ] Trigger: merge to `main`
  - [ ] Steps: spin up Docker services, run Flower simulation, report metrics

### 4.5 Server Monitoring & Observability
- [ ] Prometheus metrics endpoint in FastAPI
  - [ ] FL round duration, participation rate
  - [ ] API request latency (p50, p95, p99)
  - [ ] Aggregation time
- [ ] Grafana dashboard configs:
  - [ ] FL rounds overview (participation, convergence)
  - [ ] API health (latency, errors, throughput)
  - [ ] System resources (CPU, memory, disk)
- [ ] Structured logging (JSON, with correlation IDs)
- [ ] Alert rules: round failure, low participation, API errors > threshold

### 4.6 Security Hardening
- [ ] API rate limiting (`slowapi` or middleware)
- [ ] Input validation on all endpoints (Pydantic strict mode)
- [ ] HTTPS enforcement (TLS termination)
- [ ] Database connection pooling and SSL
- [ ] Secrets management (`.env` files, never committed)
- [ ] Model update signature verification (prevent tampered adapters)

### 4.7 Final Validation
- [ ] End-to-end walkthrough: onboarding → chat → personalization → FL round → privacy dashboard
- [ ] Performance benchmarks:
  - [ ] Model inference: tokens/sec on reference device
  - [ ] LoRA training: time per epoch, battery % consumed
  - [ ] FL round: total time from start to aggregated adapter available
  - [ ] App cold start: time to interactive
- [ ] Network traffic audit (no raw data leaves device)
- [ ] Battery consumption profiling during training
- [ ] Test on low-end device (4 GB RAM, Android 10)
- [ ] Test on high-end device (12 GB RAM, Android 14)
- [ ] `flutter analyze` — zero issues
- [ ] `flutter test --coverage` — >80% coverage
- [ ] All server tests passing
- [ ] FL simulation converges within expected rounds
