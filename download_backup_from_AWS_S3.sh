#!/bin/bash

echo "Enter the name of the backup to download from bucket '$S3_BUCKET' and subfolder '$S3_PREFIX': "  
read backup_name
echo "Downloading $backup_name now..."

aws s3api get-object --bucket $S3_BUCKET --key $S3_PREFIX/$backup_name $backup_name

echo "Download complete!"
exit 0
