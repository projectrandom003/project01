-- ============================================================================
-- PROJECT FANTASY — proposed PostgreSQL schema (Phase 12+)
-- ============================================================================
-- This is a design artifact, not a deployed migration. Review with a backend
-- and security engineer before production. It assumes PostgreSQL 16+.
--
-- Principles:
--   * UUIDs for player-facing entities; bigint identity for append-only ledgers.
--   * Currencies and items are ledgered; balance tables are reconciled caches.
--   * Every grant/mutation carries an idempotency key where retries are possible.
--   * Gacha and battle results are append-only and auditable.
--   * Content definitions are versioned and pinned per session/battle/pull.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---------------------------------------------------------------------------
-- Shared updated_at trigger
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- Accounts and sessions
-- ---------------------------------------------------------------------------
CREATE TABLE accounts (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email           text NOT NULL,
    password_hash   text NOT NULL,
    status          text NOT NULL DEFAULT 'active'
                    CHECK (status IN ('active', 'suspended', 'banned', 'deleted')),
    locale          text NOT NULL DEFAULT 'en',
    country_code    char(2),
    birth_date      date,
    email_verified  boolean NOT NULL DEFAULT false,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    last_login_at   timestamptz
);

CREATE UNIQUE INDEX accounts_email_lower_uq ON accounts (lower(email));
CREATE INDEX accounts_status_idx ON accounts (status);

CREATE TRIGGER accounts_set_updated_at
BEFORE UPDATE ON accounts
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE account_sessions (
    id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id          uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
    refresh_token_hash  text NOT NULL,
    device_id           text,
    user_agent          text,
    ip_address          inet,
    created_at          timestamptz NOT NULL DEFAULT now(),
    last_used_at        timestamptz,
    expires_at          timestamptz NOT NULL,
    revoked_at          timestamptz
);

CREATE UNIQUE INDEX account_sessions_token_uq ON account_sessions (refresh_token_hash);
CREATE INDEX account_sessions_account_idx ON account_sessions (account_id, expires_at DESC);

-- ---------------------------------------------------------------------------
-- Content versioning
-- ---------------------------------------------------------------------------
CREATE TABLE content_versions (
    id              text PRIMARY KEY,              -- e.g. '2026.11.1'
    manifest_hash   text NOT NULL,
    manifest        jsonb NOT NULL DEFAULT '{}'::jsonb,
    is_active       boolean NOT NULL DEFAULT false,
    created_at      timestamptz NOT NULL DEFAULT now(),
    activated_at    timestamptz
);

CREATE UNIQUE INDEX content_versions_one_active
ON content_versions (is_active)
WHERE is_active;

-- ---------------------------------------------------------------------------
-- Players
-- ---------------------------------------------------------------------------
CREATE TABLE players (
    id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id          uuid NOT NULL UNIQUE REFERENCES accounts (id) ON DELETE CASCADE,
    name                text NOT NULL,
    level               integer NOT NULL DEFAULT 1 CHECK (level >= 1 AND level <= 60),
    xp                  bigint NOT NULL DEFAULT 0 CHECK (xp >= 0),
    flags               jsonb NOT NULL DEFAULT '{}'::jsonb,
    settings            jsonb NOT NULL DEFAULT '{}'::jsonb,
    content_version_id  text REFERENCES content_versions (id),
    position_x          real,
    position_y          real,
    created_at          timestamptz NOT NULL DEFAULT now(),
    updated_at          timestamptz NOT NULL DEFAULT now(),
    last_seen_at        timestamptz
);

CREATE UNIQUE INDEX players_name_lower_uq ON players (lower(name));
CREATE INDEX players_account_idx ON players (account_id);

CREATE TRIGGER players_set_updated_at
BEFORE UPDATE ON players
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------------
-- Currencies (definitions + balances + ledger)
-- ---------------------------------------------------------------------------
CREATE TABLE currencies (
    id              text PRIMARY KEY,              -- 'gold', 'crystals', ...
    display_name    text NOT NULL,
    category        text NOT NULL DEFAULT 'currency',
    is_premium      boolean NOT NULL DEFAULT false,
    created_at      timestamptz NOT NULL DEFAULT now()
);

