#!/usr/bin/env bash

set -o allexport
source ./deploy.env
set +o allexport

echo "https://api.telegram.org/bot${TelegramToken}/setWebhook"
echo "Stack name $1"

 curl \
 	--request POST \
 	--url "https://api.telegram.org/bot${TelegramToken}/setWebhook" \
 	--header 'content-type: application/json' \
 	--data "{\"url\": \"$(aws cloudformation describe-stacks --stack-name $1 --query 'Stacks[0].Outputs[?OutputKey==`Endpoint`].OutputValue'  --output text)\"}"
