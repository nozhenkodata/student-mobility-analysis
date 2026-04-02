/*
АНАЛИЗ МЕЖДУНАРОДНОЙ МОБИЛЬНОСТИ РОССИЙСКИХ СТУДЕНТОВ (2000-2024 гг.)
----------------------------------------------------------------

ЦЕЛЬ - дополнить основной анализ проекта, проведенный с помощью Python: 
- проанализировать структуру данных; 
- рассчитать показатели структуры и динамики международной мобильности студентов из России с 2000 по 2024 г. (110 стран).
*/



-- 1. СТРУКТУРА И ПОЛНОТА ДАННЫХ

-------- Структура данных

SELECT 
    COUNT(*) AS Всего_строк,
    COUNT(DISTINCT country) AS Всего_стран,
    COUNT(DISTINCT year) AS Всего_лет,
    MIN(year) AS Первый_год,
    MAX(year) AS Последний_год
FROM student_mobility;


-------- Полнота данных

SELECT 
    country AS Страна,
    MIN(year) AS Первый_год,
    MAX(year) AS Последний_год,
    COUNT(*) AS Число_наблюдений,
    25 AS Ожидаемое_число_наблюдений,
    (25 - COUNT(*)) AS Число_пропусков,
    ROUND((25 - COUNT(*)) * 100.0 / 25) || '%' AS Доля_пропусков,
	CASE 
   		WHEN COUNT(*) = 25 THEN 'Полные данные'
    	WHEN COUNT(*) = (MAX(year) - MIN(year) + 1) AND COUNT(*) >= 5 THEN 'Непрерывный ряд (5+ лет)'
    	WHEN COUNT(*) = (MAX(year) - MIN(year) + 1) AND COUNT(*) BETWEEN 2 AND 4 THEN 'Непрерывный ряд (2-4 года)'
    	WHEN COUNT(*) = (MAX(year) - MIN(year) + 1) AND COUNT(*) = 1 THEN 'Данные за 1 год'
    	ELSE 'Пропуски внутри периода'
	END AS Полнота_данных
FROM student_mobility
GROUP BY country
ORDER BY ROUND((25 - COUNT(*)) * 100.0 / 25) DESC;



-- 2. ОСНОВНЫЕ СТАТИСТИЧЕСКИЕ ПОКАЗАТЕЛИ

-------- Всего студентов, среднее, минимальное и максимальное число, размах, стандартное отклонение и коэффициент вариации

SELECT country AS  Страна,
	MIN(year) AS Первый_год,
	MAX(year) AS Последний_год,
	COUNT(*) AS Число_лет,
	SUM(students) AS Всего_студентов,
	ROUND(AVG(students)) AS Среднее_число,
	MIN(students) AS Мин_число,
	MAX(students) AS Макс_число,
	MAX(students)-MIN(students) AS Размах,
	ROUND(STDDEV(students),1) AS Ст_отклонение,
	ROUND(STDDEV(students)/AVG(students),2) AS Коэффициент_вариации
FROM student_mobility
GROUP BY country
ORDER BY Всего_студентов DESC;	



-- 3. ДИНАМИКА МОБИЛЬНОСТИ

-------- Годовое изменение числа студентов по странам

SELECT
    country AS Страна,
    year AS Год,
    students AS Число_студентов,
    students - LAG(students) OVER (
    	PARTITION BY country ORDER BY year
   ) AS Годовое_изменение
FROM student_mobility
ORDER BY
	CASE country
        WHEN 'Germany' THEN 1
        WHEN 'Czechia' THEN 2
        WHEN 'France' THEN 3
        WHEN 'United Kingdom' THEN 4
        WHEN 'Finland' THEN 5
        WHEN 'Kazakhstan' THEN 6
        WHEN 'Armenia' THEN 7
        WHEN 'Kyrgyzstan' THEN 8
        WHEN 'Türkiye' THEN 9
        WHEN 'Korea, Republic of' THEN 10
    END,
    country,
    year;


