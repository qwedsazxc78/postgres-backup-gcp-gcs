#! /bin/sh

set -eu
set -o pipefail

source ./env.sh

echo "Creating backup of $POSTGRES_DATABASE database..."
pg_dump --format=custom \
        -h $POSTGRES_HOST \
        -p $POSTGRES_PORT \
        -U $POSTGRES_USER \
        -d $POSTGRES_DATABASE \
        $PGDUMP_EXTRA_OPTS \
        > db.dump

timestamp=$(date +"%Y-%m-%dT%H:%M:%S")
gcs_uri_base="gs://${GCS_BUCKET}/${GCS_PREFIX}/${POSTGRES_DATABASE}_${timestamp}.dump"

if [ -n "$PASSPHRASE" ]; then
  echo "Encrypting backup..."
  rm -f db.dump.gpg
  gpg --symmetric --batch --passphrase "$PASSPHRASE" db.dump
  rm db.dump
  local_file="db.dump.gpg"
  gcs_uri="${gcs_uri_base}.gpg"
else
  local_file="db.dump"
  gcs_uri="$gcs_uri_base"
fi

echo "Uploading backup to $GCS_BUCKET... $gcs_uri"
gsutil $GCS_ARGS cp "$local_file" "$gcs_uri"
rm "$local_file"

echo "Backup complete."

if [ -n "$BACKUP_KEEP_DAYS" ]; then
  sec=$((86400*BACKUP_KEEP_DAYS))
  date_from_remove=$(date -d "@$(($(date +%s) - sec))" +%Y-%m-%d)

  echo "Removing old backups from gs://${GCS_BUCKET}/${GCS_PREFIX}..."
  gsutil $GCS_ARGS ls "gs://${GCS_BUCKET}/${GCS_PREFIX}" | while read -r line; do
    file_date=$(gsutil $GCS_ARGS stat "$line" | grep "Creation time:" | awk '{print $3}')
    if [[ $file_date < $date_from_remove ]]; then
      echo "Removing $line"
      gsutil $GCS_ARGS rm "$line"
    fi
  done
  echo "Removal complete."
fi
