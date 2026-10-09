---
type: Reference
genre: Investigation
title: Request latency
description: Measured latency of the request path, transcribed from a workbook behind a sign-in.
tags:
  - example-service
  - performance
status: stable
generated:
  by: process:latency-import
  at: "2026-10-09T00:00:00Z"
verified:
  - by: human:reviewer
    at: "2026-10-09T01:00:00Z"
sources:
  - id: latency-workbook
    resource: https://example.sharepoint.com/sites/example/latency.xlsx
    title: "Latency workbook: the live copy behind a sign-in"
    last_modified: "2026-09-30T00:00:00Z"
---

# Request latency

Latency per endpoint, transcribed from the workbook. Its snapshot sits next to this document as
[`request-latency.csv`](request-latency.csv).[^latency-workbook]

## Bottom line

- Every endpoint answers within 200 ms at p95.

## 1. Inventory

| Endpoint | p95 |
| --- | --- |
| `/orders` | 120 ms |

## 2. Sources

[^latency-workbook]: [Latency workbook](https://example.sharepoint.com/sites/example/latency.xlsx): sheet 1; snapshot in [`request-latency.csv`](request-latency.csv).
