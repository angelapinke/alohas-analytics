select
    id                              as user_id,
    first_name,
    last_name,
    email,
    age,
    gender,
    state,
    street_address,
    postal_code,
    city,
    country,
    latitude,
    longitude,
    traffic_source,
    user_geom,
    cast(created_at as timestamp)   as ordered_at
from {{ source('thelook', 'users') }}