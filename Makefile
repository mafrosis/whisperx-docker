.PHONY: build-local push push-amd64 push-arm64 setup-buildx login help

.DEFAULT_GOAL := help

# Image names
IMAGE_CPU := ghcr.io/mafrosis/whisperx:cpu
IMAGE_GPU := ghcr.io/mafrosis/whisperx:gpu
GITHUB_USER := mafrosis

# Login to GitHub Container Registry
login:
	@echo "Logging in to GitHub Container Registry..."
	@if [ -z "$$GITHUB_TOKEN" ]; then \
		echo "Error: GITHUB_TOKEN environment variable not set"; \
		echo "Please set it with: export GITHUB_TOKEN=your_token_here"; \
		echo "Get a token from: https://github.com/settings/tokens"; \
		exit 1; \
	fi
	@echo "$$GITHUB_TOKEN" | docker login ghcr.io -u $(GITHUB_USER) --password-stdin

# Setup docker buildx for multi-arch builds
setup-buildx:
	@echo "Setting up docker buildx..."
	@docker buildx create --name whisperx-builder --use 2>/dev/null || docker buildx use whisperx-builder || docker buildx use default
	@docker buildx inspect --bootstrap

# Build for local architecture (macOS arm64)
build-local:
	@echo "Building images for local architecture (macOS arm64)..."
	docker build -t $(IMAGE_CPU) -f Dockerfile .
	docker build -t $(IMAGE_GPU) -f Dockerfile.gpu .

# Build and push both CPU and GPU images for both amd64 and arm64
push: login setup-buildx
	@echo "Building and pushing images for linux/amd64 and linux/arm64..."
	docker buildx build \
		--platform linux/amd64,linux/arm64 \
		-t $(IMAGE_CPU) \
		-f Dockerfile \
		--push \
		.
	docker buildx build \
		--platform linux/amd64,linux/arm64 \
		-t $(IMAGE_GPU) \
		-f Dockerfile.gpu \
		--push \
		.

# Build and push only amd64 images (for AWS/Linux x86_64 hosts)
push-amd64: login setup-buildx
	@echo "Building and pushing images for linux/amd64..."
	docker buildx build \
		--platform linux/amd64 \
		-t $(IMAGE_CPU) \
		-f Dockerfile \
		--push \
		.
	docker buildx build \
		--platform linux/amd64 \
		-t $(IMAGE_GPU) \
		-f Dockerfile.gpu \
		--push \
		.

# Build and push only arm64 images (for macOS/Linux arm64 hosts)
push-arm64: login setup-buildx
	@echo "Building and pushing images for linux/arm64..."
	docker buildx build \
		--platform linux/arm64 \
		-t $(IMAGE_CPU) \
		-f Dockerfile \
		--push \
		.
	docker buildx build \
		--platform linux/arm64 \
		-t $(IMAGE_GPU) \
		-f Dockerfile.gpu \
		--push \
		.

# Help
help:
	@echo "WhisperX Docker Build & Push Commands"
	@echo ""
	@echo "Common targets:"
	@echo "  make login        - Login to GitHub Container Registry (requires GITHUB_TOKEN)"
	@echo "  make build-local  - Build both images for local macOS arm64 (no push)"
	@echo "  make push-amd64   - Build and push for Linux amd64 (AWS/x86_64) [FAST]"
	@echo "  make push-arm64   - Build and push for Linux/macOS arm64"
	@echo "  make push         - Build and push for both amd64 and arm64 [SLOW]"
	@echo ""
	@echo "Other targets:"
	@echo "  make setup-buildx - Setup docker buildx for multi-arch builds"
	@echo ""
	@echo "Environment variables:"
	@echo "  GITHUB_TOKEN      - Required for pushing images (get from: https://github.com/settings/tokens)"
