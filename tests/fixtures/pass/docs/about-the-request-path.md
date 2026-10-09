---
type: Explanation
genre: Map
title: About the request path
description: How a request travels from the browser to the backend.
tags:
  - example-service
  - architecture
status: stable
generated:
  by: pi/claude-opus-5-5
  at: "2026-10-09T00:00:00Z"
sources:
  - id: router-source
    resource: https://github.com/example-org/example-service/blob/0000000000000000000000000000000000000000/src/Router.java
    title: "example-service Router: routes each request"
    last_modified: "2026-09-01T00:00:00Z"
---

# About the request path

How a request travels from the browser to the backend. The diagram is an asset.

![Request path](../assets/request-path.svg)

## 1. Components

| Component | What it does | Main parts |
| --- | --- | --- |
| Frontend | Serves the UI | Web app |
| Backend | Answers requests | Router |

## 2. How they connect

The router sends each request to one handler.[^router-source] See also
[the measured latency](request-latency.md).

## 3. Sources

[^router-source]: example-service [`Router.route`](https://github.com/example-org/example-service/blob/0000000000000000000000000000000000000000/src/Router.java): the routing table.
