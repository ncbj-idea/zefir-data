/*
Left join EGIB data with `dane adresowe`.
Dropping duplicated rows based on the smallest distance indicator
(for the each building, select the closest address point) 
*/
SELECT bud.id egib_id, bud.geom egib_geom, addr_join.*
FROM public.budynki AS bud
LEFT JOIN LATERAL (
    SELECT pkt.*,
           St_Distance(ST_Transform(pkt.geom, 2178), bud.geom) AS dist
    FROM public."PunktyAdresowe" AS pkt
    ORDER BY ST_Transform(bud.geom, 2180) <-> pkt.geom
    LIMIT 1
    ) AS addr_join
ON true;