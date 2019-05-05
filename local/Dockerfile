FROM python:3.6

RUN pip install watchdog

WORKDIR /usr/src/app

COPY src/requirements.txt ./
RUN pip install -r requirements.txt -t ./deps

COPY src ./

CMD watchmedo auto-restart -d bot -p '*.py' --recursive -- ./run_standalone.sh

