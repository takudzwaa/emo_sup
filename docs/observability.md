# Observability & analytics ban (PR 24)

## Principles
- Prefer **aggregate** ops metrics over content mining.
- **Never** log chat message bodies, mood free-text, or PII.
- **Never** implement streaks, points, badges, leaderboards, or XP events.

## Allowed events (pilot allowlist)
See `MemoryAnalyticsService.allowedEvents` in
`lib/services/analytics_service.dart`.

Examples:
- `match_requested` / `match_connected` / `match_quota_exceeded` / `match_no_capacity`
- `booking_confirmed`, `payment_success`, `payment_declined`
- `report_submitted`, `block_submitted`, `escalate_chat`, `delete_my_data_requested`
- `safety_opened`, `crisis_resource_opened`

## Banned fragments
Any event name containing: `streak`, `points`, `badge`, `level_up`,
`leaderboard`, `xp_`, `reward`, `daily_challenge`, `gamif` is **dropped**.

## Dashboard metrics (ops)
| Metric | Use |
|--------|-----|
| match_connect_rate | Capacity / staffing |
| match_quota_exceeded_rate | Free-path sizing |
| match_no_capacity_rate | Listener coverage |
| payment_success_rate | Gateway health |
| report_rate / escalate_count | Safety load (24h ack) |
| delete_request_count | Trust / churn signal |

Wire to Crashlytics + Cloud Monitoring when Firebase project is linked.
Do not build a public social feed of metrics.
