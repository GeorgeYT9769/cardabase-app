CREATE TABLE IF NOT EXISTS cards
(
    id               TEXT PRIMARY KEY,
    last_modified_at TIMESTAMP,
    data             JSONB
);
