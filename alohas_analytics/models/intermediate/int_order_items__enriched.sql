SELECT 
    oi.order_item_id,
    oi.order_id,
    oi.customer_id,
    oi.product_id,
    oi.inventory_item_id,
    oi.order_item_status,
    oi.ordered_at,
    oi.returned_at,
    oi.gross_revenue,
    p.category, 
    p.brand, 
    p.retail_price, 
    p.department, 
    ii.cost, 
    u.country, 
    cm.local_currency, 
    fx.rate_to_eur,
    case
        when mod(abs(farm_fingerprint(cast(oi.order_id as string))), 10) = 0 then 'B2B'
        when mod(abs(farm_fingerprint(cast(oi.order_id as string))), 10) = 1 then 'Retail'
        else 'B2C'
    end as channel
FROM {{ ref('stg_thelook__order_items') }} oi
LEFT JOIN {{ ref('stg_thelook__products') }} p 
ON oi.product_id = p.product_id
LEFT JOIN {{ ref('stg_thelook__inventory_items') }} ii 
ON oi.inventory_item_id = ii.inventory_item_id
LEFT JOIN {{ ref('stg_thelook__users') }} u 
ON oi.customer_id = u.user_id
LEFT JOIN {{ ref('channel_map') }} cm 
ON u.country = cm.country
LEFT JOIN {{ ref('fx_rates') }} fx 
ON cm.local_currency = fx.currency