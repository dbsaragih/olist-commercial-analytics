# 01 — Problem Statement

## Context
Olist is a Brazilian marketplace connecting small sellers to major e-commerce channels.
Leadership wants to understand commercial performance and decide where to focus next year.

## Scope and definitions
- **Data:** Olist public dataset, ~99k orders, 9 tables
- **Analysis period:** monthly, Jan 2017 – Aug 2018 (2016 is incomplete and Sep–Oct 2018
  is the data extract cut-off; confirmed during data profiling)
- **GMV (Gross Merchandise Value):** sum of `order_items.price` for orders with status
  `delivered`, excluding freight, in BRL (R$)
- **Customer:** identified by `customer_unique_id` (`customer_id` is unique per order)

## Business questions

### BQ1. Growth drivers
- **Question:** Which product categories drove GMV growth, and was growth driven by more
  orders or by higher spend per order (AOV)?
- **Area:** Growth
- **Stakeholder:** Chief Commercial Officer
- **Decision it informs:** Where to focus assortment, merchandising and marketing spend;
  and whether next year should prioritise acquisition (order volume) or
  cross-selling/upselling (basket size)
- **Hypothesis:** The top 5 categories account for over 50% of GMV growth, and growth came
  mainly from order volume rather than higher AOV
- **Tables:** orders, order_items, products, product_category_name_translation

### BQ2. Customer repeat and retention
- **Question:** What share of customers make a second purchase, how long do they take to
  return, and what do they buy when they come back?
- **Area:** Customers
- **Stakeholder:** Chief Commercial Officer
- **Decision it informs:** Whether retention programmes justify investment, and if so,
  which categories and timing to target in re-engagement campaigns
- **Hypothesis:** Fewer than 5% of customers make a second purchase, so retention is a
  small lever and first-order experience matters more; among those who return, repeat
  purchases concentrate in a few categories
- **Tables:** customers (`customer_unique_id`), orders, order_items, products,
  product_category_name_translation

### BQ3. Delivery delays: root cause and impact
- **Question:** Where in the fulfilment chain do late deliveries originate (seller handover
  vs carrier transit), and how much do they lower review scores?
- **Area:** Operations
- **Stakeholder:** Chief Operating Officer
- **Decision it informs:** Whether to fix delays through seller SLAs and penalties, or
  through carrier contracts and regional routing
- **Hypothesis:** Late orders score at least 1.5 stars lower on average, and most lateness
  comes from carrier transit in remote states rather than seller handover
- **Tables:** orders, order_items (`shipping_limit_date`), order_reviews,
  customers (state), sellers (state)

### BQ4. Seller performance and concentration
- **Question:** Which sellers generate the most GMV, and do their delivery performance and
  ratings keep up with their sales volume?
- **Area:** Supply side
- **Stakeholder:** Head of Marketplace
- **Decision it informs:** Which key sellers to support and incentivise, and which need
  operational performance interventions
- **Hypothesis:** The top 10% of sellers generate over 60% of GMV, and several of them have
  below-average on-time rates or review scores
- **Tables:** sellers, orders, order_items, order_reviews

### BQ5. Freight cost burden
- **Question:** How does freight as a share of order value vary across product categories
  and customer regions, and do orders with a high freight share receive lower review scores?
- **Area:** Supply side
- **Stakeholder:** Chief Commercial Officer
- **Decision it informs:** Whether to adjust shipping rate rules, offer targeted freight
  subsidies, or rethink regional delivery pricing
- **Hypothesis:** Freight exceeds 25% of order value for customers in the North and
  Northeast regions, and orders with a high freight share score below average
- **Tables:** orders, order_items, products, customers, order_reviews