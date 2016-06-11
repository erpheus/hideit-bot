require 'telegram/bot'
require_relative 'hideit_bot'
require_relative 'config'

Config::require_tokens(server: true)

error_count = 0

Hideit_bot::HideItBot.start()

begin
	bot = Hideit_bot::HideItBot.new()
 
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
    end
end