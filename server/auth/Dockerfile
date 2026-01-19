# Build stage - using latest for edition 2024 support
FROM rust:latest as builder
WORKDIR /app

# Copy dependency files first for caching
COPY Cargo.toml Cargo.lock* ./

# Create dummy source file for dependency caching
RUN mkdir src && echo "fn main() {}" > src/main.rs

# Build dependencies only (cached unless Cargo.toml changes)
RUN cargo build --release || true
RUN rm -rf src

# Copy actual source code
COPY . .

# Touch main.rs to invalidate the build cache for our code
RUN touch src/main.rs

# Build the application
RUN cargo build --release

# Runtime stage
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Copy the binary from builder
COPY --from=builder /app/target/release/meshlink-auth /usr/local/bin/

# Copy migrations (if needed at runtime)
COPY --from=builder /app/migrations /app/migrations

# Create non-root user for security
RUN useradd -m -u 1000 app
USER app

EXPOSE 3000

CMD ["meshlink-auth"]
