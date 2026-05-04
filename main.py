import logging
import os

import msgspec
from litestar import Litestar, Request, Response, Route
from litestar.exceptions import HTTPException

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

class HelloRequest(msgspec.Struct):
    name: str


async def hello_handler(request: Request) -> Response:
    session_id = request.headers.get("session-id")
    if not session_id:
        raise HTTPException(status_code=400, detail="Missing session-id header")

    body = await request.body()
    try:
        payload = msgspec.json.decode(body, type=HelloRequest)
    except msgspec.DecodeError as exc:
        raise HTTPException(status_code=400, detail=f"Invalid JSON body: {exc}")

    worker_id = os.getpid()
    logging.info("worker=%s session-id=%s", worker_id, session_id)

    return Response(content=f"hello {payload.name}", media_type="text/plain")


app = Litestar(route_handlers=[Route(path="/hello", method=["POST"], handler=hello_handler)])
