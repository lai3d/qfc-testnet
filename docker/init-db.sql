-- QFC Explorer Database Initialization

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Blocks table
CREATE TABLE IF NOT EXISTS blocks (
    number BIGINT PRIMARY KEY,
    hash VARCHAR(66) UNIQUE NOT NULL,
    parent_hash VARCHAR(66) NOT NULL,
    timestamp BIGINT NOT NULL,
    producer VARCHAR(42) NOT NULL,
    gas_used BIGINT NOT NULL,
    gas_limit BIGINT NOT NULL,
    transaction_count INT NOT NULL DEFAULT 0,
    size INT,
    extra_data TEXT,
    state_root VARCHAR(66),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Aliases for explorer compatibility
    height BIGINT GENERATED ALWAYS AS (number) STORED,
    timestamp_ms BIGINT GENERATED ALWAYS AS (timestamp) STORED
);

CREATE INDEX IF NOT EXISTS idx_blocks_hash ON blocks(hash);
CREATE INDEX IF NOT EXISTS idx_blocks_timestamp ON blocks(timestamp);
CREATE INDEX IF NOT EXISTS idx_blocks_producer ON blocks(producer);

-- Transactions table
CREATE TABLE IF NOT EXISTS transactions (
    hash VARCHAR(66) PRIMARY KEY,
    block_number BIGINT REFERENCES blocks(number),
    block_hash VARCHAR(66),
    transaction_index INT,
    "from" VARCHAR(42) NOT NULL,
    "to" VARCHAR(42),
    value NUMERIC(78, 0) NOT NULL DEFAULT 0,
    gas_price NUMERIC(78, 0),
    gas_limit BIGINT,
    gas_used BIGINT,
    nonce BIGINT NOT NULL,
    input TEXT,
    status INT,
    contract_address VARCHAR(42),
    timestamp BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Aliases for explorer compatibility
    block_height BIGINT GENERATED ALWAYS AS (block_number) STORED,
    from_address VARCHAR(42) GENERATED ALWAYS AS ("from") STORED,
    to_address VARCHAR(42) GENERATED ALWAYS AS ("to") STORED
);

CREATE INDEX IF NOT EXISTS idx_tx_block ON transactions(block_number);
CREATE INDEX IF NOT EXISTS idx_tx_from ON transactions("from");
CREATE INDEX IF NOT EXISTS idx_tx_to ON transactions("to");
CREATE INDEX IF NOT EXISTS idx_tx_timestamp ON transactions(timestamp);

-- Accounts table
CREATE TABLE IF NOT EXISTS accounts (
    address VARCHAR(42) PRIMARY KEY,
    balance NUMERIC(78, 0) NOT NULL DEFAULT 0,
    nonce BIGINT NOT NULL DEFAULT 0,
    is_contract BOOLEAN DEFAULT FALSE,
    contract_code TEXT,
    first_seen_block BIGINT,
    last_seen_block BIGINT,
    transaction_count INT DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_accounts_balance ON accounts(balance DESC);

-- Tokens table (ERC-20)
CREATE TABLE IF NOT EXISTS tokens (
    address VARCHAR(42) PRIMARY KEY,
    name VARCHAR(255),
    symbol VARCHAR(32),
    decimals INT,
    total_supply NUMERIC(78, 0),
    holder_count INT DEFAULT 0,
    transfer_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Token balances
CREATE TABLE IF NOT EXISTS token_balances (
    id SERIAL PRIMARY KEY,
    token_address VARCHAR(42) NOT NULL,
    holder_address VARCHAR(42) NOT NULL,
    balance NUMERIC(78, 0) NOT NULL DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(token_address, holder_address)
);

CREATE INDEX IF NOT EXISTS idx_token_balances_holder ON token_balances(holder_address);

-- Validators table
CREATE TABLE IF NOT EXISTS validators (
    address VARCHAR(42) PRIMARY KEY,
    moniker VARCHAR(255),
    total_stake NUMERIC(78, 0) NOT NULL DEFAULT 0,
    self_stake NUMERIC(78, 0) NOT NULL DEFAULT 0,
    delegated_stake NUMERIC(78, 0) NOT NULL DEFAULT 0,
    commission INT DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active',
    contribution_score DECIMAL(10, 4) DEFAULT 0,
    uptime DECIMAL(5, 2) DEFAULT 100,
    blocks_produced BIGINT DEFAULT 0,
    blocks_missed BIGINT DEFAULT 0,
    registered_at BIGINT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexer state
CREATE TABLE IF NOT EXISTS indexer_state (
    key VARCHAR(255) PRIMARY KEY,
    value TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert initial state
INSERT INTO indexer_state (key, value) VALUES
    ('last_indexed_block', '0'),
    ('indexer_version', '1.0.0')
ON CONFLICT (key) DO NOTHING;

-- Create function to update timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers
CREATE TRIGGER update_accounts_timestamp
    BEFORE UPDATE ON accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_validators_timestamp
    BEFORE UPDATE ON validators
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
