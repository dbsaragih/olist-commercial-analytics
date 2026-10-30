# 05 — Findings

Findings for each business question, in pyramid style. Queries: `sql/analysis/`.
Scope: delivered orders; GMV = item price excluding freight, in BRL.

## Executive summary

**Olist’s growth came from acquiring customers and sellers, not from bigger baskets or repeat buying, and it stalled in 2018. Because only 2% of customers come back, the next phase has to come from two levers: larger baskets, and a Northeast served by local sellers and reliable carriers.**

**Situation.** Between January–August 2017 and January–August 2018, GMV grew
141%, from R$ 2.99M to R$ 7.22M.

**Complication.** That growth came almost entirely from volume: 99% from more
orders and 72% from more sellers, while the average order stayed at about
R$ 136. Monthly GMV has been flat at about R$ 0.9M since early 2018, and
year-on-year growth fell from +727% in January to +51% in August. Only 2% of
customers return within six months, so there is no repeat base to cushion the
slowdown.

**What the data shows:**

1. **Retention cannot carry growth in the near term.** 1.98% of customers
   return within 180 days, and a customer's 12-month GMV is only 3.5% above
   their first order, so acquisition has to pay back on the first purchase. Even raising the
   90-day return rate from 1.3% to 3% would add about R$ 200k (scenario).
2. **The basket is the untapped lever.** Customers buy about 1.14 items per
   order, unchanged in two years. Freight takes 32% of what customers pay for
   items under R$ 50 but 7% for items over R$ 200, so small baskets are also
   the ones most penalised by shipping.
3. **The Northeast is underserved on every measure.** It has the highest late
   rate (12.8%, twice the Southeast), the lowest rating (3.97), and pays 1.9×
   more freight per item, because about 84% of its items are shipped from the
   Southeast.
4. **Delivery problems come from carriers, not sellers.** Late orders are 7% of
   orders but a third of all 1–2 star reviews; 87% of their extra delivery time
   is carrier transit, and late rates are the same for large and small sellers.
5. **The seller base is concentrated in a core and dormant in the tail.**
   About 300 sellers (10%) generate 67% of GMV, but no single seller is
   critical; 53% of sellers made under R$ 1k in 20 months.

**Recommendations:**

| # | Lever | First step | Size (indicative) |
|---|---|---|---|
| 1 | Grow basket size | Test a free-shipping threshold and bundle offers on low-price categories | +0.1 items per order ≈ R$ 0.6M over 8 months (≈ 9% of GMV, scenario) |
| 2 | Recruit Northeast sellers | Target seller acquisition in the Northeast to shorten the longest, least reliable lanes | Addresses 18% of late orders and the highest freight burden |
| 3 | Manage carrier performance by lane | Set lane-level targets for Northeast lanes (rate) and Rio de Janeiro (volume); set delivery promises on the variability of transit, not the average | About 600 fewer late orders (Northeast to Southeast level) plus about 660 (Southeast −1 point) |
| 4 | Activate the seller tail | Onboarding support for sellers who made only one sale (17% of sellers) | Moves sellers into the R$ 10k–50k band, which already produces 37% of GMV |
| 5 | Low-cost reactivation | One contact 30–90 days after a high-value first purchase; measure, don't scale yet | Up to about 1.5% of GMV (scenario) |

**Limitations.** The data is observational: links such as late delivery and low
ratings are associations, not proven causes. GMV is revenue, not profit; no cost,
margin, marketing or conversion data was available. The data ends in August
2018, so the most recent months are slightly understated by orders still in
transit. Scenario figures illustrate scale and are not forecasts.

---

## BQ1. Growth drivers

**Olist's growth came entirely from more orders, spread across many categories,
and that engine stalled in 2018.**

| Metric | Jan–Aug 2017 | Jan–Aug 2018 | Change |
|---|---|---|---|
| Delivered orders | 21,998 | 52,783 | +139.9% |
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

