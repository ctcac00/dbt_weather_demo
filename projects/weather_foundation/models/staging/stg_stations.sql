select
    cast(station_id as varchar) as station_id,
    cast(station_name as varchar) as station_name,
    cast(region as varchar) as region,
    cast(country_code as varchar) as country_code,
    cast(latitude as float) as latitude,
    cast(longitude as float) as longitude,
    cast(elevation_m as number(10, 0)) as elevation_m,
    cast(station_type as varchar) as station_type,
    cast(sector_focus as varchar) as sector_focus,
    cast(opened_date as date) as opened_date,
    cast(is_active as boolean) as is_active
from {{ ref('raw_stations') }}
