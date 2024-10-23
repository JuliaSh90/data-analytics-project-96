with tab1 as (
    select
        s.visitor_id,
        s.visit_date,
        s.source,
        s.medium,
        s.campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id,
        row_number() over (partition by s.visitor_id order by s.visit_date desc)
        as visit_rank
    from sessions as s
    left join leads as l
        on
            s.visitor_id = l.visitor_id
            and s.visit_date <= l.created_at
    where s.medium != 'organic'
),

tab2 as (
    select
        to_char(va.campaign_date, 'yyyy-mm-dd') as campaign_date,
        va.utm_source,
        va.utm_medium,
        va.utm_campaign,
        sum(va.daily_spent) as total_expenses
    from vk_ads as va
    group by
        to_char(va.campaign_date, 'yyyy-mm-dd'),
        va.utm_source,
        va.utm_medium,
        va.utm_campaign
    union
    select
        to_char(ya.campaign_date, 'yyyy-mm-dd') as campaign_date,
        ya.utm_source,
        ya.utm_medium,
        ya.utm_campaign,
        sum(ya.daily_spent) as total_expenses
    from ya_ads as ya
    group by
        to_char(ya.campaign_date, 'yyyy-mm-dd'),
        ya.utm_source,
        ya.utm_medium,
        ya.utm_campaign
),

tab3 as (
    select
        tab1.source,
        tab1.medium,
        tab1.campaign,
        to_char(tab1.visit_date, 'yyyy-mm-dd') as visit_date,
        count(tab1.visitor_id) as visitors_count,
        count(tab1.visitor_id) filter
        (where tab1.created_at is not null) as leads_count,
        count(tab1.visitor_id) filter
        (where tab1.status_id = 142) as purchases_count,
        sum(tab1.amount) filter (where tab1.status_id = 142) as revenue
    from
        tab1
    where tab1.visit_rank = 1
    group by
        to_char(tab1.visit_date, 'yyyy-mm-dd'),
        tab1.source,
        tab1.medium,
        tab1.campaign
)

select
    tab3.visit_date,
    tab3.source as utm_source,
    tab3.medium as utm_medium,
    tab3.campaign as utm_campaign,
    tab3.visitors_count,
    tab2.total_expenses as total_cost,
    tab3.leads_count,
    tab3.purchases_count,
    tab3.revenue
from tab3
left join tab2
    on
        tab3.source = tab2.utm_source
        and tab3.medium = tab2.utm_medium
        and tab3.campaign = tab2.utm_campaign
        and tab3.visit_date = tab2.campaign_date
order by
    tab3.revenue desc nulls last,
    tab3.visit_date asc,
    tab3.visitors_count desc,
    utm_source asc,
    utm_medium asc,
    utm_campaign asc
limit 15;