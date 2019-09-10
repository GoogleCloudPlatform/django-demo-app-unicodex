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

from django.core.management.base import BaseCommand, CommandError
from unicodex.models import Codepoint, VendorVersion, Design
from django.core.files.base import File

# Magic import_emoji command

class Command(BaseCommand):
    def add_arguments(self, parser):
        parser.add_argument('codepoint')
        parser.add_argument('vendor_version_id')
        parser.add_argument('image_file')

    def handle(self, *args, **options):
        cp= Codepoint.objects.get(codepoint=options['codepoint'])
        vv = VendorVersion.objects.get(id=options['vendor_version_id'])
        img = open(options['image_file'], 'rb')

        d = Design.objects.create(codepoint=cp, vendorversion=vv, image=File(img))
        d.save()
        print(f"Added design for {cp.name}, {vv.vendor.name} {vv.name}")

