require 'telegram/bot'
require 'mongo'
require 'daemons'

include Mongo

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

    if message.query == ""
        results = []
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
                )
            )
        end
    end

    bot.api.answer_inline_query(
        inline_query_id: message.id,
        results: results,
        cache_time: 0,
        is_personal: true
    )

end

token = File.open('Tokenfile', 'r') { |f| token = f.readline.chomp }

error_count = 0

begin
Telegram::Bot::Client.run(token) do |bot|
    begin
        bot.listen do |message|
            case message
                when Telegram::Bot::Types::InlineQuery
                    handle_inline_query(message,bot,messages)

                when Telegram::Bot::Types::CallbackQuery
                    res = message.data
                    begin
                        res = messages.find("_id" => BSON::ObjectId(message.data)).to_a[0][:text]
                    rescue
                    end
                    bot.api.answer_callback_query(
                        callback_query_id: message.id,
                        text: res,
                        show_alert: true)

                when Telegram::Bot::Types::ChosenInlineResult
                    messages.find("_id" => BSON::ObjectId(message.result_id.split(':')[1]))
                            .update_one(:$set => {used: true})


                when Telegram::Bot::Types::Message
                    bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}!\nThis bot should be used inline.\nType @hideItBot to start")
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
        sleep(2)
        retry
    else
        database_cleaner.stop
    end
end

