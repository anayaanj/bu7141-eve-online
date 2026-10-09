"""Builds the Tableau starter: one extract per data/exports/*.csv (tableau/extracts/<name>.hyper, table "Extract"."Extract")
and tableau/eve_story.twb connected to all of them. Tableau Public only saves workbooks whose data sources are extracts.
Requires the Hyper API: python3 -m pip install tableauhyperapi. Usage: python3 scripts/make_workbook.py"""
import csv
import re
import tempfile
from pathlib import Path
from xml.sax.saxutils import quoteattr

from tableauhyperapi import (Connection, CreateMode, HyperProcess, SqlType, TableDefinition, TableName, Telemetry,
                             escape_string_literal)

ROOT = Path(__file__).resolve().parent.parent
EXPORTS = ROOT / "data" / "exports"
EXTRACTS = ROOT / "tableau" / "extracts"
OUT = ROOT / "tableau" / "eve_story.twb"

TYPES = {"integer": (SqlType.big_int(), "integer"), "real": (SqlType.double(), "real"), "date": (SqlType.date(), "date"),
         "boolean": (SqlType.bool(), "boolean"), "string": (SqlType.text(), "string")}


def infer(values):
    values = [v for v in values if v != ""]
    if not values:
        return "string"
    if all(re.fullmatch(r"-?\d+", v) for v in values):
        return "integer"
    if all(re.fullmatch(r"-?\d+(\.\d+)?(e[+-]?\d+)?", v, re.I) for v in values):
        return "real"
    if all(re.fullmatch(r"\d{4}-\d{2}-\d{2}", v) for v in values):
        return "date"
    if all(v in ("t", "f", "true", "false") for v in values):
        return "boolean"
    return "string"


def columns(path):
    with path.open(newline="", encoding="utf-8") as f:
        rows = list(csv.reader(f))
    header = rows[0]
    return [(c, infer([r[i] for r in rows[1:] if i < len(r)])) for i, c in enumerate(header)]


def build_extract(hyper, path, cols):
    table = TableDefinition(TableName("Extract", "Extract"), [TableDefinition.Column(c, TYPES[t][0]) for c, t in cols])
    with Connection(hyper.endpoint, EXTRACTS / f"{path.stem}.hyper", CreateMode.CREATE_AND_REPLACE) as conn:
        conn.catalog.create_schema("Extract")
        conn.catalog.create_table(table)
        return conn.execute_command(f"COPY {table.table_name} FROM {escape_string_literal(str(path))} "
                                    "WITH (format csv, NULL '', delimiter ',', header)")


def datasource(name, cols):
    meta = "\n".join(
        f"""        <metadata-record class='column'>
          <remote-name>{c}</remote-name>
          <local-name>[{c}]</local-name>
          <parent-name>[Extract]</parent-name>
          <local-type>{TYPES[t][1]}</local-type>
        </metadata-record>""" for c, t in cols)
    return f"""    <datasource caption={quoteattr(name)} inline='true' name='federated.{name}' version='18.1'>
      <connection class='federated'>
        <named-connections>
          <named-connection caption={quoteattr(name)} name='hyper.{name}'>
            <connection authentication='auth-none' author-locale='en_US' class='hyper' dbname='extracts/{name}.hyper' default-settings='yes' schema='Extract' sslmode='' tablename='Extract' username='tableau_internal_user' />
          </named-connection>
        </named-connections>
        <relation connection='hyper.{name}' name='Extract' table='[Extract].[Extract]' type='table' />
        <metadata-records>
{meta}
        </metadata-records>
      </connection>
      <aliases enabled='yes' />
    </datasource>"""


def main():
    EXTRACTS.mkdir(parents=True, exist_ok=True)
    sources = []
    with HyperProcess(Telemetry.DO_NOT_SEND_USAGE_DATA_TO_TABLEAU, parameters={"log_dir": tempfile.gettempdir()}) as hyper:
        for path in sorted(EXPORTS.glob("*.csv")):
            cols = columns(path)
            rows = build_extract(hyper, path, cols)
            sources.append(datasource(path.stem, cols))
            print(f"{path.stem}: {rows} rows")
    OUT.write_text(f"""<?xml version='1.0' encoding='utf-8' ?>
<workbook source-build='2026.2.0' source-platform='mac' version='18.1' xmlns:user='http://www.tableausoftware.com/xml/user'>
  <preferences>
    <color-palette name='EVE story' type='regular'>
      <color>#4fd1ff</color><color>#5b6b7a</color><color>#f2c45a</color><color>#ff6b4a</color>
      <color>#5fe0a1</color><color>#b48cff</color><color>#2e8fb8</color><color>#c7d3de</color>
    </color-palette>
  </preferences>
  <datasources>
{chr(10).join(sources)}
  </datasources>
  <worksheets>
    <worksheet name='Start here'>
      <table>
        <view>
          <datasources />
          <aggregation value='true' />
        </view>
        <style />
        <panes>
          <pane selection-relaxation-option='selection-relaxation-allow'>
            <view>
              <breakdown value='auto' />
            </view>
            <mark class='Automatic' />
          </pane>
        </panes>
        <rows />
        <cols />
      </table>
    </worksheet>
  </worksheets>
  <windows source-height='30'>
    <window class='worksheet' maximized='true' name='Start here'>
      <cards>
        <edge name='left'><strip size='160'><card type='pages' /><card type='filters' /><card type='marks' /></strip></edge>
        <edge name='top'><strip size='2147483647'><card type='columns' /></strip><strip size='2147483647'><card type='rows' /></strip></edge>
      </cards>
    </window>
  </windows>
</workbook>
""", encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)} with {len(sources)} extracts")


if __name__ == "__main__":
    main()
