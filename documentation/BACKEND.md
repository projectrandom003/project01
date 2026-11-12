# Backend and Database Recommendations

> **Current state:** there is **no backend** in this repository. The vertical slice is offline and client-authoritative. This document is the recommended design for Phase 12+, not a description of running code. The SQL file at `backend/schemas/schema.sql` is a proposed schema, not a deployed migration.

The non-negotiable rule for the online game:

> **The client may request. The server decides. The database records.**

Anything that can be exchanged, ranked, purchased or bragged about must be server-owned: gacha results, pity, currencies, inventory, equipment, quest rewards, battle outcomes, trades, PvP rating, mail attachments and event progress.

---

## 1. Recommended stack

Optimize for a small team that needs to ship, observe and iterate.

| Layer | Recommendation | Why |
| --- | --- | --- |
| Client | Godot 4.7, GDScript | Existing codebase; HTTP/WebSocket clients are straightforward |
| API / game services | **TypeScript + Fastify** (or NestJS for structure) | Fast iteration, strong JSON ergonomics, shared types with tooling |
| Combat simulation | **Go** service (optional at first) | CPU-bound, deterministic, easy to scale independently |
| Primary database | **PostgreSQL 16+** | Transactions, row locks, JSONB, mature operations |
| Cache / locks / rate limits | **Redis 7+** | Pity locks, sessions, presence, queues, idempotency keys |
| Messaging | **NATS JetStream** or Redis Streams | Reward grants, mail, analytics, async jobs |
| Object storage | S3-compatible (AWS S3, Cloudflare R2, MinIO) | Replays, support exports, content bundles |
| CDN | Cloudflare or equivalent | Content manifests, static assets, DDoS protection |
| Deployment | Managed containers (Fly.io, Railway, Render, ECS, GKE) | Start simple; move to Kubernetes only when needed |
| Observability | OpenTelemetry + Grafana/Loki/Tempo or hosted equivalent | Traces across gateway → services → DB |
| Secrets | Cloud secret manager + short-lived credentials | No secrets in client or repo |

### Start as a modular monolith

Do **not** begin with 12 microservices. Start with one deployable API containing clear modules:

```text
api/
├─ auth/
├─ players/
├─ content/
├─ gacha/
├─ inventory/
├─ quests/
├─ battles/
├─ social/
├─ economy/
└─ admin/
```

Extract the battle simulator, realtime gateway or marketplace only when load or team ownership demands it. The module boundaries and database tables should already reflect the future split.

### Why not Firebase/Supabase alone?

They are excellent for prototypes and auth, but an RPG economy needs transactional multi-row grants, row-level locks for pity and trades, auditable ledgers, deterministic combat replay and custom anti-fraud. PostgreSQL is the right source of truth. Managed auth can still sit in front of it.

---

## 2. Authority matrix

| Feature | Client today | Online authority |
| --- | --- | --- |
| Movement | Client | Client predicts; server validates plausibility and checkpoints position |
| NPC dialogue | Client | Server can validate quest flags; dialogue text is content |
| Quest start/progress | Client | Server owns quest state and kill/collect credit |
| Quest reward claim | Client | Server grants with idempotency key |
| Battle actions | Client | Server validates actor, skill, target, energy, cooldowns |
| Battle outcome | Client | Server simulates and signs the result |
| Battle rewards | Client | Server grants after validated victory |
| Gacha roll | Client | **Server only** |
| Pity | Client | **Server only** |
| Currency | Client | **Server only**, ledger-backed |
| Inventory/equipment | Client | **Server only** |
| Character ownership | Client | **Server only** |
| Trading/market | Not implemented | **Server only**, escrow + audit |
| PvP rating | Not implemented | **Server only** |
| Mail | Not implemented | **Server only**, attachments escrowed |
| Premium purchases | Not implemented | Platform store + server receipt validation |

---

## 3. Service responsibilities

### Auth service

- Registration, login, refresh, logout.
- Email/password with Argon2id; optional OAuth/device linking.
- Short-lived access tokens (JWT or opaque session), rotating refresh tokens.
- Device/account linking and recovery codes.
- Session revocation and “log out all devices”.
- Rate limits and breached-password checks.
- Age gate and regional eligibility flags.

### Player service

- Profile, level, XP, flags, settings.
- Roster, party, equipment, inventory, currencies.
- Quest state and progress.
- Position checkpoints (not every frame).
- Bootstrap snapshot for login: profile + roster + inventory + quests + pity + content version.

