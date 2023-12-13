/*
Left join EGIB data with `gas grid`.
Dropping duplicated rows based on the smallest distance indicator
(for the each building, select the closest gas polygon) 
*/
SELECT bud.id egib_id, bud.geom egib_geom, gas_join.*,
       CASE WHEN dist<=10 THEN True ELSE False END as connected,
       CASE WHEN dist<=20 THEN True ELSE False END as connectable
FROM public.budynki AS bud
LEFT JOIN LATERAL (
    SELECT gas.*,
           St_Distance(gas.geom, ST_Transform(bud.geom, 2180)) AS dist
    FROM public.gastile AS gas
    ORDER BY ST_Transform(bud.geom, 2180) <-> gas.geom
    LIMIT 1
    ) AS gas_join
ON true;