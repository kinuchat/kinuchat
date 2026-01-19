# Dendrite Matrix Server for Kinu
# Uses official Dendrite monolith image

FROM matrixdotorg/dendrite-monolith:latest

# Copy configuration template
# Note: dendrite.yaml uses environment variable substitution at runtime
COPY dendrite.yaml /etc/dendrite/dendrite.yaml

# Copy entrypoint script for environment variable substitution
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose Matrix client-server API port
EXPOSE 8008

# Create data directory
RUN mkdir -p /var/dendrite/media /var/dendrite/jetstream /var/dendrite/searchindex

ENTRYPOINT ["/entrypoint.sh"]
