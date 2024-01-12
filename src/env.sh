# GCS_BUCKET=dev-postgresql-backup
# GCS_PREFIX=backup
# POSTGRES_HOST=127.0.0.1
# POSTGRES_DATABASE=postgres
# POSTGRES_USER=user
# POSTGRES_PASSWORD=password
# POSTGRES_PORT=5432
# PGDUMP_EXTRA_OPTS=
# gcloud_args=
# BACKUP_KEEP_DAYS=3
# PASSPHRASE=passphrase

if [ -z "$GCS_BUCKET" ]; then
  echo "You need to set the GCS_BUCKET environment variable."
  exit 1
fi

if [ -z "$POSTGRES_DATABASE" ]; then
  echo "You need to set the POSTGRES_DATABASE environment variable."
  exit 1
fi

if [ -z "$POSTGRES_HOST" ]; then
  # https://docs.docker.com/network/links/#environment-variables
  if [ -n "$POSTGRES_PORT_5432_TCP_ADDR" ]; then
    POSTGRES_HOST=$POSTGRES_PORT_5432_TCP_ADDR
    POSTGRES_PORT=$POSTGRES_PORT_5432_TCP_PORT
  else
    echo "You need to set the POSTGRES_HOST environment variable."
    exit 1
  fi
fi

if [ -z "$POSTGRES_USER" ]; then
  echo "You need to set the POSTGRES_USER environment variable."
  exit 1
fi

if [ -z "$POSTGRES_PASSWORD" ]; then
  echo "You need to set the POSTGRES_PASSWORD environment variable."
  exit 1
fi

if [ -n "$GCS_SERVICE_ACCOUNT" ]; then
  echo $GCS_SERVICE_ACCOUNT | base64 -d > service-account-key.json
  GCS_ARGS="-q -m -o Credentials:gs_service_key_file=service-account-key.json"
fi

export PGPASSWORD=$POSTGRES_PASSWORD
