---
type: How-to guide
genre: Runbook
title: How to rotate the API key
description: Replace the service's API key without downtime.
tags:
  - example-service
  - credentials
status: stable
work_item: "[example-org/example-service#42](https://github.com/example-org/example-service/issues/42)"
generated:
  by: pi/claude-opus-5-5
  at: "2026-10-09T00:00:00Z"
---

# How to rotate the API key

Replace the example service's API key in the dev environment without downtime.

## Before you start

- Access to the dev secrets store.

## Steps

1. Create the new key.
2. Deploy it alongside the old key, then remove the old key.

## Verify

Requests succeed with the new key.

## Traps

- The old key keeps working until it is removed.
