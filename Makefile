.PHONY: build run test scan stop clean

APP_NAME = fastapi-portfolio
TAG = local

build:
	docker build -t $(APP_NAME):$(TAG) app/

run:
	docker run -d --name $(APP_NAME) -p 8000:8000 $(APP_NAME):$(TAG)

test:
	@echo "Testando endpoints da aplicacao..."
	@sleep 2
	@curl -s -f http://localhost:8000/healthz | grep "azure" || (echo "Health check falhou" && exit 1)
	@echo "\n[OK] Health check validado"
	@curl -s -f http://localhost:8000/metrics | grep "http_requests_total" || (echo "Metrics falhou" && exit 1)
	@echo "\n[OK] Metrics endpoint validado"

scan:
	trivy image --severity HIGH,CRITICAL --ignore-unfixed $(APP_NAME):$(TAG)

stop:
	docker stop $(APP_NAME) || true
	docker rm $(APP_NAME) || true

clean: stop
	docker rmi $(APP_NAME):$(TAG) || true