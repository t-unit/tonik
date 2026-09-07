"""Deterministic FastAPI routes. The served OpenAPI is FastAPI's own output."""

from datetime import date, datetime
from typing import Annotated, Literal
from uuid import UUID

from fastapi import (
    Body,
    Cookie,
    FastAPI,
    File,
    Form,
    Header,
    HTTPException,
    Query,
    Request,
    UploadFile,
)
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import JSONResponse, Response
from pydantic import BaseModel, ConfigDict, Field

app = FastAPI(
    title="FastAPI catalog", version="1.0.0", servers=[{"url": "http://localhost"}]
)
app.add_middleware(GZipMiddleware, minimum_size=1)


@app.middleware("http")
async def capture_form(request: Request, call_next):
    if request.headers.get("content-type", "").startswith(
        "application/x-www-form-urlencoded"
    ):
        request.state.raw_form = (await request.body()).decode()
    return await call_next(request)


class Customer(BaseModel):
    id: UUID
    name: str


class Product(BaseModel):
    id: int
    name: str
    status: Literal["available", "sold"]
    customer: Customer
    tags: list[str]
    attributes: dict[str, int]
    released: date
    updated: datetime
    note: str | None = None


class Receipt(BaseModel):
    text: str
    count: int
    enabled: bool
    tags: list[str]
    fileName: str
    contentType: str
    bytes: list[int]
    raw: str


class Card(BaseModel):
    kind: Literal["card"]
    last4: str


class Bank(BaseModel):
    kind: Literal["bank"]
    iban: str


class PaymentDocument(BaseModel):
    payment: Annotated[Card | Bank, Field(discriminator="kind")]


class EmailContact(BaseModel):
    model_config = ConfigDict(extra="allow")
    email: str


class PhoneContact(BaseModel):
    model_config = ConfigDict(extra="allow")
    phone: str


class ContactDocument(BaseModel):
    contact: EmailContact | PhoneContact


class CustomerInput(BaseModel):
    name: str
    secret: str = Field(json_schema_extra={"writeOnly": True})


class Error(BaseModel):
    detail: str


PRODUCT = Product(
    id=42,
    name="Tea & café",
    status="available",
    customer=Customer(id="123e4567-e89b-12d3-a456-426614174000", name="Ada Example"),
    tags=["tea", "東京"],
    attributes={"stock": 7},
    released=date(2025, 1, 2),
    updated=datetime.fromisoformat("2025-01-02T03:04:05+02:00"),
)


@app.get("/health", include_in_schema=False)
def health():
    return {"ok": True}


@app.get(
    "/products/42", response_model=Product, tags=["Catalog"], operation_id="jsonProduct"
)
def product():
    return PRODUCT


@app.post(
    "/products/echo",
    response_model=Product,
    tags=["Catalog"],
    operation_id="echoProduct",
)
def echo_product(body: Product):
    return body


@app.get(
    "/inspect/{key}", response_model=Receipt, tags=["Catalog"], operation_id="inspect"
)
def inspect(
    request: Request,
    key: str,
    count: Annotated[int, Query(ge=0)],
    enabled: bool,
    tags: Annotated[list[str], Query()],
    x_trace: Annotated[str, Header()],
    session: Annotated[str, Cookie()],
):
    return Receipt(
        text=key,
        count=count,
        enabled=enabled,
        tags=tags,
        fileName=session,
        contentType=x_trace,
        bytes=[],
        raw=request.url.query,
    )


@app.post("/forms/echo", response_model=Receipt, tags=["Catalog"], operation_id="form")
async def form(
    request: Request,
    text: Annotated[str, Form()],
    count: Annotated[int, Form()],
    enabled: Annotated[bool, Form()],
    tags: Annotated[list[str], Form()],
):
    return Receipt(
        text=text,
        count=count,
        enabled=enabled,
        tags=tags,
        fileName="",
        contentType=request.headers["content-type"],
        bytes=[],
        raw=request.state.raw_form,
    )


@app.post("/uploads", response_model=Receipt, tags=["Catalog"], operation_id="upload")
async def upload(
    file: Annotated[UploadFile, File()],
    text: Annotated[str, Form()],
    count: Annotated[int, Form()],
    enabled: Annotated[bool, Form()],
):
    return Receipt(
        text=text,
        count=count,
        enabled=enabled,
        tags=[],
        fileName=file.filename,
        contentType=file.content_type,
        bytes=list(await file.read()),
        raw="",
    )


@app.get(
    "/files/sample",
    response_class=Response,
    responses={
        200: {
            "content": {
                "application/octet-stream": {
                    "schema": {"type": "string", "format": "binary"}
                }
            }
        }
    },
    tags=["Catalog"],
    operation_id="binary",
)
def binary():
    return Response(bytes([0, 1, 127, 128, 255]), media_type="application/octet-stream")


