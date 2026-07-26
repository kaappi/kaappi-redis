# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

## [0.1.0] - 2026-07-26

### Added
- Redis client — `redis-connect`/`redis-disconnect!` and `redis-command`,
  with helpers across strings, keys, lists, hashes, sets, sorted sets,
  pub/sub, and pipelining (`redis-pipeline`), plus server commands
  (`redis-dbsize`/`redis-info`/`redis-type`)
- RESP protocol reader/writer with offline tests
- Built on kaappi-net; native helper library built via `make`
- CI workflow for automated testing
