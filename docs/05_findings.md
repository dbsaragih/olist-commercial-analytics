# 05 — Findings

Findings for each business question, in pyramid style. Queries: `sql/analysis/`.
Scope: delivered orders; GMV = item price excluding freight, in BRL.

## BQ1. Growth drivers

**Olist's growth came entirely from more orders, spread across many categories,
and that engine stalled in 2018.**

| Metric | Jan–Aug 2017 | Jan–Aug 2018 | Change |
|---|---|---|---|
| Delivered orders | 21,998 | 52,783 | +140.9% |
| GMV | R$ 2,993,456 | R$ 7,218,125 | +141.1% |
| Average order value | R$ 136.08 | R$ 136.75 | +0.5% |
| Items per order | 1.134 | 1.143 | +0.8% |
| Average item price | R$ 120.01 | R$ 119.66 | −0.3% |

- **Volume, not basket:** 99.2% of the R$ 4.22M increase came from order volume;
  basket behaviour did not change.
- **Broad-based:** the top 5 categories contributed 44% of growth, led by
  Health & Beauty (12.1%) and Watches & Gifts (11.5%). 14 of 74 categories
  declined, losing less than 0.5% of the gain.
- **Stalling:** monthly GMV rose five-fold during 2017, then plateaued at about
  R$ 0.9M a month in 2018, stepping down after the May peak (R$ 978k) to
  R$ 840–870k in June–August. Year-on-year growth fell from +727% (January) to
  +51% (August). In-transit orders at the data cut-off explain only a small part
  of the late-2018 softness.

| Hypothesis | Verdict |
|---|---|
| Growth came mainly from order volume rather than higher AOV | Supported (99.2% volume) |
| The top 5 categories account for over 50% of growth | Rejected (44%) |

**Implication:** with order growth flattening and basket size unchanged, the
next growth lever is basket size (cross-selling to single-item buyers) alongside
renewed acquisition. BQ2 tests whether repeat purchases offer a third lever.

**Checks:** the category view and the order view of growth reconcile to
R$ 0.00 (R$ 4,224,668.99 in both); monthly totals reconcile with the fact
tables (96,211 orders, R$ 13.18M).

## BQ2. Customer repeat and retention

**Olist is almost entirely a one-purchase marketplace: about 2 in 100 customers
come back within six months, so growth depends on acquiring new buyers.**

| Measure | Result |
|---|---|
| Customers with a delivered order (Jan 2017 – Aug 2018) | 93,104 |
| Placed more than one order | 3.00% (2,789) |
| Of which, same-day orders only | 784 (28% of multi-order customers) |
| Returned on a later date | 2.15% (2,005) |
| Returned within 90 days (eligible customers) | 1.30% (981 of 75,448) |
| Returned within 180 days (eligible customers) | 1.98% (1,112 of 56,194) |

- **Real returns are lower than the headline:** 28% of multi-order customers
  only ordered on the same day; counting them would overstate retention by 40%.
- **No improvement with scale:** the 90-day return rate was 1.52% for the
  May–Sep 2017 cohorts and 1.25% for the larger Jan–May 2018 cohorts (about
  6,600 new customers a month). The cause is untested; one hypothesis is lower
  loyalty among customers acquired at scale.
- **Frequency, not spend:** returners generate 4.13% of GMV, about twice their
  2.15% share of customers, because they place about 2.1 orders each. Their GMV
  per order (R$ 126.52) is lower than one-time buyers' (R$ 137.91).
- **Timing:** among observed returners, 30% came back within 30 days and the
  median gap was 74 days (understated: recent cohorts can only show short gaps).

| Hypothesis | Verdict |
|---|---|
| Fewer than 5% of customers repeat | Supported under every definition (3.00% / 2.15% / 1.98% within 180 days) |

**Implication:** retention cannot replace acquisition as a growth engine in the
near term. As a scenario, raising the 90-day return rate from 1.30% to 3% would
add about R$ 200k (about 1.5% of GMV). A low-cost reactivation contact within
30–90 days of the first purchase is worth testing, but the 2018 stall (BQ1) has
to be solved through acquisition. BQ3 tests whether a late first delivery
reduces the chance of returning.

**Notes and scope decisions:**
- Fixed-window rates only use cohorts whose full window ends by 2018-08-31;
  incomplete cohorts are shown as NULL, not zero.
- Jan–Feb 2017 cohorts are too small to interpret (about 6 and 15 returners).
- "Categories bought on return" was not analysed: 2,005 returners spread across
  74 categories give groups too small to support a decision.
- Checks: customer count (93,104), orders (96,211) and GMV (R$ 13,181,027.13)
  reconcile with the fact tables; Q2a vs Q2b eligibility differences
  (+316 and +927 customers) are explained by customer-level vs month-level
  eligibility.

## BQ3. Delivery performance and customer ratings

**Late delivery is the clearest driver of bad reviews, and the carrier leg causes
it: late orders are 7% of orders but a third of all 1–2 star reviews, and 87% of
their extra delivery time is spent in carrier transit.**

| Measure | On time | Late |
|---|---|---|
| Delivered orders | 89,672 (93.2%) | 6,531 (6.8%) |
| Average review score | 4.29 | 2.27 |
| Low scores (1–2 stars) | 9.2% | 62.4% |
| Average seller handover | 3.0 days | 6.0 days |
| Average carrier transit | 7.9 days | 27.9 days |

- **Damage starts on the first day late:** the low-score rate rises from 12.4%
  (delivered on the estimated day) to 32.1% at 1–3 days late and 67.7% at
  4–7 days late, then levels off at about 80%. Arriving early earns little:
  10+ days early scores only 0.29 higher than on the day.
- **The carrier leg causes the delay:** of the 23 extra days for late orders,
  20 are carrier transit (87%) and 3 are seller handover (13%). Late seller
  handover is a contributing trigger (27.8% of late orders vs 7.6% on time).
- **Two geographic problems, not one:** the Northeast has the highest late rate
  (12.8%, twice the Southeast's 6.1%) and the lowest score (3.97); the Southeast
  holds 62% of all late orders because of its volume (RJ alone about 23%).
- **Remote is not the same as late:** the North has the longest transit
  (19.2 days) but arrives 15.5 days before the promise on average. The Northeast
  has a similar buffer to the Southeast but twice the late rate, which points to
  more variable transit times rather than longer ones.
- **Weak link to retention:** customers whose first order was late returned
  within 180 days at 1.57% vs 2.01% (62 vs 1,050 customers; about 2 standard
  errors). Directionally consistent, but commercially immaterial (about 17
  customers).

| Hypothesis | Verdict |
|---|---|
| Late orders score at least 1.5 stars lower | Supported (2.02 lower) |
| Carrier transit drives lateness | Supported (87% of the extra days) |
| Lateness is concentrated in remote states | Partly rejected: highest rates in the Northeast, not the North; 62% of late orders in the Southeast |

**Implication:** two carrier levers of similar size: bringing Northeast lanes to
the Southeast's late rate (about 600 fewer late orders) and cutting the
Southeast's rate by one point (about 660). Delivery promises should be set on
the variability of transit by region, not the average. Because damage starts on
day 1, proactive contact when an order is about to miss its date is worth
testing.

**Notes:** 92% of orders arrive before the promised date (64% by 10+ days), so
the promise is conservative; whether it suppresses conversion cannot be tested
with this data. Scope excludes 8 delivered orders without a date (T3); the leg
analysis also excludes T4 and T5. Ratings cover 95,560 reviewed orders.  