@app.post(
    "/files/echo",
    response_class=Response,
    responses={
        200: {
            "content": {
                "application/octet-stream": {
                    "schema": {"type": "string", "format": "binary"}
                }
            }
        }
    },
    tags=["Catalog"],
    operation_id="echoBinary",
)
def echo_binary(body: Annotated[bytes, Body(media_type="application/octet-stream")]):
    return Response(body, media_type="application/octet-stream")


@app.get(
    "/text/{encoding}",
    response_class=Response,
    responses={200: {"content": {"text/plain": {"schema": {"type": "string"}}}}},
    tags=["Catalog"],
    operation_id="text",
)
def text(encoding: Literal["utf8", "latin1", "windows1252", "shift-jis"]):
    value, charset = {
        "utf8": ("Grüße, 東京 👋", "utf-8"),
        "latin1": ("café", "iso-8859-1"),
        "windows1252": ("€ café", "windows-1252"),
        "shift-jis": ("東京", "shift_jis"),
    }[encoding]
    return Response(
        value.encode(charset),
        headers={"Content-Type": f"text/plain; charset={charset}"},
    )


@app.get(
    "/payments/{kind}",
    response_model=PaymentDocument,
    tags=["Catalog"],
    operation_id="payment",
)
def payment(kind: Literal["card", "bank"]):
    return PaymentDocument(
        payment=Card(kind="card", last4="4242")
        if kind == "card"
        else Bank(kind="bank", iban="DE02120300000000202051")
    )


@app.post(
    "/payments/echo",
    response_model=PaymentDocument,
    tags=["Catalog"],
    operation_id="echoPayment",
)
def echo_payment(body: PaymentDocument):
    return body


@app.post(
    "/contacts/echo",
    response_model=ContactDocument,
    tags=["Catalog"],
    operation_id="contact",
)
def contact(body: ContactDocument):
    return body


@app.post(
    "/customers",
    response_model=Customer,
    status_code=201,
    tags=["Catalog"],
    operation_id="createCustomer",
)
def create_customer(body: CustomerInput):
    return Customer(id="123e4567-e89b-12d3-a456-426614174000", name=body.name)


@app.delete(
    "/products/42", status_code=204, tags=["Catalog"], operation_id="deleteProduct"
)
def delete_product():
    return Response(status_code=204)


@app.get(
    "/missing",
    responses={404: {"model": Error}},
    status_code=404,
    tags=["Catalog"],
    operation_id="missing",
)
def missing():
    raise HTTPException(status_code=404, detail="Product not found")


class UploadedPart(BaseModel):
    fileName: str
    contentType: str
    bytes: list[int]


class BatchReceipt(BaseModel):
    files: list[UploadedPart]
    tags: list[str]


class Category(BaseModel):
    name: str
    children: list["Category"]


class Problem(BaseModel):
    type: str
    title: str
    status: int
    detail: str


@app.post(
    "/uploads/batch",
    response_model=BatchReceipt,
    tags=["Catalog"],
    operation_id="batchUpload",
)
async def batch_upload(
    files: Annotated[list[UploadFile], File()], tags: Annotated[list[str], Form()]
):
    parts = []
    for file in files:
        parts.append(
            UploadedPart(
                fileName=file.filename,
                contentType=file.content_type,
                bytes=list(await file.read()),
            )
        )
    return BatchReceipt(files=parts, tags=tags)


@app.post(
    "/uploads/optional",
    response_model=Receipt,
    tags=["Catalog"],
    operation_id="optionalUpload",
)
async def optional_upload(
    text: Annotated[str, Form()], file: Annotated[UploadFile | None, File()] = None
):
    return Receipt(
        text=text,
        count=0 if file is None else 1,
        enabled=file is not None,
        tags=[],
        fileName="" if file is None else file.filename,
        contentType="" if file is None else file.content_type,
        bytes=[] if file is None else list(await file.read()),
        raw="",
    )


@app.get(
    "/categories", response_model=Category, tags=["Catalog"], operation_id="category"
)
def category():
    return Category(name="catalog", children=[Category(name="tea", children=[])])


class VendorResponse(JSONResponse):
    media_type = "application/vnd.catalog+json"


class ProblemResponse(JSONResponse):
    media_type = "application/problem+json"


@app.get(
    "/media/vendor",
    response_class=VendorResponse,
    response_model=Product,
    tags=["Catalog"],
    operation_id="vendor",
)
def vendor():
    return PRODUCT


@app.get(
    "/media/csv",
    response_class=Response,
    responses={200: {"content": {"text/csv": {"schema": {"type": "string"}}}}},
    tags=["Catalog"],
    operation_id="csv",
)
def csv():
    return Response("id,name\n42,Tea\n", media_type="text/csv")


@app.get(
    "/media/problem",
    response_class=ProblemResponse,
    response_model=Problem,
    status_code=400,
    tags=["Catalog"],
    operation_id="problem",
)
def problem():
    return Problem(
        type="https://example.test/problems/catalog",
        title="Catalog problem",
        status=400,
        detail="Fake product is unavailable",
    )
