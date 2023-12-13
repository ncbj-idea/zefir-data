EGIB_UPDATE_PROCEDURE_NAME = "update_egib"
CREATE_EGIB_UPDATE_PROC = f"""
create or replace procedure {EGIB_UPDATE_PROCEDURE_NAME}(
    imp_id int
)
    language plpgsql
as $$
begin
    update egib
    set identyfikator = other ->> 'identyfikator',
        kst = other ->> 'funkcja'
    where egib.import_id = imp_id;
end;$$
;
"""


if __name__ == "__main__":
    print(CREATE_EGIB_UPDATE_PROC)
