# Repository Guidelines

## Project Structure & Module Organization

This repository is currently an empty project scaffold. Keep the root focused on project-wide configuration and documentation. As code is introduced, use a predictable layout:

- `src/` for application or library code.
- `tests/` for automated tests that mirror the structure under `src/`.
- `assets/` for static files such as images, fixtures, or sample data.
- `docs/` for architecture notes and longer-form documentation.

Prefer small, cohesive modules. Avoid placing generated files or local environment data in version control.

## Build, Test, and Development Commands

No build system or package manager has been configured yet. When adding one, expose common workflows through a single, documented interface (for example, package scripts or a `Makefile`). Typical commands should include:

- `npm run dev` or `make dev` to start local development.
- `npm test` or `make test` to run the complete test suite.
- `npm run lint` or `make lint` to check formatting and static analysis.
- `npm run build` or `make build` to create production artifacts.

Update this section when tooling is added; contributors should not need to infer commands from CI configuration.

## Coding Style & Naming Conventions

Follow the formatter and linter selected for the implementation language, and commit their configuration. Use spaces rather than tabs unless the language's standard tooling dictates otherwise. Choose descriptive names: `camelCase` for variables and functions, `PascalCase` for types or components, and `kebab-case` for general file names where the language has no stronger convention. Keep configuration examples free of secrets.

## Testing Guidelines

Add tests with every behavior change or bug fix. Name tests after observable behavior, and mirror source paths where practical (for example, `src/auth/session.ts` and `tests/auth/session.test.ts`). Tests should be deterministic and runnable locally with one command. Document any coverage threshold after a test framework is adopted.

## Commit & Pull Request Guidelines

No Git history is available yet. Use short, imperative commit subjects such as `Add session validation`, keeping unrelated changes separate. Pull requests should explain the motivation, summarize the implementation, list verification performed, and link relevant issues. Include screenshots or recordings for visible UI changes and call out configuration or migration steps explicitly.
