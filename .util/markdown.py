#!/usr/bin/env python
import re
from pathlib import Path

"""
For a bunch of markdown, return all the triple-backtick blocks
"""


def extract(f, filter=None):
    code_blocks = []
    while True:
        line = f.readline()
        if not line:
            # EOF
            break

        out = re.match("[^`]*```(.*)$", line)
        if out:
            if filter and filter.strip() != out.group(1).strip():
                continue
            code_block = [f.readline()]
            while re.search("```", code_block[-1]) is None:
                code_block.append(f.readline())
            code_blocks.append("".join(code_block[:-1]))
    return code_blocks


"""
For a glob of files, send them all off for processing in a logical order
"""


def get_all_codeblocks(path):
    r = []
    targets = sorted(Path(path).glob("*.md"))
    for x in targets:
        r.append(f"# {x.name}")
        with open(x) as f:
            data = extract(f, "shell")

        r.append("\n".join(data))
    return r
