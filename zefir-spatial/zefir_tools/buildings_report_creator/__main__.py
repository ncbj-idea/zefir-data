import datetime
import logging
import sys
from pathlib import Path

from db.session import engine
from zefir_tools.buildings_report_creator.cli import get_parser
from zefir_tools.buildings_report_creator.process import create_buildings_report

TEMPLATE_PATH = Path(__file__).parent / "Template.xlsx"
logger = logging.getLogger(__name__)


def main(args=None):
    if not args:
        args = sys.argv[1:]
    parser = get_parser()
    args = parser.parse_args(args)

    outpath, terc = args.outpath, args.terc
    if outpath is None:
        outpath = Path.cwd() / f"buildings_report_{terc}.xlsx"
    extended_data = create_buildings_report(engine, terc, TEMPLATE_PATH)
    if extended_data.empty:
        print(f"No data for given terc: '{terc}' in the database!")
    else:
        extended_data.to_excel(outpath, merge_cells=False, index=False)
        print(datetime.datetime.now(), "SAVED TO: ", outpath)


if __name__ == "__main__":
    # example: python -m zefir_tools.buildings_report_creator -t 2212011
    main()
