import os
import sys
import click
from math import ceil
import shutil

columns, _ = shutil.get_terminal_size()
RESULTS = {"success": 0, "failure": 0}


def header(msg):
    click.secho(f"\n# {msg}", bold=True)


def s(n):
    if n == 1:
        return ""
    return "s"


def error(s, details=None):
    lineart = "********************************"
    click.secho(f"{lineart}\nError {s}", bold=True, fg="red")
    if details:
        click.echo(details)
    click.secho(f"{lineart}", bold=True, fg="red")


def echo(msg, indent=""):
    click.echo(f"{indent}{msg}")


def summary():
    total = RESULTS["success"] + RESULTS["failure"]
    fails = RESULTS["failure"]
    if fails != 0:
        failcol = {"bold": True, "fg": "red"}
    else:
        failcol = {}
    click.echo(
        (
            click.style(
                f"\nResults: {total} check{s(total)}, ",
                bold=True,
            )
            + click.style(f"{fails} failure{s(fails)}", **failcol)
            + click.style(".", bold=True)
        )
    )
    if fails == 0:
        sys.exit(0)
    else:
        sys.exit(1)


def result(msg, success=True, details=None):
    if success:
        success_message = "PASS"
        fg = "green"
        RESULTS["success"] += 1
    else:
        success_message = "FAIL"
        fg = "red"
        RESULTS["failure"] += 1

    # overflow math. 7 is the result length ("[FAIL] ")
    amsg = msg.ljust(ceil((len(msg) + 7) / columns) * columns - 7)

    click.echo(amsg + click.style(f"[{success_message}]", fg=fg, bold=True))
    if details and not success:
        click.echo(details)


"""
Usage:
header("Testing the things")
result("I did a thing")
result("I failed a thing", success=False, details="how to fix the issue")
summary()
"""
