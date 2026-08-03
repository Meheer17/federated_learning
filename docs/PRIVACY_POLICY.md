# 🛡️ FedChat Technical Privacy Policy & Architecture Guarantees

**Last Updated**: August 2026  
**Compliance Standards**: GDPR Article 25 (Privacy by Design), CCPA/CPRA, HIPAA Security Rule Alignment

---

## 1. Zero-Trust Local Data Sovereignty

FedChat is engineered under a **Zero-Trust Privacy Architecture**.

### 1.1 Local Data Residency (100% On-Device)
The following data types **never leave your physical smartphone**:
- All raw chat messages, prompts, and assistant responses.
- Conversation titles, timestamps, and message metadata.
- User style profiles (vocabulary frequency, formality scores, emoji preferences).
- Local SQLite database files (`fedchat_encrypted.db`).
- SQLite encryption passphrases.

### 1.2 Local Database Encryption
All persistent local data is encrypted at rest using **SQLCipher (AES-256 in CBC mode)** with HMAC-SHA512 integrity checks per 4096-byte database page. Passphrases are generated via cryptographically secure random number generators (`Random.secure()`) and stored in hardware-backed keychains via Android Keystore or iOS Keychain (`flutter_secure_storage`).

---

## 2. Federated Learning Privacy Model

When a user explicitly **opts in** to Federated Learning:

### 2.1 What Is Transmitted
Only tiny, encrypted **LoRA adapter weight difference matrices ($\Delta W$)** (~1–4 MB) are transmitted during active FL rounds. 

### 2.2 What Is NEVER Transmitted
- Raw text messages or conversation excerpts.
- Tokenized representations or word embeddings.
- User identity or device IP addresses (connections use ephemeral anonymous UUID tokens).

---

## 3. Cryptographic & Differential Privacy Protections

Each exported weight delta matrix $\Delta W$ is processed through two defensive privacy layers prior to network transmission:

### 3.1 Differential Privacy ($\varepsilon$-DP)
1. **L2 Gradient Clipping**: Weight updates are bounded by norm $C$:
   $$\Delta W_{\text{clipped}} = \Delta W \cdot \min\left(1, \frac{C}{\|\Delta W\|_2}\right)$$
2. **Gaussian Noise Injection**: Calibrated Gaussian noise $N(0, \sigma^2 I)$ is added:
   $$\sigma = \frac{C \sqrt{2 \ln(1.25/\delta)}}{\varepsilon}$$
3. **Privacy Budget Accounting**: Cumulative privacy loss ($\varepsilon$) is calculated per round. When the cumulative budget reaches $\varepsilon_{\text{max}} = 10.0$, FL participation is automatically terminated.

### 3.2 Secure Aggregation (SecAgg)
Individual updates are masked with pairwise secret masks generated via Diffie-Hellman key exchange. The FL server receives only the sum of all masked client updates:
$$\sum_i (\Delta W_i + M_i) = \sum_i \Delta W_i \quad \text{since } \sum_i M_i = 0$$
The server cannot inspect any individual user's update.

---

## 4. User Rights & Data Erasure

- **Instant Revocation**: Users may disable FL participation at any time in Settings.
- **One-Tap Data Wipe**: Tap **"Delete All FL Data"** in the Privacy Dashboard to immediately purge all local LoRA adapters, reset the privacy budget counter, and revoke server registration.
