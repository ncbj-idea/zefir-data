ADDR_POINTS_UPDATE_PROCEDURE_NAME = "update_addr_points"
CREATE_ADDR_POINTS_UPDATE_PROC = f"""
create or replace procedure {ADDR_POINTS_UPDATE_PROCEDURE_NAME}(
    imp_id int
)
    language plpgsql
as $$
begin
    update address_point
    set miejscowosc = other ->> 'miejscowosc',
        kod_pocztowy = other ->> 'kodpocztowy',
        ulica = other ->> 'ulica',
        numer_porzadkowy = other ->> 'numerporzadkowy'
    where address_point.import_id = imp_id;
end;$$
;
"""


if __name__ == "__main__":
    print(CREATE_ADDR_POINTS_UPDATE_PROC)