## BQ4. Seller concentration

**Olist runs on a core of about 300 sellers: the top 10% generate two-thirds of
GMV, but no single seller is critical, and half of all sellers are effectively
dormant.**

| Seller GMV band (Jan 2017 – Aug 2018) | Sellers | Share of sellers | Share of GMV |
|---|---|---|---|
| R$ 50k and over | 38 | 1.3% | 29.1% |
| R$ 10k–50k | 244 | 8.3% | 37.0% |
| R$ 1k–10k | 1,102 | 37.4% | 29.9% |
| Under R$ 1k | 1,561 | 53.0% | 4.0% |
| **Total** | **2,945** | **100%** | **R$ 13.18M** |

- **Concentrated as a group:** the top 10% (295 sellers) generate 67.0% of GMV
  and the top 20% generate 82.2%; the bottom 50% generate 3.3%.
- **Not dependent on individuals:** the top 10 sellers hold 13.3% (about 1.3%
  each); the HHI of 36 is equivalent to 275 equal-sized sellers, close to the
  size of the top decile.
- **Mid-sized sellers are the backbone:** the R$ 10k–50k band produces more GMV
  (37.0%) than the 38 largest sellers (29.1%).
- **A dormant tail:** 53% of sellers made under R$ 1k in 20 months, and 494
  (17%) sold only once.
- **Growth came from more sellers:** active sellers doubled from 1,153 to 2,330
  (Jan–Aug, like-for-like); 72% of the GMV increase came from more sellers,
  14% from higher GMV per seller and 14% from both. Concentration was stable
  (top-decile share 62.1% → 63.4%), so new sellers mostly joined the tail.
- **Service does not depend on seller size:** late delivery is 5–7% in every
  decile (item-weighted). Small sellers hand over late more often (18.4% in the
  bottom decile vs 8.8% in the top), but the delivery buffer absorbs it.

| Hypothesis | Verdict |
|---|---|
| The top 10% of sellers generate more than 60% of GMV | Supported (67.0%); concentration sits in a group, not in individual sellers |

**Implication:** manage the top ~300 sellers as key accounts, since losing the
largest one would cost about 1–2% of GMV. The bigger opportunity is moving
sellers up a band: activating the dormant half and helping R$ 1k–10k sellers
reach R$ 10k–50k. Onboarding quality matters more than onboarding volume, given
that 17% of sellers sold only once.

**Notes:** decile counts differ by one seller because 2,945 does not divide by
10. Service rates join item-level sellers to order-level outcomes and are
item-weighted. Deciles 7–10 rest on small item counts.

## BQ5. Freight cost by region

**Freight takes 14% of what customers pay overall and 18–19% in the North and
Northeast, below the 25% hypothesised; but for the typical North order it
exceeds 25%, and cheap items carry far more of the burden than distance does.**

| Customer region | Freight share (ratio of sums) | Median order | Orders over 25% | Freight per item |
|---|---|---|---|---|
| North | 18.5% | 26.3% | 52.9% | R$ 36.82 |
| Northeast | 17.9% | 23.9% | 46.9% | R$ 32.26 |
| Center-West | 15.0% | 20.1% | 35.7% | R$ 22.99 |
| South | 15.0% | 20.1% | 34.7% | R$ 21.19 |
| Southeast | 13.2% | 17.1% | 26.1% | R$ 17.34 |
| **Total** | **14.3%** | **18.3%** | **30.3%** | **R$ 19.95** |

- **Two views, two answers:** as a share of revenue, freight is 18.5% (North)
  and 17.9% (Northeast). For the customer, the median North order pays 26.3%
  freight, and about half of North and Northeast orders exceed 25%.
- **The averaging trap:** averaging item-level ratios would give 28.6% (North)
  and 26.7% (Northeast) and wrongly confirm the hypothesis; overall it
  overstates freight share by 7 points (21.3% vs 14.3%).
