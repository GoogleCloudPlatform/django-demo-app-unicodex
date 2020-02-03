#!/bin/bash -eu
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

#!/bin/sh
set -e

echo "🎸 migrate"
python manage.py migrate

echo "🦄 loaddata"
python manage.py loaddata sampledata

echo "🎸 collect static"
python manage.py collectstatic --noinput

echo "🎸 createsuperuser"

# Custom management command to automate this step 
# as by default, you must be in a TTY to create a superuser
#
no_superusers=$(python manage.py shell -c "from django.contrib.auth import get_user_model; User=get_user_model(); print(User.objects.filter(is_superuser=True).count())")

if [ ${no_superusers} -ne 0 ]; then
    echo " ⏩ a superuser already existed."
else
    SUPERUSER=$(python -c "import sm_helper; print(sm_helper.access_secrets(['SUPERUSER'])['SUPERUSER'])")
    SUPERPASS=$(python -c "import sm_helper; print(sm_helper.access_secrets(['SUPERPASS'])['SUPERPASS'])")

    python manage.py automatesuperuser --username ${SUPERUSER} --password ${SUPERPASS}
    echo " ❗️ created superuser $SUPERUSER, as none existed"
fi