-------- Темп роста числа студентов по странам

SELECT 
    country AS Страна,
    year AS Год,
    students AS Число_студентов,
    CASE 
        WHEN LAG(students) OVER (PARTITION BY country ORDER BY year) IS NULL 
            THEN '—'
        WHEN LAG(students) OVER (PARTITION BY country ORDER BY year) = 0 
            AND students > 0
            THEN 'рост с 0 до ' || students || ' студентов'
        WHEN LAG(students) OVER (PARTITION BY country ORDER BY year) = 0 
            AND students = 0
            THEN '0%'
        ELSE ROUND(
            (students - LAG(students) OVER (PARTITION BY country ORDER BY year)) * 100.0 / 
            LAG(students) OVER (PARTITION BY country ORDER BY year), 
            1
        ) || '%'
    END AS Темп_роста
FROM student_mobility
ORDER BY
	CASE country
        WHEN 'Germany' THEN 1
        WHEN 'Czechia' THEN 2
        WHEN 'France' THEN 3
        WHEN 'United Kingdom' THEN 4
        WHEN 'Finland' THEN 5
        WHEN 'Kazakhstan' THEN 6
        WHEN 'Armenia' THEN 7
        WHEN 'Kyrgyzstan' THEN 8
        WHEN 'Türkiye' THEN 9
        WHEN 'Korea, Republic of' THEN 10
    END,
    country,
    year;


-------- Совокупный среднегодовой темп роста CAGR по странам за 2000-2024 гг. (доступные данные)

WITH years AS (
    SELECT 
        country,
        MIN(year) AS first_year,
        MAX(year) AS last_year
    FROM student_mobility
   	GROUP BY country
),
stud AS(
	SELECT country,
		first_year,
		last_year,
		(SELECT students FROM student_mobility sm
		WHERE sm.country=y.country AND sm.year=y.first_year) AS first_count,
		(SELECT students FROM student_mobility sm
		WHERE sm.country=y.country AND sm.year=y.last_year) AS last_count
	FROM years y
)
SELECT 
    country AS Страна,
    first_year AS Первый_год,
    last_year AS Последний_год,
    CASE 
    	WHEN first_count IS NULL OR first_count = 0 OR last_year = first_year
        THEN '—'
        ELSE ROUND((POWER(last_count*1.0/first_count, 1.0/(last_year - first_year)) - 1) * 100, 1) || '%' 
    END AS Среднегодовой_темп_роста
FROM stud
ORDER BY
	CASE country
        WHEN 'Germany' THEN 1
        WHEN 'Czechia' THEN 2
        WHEN 'France' THEN 3
        WHEN 'United Kingdom' THEN 4
        WHEN 'Finland' THEN 5
        WHEN 'Kazakhstan' THEN 6
        WHEN 'Armenia' THEN 7
        WHEN 'Kyrgyzstan' THEN 8
        WHEN 'Türkiye' THEN 9
        WHEN 'Korea, Republic of' THEN 10
    END,
    country;


-------- Среднегодовой темп роста по странам за 2013-2024 гг. (гибкий период)

WITH years_b AS (
	SELECT country,
		region,
		year,
		students,
		ROW_NUMBER() OVER(PARTITION BY country, region ORDER BY year) AS row_num1
	FROM student_mobility_regions
	WHERE year BETWEEN 2013 AND 2015
),
years_e AS (
	SELECT country,
		region,
		year,
		students,
		ROW_NUMBER() OVER(PARTITION BY country, region ORDER BY year DESC) AS row_num2
	FROM student_mobility_regions
	WHERE year BETWEEN 2022 AND 2024
),
first_v AS (
	SELECT country,
		region,
		year AS f_year,
		SUM(students) AS f_value
	FROM years_b
	WHERE row_num1=1
	GROUP BY country, region, year
),
last_v AS (
	SELECT country,
		region,
		year AS l_year,
		SUM(students) AS l_value
	FROM years_e
	WHERE row_num2=1
	GROUP BY country, region, year
)
SELECT f.country AS Страна,
	f.region AS Регион,
	f_year AS Первый_год,
	l_year AS Последний_год,
	f_value AS Первое_значение,
	l_value AS Последнее_значение,
	l_year-f_year AS Число_лет,
	l_value-f_value AS Прирост,
	CASE
		WHEN f_value IS NULL OR l_value IS NULL OR f_value=0 OR l_value=0
		THEN NULL
		ELSE ROUND((POWER(l_value*1.0/f_value, 1.0/(l_year-f_year))-1)*100,1) || '%'
	END AS cagr_2013_2024
