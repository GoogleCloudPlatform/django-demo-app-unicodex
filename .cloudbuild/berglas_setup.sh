export DATABASE_URL=berglas://${PROJECT_ID}-secrets/database_url?destination=/secrets/database_url
export SECRET_KEY=berglas://${PROJECT_ID}-secrets/secret_key?destination=/secrets/secret_key
export BUCKET_NAME=berglas://${PROJECT_ID}-secrets/bucket_name?destination=/secrets/bucket_name

export SUPERUSER=berglas://${PROJECT_ID}-secrets/superuser?destination=/secrets/superuser
export SUPERPASS=berglas://${PROJECT_ID}-secrets/superpass?destination=/secrets/superpass

berglas exec --local -- /bin/sh

ENVFILE=/secrets/.env

touch $ENVFILE
echo "DATABASE_URL=$(cat /secrets/database_url)" >> $ENVFILE 
echo "SECRET_KEY=$(cat /secrets/secret_key)" >> $ENVFILE 
echo "GS_BUCKET_NAME=$(cat /secrets/bucket_name)" >> $ENVFILE 

DBFILE=/secrets/database
echo "$(cat /secrets/database_url | cut -d'/' -f6)" >> $DBFILE


echo "DEBUGGING: cat $ENVFILE"
for i in $(cat $ENVFILE); do echo $i | cut -d"=" -f1; done

echo "DEBUGGING: cat $DBFILE"
cat $DBFILE
