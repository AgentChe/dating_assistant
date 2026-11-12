# Сборка: статический бинарник без C-зависимостей. Промпты вшиты в него (go:embed).
FROM golang:1.25 AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /cue-server .

# Запуск: минимальный образ с корневыми сертификатами для HTTPS к Gemini.
# Ключ — GEMINI_API_KEY из секретов хостинга, не из образа.
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /cue-server /cue-server
ENV PORT=8080
EXPOSE 8080
ENTRYPOINT ["/cue-server"]