### Content service

- Serves a signed **content manifest**: version, hash, banner definitions, character/skill/enemy data.
- Pins a client session to a content version so balance changes do not corrupt in-flight battles.
- Supports staged rollout and rollback.
- Content itself can be bundled in the client, but the server must know the exact version used for rolls and combat.

### Gacha service

- Owns banner state, rates, pity and featured rules.
- Uses a CSPRNG (`crypto.randomInt` / `crypto/rand`), not `Math.random`.
- Locks the player’s pity row in a transaction.
- Records every pull in an append-only audit table.
- Grants ownership and duplicate/awakening effects in the same transaction.
- Returns a result signed or retrievable by pull ID so the client cannot forge it.

### Battle service

- Creates a battle from a validated party and enemy group.
- Runs the same deterministic rules as `CombatEngine` (port or shared spec).
- Accepts one action at a time from the current actor.
- Rejects out-of-turn, unknown-skill, insufficient-energy and invalid-target actions.
- Stores the event stream and a hash for replay.
- On victory, grants rewards through the reward service with an idempotency key.
- Supports reconnect by replaying events from a sequence number.

### Economy service

- Ledger-backed currencies. Every change is a row, not an overwrite.
- Inventory grants/removals with reason codes.
- Trading escrow and marketplace settlement.
- Faucet/sink reporting and anomaly detection.
- Support adjustments require a ticket ID and audit entry.

### Social service

- Friends, blocks, presence, chat, guilds, mail.
- Rate limits, profanity/spam filters, report queue.
- Chat retention policy and moderator tooling.
- Guild bank audit log.

---

## 4. API sketch

Use JSON over HTTPS for request/response and WebSocket for realtime. Version the API (`/v1`). Every mutating request carries:

- `Authorization: Bearer <access token>`
- `Idempotency-Key: <uuid>` for grants, pulls, trades, claims
- `X-Client-Version` and `X-Content-Version`
- Optional `X-Request-Signature` for high-value endpoints

### Bootstrap

```http
GET /v1/bootstrap
```

```json
{
  "server_time": "2026-11-11T12:00:00Z",
  "content_version": "2026.11.1",
  "player": { "id": "...", "name": "Wanderer", "level": 4 },
  "currencies": { "gold": 1250, "crystals": 900, "gems": 0 },
  "roster": [ { "uid": "...", "char_id": "mira_sol", "level": 12, "awakening": 1 } ],
  "party": ["..."],
  "inventory": [ { "item_id": "glade_sap", "qty": 3 } ],
  "quests": [ { "quest_id": "glade_whisper", "state": "active", "step": 1 } ],
  "pity": { "glade_whispers": { "legendary": 12, "featured": 4 } }
}
```

### Gacha pull

```http
POST /v1/gacha/pulls
Idempotency-Key: 7f4c...
```

```json
{ "banner_id": "glade_whispers", "count": 10 }
```

Server flow:

1. Authenticate and rate-limit.
2. Load banner for the session’s content version.
3. `SELECT ... FOR UPDATE` the player’s pity row for that banner.
4. Check and debit currency in the same transaction.
5. Roll with CSPRNG.
6. Insert `gacha_pulls` rows and grant characters/awakening.
7. Update pity.
8. Commit.
9. Return results with pull ID and new balances.

Response:

```json
{
  "pull_id": "...",
  "results": [
    { "character_id": "lyra_vey", "rarity": "epic", "featured": true, "is_new": true }
  ],
  "pity": { "legendary": 0, "featured": 0 },
  "balances": { "crystals": 150 }
}
```

If the same idempotency key is retried, return the original result. Never roll twice.

### Battle

```http
POST /v1/battles
{ "group_id": "glade_mossling_pack", "party": ["uid1", "uid2", "uid3"] }
```

```json
{
  "battle_id": "...",
  "state": { "round": 1, "current_actor": "p_uid1", "units": [ ... ] },
  "events": [ ... ],
  "sequence": 1
}
```

```http
POST /v1/battles/{battle_id}/actions
Idempotency-Key: ...
{ "sequence": 2, "skill_id": "shield_bash", "targets": ["e_mossling_1"] }
```

Server validates and returns the next event batch. On completion:

```http
POST /v1/battles/{battle_id}/claim
Idempotency-Key: ...
```

