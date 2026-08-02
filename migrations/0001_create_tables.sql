-- +goose Up
-- Users & Auth
-- Enums
CREATE TYPE trip_visibility AS ENUM('private', 'public');

CREATE TYPE trip_member_role AS ENUM('viewer', 'editor');

CREATE TYPE trip_access_request_status AS ENUM('pending', 'accepted', 'rejected');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE,
    password_hash TEXT,
    display_name TEXT NOT NULL,
    avatar_url TEXT,
    is_guest BOOLEAN NOT NULL DEFAULT FALSE,
    guest_expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Trips
CREATE TABLE trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    name TEXT NOT NULL,
    notes TEXT,
    visibility trip_visibility NOT NULL DEFAULT 'private',
    start_date DATE,
    end_date DATE,
    CHECK (
        start_date IS NULL
        OR end_date IS NULL
        OR start_date <= end_date
    ),
    created_by UUID NOT NULL REFERENCES users (id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE trip_members (
    trip_id UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role trip_member_role NOT NULL DEFAULT 'editor',
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (trip_id, user_id)
);

CREATE TABLE trip_code_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    code TEXT NOT NULL UNIQUE,
    created_by UUID NOT NULL REFERENCES users (id),
    role trip_member_role NOT NULL DEFAULT 'viewer',
    max_uses INT CHECK (
        max_uses IS NULL
        OR max_uses > 0
    ),
    use_count INT NOT NULL DEFAULT 0 CHECK (use_count >= 0),
    CHECK (
        max_uses IS NULL
        OR use_count <= max_uses
    ),
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE trip_direct_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES users (id),
    role trip_member_role NOT NULL DEFAULT 'viewer',
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (trip_id, user_id)
);

CREATE TABLE trip_access_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role trip_member_role NOT NULL DEFAULT 'viewer',
    status trip_access_request_status NOT NULL DEFAULT 'pending',
    resolved_by UUID REFERENCES users (id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at TIMESTAMPTZ,
    UNIQUE (trip_id, user_id)
);

-- Destinations
CREATE TABLE destinations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    notes TEXT,
    lat NUMERIC(9, 6) CHECK (lat BETWEEN -90 AND 90),
    long NUMERIC(9, 6) CHECK (long BETWEEN -180 AND 180),
    position INT NOT NULL CHECK (position >= 0),
    starts_at TIMESTAMPTZ,
    ends_at TIMESTAMPTZ,
    CHECK (
        starts_at IS NULL
        OR ends_at IS NULL
        OR starts_at <= ends_at
    ),
    created_by UUID NOT NULL REFERENCES users (id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Itinerary
CREATE TABLE itinerary_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    destination_id UUID NOT NULL REFERENCES destinations (id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    notes TEXT,
    starts_at TIMESTAMPTZ,
    ends_at TIMESTAMPTZ,
    position INT NOT NULL CHECK (position >= 0),
    CHECK (
        starts_at IS NULL
        OR ends_at IS NULL
        OR starts_at <= ends_at
    ),
    created_by UUID NOT NULL REFERENCES users (id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Legs
CREATE TABLE legs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    from_destination_id UUID NOT NULL REFERENCES destinations (id) ON DELETE CASCADE,
    to_destination_id UUID NOT NULL REFERENCES destinations (id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    notes TEXT,
    distance NUMERIC(10, 2) CHECK (
        distance IS NULL
        OR distance >= 0
    ),
    cost NUMERIC(10, 2) CHECK (
        cost IS NULL
        OR cost >= 0
    ),
    created_by UUID NOT NULL REFERENCES users (id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (trip_id, from_destination_id, to_destination_id),
    CHECK (from_destination_id <> to_destination_id)
);

-- Geocode Cache
CREATE TABLE geocode_cache (
    query TEXT PRIMARY KEY,
    lat NUMERIC(9, 6) CHECK (lat BETWEEN -90 AND 90),
    long NUMERIC(9, 6) CHECK (long BETWEEN -180 AND 180),
    name TEXT NOT NULL,
    cached_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX ON trips (owner_id);

CREATE INDEX ON trip_access_requests (trip_id);

CREATE INDEX ON trip_direct_invites (trip_id);

CREATE INDEX ON trip_direct_invites (user_id);

CREATE INDEX ON trip_code_invites (trip_id);

CREATE INDEX ON trip_access_requests (user_id);

CREATE INDEX ON legs (trip_id);

CREATE INDEX ON trip_members (user_id);

CREATE INDEX ON destinations (trip_id);

CREATE INDEX ON itinerary_items (destination_id);

CREATE INDEX ON refresh_tokens (user_id);

CREATE INDEX ON users (is_guest, guest_expires_at)
WHERE
    is_guest = TRUE;

-- +goose Down
DROP TABLE IF EXISTS trip_access_requests;

DROP TABLE IF EXISTS trip_direct_invites;

DROP TABLE IF EXISTS trip_code_invites;

DROP TABLE IF EXISTS legs;

DROP TABLE IF EXISTS geocode_cache;

DROP TABLE IF EXISTS itinerary_items;

DROP TABLE IF EXISTS destinations;

DROP TABLE IF EXISTS trip_members;

DROP TABLE IF EXISTS trips;

DROP TABLE IF EXISTS refresh_tokens;

DROP TABLE IF EXISTS users;

DROP TYPE IF EXISTS trip_access_request_status;

DROP TYPE IF EXISTS trip_member_role;

DROP TYPE IF EXISTS trip_visibility;
