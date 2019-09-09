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
