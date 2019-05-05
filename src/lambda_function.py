import sys
import os
# Add deps folder to import path for non-default libraries
sys.path.insert(
    0,
    os.path.join(os.path.dirname(os.path.realpath(__file__)), "deps")
)

import json
import requests

print('Loading function')

TELEGRAM_TOKEN=os.getenv('TELEGRAM_TOKEN')
BASE_URL = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}"

def lambda_handler(event, context):

    try:
        data = json.loads(event["body"])
        message = str(data["message"]["text"])
        chat_id = data["message"]["chat"]["id"]
        first_name = data["message"]["chat"]["first_name"]

        response = "Please /start, {}".format(first_name)

        if "start" in message:
            response = "Hello {}".format(first_name)

        data = {"text": response.encode("utf8"), "chat_id": chat_id}
        url = BASE_URL + "/sendMessage"
        requests.post(url, data)

    except Exception as e:
        print(e)

    return {"statusCode": 200}