FROM first_v f JOIN last_v l ON f.country=l.country AND f.region=l.region
ORDER BY Прирост DESC;


-------- Среднегодовые темпы роста Европы и Азии (2000-2024 гг.)

WITH region_sums AS (
    SELECT 
        region,
        SUM(CASE WHEN year = 2000 THEN students END) AS sum_2000,
        SUM(CASE WHEN year = 2024 THEN students END) AS sum_2024
    FROM student_mobility_regions
    WHERE region IN ('Europe', 'Asia')
    GROUP BY region
)
SELECT 
    region AS Регион,
    ROUND((POWER(sum_2024 * 1.0 /sum_2000, 1.0 / (2024-2000)) - 1) * 100, 1) || '%' AS Среднегодовой_темп_роста
FROM region_sums
ORDER BY 1 DESC;


-------- Среднегодовые темпы роста Европы и Азии за два периода (2000-2012 и 2013-2024 гг.)

WITH region_sums_2000_2012 AS (
    SELECT 
        region,
        SUM(CASE WHEN year=2000 THEN students END) AS sum_2000,
        SUM(CASE WHEN year = 2012 THEN students END) AS sum_2012
    FROM student_mobility_regions
    WHERE region IN ('Europe', 'Asia')
    GROUP BY region
),
cagr_2000_2012 AS (
	SELECT region AS Регион,
    	ROUND((POWER(sum_2012 * 1.0 /sum_2000, 1.0 / (2012-2000)) - 1) * 100, 1) || '%' AS cagr_2000_2012
	FROM region_sums_2000_2012
),
region_sums_2013_2024 AS (
    SELECT region,
        SUM(CASE WHEN year=2013 THEN students END) AS sum_2013,
        SUM(CASE WHEN year = 2024 THEN students END) AS sum_2024
    FROM student_mobility_regions
    WHERE region IN ('Europe', 'Asia')
    GROUP BY region
),
cagr_2013_2024 AS (
	SELECT region AS Регион,
    	ROUND((POWER(sum_2024 * 1.0 /sum_2013, 1.0 / (2024-2013)) - 1) * 100, 1) || '%' AS cagr_2013_2024
	FROM region_sums_2013_2024
)
SELECT Регион,
	cagr_2000_2012,
	cagr_2013_2024
FROM cagr_2000_2012 JOIN cagr_2013_2024 USING (Регион)
ORDER BY 1 DESC;



-- 4. СТРУКТУРА МОБИЛЬНОСТИ 

-------- Структура в начале рассматриваемого периода (2000 г.)

SELECT country AS Страна,
	students AS Число_студентов_начало_периода,
	ROUND(students*100.0/(
		SELECT SUM(students) 
		FROM student_mobility 
		WHERE year=(
			SELECT MIN(year) FROM student_mobility)
	),1) || '%' AS Доля_страны
FROM student_mobility
WHERE year=(
	SELECT MIN(year) FROM student_mobility)
ORDER BY round(students*100.0/(
		SELECT SUM(students) 
		FROM student_mobility 
		WHERE year=(
			SELECT MIN(year) FROM student_mobility)
	),1) DESC;


-------- Структура в конце рассматриваемого периода (2024 г.)

