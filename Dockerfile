FROM ruby:2.3

WORKDIR /usr/src/bot
COPY Gemfile Gemfile.lock ./
RUN bundle

COPY . .
CMD ["ruby","src/hideit_bot.rb"]