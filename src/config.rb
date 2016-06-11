module BotConfig

	Telegram_token = ENV['TELEGRAM_TOKEN']
	Botan_token = ENV['BOTAN_TOKEN']
	Webhook_domain = ENV['WEBHOOK_DOMAIN']

	def BotConfig.require_tokens(server:false)
		if not BotConfig.has_telegram_token
		    STDERR.puts "Telegram token not provided. Write your token to tokens.env file."
		    exit
		end
		if not BotConfig.has_webhook_domain and server
		    STDERR.puts "Webhook domain not provided. Write your domain to tokens.env file."
		    exit
		end
	end

	def BotConfig.has_telegram_token()
		return (Telegram_token and Telegram_token != 'placeholder')
	end

	def BotConfig.has_botan_token()
		return (Botan_token and Botan_token != 'placeholder')
	end

	def BotConfig.has_webhook_domain()
		return (Webhook_domain and Webhook_domain != 'placeholder')
	end

end


