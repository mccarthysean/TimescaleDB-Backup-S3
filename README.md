# TimescaleDB-Backup-S3
For creating a Docker image that runs alongside the TimescaleDB container. It uses pg_dump to back up the container periodically, and then uploads the backup to an AWS S3 bucket

## Usage

Docker:
```sh
$ docker run -e AWS_ACCESS_KEY_ID=key -e AWS_SECRET_ACCESS_KEY=secret -e AWS_BUCKET=my-bucket -e AWS_DEFAULT_REGION=us-west-2 -e S3_PREFIX=subfolder -e PGDATABASE=dbname -e PGUSER=user -e PGPASSWORD=password -e PGHOST=localhost mccarthysean/timescaledb_backup_s3:12
```

See the docker-compose.example.yml file for typical usage, like below:
```yaml
  backup:
    # Choose 11 as the tag for TimescaleDB/PostgreSQL version 11, instead of 12
    image: mccarthysean/timescaledb_backup_s3:12
    env_file: .env
    environment:
      # Schedule this backup job to backup and upload to AWS S3 every so often
      SCHEDULE: '@daily' # or possibly '@every 1h'
      # Or use a more specific/flexible cron-type schedule:
      # SCHEDULE: '0 7 * * *'
      # * * * * * command(s)
      # - - - - -
      # | | | | |
      # | | | | ----- Day of week (0 - 7) (Sunday=0 or 7)
      # | | | ------- Month (1 - 12)
      # | | --------- Day of month (1 - 31)
      # | ----------- Hour (0 - 23)
      # ------------- Minute (0 - 59)
      # The AWS S3 bucket to which the backup file should be uploaded
      S3_BUCKET: backup-timescaledb
      # S3_PREFIX creates a sub-folder in the above AWS S3 bucket
      S3_PREFIX: daily-backups
      # EXTRA OPTIONS #######################################################################
      # --format custom outputs to a custom-format archive suitable for input into pg_restore
      # Together with the directory output format, this is the most flexible output format
      # in that it allows manual selection and reordering of archived items during restore.
      # This format is also compressed by default
      # "--create --clean" drops the database and recreates it
      # --if-exists adds "IF EXISTS" to the SQL where appropriate
      # --blobs includes large objects in the dump
      POSTGRES_BACKUP_EXTRA_OPTS: '--format custom --create --clean --if-exists --blobs'
      POSTGRES_RESTORE_EXTRA_OPTS: '--format custom --create --clean --if-exists --jobs 2'
    networks:
      traefik-public:
    healthcheck:
      # Periodically check if PostgreSQL is ready, for Docker status reporting
      test: ["CMD", "pg_isready", "-U", "postgres"]
      interval: 60s
      timeout: 5s
      retries: 5
    deploy:
      placement:
        constraints:
          # Since this is for the stateful database,
          # only run it on the swarm manager, not on workers
          - "node.role==manager"
      restart_policy:
        condition: on-failure
```

Also see the .env_template (to be saved as .env in production) for the environment variables needed.
```bash
# For AWS, an access key for a role with write/put permissions to AWS S3 bucket
AWS_ACCESS_KEY_ID=some-key
AWS_SECRET_ACCESS_KEY=password
AWS_DEFAULT_REGION=us-west-2

# For the Postgres/TimescaleDB init/default setup.
PGHOST=timescale # the docker-compose.example.yml file specifies this as timescale
PGPORT=5432
PGDATABASE=postgres
PGDATA=/var/lib/postgresql/data
PGUSER=postgres

# PGPASSWORD is for connecting to an existing database (the backup container needs this)
PGPASSWORD=password

# POSTGRES_PASSWORD initializes the database password if we're setting up a brand new TimescaleDB container/volume
POSTGRES_PASSWORD=password
```
### Automatic Periodic Backups

Set the `SCHEDULE` environment variable like `-e SCHEDULE="@daily"` to run the backup automatically.

More information about scheduling can be found [here](http://godoc.org/github.com/robfig/cron#hdr-Predefined_schedules).

-Sean