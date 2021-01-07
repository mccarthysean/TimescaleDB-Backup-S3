#! /bin/sh

set -e

if [ "${S3_S3V4}" = "yes" ]; then
    aws configure set default.s3.signature_version s3v4
fi

if [ "${SCHEDULE}" = "**None**" ]; then
  echo "SCHEDULE environment variable = **None** so running backup.sh now, and not scheduling it with cron..."
  sh backup.sh
  echo "Finished running backup.sh"
  exit 0
fi

echo "SCHEDULE environment variable = '$SCHEDULE' so we're setting up cron now..."

# Create a crontab.txt file to set as the default crontab
echo "
# min hour dom month dow   command
$SCHEDULE /bin/sh /backup.sh
# Leave the last line blank for a valid cron file" > /crontab.txt

# Set the default crontab as the crontab.txt file
/usr/bin/crontab /crontab.txt

echo "Cron setup complete!"

# Start cron and run it forever
/usr/sbin/crond -f -l 8
