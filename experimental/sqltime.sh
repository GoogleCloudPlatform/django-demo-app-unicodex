PROJECT=$1

sql=$(gcloud services list --project $PROJECT --enabled --filter sqladmin --format "value(name)")

if [ -z "$sql" ] ; then return; fi

read starttime endtime < <(gcloud sql operations list --project $PROJECT --instance psql --filter "operationType=CREATE" --format "value(startTime,endTime)")

timetaken=$(($(date -d "$endtime" +%s) - $(date -d "$starttime" +%s)))

printf '%dh %dm %ds (total %ds)\n' $((timetaken / 3600)) $((timetaken % 3600 / 60)) $((timetaken % 60)) $timetaken
