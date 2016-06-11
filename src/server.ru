require 'rack'

require 'oj'
require 'multi_json'
require 'telegram/bot'
require_relative 'hideit_bot'
require_relative 'config'

BotConfig.require_tokens(server: true)

Webhook_token = SecureRandom.hex
url = 'https://' + BotConfig::Webhook_domain + '/' + Webhook_token

puts "telegram webhook url: ",url

Hideit_bot::HideItBot.start()

bot = Hideit_bot::HideItBot.new()
bot.set_webhook(url)

def extract_message(update)
	update.inline_query ||
	update.chosen_inline_result ||
  	update.callback_query ||
  	update.message
end

app = Proc.new do |env|
	request = Rack::Request.new(env)

	if request.post?
		data = MultiJson.load request.body.read

		token = request.path[1..-1]
		if token != Webhook_token
			[403, {'Content-Type' => 'text/html'}, ['Invalid token!']]
		else
			update = Telegram::Bot::Types::Update.new(data)
			bot.process_update extract_message(update)

			[200, {}, []]
		end
	else
		[200, {'Content-Type' => 'text/html'}, ['hello! bot here. You are not using a token nor a POST request']]
	end
end


run app
