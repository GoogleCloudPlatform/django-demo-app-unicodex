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

import os
import sys

from django.contrib.auth.models import User
from django.core.management import call_command
from django.test import Client, TestCase, TransactionTestCase, tag
from django.urls import reverse

from unicodex.models import *

client = Client()

emoji_data = {"name": "Unicorn", "codepoint": "1F984", "description": "Magic!"}


class UnicodexIndexViewTest(TestCase):
    def test_landing_page(self):
        response = self.client.get(reverse("index"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Unicodex")


class UnicodexCodepointViewTest(TransactionTestCase):
    def test_fixture_data(self):
        emoji = Codepoint.objects.create(**emoji_data)

        self.assertEqual(len(Codepoint.objects.all()), 1)

        response = self.client.get(reverse("index"))
        self.assertContains(response, emoji.codepoint)

        response = self.client.get(f"/u/{emoji.codepoint}")
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Unicodex")

        self.assertContains(response, f"No {emoji.name} designs found")
        self.assertContains(response, emoji.description)
        self.assertContains(response, emoji.codepoint)


class UnicodexAdminGenerateTest(TransactionTestCase):
    @tag("external")
    def test_generate_design(self):
        user = User.objects.create_superuser(username="test", password="test")
        client.force_login(user)

        emoji = Codepoint.objects.create(**emoji_data)
        vendor = Vendor.objects.create(name="Twitter")
        vversion = VendorVersion.objects.create(name="Twemoji 2.0", vendor=vendor)

        response = client.get(reverse("admin:unicodex_vendor_changelist"))
        self.assertContains(response, vendor.name)

        response = client.get(reverse("admin:unicodex_vendorversion_changelist"))
        self.assertContains(response, vversion.name)

        data = {"action": "generate_designs", "_selected_action": [emoji.pk]}
        change_url = reverse("admin:unicodex_codepoint_changelist")
        response = client.get(change_url)
        self.assertContains(response, "Generate designs")

        # Importer is noisy, suppress output for a moment.
        sys.stdout = open(os.devnull, "w")
        response = client.post(change_url, data)
        sys.stdout = sys.__stdout__

        designs = Design.objects.all()
        self.assertEqual(len(designs), 1)

        response = client.get(reverse("admin:unicodex_design_changelist"))
        self.assertContains(response, vendor.name)

        twemoji_unicorn = Design.objects.get(codepoint=emoji.pk)
        self.assertTrue(vendor.name.lower() in twemoji_unicorn.image.name)
        self.assertTrue(emoji.name.lower() in twemoji_unicorn.image.name)