- **The share understates the regional burden:** North customers buy pricier
  items (R$ 162 vs R$ 114 in the Southeast), which lowers their share, yet pay
  2.1× more freight per item.
- **Price matters more than distance:** within every price band the North and
  Northeast pay the highest share, so the gap is real; but the spread across
  price bands (32% under R$ 50 vs 7% over R$ 200) is twice the spread across
  regions.
- **Supply is far from demand:** about 84% of items delivered to the North and
  Northeast are shipped from the Southeast, at R$ 31–36 per item vs R$ 16 within
  the Southeast.

| Hypothesis | Verdict |
|---|---|
| Freight exceeds 25% of order value in the North and Northeast | Rejected as a regional aggregate (18.5% / 17.9%); supported for the typical North order (median 26.3%) and borderline in the Northeast (23.9%) |

**Implication:** the strongest freight lever is basket size, since one freight
charge spread over more items cuts the share most for cheap items; a
free-shipping threshold or bundle offers would test this, and it is the same
lever identified in BQ1. The structural lever is recruiting sellers in the
Northeast, which would shorten the longest and least reliable lanes (BQ3) while
growing the seller base (BQ4).

**Notes:** freight share = freight ÷ (item price + freight). Regional figures
use the ratio of sums; the average of item ratios is shown only to demonstrate
the error. Lane shares cover lanes with at least 100 items. Item counts for the
84% estimate are derived from GMV ÷ average item price.

## Customer value: RFM segmentation and CLV (Python)

Notebook: `notebooks/01_rfm_clv.ipynb`

**A customer is worth their first order: 12-month GMV is only 3.5% above the
first purchase, so acquisition must pay back on the first order, and
reactivation should target recent high-value buyers, not lapsed ones.**

| Window after first purchase | Eligible customers | GMV per customer | Uplift vs first day |
|---|---|---|---|
| First day | 93,104 | R$ 138.53 | — |
| 90 days | 75,448 | R$ 140.53 | +1.3% |
| 180 days | 56,194 | R$ 139.83 | +2.0% |
| 365 days | 21,404 | R$ 142.96 | +3.5% |

- **Value arrives on day one:** 96.6% of a customer's 12-month GMV comes from
  the first purchase day. Break-even acquisition cost is therefore Olist's
  margin on a single order of about R$ 143 (for example about R$ 14 at an
  illustrative 10% contribution margin).
- **Value is concentrated among one-time buyers:** the top 40% by spend (38% of
  customers) generate 72% of GMV; repeat buyers generate 4%.
- **A high-value one-time buyer is worth as much as a repeat buyer:** R$ 268 in
  one order vs R$ 266–276 across two or more.
- **RFM reduces to value × customer age:** frequency carries almost no
  information (98% buy once), and for one-time buyers recency measures how long
  ago they were acquired, not churn.
- **Reactivation target:** high-value recent buyers (14,499 customers, last
  purchase about 94 days ago) and, going forward, every high-value buyer 30–90
  days after the first purchase, when 55% of returns happen (BQ2). Lapsed
  high-value buyers (about 336 days) are past that window.

**Implication:** acquisition spend must be judged on first-order economics, not
on future repeat value. This reinforces the executive summary: retention is not
a growth lever, and basket size (the value of the first order) is.

**Notes:**
- Frequency counts distinct purchase days (same-day orders = one occasion).
  Recency is measured as at 2018-09-01.
- R scores split customers 40% recent / 60% older by design, so "lapsed"
  segments are larger by construction; GMV per customer is the same
  (R$ 268 vs R$ 269).
- Revenue CLV only: no commission, margin or cost data. The 365-day figure
  covers only 2017 cohorts; 2018 cohorts return less (BQ2), so it is an upper
  bound for current customers.
- Cross-method check: repeat-buyer GMV in Python (R$ 544,289.32) equals the SQL
  result in BQ2.