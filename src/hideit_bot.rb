require 'telegram/bot'
require 'telegram/bot/botan'
require 'mongo'
require 'daemons'

include Mongo

telegram_token = ENV['TELEGRAM_TOKEN']
if not telegram_token or telegram_token == 'placeholder'
    puts "Telegram token not provided. Write your token to tokens.env file."
    exit
end

botan_token = ENV['BOTAN_TOKEN']

Mongo::Logger.logger.level = ::Logger::FATAL

database_cleaner = Daemons.call(:log_output => true) do
    # clean unused data
    mongoc = Client.new("mongodb://mongodb:27017/hideitbot")
    loop do
        sleep 30
        mongoc[:messages].delete_many(:used => false, :created_date => {:$lte => (Time.now - 30).utc})
    end
end


messages = Client.new("mongodb://mongodb:27017/hideitbot")[:messages]

def message_to_blocks(message)
    return  message.gsub(/[^\s]/i, "\u2588")
end

def handle_inline_query(message, bot, messages)

    default_params = {}
    id = nil

    if message.query == ""
        results = []
        default_params = {
            switch_pm_text: 'How to use this bot',
            switch_pm_parameter: 'howto'
        }
    elsif message.query.length > 200
        results = []
        default_params = {
            switch_pm_text: 'Sorry, this message is too long, split it to send.',
            switch_pm_parameter: 'toolong'
        }
    else
        id = messages.insert_one({user: message.from.id, text: message.query, used: false, created_date: Time.now.utc}).inserted_id.to_s
        results = [
          ['1:'+id, 'Send covered text', message_to_blocks(message.query), message_to_blocks(message.query)],
          ['2:'+id, 'Send generic message', '[[Hidden Message]]','[[Hidden Message]]']
        ].map do |arr|
            Telegram::Bot::Types::InlineQueryResultArticle.new(
                id: arr[0],
                title: arr[1],
                description: arr[2],
                input_message_content: Telegram::Bot::Types::InputTextMessageContent.new(message_text: arr[3]),
                reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(
                    inline_keyboard: [
                        Telegram::Bot::Types::InlineKeyboardButton.new(
                            text: 'Read',
                            callback_data: id
                        )
                    ]
                ),
            )
        end
    end

    bot.api.answer_inline_query({
        inline_query_id: message.id,
        results: results,
        cache_time: 0,
        is_personal: true
    }.merge!(default_params))
    return id

end

error_count = 0

begin
Telegram::Bot::Client.run(telegram_token) do |bot|
    if botan_token and botan_token != 'placeholder'
        bot.enable_botan!(botan_token)
    end
    begin
        bot.listen do |message|
            case message
                when Telegram::Bot::Types::InlineQuery
                    id = handle_inline_query(message,bot,messages)
                    bot.track('inline_query', message.from.id, {message_length: message.query.length, db_id: id})

                when Telegram::Bot::Types::CallbackQuery
                    res = message.data
                    begin
                        res = messages.find("_id" => BSON::ObjectId(message.data)).to_a[0][:text]
                    rescue
                        res = "Message not found in database. Sorry!"
                    end
                    bot.api.answer_callback_query(
                        callback_query_id: message.id,
                        text: res,
                        show_alert: true)
                    bot.track('callback_query', message.from.id, {db_id: message.data})

                when Telegram::Bot::Types::ChosenInlineResult
                    message_type, message_id = message.result_id.split(':')
                    messages.find("_id" => BSON::ObjectId(message_id))
                            .update_one(:$set => {used: true})
                    bot.track('chosen_inline', message.from.id, {db_id: message_id, chosen_type: message_type})


                when Telegram::Bot::Types::Message
                    if message.text == "/start toolong"
                        bot.api.send_message(chat_id: message.chat.id, text: "Unfortunately, due to telegram's api restrictions we cannot offer this functionality with messages over 200 characters. We'll try to find more options and contact telegram. Sorry for the inconvenience.")
                        bot.track('message', message.from.id, message_type: 'toolong')
                    else
                        bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}!\nThis bot should be used inline.\nType @hideItBot to start")
                        bot.api.send_message(chat_id: message.chat.id, text: "You can use it to send a spoiler in a group conversation.")
                        bot.track('message', message.from.id, message_type: 'hello')
                    end

            end
            error_count = 0
        end
    rescue Telegram::Bot::Exceptions::ResponseError => e
        puts e
        retry
    end
end
rescue => e
    error_count += 1
    open('hideit_server_log.txt', 'a') { |f|
        f.puts e.to_s
        puts e.to_s
    }
    if error_count < 5
        sleep(1)
        retry
    else
        database_cleaner.stop
    end
end

