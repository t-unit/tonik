FROM python:3.13.7-slim
COPY requirements.txt /requirements.txt
RUN pip install --no-cache-dir -r /requirements.txt
COPY validate.py /validate.py
ENTRYPOINT ["python", "/validate.py"]
