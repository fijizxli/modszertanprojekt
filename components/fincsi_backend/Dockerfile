FROM python:3.10-slim-bookworm

# Environment variable that tells Docker not to write cache files (.pyc), which are Python bytecode files, usually stored in the __pycache__ folder. 
ENV PYTHONDONTWRITEBYTECODE 1 
ENV PYTHONBUFFERED 1

WORKDIR /app
COPY ./requirements.txt /app/
RUN pip install --trusted-host pypi.python.org -r requirements.txt
COPY . /app/
COPY run.bash /run.bash

EXPOSE 8000

CMD ["/run.bash"]
