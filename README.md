## Docker / Production

The app is published as a Docker image to [Docker Hub](https://hub.docker.com/r/brandiit/reelix-manager).

### Pull and run

```bash
docker pull brandiit/reelix-manager:latest

docker run -d \
  -p 80:80 \
  -e RAILS_MASTER_KEY=<value from config/master.key> \
  -v reelix_storage:/rails/storage \
  --name reelix-manager \
  brandiit/reelix-manager:latest
```

### Environment variables

| Variable | Required | Description |
|---|---|---|
| `RAILS_MASTER_KEY` | ✅ Yes | Contents of `config/master.key` — decrypts credentials |

### Persistent storage

SQLite databases are stored in `/rails/storage` inside the container. Mount a Docker volume
(or bind mount a host directory) to persist data across container restarts:

```bash
-v reelix_storage:/rails/storage
```

### Image tags

| Tag | Published when |
|---|---|
| `latest` | Every push to the `main` branch |
| `v1.2.3` | When a `v*.*.*` git tag is pushed |

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
