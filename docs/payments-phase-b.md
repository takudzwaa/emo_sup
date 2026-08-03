# Payments Phase B — mobile money staging (PR 23)

## Status
- **Phase A:** `PaymentService` / FakePaymentGateway + in-memory ledger (shipped).
- **Phase B:** `StagingMobileMoneyGateway` adapter + this doc.
- **Production rails:** blocked on commercial choice of aggregator + merchant account.

## Selection criteria
| # | Criterion | Why |
|---|-----------|-----|
| 1 | EcoCash + OneMoney + InnBucks coverage | Matches existing `PaymentMethod` enum and Mbare money reality |
| 2 | Settlement currency clarity (USD / ZiG) | Pilot default remains USD minor units until config says otherwise |
| 3 | Webhook + idempotent payment ids | Avoid double-confirm of bookings |
| 4 | KYC path for local entity / NGO | Vulnerable-community funding models |
| 5 | Low-bandwidth UX (USSD or short redirect) | Spotty 3G devices |

## Sandbox credentials plan
1. Create staging Firebase project + Functions secrets for gateway keys.
2. Store keys only in Functions config / Secret Manager — never in client.
3. Field-test checklist: success, decline, timeout, double-submit, offline retry.
4. Switch `AppServices.payments` from Fake → Staging → Real via flavor.

## Go-live gate

`confirmBookingPayment` and `activateMembership` currently trust a
client-supplied `paymentId` with no gateway verification — safe only because
they check **two** separate `config/payments` flags: `enabled` (general
checkout toggle) and `gatewayVerified` (functions/src/index.ts:
`gatewayVerificationImplemented()`). Do not set `gatewayVerified: true` until
this file's webhook-verification work has actually shipped and replaced the
client-trust code in both functions — the two-flag split exists specifically
so that flipping `enabled` alone (e.g. to test checkout UI) can't
accidentally open a free-money hole.

## Client switch
```dart
// prototype / tests
PaymentService(delay: Duration.zero)

// staging field tests
StagingMobileMoneyGateway(providerLabel: 'paynow_sandbox') // example only
```

## Do not
- Hardcode a brand name into product UI until contract is signed.
- Put real EcoCash PINs or merchant secrets in the repo.
