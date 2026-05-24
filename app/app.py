import os

from fastapi import FastAPI

DATABASE_URL = os.environ["DATABASE_URL"]
API_KEY = os.environ["API_KEY"]

app = FastAPI()


@app.get("/healthz")
def healthz():
    return {"ok": True}


@app.get("/")
def root():
    return {
        "database_url": DATABASE_URL,
        "api_key_set": bool(API_KEY),
    }
