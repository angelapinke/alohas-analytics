select
    id                              as inventory_item_id,
    product_id,
    cost,                         
    product_category,
    product_name,
    product_brand,
    product_department,
    product_sku,
    product_distribution_center_id,
    cast(created_at as timestamp)   as ordered_at,
    cast(sold_at as timestamp)      as sold_at,
    product_retail_price                 
from {{ source('thelook', 'inventory_items') }}