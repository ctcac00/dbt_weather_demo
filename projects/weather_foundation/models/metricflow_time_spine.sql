{{
    config(
        materialized='table',
        static_analysis='strict'
    )
}}

with spine as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2020-01-01' as date)",
        end_date="dateadd(year, 10, current_date())"
    ) }}

),

final as (

    select
        spine.date_day
    from spine

)

select * from final
