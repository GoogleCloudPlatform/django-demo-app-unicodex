#!/bin/sh
set -e

echo "🎸 migrate"
python manage.py migrate

echo "🎸 collect static"
python manage.py collectstatic --noinput --verbosity 2

echo "🎸 createsuperuser"

# Custom management command to automate this step 
# as by default, you must be in a TTY to create a superuser

no_superusers=$(python manage.py shell -c "from django.contrib.auth import get_user_model; User=get_user_model(); print(User.objects.filter(is_superuser=True).count())")

if [ ${no_superusers} -ne 0 ]; then
    echo "a superuser already existed."
else
    SUPERUSER=$(cat /secrets/superuser)
    SUPERPASS=$(cat /secrets/superpass)

    python manage.py automatesuperuser --username ${SUPERUSER} --password ${SUPERPASS}
    echo "created superuser $SUPERUSER, as none existed"
fi
