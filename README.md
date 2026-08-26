# Bootcamper

Bootcamper is a Ukrainian-language Rails application for course discovery and learning journeys.

## Runtime

- Ruby 4.0.6
- Rails 8.1.3.1
- PostgreSQL 17

Ruby, Rails, and the resolved dependency graph are pinned in `.ruby-version`, `Gemfile`, and `Gemfile.lock`.

## Container development

Requirements: Docker Engine with Compose v2.

```sh
docker compose up --build
```

Open <http://localhost:3000>. The web service prepares the development database after PostgreSQL becomes healthy.

## Checks

CI runs the same containerized checks:

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_NAME=bootcamper_test web sh -c 'bin/rails db:prepare && bundle exec rspec'
docker compose run --rm web bundle exec rubocop
```

The complete blocking quality gate is:

```sh
docker compose run --rm web sh -c 'bin/rails db:prepare && bin/quality'
```

It runs RuboCop, Fasterer, Brakeman, Bundler Audit (refreshing advisories),
database consistency, ERB Lint, and the frozen AnnotateRb schema check. All
checks fail closed; Bundler Audit therefore requires network access.

Stop services and remove the development database with `docker compose down -v`.
