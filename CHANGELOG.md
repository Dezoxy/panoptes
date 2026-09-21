# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Until the first tagged release, `main` is the only supported version and the public
surface may change without a major version bump.

## [Unreleased]

### Added

- Repository scaffold: licence, ownership, security policy, contribution rules and
  changelog.
- Control gates: pre-commit hook suite (formatting, linting, type checking, Terraform
  static analysis, secret scanning, commit-message validation) and the CI workflow that
  runs it on every pull request and push to `main`.
