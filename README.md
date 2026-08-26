# Bootcamper

Bootcamper is a Ukrainian-language Rails application for course discovery and learning journeys.

## Runtime

- Ruby 4.0.6
- Rails 8.1.3.1
- PostgreSQL 17

Ruby, Rails, and the resolved dependency graph are pinned in `.ruby-version`, `Gemfile`, and `Gemfile.lock`.

## Container development

Requirements: Docker Engine with Compose v2.

Compose requires `RAILS_MASTER_KEY` for encrypted development credentials and `POSTGRES_PASSWORD` for PostgreSQL; the latter must match encrypted `database.password`.

Before starting, create the environment-specific encrypted credentials and keep the generated key out of Git:

```sh
RAILS_ENV=development bin/rails credentials:edit
```

Add `database.host`, `database.username`, `database.password`, and `database.name` to the encrypted file, then export its ignored key as `RAILS_MASTER_KEY` (for example, `export RAILS_MASTER_KEY="$(cat config/credentials/development.key)"`). Export `POSTGRES_PASSWORD` for Compose and make it exactly match the encrypted `database.password`; Compose refuses to start if it is missing. Never put the key or plaintext credentials in Git. The web service prepares the development database after PostgreSQL becomes healthy.

Create test credentials similarly with `RAILS_ENV=test bin/rails credentials:edit`; CI supplies the matching key through its secret store.

Start the application after exporting both development values:

```sh
export RAILS_MASTER_KEY="$(cat config/credentials/development.key)"
read -r -s -p 'PostgreSQL password (must match encrypted database.password): ' POSTGRES_PASSWORD; export POSTGRES_PASSWORD; echo
docker compose up --build
```

Open <http://localhost:3000>. Stop the services without deleting the named database volume:

```sh
docker compose down
```

## Checks

CI runs the same containerized checks:

```sh
docker compose run --rm -e RAILS_ENV=test web sh -c 'bin/rails db:prepare && bundle exec rspec'
docker compose run --rm web bundle exec rubocop
```

The complete blocking quality gate is:

```sh
docker compose run --rm web sh -c 'bin/rails db:prepare && bin/quality'
```

It runs RuboCop, Fasterer, Brakeman, Bundler Audit (refreshing advisories),
database consistency, ERB Lint, and the frozen AnnotateRb schema check. All
checks fail closed; Bundler Audit therefore requires network access.

CI supplies `RAILS_MASTER_KEY_DEVELOPMENT` and `POSTGRES_PASSWORD_DEVELOPMENT` for the development build/smoke steps, and `RAILS_MASTER_KEY_TEST` and `POSTGRES_PASSWORD_TEST` for test/quality steps. Each password must match `database.password` in its corresponding encrypted credentials file. Missing secrets, encrypted files, or required `database` entries fail boot with a non-secret diagnostic.
