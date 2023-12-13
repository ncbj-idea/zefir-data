/*
Left join EGIB data with BDOT10k.
Dropping duplicated rows based on the largest area indicator
(keep only that row that area of intersection is the largest within a group) 
*/
WITH bdot_join as (
    SELECT bud.id egib_id,
           bud.geom egib_geom,
           bdot.*,
           ST_Area(ST_Intersection(bud.geom, ST_Transform(bdot.geom, 2178))) inter_area,
           ST_Area(bud.geom) egib_area,
           ST_Area(ST_Transform(bdot.geom, 2178)) bdot_area,
           row_number() over (partition by bud.id order by ST_Area(ST_Intersection(bud.geom, ST_Transform(bdot.geom, 2178))) desc) rank_no
    FROM budynki as bud
             LEFT JOIN "bdot_BUBD_A" as bdot ON ST_Intersects(ST_Transform(bud.geom, 2180), bdot.geom)
)

SELECT *
FROM bdot_join
WHERE rank_no = 1 OR bdot_join.id is null;