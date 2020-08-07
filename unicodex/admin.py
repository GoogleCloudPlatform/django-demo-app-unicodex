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

from django.contrib import admin
from django.core import management

from .models import *


def generate_designs(modeladmin, request, queryset):
    for codepoint in queryset:
        management.call_command("import_from_vendor", codepoint)
        admin.ModelAdmin.message_user(Codepoint, request, "Imported vendor versions")


generate_designs.short_description = "Generate designs for available vendor versions"


@admin.register(Codepoint)
class CodepointAdmin(admin.ModelAdmin):
    list_display = ("codepoint", "name", "description", "order")
    actions = [generate_designs]
    ordering = ['order']


@admin.register(Vendor)
class VendorAdmin(admin.ModelAdmin):
    pass


@admin.register(VendorVersion)
class VendorVersionAdmin(admin.ModelAdmin):
    pass


@admin.register(Design)
class DesignAdmin(admin.ModelAdmin):
    pass
