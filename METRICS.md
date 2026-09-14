Canonical metric definitions for the theLook DTC dataset; SQL is written against fct_order_items unless stated otherwise; every entry documents the judgment call, not just the formula.
## Conventions

Unless an entry states otherwise, all metrics:
- exclude lines with `order_item_status = 'Cancelled'` — a cancellation means the
  order never happened, as distinct from a return, which happened and reversed
- exclude forward-dated rows (`ordered_at >= current_date()`), an artifact of
  theLook's generator
- are denominated in USD, the source's only currency

### Gross Revenue

**Definition:** Sale price of all order lines that represent a real, non-cancelled
sale. Gross means before returns are netted off — a returned item still
contributed gross revenue.

**SQL:** `sum(case when order_item_status != 'Cancelled' then gross_revenue else 0 end)` from `fct_order_items`, excluding forward-dated rows (see caveat).

**Grain available at:** date (`ordered_at`), product, category, brand, department,
distribution centre, customer, order status.

**The judgment call:** whether to count orders that haven't shipped.
1. *Include Processing* — it's a placed order with payment taken, and the vast
   majority will ship. Excluding it makes the current period look artificially
   weak simply because orders haven't cleared the warehouse yet.
2. *Exclude Processing* — nothing has physically left the building and a
   portion will still be cancelled. Safer for finance, worse for daily trading.

`Processing` is 19.9% of lines and 20.1% of revenue, so the choice moves the
headline number by roughly 20.1%.

**We default to:** everything except `Cancelled`, i.e. `Processing`, `Shipped`,
`Complete` and `Returned`. Commercial teams need to see orders the day they
land. Finance can use the shipped-only view via the status dimension.

**Caveat:** the source generates forward-dated orders. All revenue queries must
filter `ordered_at < current_date()` until this is handled in `fct_order_items`.

**Common mistake:** excluding `Returned` here. Those items did sell and did
generate gross revenue; removing them turns this into Net Revenue and makes
the two metrics indistinguishable.


### Net Revenue

**Definition:** Gross revenue excluding returned items.

**SQL:** `sum(case when order_item_status not in ('Cancelled', 'Returned') then gross_revenue else 0 end)` from `fct_order_items`.

**Grain available at:** date (`ordered_at`), product, category, brand, department,
distribution centre, customer, order status.

**The judgment call:** whether March's net revenue change if a sale in March returns in April
1. *Sale-date attribution* — March number is correct but numbers can change each day until the end 
   of April (in case of a 30-day return policy). 90% of returns land within 8 days, so we treat a period as mature after 8 days.
2. *Return-date attribution* — March number only includes the returns in March so an order which  
   was done on March but returned in April will affect the April number. Less true to reality, but number won't change after March is over.

Measured on this data: p50 days-to-return is 5, p90 is 8, p99 is 9.

Note: this distribution is implausibly tight for fashion DTC, where returns
typically cluster near the end of the returns window and carry a long tail. It
reflects how theLook generates `returned_at` rather than real customer
behaviour. On production data I would expect p90 nearer 30–45 days, which makes
the maturity window materially more painful — a month would stay provisional for
six weeks rather than eight days. The method holds; only the constant changes.

**We default to:** Sale-date attribution, with an 8-day maturity window. Periods newer than 8 days are flagged provisional in dashboards.

**Common mistake:** comparing an immature recent month against a mature old month and
concluding quality improved.

### AOV

**Definition:** Total revenue ÷ total number of orders (cancelled orders excluded).

**SQL:** `round(sum(case when order_item_status != 'Returned' then gross_revenue else 0 end) / count(distinct order_id), 2)` from `fct_order_items` where `order_item_status != 'Cancelled'`.

**Grain available at:** date (`ordered_at`), customer, gender, number of items.

**The judgment call:** whether revenue is net or gross.
1. *Net* - This reflects the cash the business actually keeps. 
2. *Gross* — This reflects what the customer actually committed to spending at the exact moment of checkout. Important for marketing and merchandising.

AOV in case of gross revenue is 85.65USD. AOV in case of net revenue is 75.66USD. Net is 11.7% below gross.

**We default to:** Net. Shows a more real picture of how much is the average value order if we exclude the returns.

**Common mistake:** Product or category as grain. One order can include more products and more categories so it's not correct to calculate AOV for these dimensions.

### Discount Rate

**Definition:** 1 − (sale price ÷ full retail price).

**Status: not buildable on this source.** Checked `sale_price` against
`products.retail_price` across all non-cancelled lines: 0 of 153038 sold below
list. theLook generates `sale_price` from list price without modelling markdown,
so there is no discount signal to measure.

**What production would need:**
- An order-level discount or promotion field.

**Related metrics, equally unbuildable here:** full-price sell-through (share of
units sold before markdown) and markdown mix (share of revenue from discounted
units).

### Units

**Definition:** count of physical items sold.

**SQL:** `count(*)` from `fct_order_items` where `order_item_status != 'Cancelled'`.

**Grain available at:** date (`ordered_at`), product, category, brand, department,
distribution centre, customer, order status.

**The judgment call:** whether returned units count.
1. *Returned units included* — it is the most presice for the definition as it includes every item 
   sold, but returned items do come back to the warehouse so it is not a 'lost' item.
2. *Returned units excluded* — returned items show as they have never left the warehouse, as they 
   were not even sold. which is accurate in a way that they do come back to the warehouse almost like nothing happened.

Returned units included the units altogether 153038, excluded 135039. Number with returns excluded 11,76% below the returned units included number.

**We default to:** returned units included.

**Common mistake:** there is no quantity column, but has to be careful because if there is then the sql query is different, not this simple.

### Return Rate

**Definition:** Units returned ÷ units sold.

**SQL:** `round(countif(returned_at is not null) / count(*), 2)` from `fct_order_items` where `order_item_status != 'Cancelled'`.

**Grain available at:** date (`ordered_at`), product, category, brand, department,
distribution centre, customer, order status.

**The judgment call:** Three defensible versions, and they disagree by several points.
1. *Sale-date attribution* — returns counted against the period the item sold in.
   Truest measure of merchandise quality. Restates history for ~8 days.
2. *Return-date attribution* — returns counted in the period they arrive.
   Never restates, good for warehouse/ops capacity planning. Lags reality.
3. *Value-based* — return value ÷ gross revenue rather than units.
   Higher than the unit rate when expensive items return more, which for fashion they do.

Measured on this data: p50 days-to-return is 5, p90 is 8, p99 is 9.

**We default to:** sale-date, unit-based, with a documented 8-day maturity window.
Dashboards show the last complete 8-day period as "mature" and anything newer as provisional.

**Common mistake:** comparing an immature recent month against a mature old month and
concluding quality improved.