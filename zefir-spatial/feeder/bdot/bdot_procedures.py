BDOT_UPDATE_PROCEDURE_NAME = "update_bdot10k"
CREATE_BDOT_UPDATE_PROC = f"""
create or replace procedure {BDOT_UPDATE_PROCEDURE_NAME}(
    imp_id int
)
    language plpgsql
as $$
begin
    update bdot10k
    set funkcja_ogolna = other ->> 'funogolnabudynku',
        liczba_kondygnacji = (other ->> 'liczbakondygnacji') :: INTEGER,
        funkcja_szczegolowa = ARRAY(SELECT json_array_elements_text((other -> 'funszczegolowabudynku') :: json)),
        identyfikator = (ARRAY(SELECT json_array_elements_text((other -> 'egib|bt_referencjadoobiektu|idiip|bt_identyfikator|lokalnyid') :: json)) ) [1],
        czy_zabytek = (other ->> 'zabytek') :: boolean,
        kst = (other ->> 'kodkst')
    where bdot10k.import_id = imp_id;
end;$$
;
"""

if __name__ == "__main__":
    print(CREATE_BDOT_UPDATE_PROC)
