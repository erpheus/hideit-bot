import bot.base
import json
import os
from telegram.ext import Dispatcher
from telegram import Update, Bot
from bot.handlers import set_up


bot = Bot(token=os.getenv('TELEGRAM_TOKEN'))
dispatcher = Dispatcher(bot, None, use_context=True)
set_up(dispatcher)


def lambda_handler(event, context):
    try:
        dispatcher.process_update(
            Update.de_json(json.loads(event["body"]), bot)
        )

    except Exception as e:
        print(e)
        return {"statusCode": 500}

    return {"statusCode": 200}
