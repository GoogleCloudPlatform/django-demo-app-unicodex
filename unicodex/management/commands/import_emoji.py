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

