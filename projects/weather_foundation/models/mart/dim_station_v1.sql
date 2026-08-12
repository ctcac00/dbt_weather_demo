select
    {{ dbt_utils.generate_surrogate_key(['station_id']) }} as station_key,
    station_id,
    station_name,
    region,
    country_code,
    latitude,
    longitude,
    elevation_m,
    station_type,
    sector_focus,
    opened_date,
    is_active
from {{ ref('stg_stations') }}
