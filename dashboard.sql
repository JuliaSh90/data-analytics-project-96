/*Уникальное кол-во посетителей сайта*/
select
    count(distinct s.visitor_id) as visitors_count,
    to_char(s.visit_date, 'yyyy-mm-dd') as datee
from sessions as s
group by datee
order by datee;

/*Каналы, которые приводят на сайт посетителей (разбивка по дням и каналам)*/
select
    s.source,
    s.medium,
    s.campaign,
    count(distinct s.visitor_id) as visitors_count,
    to_char(s.visit_date, 'yyyy-mm-dd') as datee
from sessions as s
group by
    datee,
    s.source,
    s.medium,
    s.campaign
order by datee;


/*Каналы, которые приводят на сайт посетителей (разбивка по неделям и каналам)*/
select
    s.source,
    s.medium,
    s.campaign,
    count(distinct s.visitor_id) as visitors_count,
    extract(week from s.visit_date) as weekk
from sessions as s
group by
    weekk,
    s.source,
    s.medium,
    s.campaign
order by weekk;

/*Каналы, которые приводят на сайт посетителей (разбивка по месяцу и каналам)*/
select
    s.source,
    s.medium,
    s.campaign,
    count(distinct s.visitor_id) as visitors_count,
    to_char(s.visit_date, 'yyyy-mm') as monthh
from sessions as s
group by
    monthh,
    s.source,
    s.medium,
    s.campaign
order by monthh;

/*Количество лидов (разбивка по дате)*/
select
    to_char(l.created_at, 'yyyy-mm-dd') as datee,
    count(l.lead_id) as lead_count
from leads as l
group by datee
order by datee;

/*Конверсия из клика в лид*/
with tab as (
    select
        to_char(s.visit_date, 'yyyy-mm-dd') as v_date,
        count(s.visitor_id) as click_count
    from sessions as s
    group by to_char(s.visit_date, 'yyyy-mm-dd')
    order by to_char(s.visit_date, 'yyyy-mm-dd')
), 
tab2 as (
    select
        to_char(l.created_at, 'yyyy-mm-dd') as l_date,
        count(l.lead_id) as lead_count
    from leads as l
    group by to_char(l.created_at, 'yyyy-mm-dd')
    order by to_char(l.created_at, 'yyyy-mm-dd')
)

select
    tab2.l_date as date,
    round(((tab2.lead_count * 100.00) / tab.click_count), 2) as conversion
from tab2
join tab
on tab2.l_date = tab.v_date;

/*Конверсия из лида в оплату*/
with tab as (
    select count(l.lead_id) as total_leads
    from leads as l
),

tab1 as (
    select count(l.lead_id) as paid_lead
    from leads as l
    where l.status_id = 142
)

select round(((tab1.paid_lead * 100.00) / tab.total_leads), 2) as conversionn
from tab1
cross join tab;

/*Затраты на каждый канал (с разбивкой по дням)*/
select
    to_char(va.campaign_date, 'yyyy-mm-dd') as campaign_datee,
    va.utm_source,
    va.utm_medium,
    va.utm_campaign,
    sum(va.daily_spent) as daily_spent
from vk_ads as va
group by campaign_datee, va.utm_source, va.utm_medium, va.utm_campaign
union
select
    to_char(ya.campaign_date, 'yyyy-mm-dd') as campaign_datee,
    ya.utm_source,
    ya.utm_medium,
    ya.utm_campaign,
    sum(ya.daily_spent) as daily_spent
from ya_ads as ya
group by campaign_datee, ya.utm_source, ya.utm_medium, ya.utm_campaign
order by campaign_datee, ya.utm_source, ya.utm_medium, ya.utm_campaign;


/*Окупаемость затрат на каналы*/
with tab as (
    select
        s.source,
        s.medium,
        s.campaign,
        to_char(l.created_at, 'yyyy-mm-dd') as datee,
        sum(l.amount) as income
    from leads as l
    left join sessions as s
        on s.visitor_id = l.visitor_id
    group by s.source, s.medium, s.campaign, datee
    order by s.source, s.medium, s.campaign, datee
),

