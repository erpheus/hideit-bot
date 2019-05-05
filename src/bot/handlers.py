import logging
from telegram.ext import CommandHandler, MessageHandler, Filters

logger = logging.getLogger(__name__)

# Code to gather all handlers and make then easy to attach to a dispatcher
# Use the @handler decorator in every handler

handlers = []

def handler(h_type, *args):
	def wrapper(f):
		handlers.append((h_type, args, f))
		return f
	return wrapper

def set_up(dispatcher):
	for h_type, args, f in handlers:
		dispatcher.add_handler(h_type(*args, f))


####   HANDLERS   ####

@handler(CommandHandler, 'start')
def start(update, context):
    update.message.reply_text("I'm a bot, please talk to me!")
    logger.info("said hello")


@handler(MessageHandler, Filters.text)
def echo(update, context):
    update.message.reply_text(f"{update.message.chat.first_name} said: {update.message.text}")
    logger.info("echoed")
