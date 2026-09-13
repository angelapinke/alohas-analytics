Canonical metric definitions for the theLook DTC dataset; SQL is written against fct_order_items unless stated otherwise; every entry documents the judgment call, not just the formula.

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

**Definition:** Total revenue ÷ total number of orders.

**SQL:** 

**Grain available at:** 

**The judgment call:** whather revenue is net or gross.
1. *Net* - 
2. *Gross* — 

**We default to:** 

**Common mistake:** 