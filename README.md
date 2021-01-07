# TimescaleDB-Backup-S3
For creating a Docker image that runs alongside the TimescaleDB container. It uses pg_dump to back up the container periodically, and then uploads the backup to an AWS S3 bucket

See the docker-compose.example.yml file for typical usage.

Also see the .env_template (to be saved as .env in production) for the environment variables needed.

-Sean