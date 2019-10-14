#!/usr/bin/python
#
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

import io
import os
import sys
from tempfile import NamedTemporaryFile
from urllib.parse import urlparse
from urllib.request import urlopen

import requests
from django.core.files.base import File
from django.core.management import call_command
from django.core.management.base import BaseCommand, CommandError
from django.utils.text import slugify

from bs4 import BeautifulSoup
from unicodex.models import Codepoint, Design, VendorVersion


# Force a flused output to get real-time output in StackDriver
def out(s):
    print(s, file=sys.stdout)
    sys.stdout.flush()


class Command(BaseCommand):
    def add_arguments(self, parser):
        parser.add_argument("codepoint")

    # Called from admin.py#generate_designs
    # Crawls emojipedia.org on the selected codepoint and pulls any information
    # from known vendor/vendorversions
    def handle(self, *args, **options):
        cp = Codepoint.objects.get(name=options["codepoint"])
        vendorversions = VendorVersion.objects.all()

        if cp.emojipedia_name:
            emojipedia_name = cp.emojipedia_name
        else:
            emojipedia_name = slugify(cp.name)

        uri = f"https://emojipedia.org/{emojipedia_name}"
        out(f"Retrieving data for {cp.name} from {uri}")

        resp = requests.get(uri)
        page = BeautifulSoup(resp.content, "html.parser")

        v = page.find_all(class_="vendor-image")

        def download_image(url):
            img_temp = NamedTemporaryFile(dir=".", delete=True)
            img_temp.write(urlopen(url).read())
            img_temp.flush()
            return img_temp

        out(f"Parsing {uri}")

        stats = {"ignored": 0, "added": 0, "skipped": 0}
        for x in v:
            if x.a:
                href = x.a["href"]
                url = x.a.img["data-src"]

                _, vendor, version, _, _ = href.split("/")
                version = version.replace("-", " ")

                try:
                    vv = VendorVersion.objects.get(
                        vendor__name__iexact=vendor, name__iexact=version
                    )

                    try:
                        d = Design.objects.get(codepoint=cp, vendorversion=vv)
                        out(
                            f"- Skipped existing vendorvesion: {vv.vendor.name} {vv.name}"
                        )
                        stats["skipped"] += 1
                    except Design.DoesNotExist:
                        # attempt from https://www.revsys.com/tidbits/loading-django-files-from-code/
                        img = download_image(url)
                        d = Design.objects.create(codepoint=cp, vendorversion=vv)
                        d.image.save(
                            os.path.basename(urlparse(url).path), File(img), save=True
                        )
                        out(f"- Added design for {cp.name}, {vv.vendor.name} {vv.name}")
                        stats["added"] += 1

                except VendorVersion.DoesNotExist:
                    out(f"- Ignoring unconfigured vendorversion: {vendor} {version}")
                    stats["ignored"] += 1
                    pass
        stat = ", ".join([f"{x}: {stats[x]}" for x in stats.keys()])
        out(f"Final statistics: {stat}")
