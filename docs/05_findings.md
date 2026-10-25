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