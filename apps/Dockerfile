# One image for every service of Mesh Pizza. The SERVICE environment
# variable picks the module to run: services/<SERVICE>.py
FROM python:3.14-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY services/ services/
COPY entrypoint.sh .
ENV SERVICE=frontend PYTHONUNBUFFERED=1
EXPOSE 8080
ENTRYPOINT ["./entrypoint.sh"]
