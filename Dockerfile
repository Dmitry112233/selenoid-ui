FROM golang:1.22 AS builder

WORKDIR /app

# Устанавливаем statik (генератор статичных ресурсов)
RUN go install github.com/rakyll/statik@latest

COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Генерируем статичные ресурсы в пакет statik
RUN /go/bin/statik -src=./ui/build -dest=./statik

# Обновляем зависимости (go.mod должен содержать ссылку на локальный пакет statik)
RUN go mod tidy

# Собираем бинарь с вшитой статики
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o selenoid-ui .

FROM scratch

# Копируем бинарь из builder
COPY --from=builder /app/selenoid-ui /

# (если есть) копируем health-check и licenses
# COPY --from=builder /app/health-check /
# COPY licenses /

HEALTHCHECK --interval=30s --timeout=2s --start-period=2s --retries=2 CMD ["/health-check"]

EXPOSE 8080

ENTRYPOINT ["/selenoid-ui"]
