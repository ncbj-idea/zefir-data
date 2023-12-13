BEGIN;
    DROP TABLE IF EXISTS tmp_gis_data;
    CREATE TEMPORARY TABLE  tmp_gis_data AS
    SELECT *, CONCAT(ulica, numer_porzadkowy) as key_gis
    FROM get_gis_data_for_given_terc('2212011')
    WHERE czy_ogrzewany;
    CREATE INDEX trgm_data_idx ON tmp_gis_data USING GIST (key_gis gist_trgm_ops);
    CREATE INDEX addr_dist_idx ON tmp_gis_data(addr_distance);

    DROP TABLE IF EXISTS tmp_inwentaryzacja;
    CREATE TEMPORARY TABLE  tmp_inwentaryzacja AS
    SELECT *, CONCAT("Dane adresowe Ulica", "Dane adresowe Numer budynku") as key_inw
    FROM ustka.inwentaryzacja;
    CREATE INDEX trgm_inw_idx ON tmp_inwentaryzacja USING GIST (key_inw gist_trgm_ops);

    DROP TABLE IF EXISTS ustka.inwentaryzacja_join_gis_data;
    CREATE TABLE ustka.inwentaryzacja_join_gis_data AS
    SELECT *,
            "Dane adresowe Ulica" <-> ulica ulica_error,
            "Dane adresowe Numer budynku" <-> numer_porzadkowy numer_porzadkowy_error,
            ("Dane adresowe Numer budynku" <-> numer_porzadkowy) < 0.01 is_valid
    FROM tmp_inwentaryzacja inwentaryzacja
                LEFT JOIN LATERAL (
        SELECT data.*
        FROM tmp_gis_data data
        ORDER BY data.key_gis <-> inwentaryzacja.key_inw, data.addr_distance
        LIMIT 1
        ) AS join_
                        ON true;
    COMMIT;