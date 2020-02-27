FROM python:3.8-slim-buster

ENV APP_HOME /app
ENV PORT 8080
ENV PYTHONUNBUFFERED 1

WORKDIR $APP_HOME
COPY . .

RUN pip install --no-cache-dir -r requirements.txt

CMD gunicorn --bind :$PORT --workers 1 --threads 8 unicodex.wsgi:application
