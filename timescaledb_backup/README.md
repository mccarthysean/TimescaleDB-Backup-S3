# postgres-backup-s3

Backup PostgresSQL to S3 (supports periodic backups)

## Usage

Docker:
```sh
$ docker run -e S3_ACCESS_KEY_ID=key -e S3_SECRET_ACCESS_KEY=secret -e S3_BUCKET=my-bucket -e S3_PREFIX=backup -e PGDATABASE=dbname -e PGUSER=user -e PGPASSWORD=password -e PGHOST=localhost schickling/postgres-backup-s3
```

Docker Compose:
```yaml
postgres:
  image: postgres
  environment:
    PGUSER: user
    PGPASSWORD: password

pgbackups3:
  image: schickling/postgres-backup-s3
  links:
    - postgres
  environment:
    SCHEDULE: '@daily'
    S3_REGION: region
    S3_ACCESS_KEY_ID: key
    S3_SECRET_ACCESS_KEY: secret
    S3_BUCKET: my-bucket
    S3_PREFIX: backup
    PGDATABASE: dbname
    PGUSER: user
    PGPASSWORD: password
    POSTGRES_BACKUP_EXTRA_OPTS: '--schema=public --blobs'
```

### Automatic Periodic Backups

You can additionally set the `SCHEDULE` environment variable like `-e SCHEDULE="@daily"` to run the backup automatically.

More information about the scheduling can be found [here](http://godoc.org/github.com/robfig/cron#hdr-Predefined_schedules).
