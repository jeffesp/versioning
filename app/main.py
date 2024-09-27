from enum import Enum

from fastapi import FastAPI
from pydantic import BaseModel

from fastapi_versioning import VersionedFastAPI, version

app = FastAPI(title="Jokes Service")


class JokeType(int, Enum):
    JOKE_TYPE_UNSPECIFIED = 0
    JOKE_TYPE_QUESTION_ANSWER = 1
    JOKE_TYPE_KNOCK_KNOCK = 2
    JOKE_TYPE_WHAT_TIME_IS_IT = 3
    JOKE_TYPE_GUESS_WHO = 4


class Joke(BaseModel):
    value: str

    def __init__(self, joke_type: JokeType, **kwargs) -> None:
        if joke_type == JokeType.JOKE_TYPE_UNSPECIFIED:
            result = "Hey, funny thing... this HTTP stuff does work..."
        elif joke_type == JokeType.JOKE_TYPE_QUESTION_ANSWER:
            result = "Glad you asked about the new service_registry! More to come..."
        elif joke_type == JokeType.JOKE_TYPE_KNOCK_KNOCK:
            result = "Who's there? Must be a service_registry user?"
        elif joke_type == JokeType.JOKE_TYPE_WHAT_TIME_IS_IT:
            result = "It's Tool Time!"
        elif joke_type == JokeType.JOKE_TYPE_GUESS_WHO:
            result = "What do you mean 'Who' ?! It's SDTK team!"
        else:
            result = "A joke you didn't ask for"
        super().__init__(value=result, **kwargs)


class JokeRequest(BaseModel):
    joke_type: JokeType


class ContinuedJoke(Joke):
    continue_token: str | None

    def __init__(
        self, joke_type: JokeType, continue_token: str | None = None, **kwargs
    ) -> None:
        super().__init__(joke_type=joke_type, continue_token=continue_token, **kwargs)


@app.get("/tell/joke")
@version(1,0)
def tell_joke(joke_type: JokeType = JokeType.JOKE_TYPE_UNSPECIFIED):
    return Joke(joke_type)


@app.post("/tell/joke")
@version(2,0)
def tell_joke_post(joke: JokeRequest):
    return Joke(joke_type=joke.joke_type)


@app.get("/tell/joke")
@version(2,1)
def tell_joke2(
    joke_type: JokeType = JokeType.JOKE_TYPE_UNSPECIFIED,
    continue_token: str | None = None,
):
    return ContinuedJoke(joke_type, continue_token=continue_token)


app = VersionedFastAPI(app, version_format="{major}.{minor}", prefix_format="/v{major}.{minor}")