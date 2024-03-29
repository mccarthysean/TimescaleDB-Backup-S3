# TimescaleDB-Backup-S3
For creating a Docker container that runs alongside the TimescaleDB container. It uses `pg_dump` to back up the container periodically, and then uploads the backup to an AWS S3 bucket.

Docker images here:
<https://hub.docker.com/r/mccarthysean/timescaledb_backup_s3/tags>

The container also contains a `restore.sh` file which uses `pg_restore` to restore the backup.

For even more convenience, there's also a `download_backup_from_AWS_S3.sh` script to download a backup file from your AWS S3 bucket, prior to restoring it.

I hope this Docker container makes your life a bit easier.

-Sean

## Usage

Docker:
```sh
$ docker run \
  -e AWS_ACCESS_KEY_ID=key \
  -e AWS_SECRET_ACCESS_KEY=secret \
  -e AWS_DEFAULT_REGION=us-west-2 \
  -e S3_BUCKET=my-bucket \
  -e S3_PREFIX=subfolder \
  -e POSTGRES_HOST=localhost \
  -e POSTGRES_USER=user \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DATABASE=dbname \
  -e SCHEDULE='0 7 * * *' \
  mccarthysean/timescaledb_backup_s3:latest-14
```

See the docker-compose.example.yml file for typical usage, like below:
```yaml
  timescale:
    image: timescale/timescaledb-ha:pg13.8-ts2.8.1-latest
    volumes: 
      - type: volume
        source: timescale-db-pg13
        # the location in the container where the data are stored
        target: /var/lib/postgresql/data
        read_only: false
    env_file: .env
    ports:
      - 0.0.0.0:5432:5432

  backup:
    # image: mccarthysean/timescaledb_backup_s3:13-1.0.10
    image: mccarthysean/timescaledb_backup_s3:14-1.0.10
    env_file: .env
    environment:
      # cron-schedule this backup job to backup and upload to AWS S3 every so often
      # * * * * * command(s)
      # - - - - -
      # | | | | |
      # | | | | ----- Day of week (0 - 7) (Sunday=0 or 7)
      # | | | ------- Month (1 - 12)
      # | | --------- Day of month (1 - 31)
      # | ----------- Hour (0 - 23)
      # ------------- Minute (0 - 59)
      SCHEDULE: '0 7 * * *'
      # The AWS S3 bucket to which the backup file should be uploaded
      S3_BUCKET: backup-timescaledb
      # S3_PREFIX creates a sub-folder in the above AWS S3 bucket
      S3_PREFIX: daily-backups
    networks:
      traefik-public:
    healthcheck:
      # Periodically check if PostgreSQL is ready, for Docker status reporting
      test: ["ping", "-c", "1", "timescale"]
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
# the docker-compose.example.yml file specifies the host as "timescale"
POSTGRES_HOST=timescale
POSTGRES_PORT=5432
POSTGRES_DATABASE=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password
```
### Automatic Periodic Backups

Set the cron `SCHEDULE` environment variable like `-e SCHEDULE="0 0 * * *"` to run the backup automatically.

-Sean