tab1 as (
    select
        to_char(va.campaign_date, 'yyyy-mm-dd') as date1,
        va.utm_source,
        va.utm_medium,
        va.utm_campaign,
        sum(va.daily_spent) as daily_spent
    from vk_ads as va
    group by date1, va.utm_source, va.utm_medium, va.utm_campaign
    union
    select
        to_char(ya.campaign_date, 'yyyy-mm-dd') as date1,
        ya.utm_source,
        ya.utm_medium,
        ya.utm_campaign,
        sum(ya.daily_spent) as daily_spent
    from ya_ads as ya
    group by date1, ya.utm_source, ya.utm_medium, ya.utm_campaign
    order by date1, ya.utm_source, ya.utm_medium, ya.utm_campaign
)

select
    tab.date,
    tab.source,
    tab.medium,
    tab.campaign,
    sum(((tab.income - tab1.daily_spent) / tab1.daily_spent) * 100.00) as roi
from tab
inner join tab1
    on
        tab.date = tab1.date1
        and tab.source = tab1.utm_source
        and tab.medium = tab1.utm_medium
        and tab.campaign = tab1.utm_campaign
group by tab.date, tab.source, tab.medium, tab.campaign;

/*Расчет метрики cpu, cpl, cppu, roi по utm_source*/
with tab1 as (
    select distinct on (s.visitor_id)
        s.visitor_id,
        s.visit_date,
        l.created_at,
        l.status_id,
        l.amount,
        l.lead_id,
        l.closing_reason,
        s.medium,
        s.source,
        s.campaign
    from sessions as s
    left join leads as l
        on
            s.visitor_id = l.visitor_id
            and s.visit_date <= l.created_at
    where s.medium != 'organic'
    order by
        s.visitor_id asc,
        s.visit_date desc
)
,
tab as (
    select
        va.utm_source,
        va.utm_medium,
        va.utm_campaign,
        cast(va.campaign_date as date) as campaign_date,
        sum(va.daily_spent) as total_cost
    from vk_ads as va
    group by
        va.utm_source,
        va.utm_medium,
        va.utm_campaign,
        cast(va.campaign_date as date)
    union
    select
        ya.utm_source,
        ya.utm_medium,
        ya.utm_campaign,
        cast(ya.campaign_date as date) as campaign_date,
        sum(ya.daily_spent) as total_cost
    from ya_ads as ya
    group by
        ya.utm_source,
        ya.utm_medium,
        ya.utm_campaign,
        cast(ya.campaign_date as date)
)
,
tab2 as (
    select
        tab1.source,
        tab1.medium,
        tab1.campaign,
        cast(tab1.visit_date as date) as visit_date,
        count(tab1.visitor_id) as visitors_count,
        count(tab1.visitor_id) filter (
            where tab1.created_at is not null
        ) as leads_count,
        count(tab1.visitor_id) filter (
            where tab1.status_id = 142
        ) as purchases_count,
        sum(tab1.amount) filter (
            where tab1.status_id = 142
        ) as revenue
    from
        tab1
    group by
        tab1.source,
        tab1.medium,
        tab1.campaign,
        cast(tab1.visit_date as date)
)
,
tab3 as (
select
    tab2.visit_date as visit_date,
    tab2.visitors_count,
    tab2.source as utm_source,
    tab2.medium as utm_medium,
    tab2.campaign as utm_campaign,
    tab.total_cost,
    tab2.leads_count,
    tab2.purchases_count,
    tab2.revenue
from tab2
left join tab
    on
        tab2.medium = tab.utm_medium
        and tab2.source = tab.utm_source
        and tab2.campaign = tab.utm_campaign
        and tab2.visit_date = tab.campaign_date
where tab2.medium != 'organic'
and tab2.source = 'vk' or tab2.source = 'yandex'
group by 1, 2, 3, 4, 5, 6, 7, 8, 9
order by
    tab2.revenue desc nulls last,
    tab2.visit_date asc,
    tab2.visitors_count desc,
    utm_source asc,
    utm_medium asc,
    utm_campaign asc
)
select
    tab3.utm_source,
    round(sum(tab3.total_cost) / sum(tab3.visitors_count), 1) as cpu,
    case when sum(tab3.leads_count) = 0 or sum(tab3.leads_count) is null then 0
        else round(sum(tab3.total_cost) / sum(tab3.leads_count), 1) end as cpl,
    case when sum(tab3.purchases_count) = 0
    or sum(tab3.purchases_count) is null then 0
        else round(sum(tab3.total_cost) / sum(tab3.purchases_count), 1)
        end as cppu,
    round((sum(tab3.revenue) - sum(tab3.total_cost)) /
    sum(tab3.total_cost) * 100, 1) as roi
