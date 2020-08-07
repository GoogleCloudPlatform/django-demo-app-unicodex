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

from django.db import models
from django.utils.text import slugify


class Codepoint(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True, help_text="Totally optional, tbh.")
    codepoint = models.CharField(
        max_length=10,
        help_text="U+xxxx; tell me X, or I can work it out myself",
        blank=True,
    )
    emojipedia_name = models.CharField(
        max_length=50,
        help_text="If the name of this codepoint is strange on Emojipedia, add it here. Otherwise, I'll work it out myself.",
        blank=True,
    )
    order = models.IntegerField(default=1)

    @property
    def render(self):
        return f"U{str(self.codepoint).zfill(8)}"

    def __str__(self):
        return self.name

    @property
    def display(self):
        return f"&#x{self.codepoint};&#xFE0F;"


class Vendor(models.Model):
    name = models.CharField(max_length=100)

    def __str__(self):
        return self.name


class VendorVersion(models.Model):
    name = models.CharField(max_length=100)
    vendor = models.ForeignKey(Vendor, on_delete=models.CASCADE)

    def __str__(self):
        return "{} {}".format(self.vendor, self.name)


class Design(models.Model):
    vendorversion = models.ForeignKey(VendorVersion, on_delete=models.CASCADE)
    codepoint = models.ForeignKey(Codepoint, on_delete=models.CASCADE)

    def design_path(instance, filename):
        path = (
            f"design/{slugify(instance.vendorversion.vendor.name)}"
            f"/{slugify(instance.vendorversion.name)}/"
            f"{slugify(instance.codepoint.name)}/{filename}"
        )
        print(path)
        return path

    image = models.FileField(upload_to=design_path)

    class Meta:
        unique_together = ("vendorversion", "codepoint")

    def __str__(self):
        return " ".join([str(self.codepoint), str(self.vendorversion)])
