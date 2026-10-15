\# 01 — Problem Statement



\## Context

Olist is a Brazilian marketplace connecting small sellers to major e-commerce channels.

Leadership wants to understand commercial performance and decide where to focus next year.



\## Scope and definitions

\- \*\*Data:\*\* Olist public dataset, \~99k orders, 9 tables

\- \*\*Analysis period:\*\* monthly, Jan 2017 – Aug 2018 (2016 is a partial start-up period;

&#x20; the final cut-off will be confirmed during data profiling)

\- \*\*GMV (Gross Merchandise Value):\*\* sum of `order\_items.price` for orders with status

&#x20; `delivered`, excluding freight, in BRL (R$)

\- \*\*Customer:\*\* identified by `customer\_unique\_id` (`customer\_id` is unique per order)



\## Business questions



\### Q1. Growth drivers

\- \*\*Question:\*\* Which product categories drove GMV growth, and was growth driven by more

&#x20; orders or by higher spend per order (AOV)?

\- \*\*Area:\*\* Growth

\- \*\*Stakeholder:\*\* Chief Commercial Officer

\- \*\*Decision it informs:\*\* Where to focus assortment, merchandising and marketing spend;

&#x20; and whether next year should prioritise acquisition (order volume) or

&#x20; cross-selling/upselling (basket size)

\- \*\*Hypothesis:\*\* The top 5 categories account for over 50% of GMV growth, and growth came

&#x20; mainly from order volume rather than higher AOV

\- \*\*Tables:\*\* orders, order\_items, products, product\_category\_name\_translation



\### Q2. Customer repeat and retention

\- \*\*Question:\*\* What share of customers make a second purchase, how long do they take to

&#x20; return, and what do they buy when they come back?

\- \*\*Area:\*\* Customers

\- \*\*Stakeholder:\*\* Chief Commercial Officer

\- \*\*Decision it informs:\*\* Whether retention programmes justify investment, and if so,

&#x20; which categories and timing to target in re-engagement campaigns

\- \*\*Hypothesis:\*\* Fewer than 5% of customers make a second purchase, so retention is a

&#x20; small lever and first-order experience matters more; among those who return, repeat

&#x20; purchases concentrate in a few categories

\- \*\*Tables:\*\* customers (`customer\_unique\_id`), orders, order\_items, products,

&#x20; product\_category\_name\_translation



\### Q3. Delivery delays: root cause and impact

\- \*\*Question:\*\* Where in the fulfilment chain do late deliveries originate (seller handover

&#x20; vs carrier transit), and how much do they lower review scores?

\- \*\*Area:\*\* Operations

\- \*\*Stakeholder:\*\* Chief Operating Officer

\- \*\*Decision it informs:\*\* Whether to fix delays through seller SLAs and penalties, or

&#x20; through carrier contracts and regional routing

\- \*\*Hypothesis:\*\* Late orders score at least 1.5 stars lower on average, and most lateness

&#x20; comes from carrier transit in remote states rather than seller handover

\- \*\*Tables:\*\* orders, order\_items (`shipping\_limit\_date`), order\_reviews,

&#x20; customers (state), sellers (state)



\### Q4. Seller performance and concentration

\- \*\*Question:\*\* Which sellers generate the most GMV, and do their delivery performance and

&#x20; ratings keep up with their sales volume?

\- \*\*Area:\*\* Supply side

\- \*\*Stakeholder:\*\* Head of Marketplace

\- \*\*Decision it informs:\*\* Which key sellers to support and incentivise, and which need

&#x20; operational performance interventions

\- \*\*Hypothesis:\*\* The top 10% of sellers generate over 60% of GMV, and several of them have

&#x20; below-average on-time rates or review scores

\- \*\*Tables:\*\* sellers, orders, order\_items, order\_reviews



\### Q5. Freight cost burden

\- \*\*Question:\*\* How does freight as a share of order value vary across product categories

&#x20; and customer regions, and do orders with a high freight share receive lower review scores?

\- \*\*Area:\*\* Supply side

\- \*\*Stakeholder:\*\* Chief Commercial Officer

\- \*\*Decision it informs:\*\* Whether to adjust shipping rate rules, offer targeted freight

&#x20; subsidies, or rethink regional delivery pricing

\- \*\*Hypothesis:\*\* Freight exceeds 25% of order value for customers in the North and

&#x20; Northeast regions, and orders with a high freight share score below average

\- \*\*Tables:\*\* orders, order\_items, products, customers, order\_reviews

