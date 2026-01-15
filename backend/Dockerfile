FROM golang:1.25 AS build

WORKDIR /
COPY go.mod go.sum ./

RUN go mod download

COPY . ./

# disable dependency on glibc
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /bin/cardabase-backend .

FROM scratch
COPY db_migrations /db_migrations
COPY --from=build /bin/cardabase-backend /bin/cardabase-backend
ENTRYPOINT ["/bin/cardabase-backend"]
