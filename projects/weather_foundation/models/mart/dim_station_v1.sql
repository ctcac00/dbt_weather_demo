with stg_stations as (

    select * from {{ ref('stg_stations') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['stg_stations.station_id']) }} as station_key,
        stg_stations.station_id,
        stg_stations.station_name,
        stg_stations.region,
        stg_stations.country_code,
        stg_stations.latitude,
        stg_stations.longitude,
        stg_stations.elevation_m,
        stg_stations.station_type,
        stg_stations.sector_focus,
        stg_stations.opened_date,
        stg_stations.is_active
    from stg_stations

)

select * from final
