require 'telegram/bot'
require_relative 'hideit_bot'

error_count = 0

telegram_token = ENV['TELEGRAM_TOKEN']
if not telegram_token or telegram_token == 'placeholder'
    puts "Telegram token not provided. Write your token to tokens.env file."
    exit
end

botan_token = ENV['BOTAN_TOKEN']


Hideit_bot::HideItBot.start()

begin
	bot = Hideit_bot::HideItBot.new(token: telegram_token, botan_token: botan_token)
 
	bot.listen do |message|
		bot.process_update message
		error_count = 0
	end


rescue => e
    error_count += 1
    puts e.to_s
    open('hideit_server_log.txt', 'a') do |f|
        f.puts e.to_s
    end
    if error_count < 5
        sleep(1)
        retry
    else
        Hideit_bot::HideItBot.end()
    end
end