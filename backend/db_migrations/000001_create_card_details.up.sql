CREATE TABLE IF NOT EXISTS cards
(
    id               TEXT PRIMARY KEY,
    text             TEXT NOT NULL,
    title_color      INT,
    type             TEXT,
    password         TEXT,
    red              INT,
    green            INT,
    blue             INT,
    tags             TEXT[],
    note             TIMESTAMP,
    image_front      BYTEA,
    image_back       BYTEA,
    last_modified_at TIMESTAMP
);
