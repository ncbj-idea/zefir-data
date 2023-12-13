from pathlib import Path


class InputValidatorException(Exception):
    pass


class InputValidatorExceptionGroup(InputValidatorException, ExceptionGroup):
    pass


class InputValidator:
    @staticmethod
    def path_must_exists(path: Path) -> None:
        if not path.exists():
            raise InputValidatorException(f"Path: {path} does not exist.")

    @staticmethod
    def validate_is_file(path: Path) -> None:
        if not path.is_file():
            raise InputValidatorException(
                "Path must contain file name and file extension."
                f" Given path: {path}. "
                "Expected path example:'C:/Users/username/Desktop/file_name.xlsx'"
            )

    @staticmethod
    def input_files_must_be_xlsx(path: Path) -> None:
        if not path.suffix == ".xlsx":
            raise InputValidatorException(
                f"File {path} should has .xlsx extension but {path.suffix} given."
            )

    @staticmethod
    def output_path_must_not_contain_file_name(path: Path) -> None:
        if path.suffix:
            raise InputValidatorException(
                f"Output path must not contain file name. Given output path: {path},"
                " expected output path example: C:/Users/username/results/ ."
            )
