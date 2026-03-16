## Docker / Production

The app is published as a Docker image to [Docker Hub](https://hub.docker.com/r/brandiit/reelix-manager).

### Pull and run

```bash
docker pull brandiit/reelix-manager:latest

docker run -d \
  -p 80:80 \
  -v reelix_storage:/rails/storage \
  --name reelix-manager \
  brandiit/reelix-manager:latest
```

### Environment variables

None required for a standard setup.

### Persistent storage

SQLite databases are stored in `/rails/storage` inside the container. Mount a Docker volume
(or bind mount a host directory) to persist data across container restarts:

```bash
-v reelix_storage:/rails/storage
```

### Docker Compose

Create a `docker-compose.yml` file:

```yaml
services:
  reelix-manager:
    image: brandiit/reelix-manager:latest
    ports:
      - "80:80"
    volumes:
      - reelix_storage:/rails/storage
    restart: unless-stopped

volumes:
  reelix_storage:
```

Then start it with:

```bash
docker compose up -d
```

To update to the latest image:

```bash
docker compose pull && docker compose up -d
```



The recommended tag for most users is **`latest`** — it always points to the most recent release.

| Tag | Published when |
|---|---|
| `latest` | Every push to `main` (tracks the most recent release) |
| `v1.2.3` | When the `VERSION` file is updated on `main` |
| `1.2` | Floating tag for the latest patch of a minor version |

```bash
docker pull brandiit/reelix-manager:latest
```

---

# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