INSERT INTO currencies (id, display_name, is_premium) VALUES
    ('gold',          'Gold',               false),
    ('gems',          'Gems',               true),
    ('crystals',      'Summoning Crystals', false),
    ('guild_tokens',  'Guild Tokens',       false),
    ('ancient_coins', 'Ancient Coins',      false),
    ('event_tokens',  'Event Tokens',       false)
ON CONFLICT (id) DO NOTHING;

CREATE TABLE player_currencies (
    player_id       uuid NOT NULL REFERENCES players (id) ON DELETE CASCADE,
    currency_id     text NOT NULL REFERENCES currencies (id),
    balance         bigint NOT NULL DEFAULT 0 CHECK (balance >= 0),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (player_id, currency_id)
);

CREATE TRIGGER player_currencies_set_updated_at
BEFORE UPDATE ON player_currencies
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE currency_ledger (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    player_id       uuid NOT NULL REFERENCES players (id) ON DELETE CASCADE,
    currency_id     text NOT NULL REFERENCES currencies (id),
    delta           bigint NOT NULL CHECK (delta <> 0),
    balance_after   bigint NOT NULL CHECK (balance_after >= 0),
    reason          text NOT NULL,                 -- 'gacha_pull', 'quest_reward', ...
    ref_type        text,                          -- 'gacha_pull', 'battle', 'trade', ...
    ref_id          text,
    idempotency_key text,
    created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX currency_ledger_idem_uq
ON currency_ledger (player_id, idempotency_key)
WHERE idempotency_key IS NOT NULL;

CREATE INDEX currency_ledger_player_time_idx ON currency_ledger (player_id, created_at DESC);
CREATE INDEX currency_ledger_ref_idx ON currency_ledger (ref_type, ref_id);

-- ---------------------------------------------------------------------------
-- Items, inventory and equipment
-- ---------------------------------------------------------------------------
CREATE TABLE items (
    id              text PRIMARY KEY,              -- 'glade_sap', 'sunfire_blade', ...
    display_name    text NOT NULL,
    category        text NOT NULL
                    CHECK (category IN ('currency', 'material', 'equipment', 'consumable')),
    rarity          text NOT NULL DEFAULT 'common'
                    CHECK (rarity IN ('common', 'rare', 'epic', 'legendary', 'mythic')),
    slot            text CHECK (slot IN ('weapon', 'armor', 'accessory')),
    metadata        jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE inventory_items (
    player_id       uuid NOT NULL REFERENCES players (id) ON DELETE CASCADE,
    item_id         text NOT NULL REFERENCES items (id),
    quantity        bigint NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (player_id, item_id)
);

CREATE TRIGGER inventory_items_set_updated_at
BEFORE UPDATE ON inventory_items
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE item_ledger (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    player_id       uuid NOT NULL REFERENCES players (id) ON DELETE CASCADE,
    item_id         text NOT NULL REFERENCES items (id),
    delta           bigint NOT NULL CHECK (delta <> 0),
    quantity_after  bigint NOT NULL CHECK (quantity_after >= 0),
    reason          text NOT NULL,
    ref_type        text,
    ref_id          text,
    idempotency_key text,
    created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX item_ledger_idem_uq
ON item_ledger (player_id, idempotency_key)
WHERE idempotency_key IS NOT NULL;

CREATE INDEX item_ledger_player_time_idx ON item_ledger (player_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- Owned characters, equipment and party
-- ---------------------------------------------------------------------------
CREATE TABLE owned_characters (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id       uuid NOT NULL REFERENCES players (id) ON DELETE CASCADE,
    char_id         text NOT NULL,                 -- content character id
    level           integer NOT NULL DEFAULT 1 CHECK (level >= 1),
    xp              bigint NOT NULL DEFAULT 0 CHECK (xp >= 0),
    ascension       integer NOT NULL DEFAULT 0 CHECK (ascension BETWEEN 0 AND 3),
    awakening       integer NOT NULL DEFAULT 0 CHECK (awakening BETWEEN 0 AND 5),
    bond            integer NOT NULL DEFAULT 0 CHECK (bond >= 0),
    dupes           integer NOT NULL DEFAULT 0 CHECK (dupes >= 0),
    acquired_at     timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    UNIQUE (player_id, char_id),
    UNIQUE (player_id, id)
);

CREATE INDEX owned_characters_player_idx ON owned_characters (player_id, level DESC);

CREATE TRIGGER owned_characters_set_updated_at
BEFORE UPDATE ON owned_characters
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE character_equipment (
    player_id       uuid NOT NULL REFERENCES players (id) ON DELETE CASCADE,
    character_id    uuid NOT NULL,
    slot            text NOT NULL CHECK (slot IN ('weapon', 'armor', 'accessory')),
    item_id         text NOT NULL REFERENCES items (id),
    equipped_at     timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (character_id, slot),
    FOREIGN KEY (player_id, character_id)
        REFERENCES owned_characters (player_id, id) ON DELETE CASCADE
);

CREATE TABLE party_members (
    player_id       uuid NOT NULL REFERENCES players (id) ON DELETE CASCADE,
    slot            smallint NOT NULL CHECK (slot BETWEEN 1 AND 4),
    character_id    uuid NOT NULL,
    added_at        timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (player_id, slot),
    UNIQUE (player_id, character_id),
    FOREIGN KEY (player_id, character_id)
        REFERENCES owned_characters (player_id, id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------------
-- Quests
-- ---------------------------------------------------------------------------
CREATE TABLE player_quests (
    player_id       uuid NOT NULL REFERENCES players (id) ON DELETE CASCADE,
    quest_id        text NOT NULL,
    state           text NOT NULL DEFAULT 'active'
                    CHECK (state IN ('not_started', 'active', 'complete', 'abandoned')),
    step            integer NOT NULL DEFAULT 0 CHECK (step >= 0),
    progress        integer NOT NULL DEFAULT 0 CHECK (progress >= 0),
    started_at      timestamptz,
    completed_at    timestamptz,
    updated_at      timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (player_id, quest_id)
);

CREATE TRIGGER player_quests_set_updated_at
BEFORE UPDATE ON player_quests
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------------
-- Gacha: pity, pull audit, per-pull results
-- ---------------------------------------------------------------------------
CREATE TABLE banner_pity (
    player_id       uuid NOT NULL REFERENCES players (id) ON DELETE CASCADE,
    banner_id       text NOT NULL,
    legendary       integer NOT NULL DEFAULT 0 CHECK (legendary >= 0),
    featured        integer NOT NULL DEFAULT 0 CHECK (featured >= 0),
    epic_streak     integer NOT NULL DEFAULT 0 CHECK (epic_streak >= 0),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (player_id, banner_id)
);

CREATE TRIGGER banner_pity_set_updated_at
BEFORE UPDATE ON banner_pity
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE gacha_pulls (
    id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id           uuid NOT NULL REFERENCES players (id) ON DELETE CASCADE,
    banner_id           text NOT NULL,
    content_version_id  text NOT NULL REFERENCES content_versions (id),
    pull_count          integer NOT NULL CHECK (pull_count IN (1, 10)),
    currency_id         text NOT NULL REFERENCES currencies (id),
    cost                bigint NOT NULL CHECK (cost >= 0),
    pity_before         jsonb NOT NULL,
    pity_after          jsonb NOT NULL,
    result_hash         text NOT NULL,
    idempotency_key     text NOT NULL,
    created_at          timestamptz NOT NULL DEFAULT now(),
    UNIQUE (player_id, idempotency_key)
);

CREATE INDEX gacha_pulls_player_time_idx ON gacha_pulls (player_id, created_at DESC);

CREATE TABLE gacha_pull_results (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pull_id         uuid NOT NULL REFERENCES gacha_pulls (id) ON DELETE CASCADE,
    roll_index      integer NOT NULL CHECK (roll_index >= 0),
    character_id    text NOT NULL,
    rarity          text NOT NULL
                    CHECK (rarity IN ('common', 'rare', 'epic', 'legendary', 'mythic')),
    featured        boolean NOT NULL DEFAULT false,
    is_new          boolean NOT NULL DEFAULT false,
    awakening_gain  integer NOT NULL DEFAULT 0 CHECK (awakening_gain >= 0),
    UNIQUE (pull_id, roll_index)
);

-- ---------------------------------------------------------------------------
-- Battles and rewards
-- ---------------------------------------------------------------------------
CREATE TABLE battles (
    id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id           uuid NOT NULL REFERENCES players (id) ON DELETE CASCADE,
    group_id            text NOT NULL,
    content_version_id  text NOT NULL REFERENCES content_versions (id),
    seed                text NOT NULL,
    status              text NOT NULL DEFAULT 'active'
                        CHECK (status IN ('active', 'victory', 'defeat', 'abandoned', 'expired')),
    state               jsonb NOT NULL DEFAULT '{}'::jsonb,
    result_hash         text,
    idempotency_key     text,
    started_at          timestamptz NOT NULL DEFAULT now(),
    ended_at            timestamptz,
    UNIQUE (player_id, idempotency_key)
);

CREATE INDEX battles_player_status_idx ON battles (player_id, status, started_at DESC);

CREATE TABLE battle_events (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    battle_id       uuid NOT NULL REFERENCES battles (id) ON DELETE CASCADE,
    sequence        integer NOT NULL CHECK (sequence >= 0),
    event           jsonb NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    UNIQUE (battle_id, sequence)
);

CREATE TABLE battle_rewards (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    battle_id       uuid NOT NULL UNIQUE REFERENCES battles (id) ON DELETE CASCADE,
    player_id       uuid NOT NULL REFERENCES players (id) ON DELETE CASCADE,
    rewards         jsonb NOT NULL,
    idempotency_key text NOT NULL,
    granted_at      timestamptz NOT NULL DEFAULT now(),
    UNIQUE (player_id, idempotency_key)
);

-- ---------------------------------------------------------------------------
-- Trading and marketplace
-- ---------------------------------------------------------------------------
CREATE TABLE trades (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    status          text NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'accepted', 'completed', 'cancelled', 'expired')),
    created_by      uuid NOT NULL REFERENCES players (id),
    idempotency_key text NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    accepted_at     timestamptz,
    completed_at    timestamptz,
    UNIQUE (created_by, idempotency_key)
);

CREATE TABLE trade_participants (
    trade_id        uuid NOT NULL REFERENCES trades (id) ON DELETE CASCADE,
    player_id       uuid NOT NULL REFERENCES players (id),
    side            char(1) NOT NULL CHECK (side IN ('a', 'b')),
    confirmed       boolean NOT NULL DEFAULT false,
    PRIMARY KEY (trade_id, player_id),
    UNIQUE (trade_id, side)
);

CREATE TABLE trade_offers (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trade_id        uuid NOT NULL REFERENCES trades (id) ON DELETE CASCADE,
    player_id       uuid NOT NULL REFERENCES players (id),
    item_id         text REFERENCES items (id),
    currency_id     text REFERENCES currencies (id),
    quantity        bigint NOT NULL CHECK (quantity > 0),
    CHECK (
        (item_id IS NOT NULL AND currency_id IS NULL)
        OR (item_id IS NULL AND currency_id IS NOT NULL)
    )
);

CREATE INDEX trade_offers_trade_idx ON trade_offers (trade_id);

CREATE TABLE market_listings (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id       uuid NOT NULL REFERENCES players (id) ON DELETE CASCADE,
    item_id         text NOT NULL REFERENCES items (id),
    quantity        bigint NOT NULL CHECK (quantity > 0),
    price_currency  text NOT NULL REFERENCES currencies (id),
    price_amount    bigint NOT NULL CHECK (price_amount > 0),
    status          text NOT NULL DEFAULT 'active'
                    CHECK (status IN ('active', 'sold', 'cancelled', 'expired')),
    buyer_id        uuid REFERENCES players (id),
    idempotency_key text,
    created_at      timestamptz NOT NULL DEFAULT now(),
    sold_at         timestamptz,
    expires_at      timestamptz
);

CREATE INDEX market_listings_active_idx ON market_listings (status, item_id, price_amount);
CREATE INDEX market_listings_seller_idx ON market_listings (seller_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- Guilds
-- ---------------------------------------------------------------------------
CREATE TABLE guilds (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name            text NOT NULL,
    tag             text NOT NULL,
    leader_id       uuid NOT NULL REFERENCES players (id),
    level           integer NOT NULL DEFAULT 1 CHECK (level >= 1),
    xp              bigint NOT NULL DEFAULT 0 CHECK (xp >= 0),
    description     text NOT NULL DEFAULT '',
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX guilds_name_lower_uq ON guilds (lower(name));
CREATE UNIQUE INDEX guilds_tag_lower_uq ON guilds (lower(tag));

CREATE TRIGGER guilds_set_updated_at
BEFORE UPDATE ON guilds
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE guild_members (
    guild_id        uuid NOT NULL REFERENCES guilds (id) ON DELETE CASCADE,
    player_id       uuid NOT NULL UNIQUE REFERENCES players (id) ON DELETE CASCADE,
    guild_rank      text NOT NULL DEFAULT 'member'
                    CHECK (guild_rank IN ('leader', 'officer', 'member')),
    joined_at       timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (guild_id, player_id)
);

CREATE TABLE guild_bank_ledger (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    guild_id        uuid NOT NULL REFERENCES guilds (id) ON DELETE CASCADE,
    player_id       uuid NOT NULL REFERENCES players (id),
    item_id         text REFERENCES items (id),
    currency_id     text REFERENCES currencies (id),
    delta           bigint NOT NULL,
    reason          text NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    CHECK (
        (item_id IS NOT NULL AND currency_id IS NULL)
        OR (item_id IS NULL AND currency_id IS NOT NULL)
    )
);

-- ---------------------------------------------------------------------------
-- Social graph and mail
-- ---------------------------------------------------------------------------
CREATE TABLE friendships (
    player_id       uuid NOT NULL REFERENCES players (id) ON DELETE CASCADE,
    friend_id       uuid NOT NULL REFERENCES players (id) ON DELETE CASCADE,
    status          text NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'accepted', 'declined', 'blocked')),
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (player_id, friend_id),
    CHECK (player_id <> friend_id)
);

CREATE TABLE blocks (
    player_id       uuid NOT NULL REFERENCES players (id) ON DELETE CASCADE,
    blocked_id      uuid NOT NULL REFERENCES players (id) ON DELETE CASCADE,
    created_at      timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (player_id, blocked_id),
    CHECK (player_id <> blocked_id)
);

CREATE TABLE mail (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id    uuid NOT NULL REFERENCES players (id) ON DELETE CASCADE,
    sender_id       uuid REFERENCES players (id),
    subject         text NOT NULL,
    body            text NOT NULL DEFAULT '',
    created_at      timestamptz NOT NULL DEFAULT now(),
    expires_at      timestamptz,
    read_at         timestamptz,
    claimed_at      timestamptz
);

CREATE INDEX mail_recipient_idx ON mail (recipient_id, created_at DESC);

CREATE TABLE mail_attachments (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    mail_id         uuid NOT NULL REFERENCES mail (id) ON DELETE CASCADE,
    item_id         text REFERENCES items (id),
    quantity        bigint CHECK (quantity > 0),
    currency_id     text REFERENCES currencies (id),
    amount          bigint CHECK (amount > 0),
    CHECK (
        (item_id IS NOT NULL AND quantity IS NOT NULL AND currency_id IS NULL AND amount IS NULL)
        OR (item_id IS NULL AND quantity IS NULL AND currency_id IS NOT NULL AND amount IS NOT NULL)
    )
);

-- ---------------------------------------------------------------------------
-- Audit and support
-- ---------------------------------------------------------------------------
CREATE TABLE audit_log (
    id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    actor_account_id    uuid REFERENCES accounts (id),
    action              text NOT NULL,
    target_type         text,
    target_id           text,
    details             jsonb NOT NULL DEFAULT '{}'::jsonb,
    ip_address          inet,
    created_at          timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX audit_log_target_idx ON audit_log (target_type, target_id, created_at DESC);
CREATE INDEX audit_log_actor_idx ON audit_log (actor_account_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- Operational notes
-- ---------------------------------------------------------------------------
-- 1. Content tables (items, currencies, banners, characters, skills) are seeded
--    from a signed content manifest. Banners themselves may live in content JSON
--    rather than a table; gacha_pulls stores banner_id + content_version_id.
-- 2. Use SELECT ... FOR UPDATE on player_currencies, banner_pity, inventory_items,
--    owned_characters and trade rows inside mutation transactions.
-- 3. Never store raw refresh tokens; store a strong hash.
-- 4. Never store client-provided currency balances or gacha results as truth.
-- 5. Partition currency_ledger, item_ledger, battle_events and audit_log by month
--    once volume requires it.
-- 6. Keep battle seeds and result hashes for dispute review and replay validation.
-- 7. Support adjustments require a ticket ID in audit_log.details.
