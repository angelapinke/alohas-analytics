select
    id                              as order_item_id,
    order_id,
    user_id                         as customer_id,
    product_id,
    inventory_item_id,
    status                          as order_item_status,
    cast(created_at as timestamp)   as ordered_at,
    cast(shipped_at as timestamp)   as shipped_at,
    cast(delivered_at as timestamp) as delivered_at,
    cast(returned_at as timestamp)  as returned_at,
    sale_price                      as gross_revenue
from {{ source('thelook', 'order_items') }}