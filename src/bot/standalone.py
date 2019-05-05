import bot.base
import os
from telegram.ext import Updater
from bot.handlers import set_up
import logging

logger = logging.getLogger(__name__)

logger.info("Starting standalone bot via long-polling.")

TELEGRAM_TOKEN=os.getenv('TelegramToken')
updater = Updater(token=TELEGRAM_TOKEN, use_context=True)
dispatcher = updater.dispatcher

set_up(dispatcher)

logger.info("Bot ready. Starting to poll")
updater.start_polling()
