# Backend

This is a server application which allows to save loyalty cards in a database.

## Getting started

### Production

This server expects to be served behind a reverse proxy like traefik which
handles TLS termination and authorization.

Create a config file (eg: `cardabase_api_secrets.json`) on the server:

```json
{
  "db": {
    "connectionString": "user=postgres password=PLEASE_REPLACE_THIS_WITH_SOMETHING_SECURE host=db port=5432 dbname=postgres sslmode=disable"
  }
}
```

Create a database-password file (eg: `db_password.txt`) on the server:

```
PLEASE_REPLACE_THIS_WITH_SOMETHING_SECURE
```

Run the following docker compose-file (with the correct paths to the secrets
files).

> Warning: the docker container is not yet published so command below will
> not work

```yaml
services:
  cardabase:
    restart: 'always'
    image: cardabase:latest
    depends_on:
      - db
    ports:
      - "5054:5054"
    secrets:
      - cardabase_api_secrets
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    deploy:
      resources:
        limits:
          pids: 99

  db:
    restart: 'always'
    image: postgres:latest
    environment:
      PGUSER: postgres
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
      PGDATA: /data/postgres
    secrets:
      - db_password
    volumes:
      - /docker-volumes/db/data:/data/postgres
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready", "-d", "zitadel", "-U", "postgres"]
      interval: '10s'
      timeout: '30s'
      retries: 5
      start_period: '20s'

secrets:
  cardabase_api_secrets:
    file: cardabase_api_secrets.json
  db_password:
    file: db_password.txt
```

### Development

#### Tools

- Go sdk to compile the application (https://go.dev/doc/install)
- Docker and docker compose to start the database (https://docs.docker.com/get-started/get-docker/)
- Curl to make requests.

#### Start the server

1. Start the service dependencies: run `docker compose up -d` inside the 
   backend directory. 
2. Start the backend: run `go run .` inside the backend directory.

#### Make requests

- Create a card: `curl -H 'Content-Type: application/json' -X PUT -d '{ "text": "test shop2", "type": "ean13" }' http://localhost:5054/cards/my-card`
- Get a single card: `curl http://localhost:5054/cards/my-card`
- Get all cards: `curl http://localhost:5054/cards`
- Delete a card: `curl -X DELETE http://localhost:5054/cards/my-card`