The claim endpoint is separate so a disconnect after victory cannot lose rewards, and a retry cannot duplicate them.

### Other endpoints

| Method | Path | Purpose |
| --- | --- | --- |
| `POST` | `/v1/auth/register` | Create account |
| `POST` | `/v1/auth/login` | Obtain tokens |
| `POST` | `/v1/auth/refresh` | Rotate refresh token |
| `POST` | `/v1/auth/logout` | Revoke session |
| `GET` | `/v1/player` | Profile |
| `PATCH` | `/v1/player` | Settings/name (validated) |
| `PUT` | `/v1/party` | Set party with ownership checks |
| `POST` | `/v1/inventory/equip` | Equip owned item |
| `POST` | `/v1/quests/{id}/start` | Start quest |
| `POST` | `/v1/quests/{id}/claim` | Claim completed quest |
| `POST` | `/v1/trades` | Create trade offer |
| `POST` | `/v1/trades/{id}/accept` | Accept with escrow |
| `GET` | `/v1/market/listings` | Browse marketplace |
| `POST` | `/v1/market/listings` | List item |
| `GET` | `/v1/mail` | Mailbox |
| `POST` | `/v1/mail/{id}/claim` | Claim attachments |
| `GET` | `/v1/guilds/{id}` | Guild info |
| `WS` | `/v1/realtime` | Presence, chat, battle updates |

---

## 5. Database design

The proposed schema is in `backend/schemas/schema.sql`. Core principles:

1. **UUID primary keys** generated by the application or `gen_random_uuid()`.
2. **Every mutable player resource has a version/`updated_at`** for optimistic concurrency.
3. **Currency and item changes are ledgered**; balances are caches derived from or reconciled against the ledger.
4. **Gacha pulls and trades are append-only** with reason codes and idempotency keys.
5. **Content definitions are versioned**, not edited in place under a live session.
6. **Foreign keys and check constraints** enforce ownership and non-negative quantities.
7. **Audit table** for support actions, grants, bans and economy adjustments.

### Main tables

| Table | Purpose |
| --- | --- |
| `accounts` | Login identity, status, locale, created_at |
| `account_sessions` | Refresh token hashes, device, expiry, revocation |
| `players` | Game profile: name, level, xp, flags, last_seen |
| `player_currencies` | Current balances per currency (cache) |
| `currency_ledger` | Append-only currency changes with reason and idempotency key |
| `owned_characters` | Character instances: level, xp, ascension, awakening, bond, dupes |
| `character_equipment` | Equipped item per slot |
| `inventory_items` | Stackable item quantities |
| `item_ledger` | Append-only item changes |
| `party_members` | Ordered party slots, max 4 enforced by service |
| `player_quests` | Quest state, step, progress |
| `banner_pity` | Per-player/per-banner pity counters |
| `gacha_pulls` | One row per pull with banner, result, pity snapshot, idempotency |
| `battles` | Encounter, state, seed, status, result hash |
| `battle_events` | Ordered event stream for replay |
| `battle_rewards` | Idempotent reward grants for a battle |
| `trades` | Trade header, status, timestamps |
| `trade_items` | Escrowed items/currency per side |
| `market_listings` | Marketplace listings, price, status |
| `guilds`, `guild_members`, `guild_bank_ledger` | Guild state |
| `friendships`, `blocks` | Social graph |
| `chat_messages` | Optional retained chat with moderation fields |
| `mail`, `mail_attachments` | Mail and escrowed attachments |
| `audit_log` | Support/admin/security actions |
| `content_versions` | Content manifest version and hash |

### Transactions that must be atomic

- Gacha: debit currency + insert pulls + grant characters + update pity.
- Quest claim: mark claimed + grant rewards + ledger rows.
- Battle claim: mark claimed + grant rewards + ledger rows.
- Trade accept: remove both offers + transfer items/currency + audit.
- Marketplace sale: remove listing + transfer item + seller proceeds + tax.
- Mail claim: mark claimed + grant attachments.

Use `SERIALIZABLE` or explicit `SELECT ... FOR UPDATE` on the player’s resource rows. Keep transactions short; do not call external services inside them.

---

## 6. Security and anti-cheat

### Client hardening (defense in depth, not authority)

- Obfuscate/export with release templates; strip debug symbols.
- Never ship server secrets, admin keys or signing keys.
- Pin TLS certificates where platform allows.
- Detect rooted/jailbroken devices only as a risk signal, never as sole enforcement.
- Validate all server responses structurally; do not trust “success” booleans.

