#1 Список клиентов
SELECT
    ID_client
FROM transactions
WHERE date_new >= '2015-06-01'
  AND date_new < '2016-06-01'
GROUP BY ID_client
HAVING COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) = 12;

SELECT
    ID_client,
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    COUNT(Id_check) AS operations,
    SUM(Sum_payment) AS monthly_sum,
    AVG(Sum_payment) AS avg_check
FROM transactions
WHERE date_new >= '2015-06-01'
  AND date_new < '2016-06-01'
  AND ID_client IN (
      SELECT ID_client
      FROM transactions
      WHERE date_new >= '2015-06-01'
        AND date_new < '2016-06-01'
      GROUP BY ID_client
      HAVING COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) = 12
  )
GROUP BY
    ID_client,
    DATE_FORMAT(date_new, '%Y-%m')
ORDER BY
    ID_client,
    month;
    
    #Final fo year
    SELECT
    ID_client,
    ROUND(AVG(Sum_payment), 2) AS avg_check_period,
    ROUND(SUM(Sum_payment) / 12, 2) AS avg_purchase_per_month,
    COUNT(Id_check) AS total_operations
FROM transactions
WHERE date_new >= '2015-06-01'
  AND date_new < '2016-06-01'
  AND ID_client IN (
      SELECT ID_client
      FROM transactions
      WHERE date_new >= '2015-06-01'
        AND date_new < '2016-06-01'
      GROUP BY ID_client
      HAVING COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) = 12
  )
GROUP BY ID_client
ORDER BY ID_client;


#2
WITH monthly_stats AS (
    SELECT
        DATE_FORMAT(date_new, '%Y-%m') AS month,

        AVG(Sum_payment) AS avg_check,

        COUNT(Id_check) AS total_operations,

        COUNT(DISTINCT ID_client) AS active_clients,

        SUM(Sum_payment) AS total_amount

    FROM transactions
    WHERE date_new >= '2015-06-01'
      AND date_new <  '2016-06-01'

    GROUP BY DATE_FORMAT(date_new, '%Y-%m')
)

SELECT
    month,
    ROUND(avg_check, 2) AS avg_check,
    total_operations,
    active_clients,
    total_amount,

    ROUND(
        total_operations /
        SUM(total_operations) OVER () * 100,
        2
    ) AS operations_share_year_percent,

    ROUND(
        total_amount /
        SUM(total_amount) OVER () * 100,
        2
    ) AS amount_share_year_percent

FROM monthly_stats
ORDER BY month;

#среднее количество операций в месяц за весь год
SELECT
    ROUND(COUNT(Id_check) / 12, 2) AS avg_operations_per_month
FROM transactions
WHERE date_new >= '2015-06-01'
  AND date_new <  '2016-06-01';
  
  #Среднее количество активных клиентов в месяц
  WITH monthly_clients AS (
    SELECT
        DATE_FORMAT(date_new, '%Y-%m') AS month,
        COUNT(DISTINCT ID_client) AS clients
    FROM transactions
    WHERE date_new >= '2015-06-01'
      AND date_new <  '2016-06-01'
    GROUP BY DATE_FORMAT(date_new, '%Y-%m')
)

SELECT
    ROUND(AVG(clients), 2) AS avg_active_clients_per_month
FROM monthly_clients;

#2 (e) M / F/ NA
WITH monthly_gender AS (
    SELECT
        DATE_FORMAT(t.date_new, '%Y-%m') AS month,

        CASE
            WHEN ci.Gender = 'M' THEN 'M'
            WHEN ci.Gender = 'F' THEN 'F'
            ELSE 'NA'
        END AS gender,

        COUNT(t.Id_check) AS operations,
        SUM(t.Sum_payment) AS amount

    FROM transactions t
    LEFT JOIN customer_info ci
        ON t.ID_client = ci.Id_client

    WHERE t.date_new >= '2015-06-01'
      AND t.date_new <  '2016-06-01'

    GROUP BY
        DATE_FORMAT(t.date_new, '%Y-%m'),
        CASE
            WHEN ci.Gender = 'M' THEN 'M'
            WHEN ci.Gender = 'F' THEN 'F'
            ELSE 'NA'
        END
),

monthly_totals AS (
    SELECT
        month,
        SUM(operations) AS total_operations,
        SUM(amount) AS total_amount
    FROM monthly_gender
    GROUP BY month
)

SELECT
    mg.month,
    mg.gender,

    mg.operations,

    ROUND(
        mg.operations / mt.total_operations * 100,
        2
    ) AS operations_percent,

    mg.amount,

    ROUND(
        mg.amount / mt.total_amount * 100,
        2
    ) AS amount_percent

FROM monthly_gender mg
JOIN monthly_totals mt
    ON mg.month = mt.month

