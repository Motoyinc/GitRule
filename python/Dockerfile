FROM python:3.12-bullseye
WORKDIR /app
COPY . /app
RUN pip install flask
RUN pip install flask-executor
EXPOSE 5000
CMD ["python3", "app.py"]