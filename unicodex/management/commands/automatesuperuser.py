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

import django
from django.contrib.auth.management.commands import createsuperuser
from django.core.management import CommandError


"""
python manage.py createsuperuser --username admin --password admin
python manage.py createsuperuser --username admin --password admin --email foo@foo.foo
"""

class Command(createsuperuser.Command):
    help = 'create/update a superuser with password'

    def add_arguments(self, parser):
        super(Command, self).add_arguments(parser)
        parser.add_argument('--password', dest='password', default=None)

    def handle(self, *args, **options):
        database = options.get('database')
        password = options.get('password')
        username = options.get('username')
        email = options.get('email')

        if not password or not username:
            raise CommandError("--username and --password are required")

        data = {'username': username,'password': password,'email': email}
        self.UserModel._default_manager.db_manager(database).create_superuser(**data)
