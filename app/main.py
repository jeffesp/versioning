from enum import Enum

from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="Jokes Service", version="1.0.0")


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


@app.get("/tell/joke")
def tell_joke(joke_type: JokeType = JokeType.JOKE_TYPE_UNSPECIFIED):
    return Joke(joke_type)

