# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# parse_docs.py /path/to/docs
# takes the living tutorial documentation and extracts any stanza marked shell

import re
import sys
import argparse
import datetime
from pathlib import Path


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

parser = argparse.ArgumentParser()

parser.add_argument("path")
parser.add_argument("--variables", default=False, action='store_true')
parser.add_argument("--project-id")
parser.add_argument("--instance-name")
parser.add_argument("--region")

args = parser.parse_args()

targets = sorted(Path(args.path).glob("*.md"))

r = []

r = ["#!/bin/bash -ex",
     "shopt -s expand_aliases",
     "",
     "# Generated from " + sys.argv[1] + " on " + str(datetime.datetime.now()),
     "# execute with: bash -ex script.sh",
     ""]

for x in targets:
    r.append(f"# {x.name}")
    with open(x) as f:
        data = extract(f, "shell")

    r.append("\n".join(data))

script = "\n".join(r)

if args.project_id:
    script = script.replace("YourProjectID", args.project_id)
if args.instance_name:
    script = script.replace("YourInstanceName", args.instance_name)
if args.region:
    script = script.replace("us-central1", args.region)

if args.variables:
    newscript = []
    for x in script.split("\n"):
        if "export" in x:
            var = x.split(" ")[1].split("=")[0]
            newscript.append(f"echo {var} = ${var}")
    script = '# Debugging -- export all the variables\n' + "; ".join(newscript)


print(script)
