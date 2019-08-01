--1
SELECT date_part('month',s.date_created) mon,COUNT(date_created) started_sub_flow, round(100*COUNT(date_initialized)/COUNT(date_created),2) percent_subscribed FROM thistle_web.subscriptions_subscription s 
GROUP BY date_part('month',s.date_created);

--2
SELECT   s.protein_type, 
         Count(DISTINCT user_id)                                      num_users, 
         Round(100*Count(s.date_initialized)/Count(s.date_created),2)/100 success_rate 
FROM     thistle_web.subscriptions_subscription s 
WHERE    s.protein_type!='' 
GROUP BY s.protein_type; 

--3
SELECT Count(user_id) cancellation_within_14_days 
FROM   thistle_web.subscriptions_subscription s 
JOIN   thistle_web.subscriptions_subscriptioncancellation sc 
ON     s.id=sc.subscription_id 
AND    date_cancelled <= date_initialized + interval '14' day; 


--4
SELECT   a.cohort                   AS cohort, 
         a.week                     AS week, 
         Date_part('week',a.week+1) AS week_number , 
         Count(js.date_initialized)    cohort_total, 
         (Count(js.date_initialized)-Sum( 
         CASE 
                  WHEN js.date_cancelled > a.cohort 
                  AND      js.date_cancelled < a.week + 7 THEN 1 
                  ELSE 0 
         END )) active_subs, 
         Round (Cast(Float8 ((Count(js.date_initialized)-Sum( 
         CASE 
                  WHEN js.date_cancelled > a.cohort 
                  AND      js.date_cancelled < a.week THEN 1 
                  ELSE 0 
         END ))/Cast(Count(js.date_initialized) AS FLOAT)) AS NUMERIC),2) active_percent 
FROM     ( 
                SELECT * 
                FROM   thistle_web.subscriptions_subscription s 
                JOIN   thistle_web.subscriptions_subscriptioncancellation sc 
                ON     s.id=sc.subscription_id ) js, 
         ( 
                SELECT e1.day AS cohort, 
                       e2.day AS week 
                FROM   etl_calendar e1, 
                       etl_calendar e2 
                WHERE  e1.dow='sun' 
                AND    e2.dow='sun' 
                AND    e1.day < '2018-01-01' 
                AND    e2.day < e1.day + interval '1' year
                AND    e2.day >=e1.day ) a 
WHERE    Cast(js.date_initialized AS DATE) < a.cohort + interval '7' day 
AND      cast(js.date_initialized AS date) >= a.cohort 
GROUP BY 1, 2 
ORDER BY 1, 2;