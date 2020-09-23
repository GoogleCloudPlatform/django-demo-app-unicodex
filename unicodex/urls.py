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

from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import path, re_path
from django.views.static import serve

from unicodex.views import *


urlpatterns = [
    re_path(r"^u/(?P<codepoint>[\w-]+)$", codepoint, name="codepoint"),
    re_path(r"^vendors$", vendor_list, name="vendor_list"),
    re_path(r"^vendor/(?P<vendor>[\w-]+)/(?P<version>[\w.]+)", vendorversion),
    re_path(r"^$", index, name="index"),
    path("admin/", admin.site.urls),
]


if settings.DEBUG:
    urlpatterns += [
        re_path(
            r"^media/(?P<path>.*)$",
            serve,
            {"document_root": settings.MEDIA_ROOT, "show_indexes": True},
        )
    ]
