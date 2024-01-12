FROM gcr.io/google.com/cloudsdktool/google-cloud-cli:alpine
ARG TARGETARCH

ADD src/install.sh install.sh
RUN sh install.sh && rm install.sh

ENV POSTGRES_DATABASE ''
ENV POSTGRES_HOST ''
ENV POSTGRES_PORT 5432
ENV POSTGRES_USER ''
ENV POSTGRES_PASSWORD ''
ENV PGDUMP_EXTRA_OPTS ''
ENV GCS_BUCKET ''
ENV GCS_REGION 'asia-east-1'
ENV GCS_PATH 'backup'
ENV GCS_ENDPOINT ''
ENV GCS_ARGS ''
ENV GCS_SERVICE_ACCOUNT ''
ENV SCHEDULE ''
ENV PASSPHRASE ''
ENV BACKUP_KEEP_DAYS ''


ADD src/run.sh run.sh
ADD src/env.sh env.sh
ADD src/backup.sh backup.sh
ADD src/restore.sh restore.sh

CMD ["sh", "run.sh"]
