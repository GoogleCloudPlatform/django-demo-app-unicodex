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

from django.shortcuts import render

from unicodex.models import Codepoint, Design, Vendor, VendorVersion


def index(request):
    codepoints = Codepoint.objects.all().order_by('order')
    designs = Design.objects.all()
    vendors = Vendor.objects.all()
    return render(request, "index.html", {"codepoints": codepoints, "designs": designs})


def codepoint(request, codepoint="2728"):
    cd = Codepoint.objects.get(codepoint=codepoint)
    designs = Design.objects.filter(codepoint__id=cd.id).order_by(
        "vendorversion__vendor__name", "vendorversion__name"
    )
    return render(request, "codepoint.html", {"designs": designs, "codepoint": cd})


def vendor_list(request):
    v = Vendor.objects.all()
    return render(request, "vendor_list.html", {"vendors": v})


def vendorversion(request, vendor=None, version=None):
    vv = VendorVersion.objects.get(vendor=vendor, name=version)
    d = Design.objects.filter(vendorversion=vv)
    return render(request, "vendor.html", {"designs": d, "vendor_name": v.name})
