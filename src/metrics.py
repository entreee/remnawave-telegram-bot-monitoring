"""Prometheus metrics helpers for the monitoring bot."""

from __future__ import annotations

from prometheus_client import Counter, Gauge, Histogram, start_http_server

# Gauges
bot_up = Gauge("bot_up", "Bot availability")
nodes_up_total = Gauge("nodes_up_total", "Number of nodes reported as up")
nodes_down_total = Gauge("nodes_down_total", "Number of nodes reported as down")
users_online_total = Gauge("users_online_total", "Total online users")

# API metrics
api_requests_total = Counter(
    "remna_api_requests_total", "Total Remnawave API requests", ["panel"]
)
api_errors_total = Counter(
    "remna_api_errors_total", "Total Remnawave API errors", ["panel"]
)
api_latency_seconds = Histogram(
    "remna_api_latency_seconds", "Latency of Remnawave API requests", ["panel"]
)


def init_metrics(port: int) -> None:
    """Start Prometheus exporter on the given port."""
    start_http_server(port)
    bot_up.set(1)


def observe_api_request(panel: str, duration: float, error: bool) -> None:
    """Record API request metrics."""
    api_requests_total.labels(panel=panel).inc()
    api_latency_seconds.labels(panel=panel).observe(duration)
    if error:
        api_errors_total.labels(panel=panel).inc()


def set_nodes(up: int, down: int) -> None:
    nodes_up_total.set(up)
    nodes_down_total.set(down)


def set_users_online(count: int) -> None:
    users_online_total.set(count)
