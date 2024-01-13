# Introduction

This project provides Docker images to periodically back up a PostgreSQL database to GCP GCS, and to restore from the backup as needed.
This repo is fork from [eeshugerman/postgres-backup-s3](https://github.com/eeshugerman/postgres-backup-s3).

# Usage

## Backup

```yaml
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password

  backup:
    image: alexhsieh8888/postgres-backup-gcp-gcs:latest
    environment:
      SCHEDULE: '@weekly'     # optional
      BACKUP_KEEP_DAYS: 7     # optional
      PASSPHRASE: passphrase  # optional
      GCS_BUCKET: dev-postgresql-backup
      GCS_PREFIX: backup
      GCS_SERVICE_ACCOUNT:
      POSTGRES_HOST: postgres
      POSTGRES_DATABASE: postgres
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
```

* Images are tagged by the alpine image.
* The `SCHEDULE` variable determines backup frequency. See go-cron schedules documentation [here](http://godoc.org/github.com/robfig/cron#hdr-Predefined_schedules). Omit to run the backup immediately and then exit.
* If `PASSPHRASE` is provided, the backup will be encrypted using GPG.
* Run `docker exec <container name> sh backup.sh` to trigger a backup ad-hoc.
* If `BACKUP_KEEP_DAYS` is set, backups older than this many days will be deleted from GCS.
* Set `GCS_ENDPOINT` if you're using a non-GCP GCS-compatible storage provider.
* The docker can be mounted by gcs service account with base 64. Or, you can use workload identity to grant kubernetes service account.
* [Docker Image](https://hub.docker.com/repository/docker/alexhsieh8888/postgres-backup-gcp-gcs/general)

## Restore

> **WARNING:** DATA LOSS! All database objects will be dropped and re-created.

### ... from latest backup

```sh
docker exec <container name> sh restore.sh
```

> **NOTE:** If your bucket has more than a 1000 files, the latest may not be restored -- only one GCS `ls` command is used

### ... from specific backup

```sh
docker exec <container name> sh restore.sh <timestamp>
```

# Development

## Build the image locally

See [ `build-and-push-images.yml` ](.github/workflows/build-and-push-images.yml) for mapping.

```sh
DOCKER_BUILDKIT=1 docker build .
```

## Run a simple test environment with Docker Compose

```sh
cp template.env .env
# fill out your secrets/params in .env
docker compose up -d
```

# Acknowledgements

This project is a fork and re-structuring of @schickling's [postgres-backup-gcs](https://github.com/schickling/dockerfiles/tree/master/postgres-backup-gcs) and [postgres-restore-gcs](https://github.com/schickling/dockerfiles/tree/master/postgres-restore-gcs).

## Fork goals

These changes would have been difficult or impossible merge into @schickling's repo or similarly-structured forks.
  + dedicated repository
  + automated builds
  + backup and restore with one image

## Other changes and features

  + some environment variables renamed or removed
  + uses `pg_dump`'s `custom` format (see [docs](https://www.postgresql.org/docs/10/app-pgdump.html))
  + drop and re-create all database objects on restore
  + backup blobs and all schemas by default
  + no Python 2 dependencies
  + filter backups on GCS by database name
  + support encrypted (password-protected) backups
  + support for restoring from a specific backup by timestamp
  + support for auto-removal of old backups
