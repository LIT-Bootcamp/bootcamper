FROM immanuwell/droast:1.6.1 AS droast

FROM ruby:4.0.6-bookworm AS base

WORKDIR /app
ENV BUNDLE_PATH=/usr/local/bundle

RUN apt-get update -qq && apt-get install -y --no-install-recommends libpq5 && rm -rf /var/lib/apt/lists/*

FROM base AS development

ENV RAILS_ENV=docker \
    BUNDLE_WITHOUT=""

RUN apt-get update -qq && apt-get install -y --no-install-recommends build-essential libpq-dev && rm -rf /var/lib/apt/lists/*

COPY --from=droast /usr/local/bin/droast /usr/local/bin/droast

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

# droast ignore=DF007 reason=".dockerignore limits the Rails build context"
COPY . .

FROM base AS production-build

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=true \
    BUNDLE_WITHOUT="development:test"

RUN apt-get update -qq && apt-get install -y --no-install-recommends build-essential libpq-dev && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

# droast ignore=DF007 reason=".dockerignore limits the Rails build context"
COPY . .
RUN SECRET_KEY_BASE_DUMMY=1 REQUIRE_MASTER_KEY=false APP_HOST=build.invalid DATABASE_URL=postgresql:///bootcamper_build bin/rails tailwindcss:build

FROM base AS runtime

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=true \
    BUNDLE_WITHOUT="development:test"

RUN groupadd --system rails && useradd --system --gid rails --home-dir /app rails

COPY --from=production-build --chown=rails:rails /usr/local/bundle /usr/local/bundle
COPY --from=production-build --chown=rails:rails /app /app

RUN mkdir -p log storage tmp/pids && chown -R rails:rails log storage tmp

USER rails

EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