ORDER BY
    mg.month,
    mg.gender;
    
    
    #3 
    
    SELECT
    CASE
        WHEN ci.AGE IS NULL THEN 'NA'
        WHEN ci.AGE < 20 THEN '<20'
        WHEN ci.AGE BETWEEN 20 AND 29 THEN '20-29'
        WHEN ci.AGE BETWEEN 30 AND 39 THEN '30-39'
        WHEN ci.AGE BETWEEN 40 AND 49 THEN '40-49'
        WHEN ci.AGE BETWEEN 50 AND 59 THEN '50-59'
        WHEN ci.AGE BETWEEN 60 AND 69 THEN '60-69'
        ELSE '70+'
    END AS age_group,

    SUM(t.Sum_payment) AS total_amount,

    COUNT(t.Id_check) AS total_operations,

    COUNT(DISTINCT t.ID_client) AS unique_clients

FROM transactions t
LEFT JOIN customer_info ci
    ON t.ID_client = ci.Id_client

WHERE t.date_new >= '2015-06-01'
  AND t.date_new < '2016-06-01'

GROUP BY
    CASE
        WHEN ci.AGE IS NULL THEN 'NA'
        WHEN ci.AGE < 20 THEN '<20'
        WHEN ci.AGE BETWEEN 20 AND 29 THEN '20-29'
        WHEN ci.AGE BETWEEN 30 AND 39 THEN '30-39'
        WHEN ci.AGE BETWEEN 40 AND 49 THEN '40-49'
        WHEN ci.AGE BETWEEN 50 AND 59 THEN '50-59'
        WHEN ci.AGE BETWEEN 60 AND 69 THEN '60-69'
        ELSE '70+'
    END

ORDER BY
    CASE
        WHEN age_group = '<20' THEN 1
        WHEN age_group = '20-29' THEN 2
        WHEN age_group = '30-39' THEN 3
        WHEN age_group = '40-49' THEN 4
        WHEN age_group = '50-59' THEN 5
        WHEN age_group = '60-69' THEN 6
        WHEN age_group = '70+' THEN 7
        WHEN age_group = 'NA' THEN 8
    END;
    
    
    WITH quarterly_age AS (
    SELECT
        CONCAT(
            YEAR(t.date_new),
            '-Q',
            QUARTER(t.date_new)
        ) AS quarter,

        CASE
            WHEN ci.AGE IS NULL THEN 'NA'
            WHEN ci.AGE < 20 THEN '<20'
            WHEN ci.AGE BETWEEN 20 AND 29 THEN '20-29'
            WHEN ci.AGE BETWEEN 30 AND 39 THEN '30-39'
            WHEN ci.AGE BETWEEN 40 AND 49 THEN '40-49'
            WHEN ci.AGE BETWEEN 50 AND 59 THEN '50-59'
            WHEN ci.AGE BETWEEN 60 AND 69 THEN '60-69'
            ELSE '70+'
        END AS age_group,

        SUM(t.Sum_payment) AS total_amount,

        COUNT(t.Id_check) AS operations,

        COUNT(DISTINCT t.ID_client) AS clients,

        AVG(t.Sum_payment) AS avg_check

    FROM transactions t

    LEFT JOIN customer_info ci
        ON t.ID_client = ci.Id_client

    WHERE t.date_new >= '2015-06-01'
      AND t.date_new < '2016-06-01'

    GROUP BY
        CONCAT(
            YEAR(t.date_new),
            '-Q',
            QUARTER(t.date_new)
        ),

        CASE
            WHEN ci.AGE IS NULL THEN 'NA'
            WHEN ci.AGE < 20 THEN '<20'
            WHEN ci.AGE BETWEEN 20 AND 29 THEN '20-29'
            WHEN ci.AGE BETWEEN 30 AND 39 THEN '30-39'
            WHEN ci.AGE BETWEEN 40 AND 49 THEN '40-49'
            WHEN ci.AGE BETWEEN 50 AND 59 THEN '50-59'
            WHEN ci.AGE BETWEEN 60 AND 69 THEN '60-69'
            ELSE '70+'
        END
),

quarter_totals AS (
    SELECT
        quarter,
        SUM(total_amount) AS quarter_amount,
        SUM(operations) AS quarter_operations
    FROM quarterly_age
    GROUP BY quarter
)

SELECT
    qa.quarter,
    qa.age_group,

    qa.total_amount,
    qa.operations,
    qa.clients,

    ROUND(qa.avg_check, 2) AS avg_check,

    ROUND(
        qa.total_amount / qt.quarter_amount * 100,
        2
    ) AS amount_percent,

    ROUND(
        qa.operations / qt.quarter_operations * 100,
        2
    ) AS operations_percent

FROM quarterly_age qa

JOIN quarter_totals qt
    ON qa.quarter = qt.quarter

ORDER BY
    qa.quarter,
    CASE
        WHEN qa.age_group = '<20' THEN 1
        WHEN qa.age_group = '20-29' THEN 2
        WHEN qa.age_group = '30-39' THEN 3
        WHEN qa.age_group = '40-49' THEN 4
        WHEN qa.age_group = '50-59' THEN 5
        WHEN qa.age_group = '60-69' THEN 6
        WHEN qa.age_group = '70+' THEN 7
        WHEN qa.age_group = 'NA' THEN 8
    END;