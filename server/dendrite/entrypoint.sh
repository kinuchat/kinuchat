#!/bin/sh
set -e

echo "Starting Dendrite initialization..."

# Generate Matrix signing key if it doesn't exist
if [ ! -f /var/dendrite/matrix_key.pem ]; then
    echo "Generating Matrix signing key..."
    /usr/bin/generate-keys --private-key /var/dendrite/matrix_key.pem
fi

# If MATRIX_KEY secret is set, use that instead
if [ -n "$MATRIX_KEY" ]; then
    echo "$MATRIX_KEY" > /var/dendrite/matrix_key.pem
fi

# Create runtime config from template with environment variable substitution
# Using sed for simple substitutions
cp /etc/dendrite/dendrite.yaml /var/dendrite/dendrite-runtime.yaml

# Substitute environment variables using sed
sed -i "s|\${SERVER_NAME:-kinuchat.com}|${SERVER_NAME:-kinuchat.com}|g" /var/dendrite/dendrite-runtime.yaml
sed -i "s|\${REGISTRATION_SECRET}|${REGISTRATION_SECRET}|g" /var/dendrite/dendrite-runtime.yaml
sed -i "s|\${DATABASE_URL}|${DATABASE_URL}|g" /var/dendrite/dendrite-runtime.yaml

echo "Configuration created. Starting Dendrite..."

# Start Dendrite
exec /usr/bin/dendrite --config /var/dendrite/dendrite-runtime.yaml
