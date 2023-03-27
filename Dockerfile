# Start by building the application.
FROM golang:1.19-alpine as build

ENV USER=appuser
ENV UID=10001

RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    "${USER}"

WORKDIR $GOPATH/src/app/

COPY ["src/go.mod", "src/go.sum", "./"]
RUN go mod download

ADD ["src/cmd", "cmd"]
ADD ["src/pkg", "pkg"]

RUN CGO_ENABLED=0 go build -o /app.bin cmd/main.go

# Now copy it into our base image.
FROM gcr.io/distroless/base-debian11

COPY --from=busybox:1.35.0-uclibc /bin/sh /bin/sh
COPY --from=build /etc/passwd /etc/passwd
COPY --from=build /etc/group /etc/group
COPY --from=build /app.bin /app.bin

USER $USER:$USER

ARG PORT="9000"
ENV PORT ${PORT}

ARG HOST="0.0.0.0"
ENV HOST ${HOST}

ARG DB_URL="postgres://user:pass@db:5432/app"
ENV DB_URL ${DB_URL}

EXPOSE $PORT

ENTRYPOINT ["/bin/sh", "-c", "/app.bin -port=$PORT -host=$HOST -dbUrl=$DB_URL"]

