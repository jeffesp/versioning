# Versioning with Tyk

Example versioning with Tyk

Aside: it's pronounced "tike" like "bike", and apparently CoPilot knows that as it suggested it after I typed pronounced.

## Setup

The notebook [`run.ipynb`](run.ipynb) will:

1. start Tyk
2. deploy the API to Tyk
3. run some requests against it
4. deploy another version of the API to Tyk
5. run some requests against that version.

You can look at the [`openapi-v1.json`](openapi-v1.json) and [`openapi-v2.0.json`](openapi-2.0.json) files to see the stuff that is needed in the `x-tyk-api-gateway` section in them. That is what defines the API to run under tyk as a "base" API or a "child" API. 
