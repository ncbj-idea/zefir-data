DROP function if exists get_gis_data_for_given_terc;
create or replace function get_gis_data_for_given_terc(
    terc_ varchar
)
    returns table (
                      id int,
                      identyfikator varchar,
                      funkcja_ogolna varchar,
                      funkcja_szczegolowa varchar[],
                      pow_obrysu_m2 numeric,
                      liczba_kondygnacji int,
                      pow_uzytkowa_m2 numeric,
                      czy_ogrzewany bool,
                      czy_zabytek bool,
                      other jsonb,
                      kategoria_istnienia text,
                      geom geometry(MultiPolygon, 2180),
                      miejscowosc varchar,
                      ulica varchar,
                      numer_porzadkowy varchar,
                      kod_pocztowy varchar,
                      longitude_addr double precision,
                      latitude_addr double precision,
                      longitude_centroid double precision,
                      latitude_centroid double precision,
                      addr_distance numeric,
                      gas_distance numeric,
                      heat_distance numeric,
                      heat_connected bool,
                      gas_connected bool

                  )
    language plpgsql
as $$
begin
    return query
        with adm_bound AS  (
            SELECT adm.geom as geom FROM administrative_boundary adm
            WHERE adm.terc = terc_
        ),
             ftr_buildings as (
                 SELECT ARRAY_AGG(kod) from dict_funkcja_szczegolowa
                 WHERE dict_funkcja_szczegolowa.czy_ogrzewany
             ),
             bdot AS(
                 SELECT *,
                        b.other ->> 'x_katistnienia' kategoria_istnienia,
                        round(st_area(b.geom):: numeric, 2) pow_obrysu_m2,
                        round((st_area(b.geom) * b.liczba_kondygnacji::FLOAT):: numeric, 2) pow_uzytkowa_m2,
                        (b.funkcja_szczegolowa && (SELECT * from ftr_buildings)) czy_ogrzewany
                 FROM bdot10k b
                 WHERE (ST_Contains((SELECT adm_bound.geom from adm_bound), b.geom))
             ),
             addr AS (SELECT *, ST_X(ST_Transform (a.geom, 4326)) AS longitude, ST_Y(ST_Transform (a.geom, 4326)) AS latitude
                      FROM address_point a WHERE ST_Contains((SELECT adm_bound.geom from adm_bound), a.geom)
             ),
             bdot_addr AS (
                 SELECT bdot.*, addr_join.miejscowosc, addr_join.ulica, addr_join.numer_porzadkowy,
                        addr_join.kod_pocztowy, addr_join.longitude, addr_join.latitude, addr_join.dist as addr_distance
                 FROM bdot
                          LEFT JOIN LATERAL (
                     SELECT addr.*, round(St_Distance(addr.geom, bdot.geom)::numeric, 3) AS dist
                     FROM addr
                     ORDER BY bdot.geom <-> addr.geom
                     LIMIT 1
                     ) AS addr_join
                                    ON true
             ),
             heat_tiles AS (
                 SELECT tile.* FROM tile
                 WHERE tile.layer = 3 and ST_Contains((SELECT adm_bound.geom from adm_bound), tile.geom)
             ),
             gas_tiles AS (
                 SELECT tile.* FROM tile
                 WHERE tile.layer = 4 and ST_Contains((SELECT adm_bound.geom from adm_bound), tile.geom)
             ),
             join_grids AS  (
                 SELECT bdot.*,
                        gas_dist, heat_dist,
                        CASE WHEN heat_dist<=10 THEN True ELSE False END as heat_connected,
                        CASE WHEN gas_dist<=10 THEN True ELSE False END as gas_connected
                 FROM bdot_addr as bdot
                          LEFT JOIN LATERAL (
                     SELECT gas.*, round(St_Distance(gas.geom, bdot.geom)::numeric, 3) AS gas_dist
                     FROM gas_tiles gas
                     ORDER BY bdot.geom <-> gas.geom
                     LIMIT 1
                     ) AS gas_join ON true
                          LEFT JOIN LATERAL (
                     SELECT heat.*, round(St_Distance(heat.geom, bdot.geom)::numeric, 3) AS heat_dist
                     FROM heat_tiles heat
                     ORDER BY bdot.geom <-> heat.geom
                     LIMIT 1
                     ) AS heat_join ON true
             )
        SELECT join_grids.id,
               join_grids.identyfikator,
               join_grids.funkcja_ogolna,
               join_grids.funkcja_szczegolowa,
               join_grids.pow_obrysu_m2,
               join_grids.liczba_kondygnacji,
               join_grids.pow_uzytkowa_m2,
               join_grids.czy_ogrzewany,
               join_grids.czy_zabytek,
               join_grids.other,
               join_grids.kategoria_istnienia,
               join_grids.geom,
               join_grids.miejscowosc,
               join_grids.ulica,
               join_grids.numer_porzadkowy,
               join_grids.kod_pocztowy,
               join_grids.longitude longitude_addr,
               join_grids.latitude latitude_addr,
               ST_X(ST_Transform (ST_Centroid(join_grids.geom), 4326)) longitude_centroid,
               ST_Y(ST_Transform (ST_Centroid(join_grids.geom), 4326)) latitude_centroid,
               join_grids.addr_distance,
               join_grids.gas_dist,
               join_grids.heat_dist,
               join_grids.heat_connected,
               join_grids.gas_connected
        FROM  join_grids
        WHERE join_grids.czy_ogrzewany;
end;$$
;