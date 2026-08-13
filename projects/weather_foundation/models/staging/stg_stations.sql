with raw_stations as (

    select * from {{ ref('raw_stations') }}

),

final as (

    select
        cast(raw_stations.station_id as varchar) as station_id,
        cast(raw_stations.station_name as varchar) as station_name,
        cast(raw_stations.region as varchar) as region,
        cast(raw_stations.country_code as varchar) as country_code,
        cast(raw_stations.latitude as float) as latitude,
        cast(raw_stations.longitude as float) as longitude,
        cast(raw_stations.elevation_m as number(10, 0)) as elevation_m,
        cast(raw_stations.station_type as varchar) as station_type,
        cast(raw_stations.sector_focus as varchar) as sector_focus,
        cast(raw_stations.opened_date as date) as opened_date,
        cast(raw_stations.is_active as boolean) as is_active
    from raw_stations

)

select * from final
