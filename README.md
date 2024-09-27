# Versioning with Tyk

Example versioning with Tyk

I wrote a small FastAPI service that has 3 endpoint, each with a different version number. The first version (v1) has a single endpoint, v2 has one more, and v2.1 has the third. If you run the service with `poetry fastapi dev app/main.py` you will be able to access these endpoints in at http://localhost:8000/v1.0/, &hellip;v2.0, and &hellip;v2.1. Playing with that API a tiny bit will help you understand what Tyk is doing in front of it.

## Setup

The notebook [`run.ipynb`](run.ipynb) will:

1. start Tyk
2. deploy the API to Tyk
3. run some requests against it
5. deploy another version of the API to Tyk
6. run some requests against that version.

You can look at the [`openapi-v1.json`](openapi-v1.json) and [`openapi-v2.0.json`](openapi-2.0.json) files to see the stuff that is needed in the `x-tyk-api-gateway` section in them. That is what defines the API to run under tyk as a "base" API or a "child" API. 
