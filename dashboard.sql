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
    group by v_date
    order by v_date
),

tab2 as (
    l.created_at as created_at,
    count(l.lead_id) as lead_count
from leads as l
group by 1
order by 1
)

select
    tab2.l_date as datee,
    round(((tab2.lead_count * 100.00) / tab.click_count), 2) as conversionn
from tab2
inner join tab
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
