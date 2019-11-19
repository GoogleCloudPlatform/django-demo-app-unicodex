FROM python:3.8-slim-stretch

ENV APP_HOME /app
ENV PORT 8080

WORKDIR $APP_HOME
COPY . .

RUN pip install --no-cache-dir -r requirements.txt

COPY --from=gcr.io/berglas/berglas:latest /bin/berglas /bin/berglas

CMD exec /bin/berglas exec -- gunicorn --bind :$PORT --workers 1 --threads 8 unicodex.wsgi:application
