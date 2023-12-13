import traceback
from datetime import datetime
from pathlib import Path

from bdot_ceeb_joiner.InputValidator import (
    InputValidator,
    InputValidatorException,
    InputValidatorExceptionGroup,
)
from bdot_ceeb_joiner.config import Config
from bdot_ceeb_joiner.process import process


def _validate_file_path(path: Path) -> None:
    InputValidator.path_must_exists(path)
    InputValidator.validate_is_file(path)
    InputValidator.input_files_must_be_xlsx(path)


def _validate_output_path(path: Path) -> None:
    InputValidator.path_must_exists(path)
    InputValidator.output_path_must_not_contain_file_name(path)


def main(config: Config = None) -> None:
    except_list = []
    if not config:
        success = False
        while not success:
            if except_list:
                exec_group = InputValidatorExceptionGroup(
                    "While parsing paths followed errors occurred", except_list
                )
                traceback.print_exception(exec_group)
                except_list = []

            ceeb_path = Path(input("Enter path to 'ceeb' .xlsx file:\n"))
            bdot_path = Path(input("Enter path to 'bdot' .xlsx file:\n"))
            zabytki_path = input("Enter path to 'zabytki' .xlsx file:\n")
            zabytki_path = Path(zabytki_path) if len(zabytki_path.strip()) > 0 else None
            output_path = Path(input("Enter path to save .xlsx files:\n"))
            joined_file_name = str(
                input("Enter name of the .xlsx file with joined bdot and ceeb:\n")
            )
            only_bdot_file_name = str(
                input("Enter name of the .xlsx file with non-joined bdot data:\n")
            )
            if zabytki_path:
                try:
                    _validate_file_path(zabytki_path)
                except InputValidatorException as exception_error:
                    except_list.append(exception_error)

            for method, file_name in (
                (_validate_file_path, ceeb_path),
                (_validate_file_path, bdot_path),
                (_validate_output_path, output_path),
            ):
                try:
                    method(file_name)
                except InputValidatorException as exception_error:
                    except_list.append(exception_error)

            if not except_list:
                success = True
                config = Config(
                    ceeb_path=ceeb_path,
                    bdot_path=bdot_path,
                    zabytki_path=zabytki_path,
                    output_path=output_path,
                    joined_file_name=joined_file_name,
                    only_bdot_file_name=only_bdot_file_name,
                )

    print(f"Joining process has been started - {datetime.now()}")
    ceeb_bdot_concat, only_bdot = process(config)
    print("Saving data to files")
    ceeb_bdot_concat.to_excel(
        (config.output_path / config.joined_file_name).with_suffix(".xlsx"), index=False
    )
    only_bdot.to_excel(
        (config.output_path / config.only_bdot_file_name).with_suffix(".xlsx"),
        index=False,
    )
    print(f"Joining process has ended - {datetime.now()}")


if __name__ == "__main__":
    config = Config(
        ceeb_path=Path("/home/artem/work/mzkutils/files/ceeb.xlsx"),
        bdot_path=Path("/home/artem/work/mzkutils/files/bdot.xlsx"),
        zabytki_path=None,
        output_path=Path(""),
        joined_file_name="ceeb_joined_bdot.xlsx",
        only_bdot_file_name="ceeb_only.xlsx",
    )
    main(config)