SELECT country AS Страна,
	students AS Число_студентов_конец_периода,
	ROUND(students*100.0/(
		SELECT SUM(students) 
		FROM student_mobility 
		WHERE year=(
			SELECT MAX(year) FROM student_mobility)
	),1) || '%' AS Доля_страны
FROM student_mobility
WHERE year=(
	SELECT MAX(year) FROM student_mobility)
ORDER BY ROUND(students*100.0/(
		SELECT SUM(students) 
		FROM student_mobility 
		WHERE year=(
			SELECT MAX(year) FROM student_mobility)
	),1) DESC;


-------- Уровень концентрации мобильности по странам (HHI) в 2000 и 2024 гг. и его изменение

WITH total_2000 AS (
    SELECT SUM(students) AS global_sum_2000
    FROM student_mobility
    WHERE year=2000
),
total_2024 AS (
    SELECT SUM(students) AS global_sum_2024
    FROM student_mobility
    WHERE year=2024
),
shares_2000 AS (
    SELECT 
        country,
        SUM(students) AS country_sum,
        SUM(students) * 1.0 / (SELECT global_sum_2000 
        	FROM total_2000) AS share_2000
    FROM student_mobility
    WHERE year=2000
    GROUP BY country
),
shares_2024 AS (
    SELECT 
        country,
        SUM(students) AS country_sum,
        SUM(students) * 1.0 / (SELECT global_sum_2024 
        	FROM total_2024) AS share_2024
    FROM student_mobility
    WHERE year=2024
    GROUP BY country
 )
SELECT 
    ROUND(SUM(share_2000 * share_2000), 4) AS HHI_2000,
    ROUND(SUM(share_2024 * share_2024), 4) AS HHI_2024,
    ROUND((SUM(share_2024 * share_2024)-SUM(share_2000 * share_2000))
    	*100.0/NULLIF(SUM(share_2000 * share_2000),0),2) || '%' as Изменение
FROM shares_2000
	FULL OUTER JOIN shares_2024 USING(country);


-------- Доли Европы, Азии и Северной Америки за два периода (2000-2012 и 2013-2024 гг.)

WITH reg AS(
	SELECT SUM(CASE WHEN region='Europe' AND year BETWEEN 2000 AND 2012 THEN students END) AS sum_stud_e,
		SUM(CASE WHEN region='Europe' AND year BETWEEN 2013 AND 2024 THEN students END) AS sum_stud_e_end,
		SUM(CASE WHEN region='Asia' AND year BETWEEN 2000 AND 2012 THEN students END) AS sum_stud_a,
		SUM(CASE WHEN region='Asia' AND year BETWEEN 2013 AND 2024 THEN students END) AS sum_stud_a_end,
		SUM(CASE WHEN region='North America' AND year BETWEEN 2000 AND 2012 THEN students END) AS sum_stud_nam,
		SUM(CASE WHEN region='North America' AND year BETWEEN 2013 AND 2024 THEN students END) AS sum_stud_nam_end
	FROM student_mobility_regions
),
total AS(
	SELECT (
		SELECT SUM(students) 
		FROM student_mobility_regions
		WHERE year BETWEEN 2000 AND 2012
		) AS total_2000_2012,
		(
		SELECT sum(students) 
		FROM student_mobility_regions
		WHERE year BETWEEN 2013 AND 2024
		) AS total_2013_2024
)
SELECT '2000-2012' AS Период,
	ROUND(sum_stud_e*100.0/total_2000_2012,1) ||'%' AS "Доля стран Европы",
	ROUND(sum_stud_a*100.0/total_2000_2012,1) ||'%' AS "Доля стран Азии",
	ROUND(sum_stud_nam*100.0/total_2000_2012,1) ||'%' AS "Доля стран Северной Америки"