### Server controls

- Authorize every object by `account_id`, not by client-supplied player ID.
- Validate party ownership, item ownership, quest state and energy before acting.
- Rate-limit pulls, battles, chat, trades and mail claims.
- Use idempotency keys for every grant.
- Record RNG seed, content version and result hash for gacha and battles.
- Detect impossible travel, impossible currency velocity and duplicated items.
- Sign high-value responses (pull results, battle results, purchases).
- Rotate keys; use short-lived service credentials.

### Anti-fraud signals

- New-account trade restrictions.
- Price bands and trade cooldowns.
- Same-device/multi-account graph analysis.
- Currency faucet anomalies by account and region.
- Chargeback and refund handling.
- Shadow restrictions for suspected RMT before hard bans.

### Privacy and compliance

- GDPR/CCPA data export and deletion.
- Data retention policy for chat, logs and replays.
- Age gate and parental consent where required.
- Loot-box odds disclosure and regional rules.
- Platform IAP rules; do not bypass store billing.
- PCI scope minimized by using platform/store payment flows.
- Accessibility and localization requirements tracked in Phases 14–15.

---

## 7. Migration from the local save

The current local save is useful for the offline slice and for a one-time beta migration, but it is **not trustworthy**.

Recommended migration:

1. User creates an account and proves control of the device/save.
2. Client uploads the local save with a one-time migration token.
3. Server validates schema, clamps values to legal ranges, rejects unknown content IDs and checks for obvious tampering (e.g., impossible playtime, negative quantities, duplicate UIDs).
4. Server creates server-side rows in a transaction.
5. Server returns a fresh bootstrap snapshot.
6. Client marks the local save as migrated and stops using it as authority.
7. Keep the original local file for support/debugging with user consent.

Do not allow repeated migrations from the same account. Do not merge arbitrary local saves into an existing online account without a support policy.

---

## 8. Deployment and operations

### Environments

- `dev` — local Postgres/Redis via Docker Compose.
- `staging` — production-like, used for load tests and store review builds.
- `prod` — multi-AZ database, backups, monitoring.

### Topology

```text
Client
  │ HTTPS / WSS
  ▼
CDN + WAF
  ▼
API gateway (stateless, autoscaled)
  ├─ auth / players / content
  ├─ gacha / inventory / quests
  ├─ battles (CPU pool)
  ├─ social / economy
  └─ admin (separate network + SSO)
        │
        ├─ PostgreSQL primary + read replicas
        ├─ Redis (locks, cache, rate limits)
        ├─ NATS / Redis Streams
        └─ S3-compatible storage
```

### Reliability targets (initial)

| Metric | Target |
| --- | --- |
| API availability | 99.9% monthly |
| p95 read latency | < 150 ms |
| p95 mutation latency | < 300 ms |
| Gacha/battle claim success | 99.99% with idempotent retry |
| RPO | ≤ 5 minutes |
| RTO | ≤ 1 hour |

### Observability

- Structured JSON logs with request ID, account ID (hashed where appropriate), route, latency, result.
- Traces for gacha, battle action, trade and claim paths.
- Metrics: pull counts by rarity, currency faucets/sinks, battle win rate, error rate, queue depth.
- Alerts: failed grants, pity lock contention, DB replication lag, unusual currency velocity.
- Dashboards for live ops and support.

### Backups and recovery

- Automated daily full backups + point-in-time recovery.
- Restore drills quarterly.
- Separate backup account/region.
- Test migrations on a production-sized snapshot.

---

## 9. Build order for Phase 12

1. Postgres schema + migrations + seed content version.
2. Auth and bootstrap.
3. Server-owned currencies, inventory, roster and party.
4. Server gacha with pity and audit.
5. Quest state and reward claims.
6. Server battle simulation and claim.
7. Local-save migration.
8. Social, mail and guilds.
9. Trading/marketplace with escrow and fraud controls.
10. Load tests, pen test, launch review.

Do not open trading, PvP or premium purchases before steps 1–7 are proven under load and abuse testing.

---

## 10. What this document does not claim

- No backend service is implemented in this repository.
- No database is deployed.
- No authentication, payment, anti-cheat or moderation system exists yet.
- The SQL schema is a starting point and must be reviewed by an experienced backend/security engineer before production use.
- The client’s local save is editable and must never be treated as authoritative once online features exist.
