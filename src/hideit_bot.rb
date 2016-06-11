require 'telegram/bot'
require 'telegram/bot/botan'
require 'mongo'
require_relative 'config'

module Hideit_bot

    class HideItBot
        RegExpParcial = /(^|[^\\])\*(([^\*\\]|\\\*)+)\*/

        def self.start()
            Mongo::Logger.logger.level = ::Logger::FATAL

            @@database_cleaner = Thread.new do
                # clean unused data
                mongoc = Mongo::Client.new("mongodb://mongodb:27017/hideitbot")
                counter = 0 # Only run every 30 seconds but sleep one second at a time
                loop do
                    sleep 1
                    counter = (counter + 1) % 30
                    if counter == 29
                        mongoc[:messages].delete_many(:used => false, :created_date => {:$lte => (Time.now - 30).utc})
                    end
                end
            end
        end

        def initialize()
            @bot = Telegram::Bot::Client.new(BotConfig::Telegram_token)
            @messages = Mongo::Client.new("mongodb://mongodb:27017/hideitbot", :pool_size => 5, :timeout => 5)[:messages]

            if BotConfig.has_botan_token
                @bot.enable_botan!(BotConfig::Botan_token)
            end
        end

        def listen(&block)
            @bot.listen &block
        end

        def process_update(message)
            case message
                when Telegram::Bot::Types::InlineQuery
                    id = handle_inline_query(message)
                    if BotConfig.has_botan_token
                      @bot.track('inline_query', message.from.id, {message_length: message.query.length, db_id: id})
                    end

                when Telegram::Bot::Types::CallbackQuery
                    res = message.data
                    begin
                        res = @messages.find("_id" => BSON::ObjectId(message.data)).to_a[0][:text]
                    rescue
                        res = "Message not found in database. Sorry!"
                    end
                    @bot.api.answer_callback_query(
                        callback_query_id: message.id,
                        text: res,
                        show_alert: true)
                    if BotConfig.has_botan_token
                      @bot.track('callback_query', message.from.id, {db_id: message.data})
                    end

                when Telegram::Bot::Types::ChosenInlineResult
                    message_type, message_id = message.result_id.split(':')
                    @messages.find("_id" => BSON::ObjectId(message_id))
                            .update_one(:$set => {used: true})
                    if BotConfig.has_botan_token
                      @bot.track('chosen_inline', message.from.id, {db_id: message_id, chosen_type: message_type})
                    end


                when Telegram::Bot::Types::Message
                    if message.text == "/start toolong"
                        @bot.api.send_message(chat_id: message.chat.id, text: "Unfortunately, due to telegram's api restrictions we cannot offer this functionality with messages over 200 characters. We'll try to find more options and contact telegram. Sorry for the inconvenience.")
                        if BotConfig.has_botan_token
                          @bot.track('message', message.from.id, message_type: 'toolong')
                        end
                    else
                        @bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}!\nThis bot should be used inline.\nType @hideItBot to start")
                        @bot.api.send_message(chat_id: message.chat.id, text: "You can use it to send a spoiler in a group conversation.")
                        if BotConfig.has_botan_token
                          @bot.track('message', message.from.id, message_type: 'hello')
                        end
                    end

            end
        end

        def set_webhook(url)
            @bot.api.set_webhook(url: url)
        end

        private

        def save_message(message, covered:false)
          if !covered
            return @messages.insert_one({user: message.from.id, text: message.query, used: false, created_date: Time.now.utc}).inserted_id.to_s
          else
            return @messages.insert_one({user: message.from.id, text: message_clear_parcial(message.query), used: false, created_date: Time.now.utc}).inserted_id.to_s
          end
        end

        def message_to_blocks(message)
            return  message.gsub(/[^\s]/i, "\u2588")
        end

        def message_to_blocks_parcial(message)
            return message.gsub(RegExpParcial) {|s| $1+message_to_blocks($2.gsub(/\*/, ""))}
        end

        def message_clear_parcial(message)
          return message.gsub(RegExpParcial) {|s| $1+$2.gsub(/\\\*/, "*")}
        end

        def handle_inline_query(message)

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

              if message.query.index(RegExpParcial) == nil
                id = save_message(message)
                results = [
                  [id, '1:'+id, 'Send covered text', message_to_blocks(message.query), message_to_blocks(message.query)],
                  [id, '2:'+id, 'Send generic message', '[[Hidden Message]]','[[Hidden Message]]']
                ]
              else
                id = save_message(message)
                id_covered = save_message(message, covered:true)
                results = [
                  [id, '1:'+id, 'Send covered text', message_to_blocks(message.query), message_to_blocks(message.query)],
                  [id_covered, '2:'+id_covered, 'Send parcially covered text', message_to_blocks_parcial(message.query), message_to_blocks_parcial(message.query)],
                  [id, '3:'+id, 'Send generic message', '[[Hidden Message]]','[[Hidden Message]]']
                ]
              end

              results =  results.map do |arr|
                  Telegram::Bot::Types::InlineQueryResultArticle.new(
                      id: arr[1],
                      title: arr[2],
                      description: arr[3],
                      input_message_content: Telegram::Bot::Types::InputTextMessageContent.new(message_text: arr[4]),
                      reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(
                          inline_keyboard: [
                              Telegram::Bot::Types::InlineKeyboardButton.new(
                                  text: 'Read',
                                  callback_data: arr[0]
                              )
                          ]
                      ),
                  )
              end
            end

            @bot.api.answer_inline_query({
                inline_query_id: message.id,
                results: results,
                cache_time: 0,
                is_personal: true
            }.merge!(default_params))
            return id
        end
    end

end
