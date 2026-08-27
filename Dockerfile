FROM ruby:4.0.6-bookworm

WORKDIR /app
ENV RAILS_ENV=development \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=""

RUN apt-get update -qq && apt-get install -y --no-install-recommends build-essential libpq-dev nodejs postgresql-client && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment true && bundle install --jobs 4 --retry 3

COPY . .
RUN SECRET_KEY_BASE_DUMMY=1 REQUIRE_MASTER_KEY=false RAILS_ENV=production bin/rails tailwindcss:build
EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