from tab3
group by 1;

/*Расчет метрики cpu, cpl, cppu, roi по source, medium и campaign*/
with tab1 as (
    select distinct on (s.visitor_id)
        s.visitor_id,
        s.visit_date,
        l.created_at,
        l.status_id,
        l.amount,
        l.lead_id,
        l.closing_reason,
        s.medium,
        s.source,
        s.campaign
    from sessions as s
    left join leads as l
        on
            s.visitor_id = l.visitor_id
            and s.visit_date <= l.created_at
    where s.medium != 'organic'
    order by
        s.visitor_id asc,
        s.visit_date desc
)
,
tab as (
    select
        va.utm_source,
        va.utm_medium,
        va.utm_campaign,
        cast(va.campaign_date as date) as campaign_date,
        sum(va.daily_spent) as total_cost
    from vk_ads as va
    group by
        va.utm_source,
        va.utm_medium,
        va.utm_campaign,
        cast(va.campaign_date as date)
    union
    select
        ya.utm_source,
        ya.utm_medium,
        ya.utm_campaign,
        cast(ya.campaign_date as date) as campaign_date,
        sum(ya.daily_spent) as total_cost
    from ya_ads as ya
    group by
        ya.utm_source,
        ya.utm_medium,
        ya.utm_campaign,
        cast(ya.campaign_date as date)
)
,
tab2 as (
    select
        tab1.source,
        tab1.medium,
        tab1.campaign,
        cast(tab1.visit_date as date) as visit_date,
        count(tab1.visitor_id) as visitors_count,
        count(tab1.visitor_id) filter (
            where tab1.created_at is not null
        ) as leads_count,
        count(tab1.visitor_id) filter (
            where tab1.status_id = 142
        ) as purchases_count,
        sum(tab1.amount) filter (
            where tab1.status_id = 142
        ) as revenue
    from
        tab1
    group by
        tab1.source,
        tab1.medium,
        tab1.campaign,
        cast(tab1.visit_date as date)
)
,
tab3 as (
select
    tab2.visit_date as visit_date,
    tab2.visitors_count,
    tab2.source as utm_source,
    tab2.medium as utm_medium,
    tab2.campaign as utm_campaign,
    tab.total_cost,
    tab2.leads_count,
    tab2.purchases_count,
    tab2.revenue
from tab2
left join tab
    on
        tab2.medium = tab.utm_medium
        and tab2.source = tab.utm_source
        and tab2.campaign = tab.utm_campaign
        and tab2.visit_date = tab.campaign_date
where tab2.medium != 'organic'
and tab2.source = 'vk' or tab2.source = 'yandex'
group by 1, 2, 3, 4, 5, 6, 7, 8, 9
order by
    tab2.revenue desc nulls last,
    tab2.visit_date asc,
    tab2.visitors_count desc,
    utm_source asc,
    utm_medium asc,
    utm_campaign asc
)
,
tab4 as (
select
    tab3.utm_source,
    tab3.utm_medium,
    tab3.utm_campaign,
    round(sum(tab3.total_cost) / sum(tab3.visitors_count), 1) as cpu,
    case when sum(tab3.leads_count) = 0 or
    sum(tab3.leads_count) is null then 0
        else round(sum(tab3.total_cost) /
        sum(tab3.leads_count), 1) end as cpl,
    case when sum(tab3.purchases_count) = 0
    or sum(tab3.purchases_count) is null then 0
        else round(sum(tab3.total_cost) /
        sum(tab3.purchases_count), 1) end as cppu,
    round((sum(tab3.revenue) - sum(tab3.total_cost)) /
    sum(tab3.total_cost) * 100, 1) as roi
from tab3
group by 1, 2, 3
order by 1, 2, 3, 4 desc, 5 desc, 6 desc, 7 desc
)
select * from tab4;
