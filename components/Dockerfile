FROM python:3.10-slim-bookworm

RUN apt-get -y update
#TODO use nix instead?
RUN apt-get -y install nodejs npm

# Environment variable that tells Docker not to write cache files (.pyc), which are Python bytecode files, usually stored in the __pycache__ folder. 
ENV PYTHONDONTWRITEBYTECODE 1 
ENV PYTHONBUFFERED 1

WORKDIR /app

COPY fincsi_backend/requirements.txt requirements.txt
#TODO switch to poetry
RUN pip install --trusted-host pypi.python.org -r requirements.txt

COPY fincsi_frontend/package.json package.json
COPY fincsi_frontend/package-lock.json package-lock.json
RUN npm install

COPY fincsi_backend fincsi_backend
COPY fincsi_frontend fincsi_frontend

RUN mv node_modules fincsi_frontend && cd fincsi_frontend && npm run build

COPY run.bash run.bash

EXPOSE 8000

CMD ["/app/run.bash"]