FROM reg CROSS JOIN total 
UNION ALL
SELECT '2013-2024' AS Период,
	ROUND(sum_stud_e_end*100.0/total_2013_2024,1) ||'%' AS "Доля стран Европы",
	ROUND(sum_stud_a_end*100.0/total_2013_2024,1) ||'%' AS "Доля стран Азии",
	ROUND(sum_stud_nam_end*100.0/total_2013_2024,1) ||'%' AS "Доля стран Северной Америки"
FROM reg CROSS JOIN total;


-- 5. РАНЖИРОВАНИЕ СТРАН

-------- Место стран в общем потоке в начале и конце рассматриваемого периода (2000 и 2024 гг.) и его изменение

WITH rank_beg AS(
	SELECT country,
		RANK() OVER (ORDER BY SUM(students) DESC) AS rank_b
	FROM student_mobility
	WHERE year=(
		SELECT MIN(year)
		FROM student_mobility
	)
	GROUP BY country
),
rank_end AS(
	SELECT country,
		RANK() OVER (ORDER BY SUM(students) DESC) AS rank_e
	FROM student_mobility
	WHERE year=(
		SELECT MAX(year)
		FROM student_mobility
	)
	GROUP BY country
)
SELECT country AS Страна,
	rank_b AS Ранг_начало_периода,
	rank_e AS Ранг_конец_периода,
	CASE
		WHEN rank_b IS NULL OR rank_e IS NULL THEN '-'
		ELSE ABS(rank_e-rank_b) || ' п.'
	END AS Изменение_по_модулю,
	CASE
		WHEN rank_b>rank_e THEN 'Рост'
		WHEN rank_b<rank_e THEN 'Снижение'
		WHEN rank_b IS NULL OR rank_e IS NULL THEN 'Недостаточно данных'
		ELSE 'Без изменений'
	END AS Динамика_ранга	
FROM rank_beg FULL OUTER JOIN rank_end USING(country)
ORDER BY Ранг_конец_периода;


-- 6. ИТОГИ ПО СТРАНАМ

-------- Итоговая таблица по странам: число наблюдений, среднее число студентов, стандартное отклонение, коэффициент вариации, всего студентов, среднегодовой темп роста, ранг за период

WITH years AS (
    SELECT 
        country,
        MIN(year) AS first_year,
        MAX(year) AS last_year
    FROM student_mobility
   	GROUP BY country
),
stud AS(
	SELECT country,
		first_year,
		last_year,
		(SELECT students FROM student_mobility sm
		WHERE sm.country=y.country AND sm.year=y.first_year) AS first_count,
		(SELECT students FROM student_mobility sm
		WHERE sm.country=y.country AND sm.year=y.last_year) AS last_count
	FROM years y
),
cagr AS(
	SELECT country,
    	first_year,
    	last_year,
    	CASE 
    		WHEN first_count IS NULL OR first_count = 0 OR last_year = first_year
        	THEN '—'
        	ELSE ROUND((POWER(last_count*1.0/first_count, 1.0/(last_year - first_year)) - 1) * 100, 1) || '%' 
    	END AS Среднегодовой_темп_роста
	FROM stud
),
stats AS(
	SELECT country,
		COUNT(*) AS Число_наблюдений,
    	ROUND(AVG(students)) AS Среднее_число_студентов,
    	ROUND(STDDEV(students),1) AS Станд_отклонение,
    	ROUND(STDDEV(students)/AVG(students),2) AS Коэффициент_вариации,
    	SUM(students) AS Всего_студентов,
    	RANK() OVER (ORDER BY SUM(students) DESC) AS Ранг_за_период
	FROM student_mobility
	GROUP BY country
)
SELECT country as Страна,
	Число_наблюдений,
	Среднее_число_студентов,
	Станд_отклонение,
	Коэффициент_вариации,
	Всего_студентов,
	Среднегодовой_темп_роста,
	Ранг_за_период
FROM stats JOIN cagr USING (country)
ORDER BY Ранг_за_период, Страна;
	

