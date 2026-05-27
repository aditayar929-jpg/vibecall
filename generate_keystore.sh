#!/bin/bash
# Generate keystore for VibeCall release signing
# Run this ONCE on your local machine

echo "==================================="
echo "  VibeCall Keystore Generator"
echo "==================================="
echo ""

KEYSTORE_PATH="android/app/vibecall-release.jks"
KEY_ALIAS="vibecall"

read -sp "Enter keystore password: " STORE_PASSWORD
echo ""
read -sp "Enter key password: " KEY_PASSWORD
echo ""

keytool -genkey -v \
  -keystore "$KEYSTORE_PATH" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias "$KEY_ALIAS" \
  -storepass "$STORE_PASSWORD" \
  -keypass "$KEY_PASSWORD" \
  -dname "CN=VibeCall, OU=Development, O=VibeCall, L=Unknown, ST=Unknown, C=IN"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Keystore generated: $KEYSTORE_PATH"
    echo ""

    # Create key.properties
    cat > android/key.properties << EOF
storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=vibecall-release.jks
EOF

    echo "✅ key.properties created"
    echo ""
    echo "==================================="
    echo "  For GitHub Actions, add these"
    echo "  secrets in your repo settings:"
    echo "==================================="
    echo ""
    echo "KEYSTORE_BASE64:"
    base64 -w 0 "$KEYSTORE_PATH"
    echo ""
    echo ""
    echo "KEYSTORE_PASSWORD: $STORE_PASSWORD"
    echo "KEY_ALIAS: $KEY_ALIAS"
    echo "KEY_PASSWORD: $KEY_PASSWORD"
    echo ""
    echo "Done! Now push to GitHub."
else
    echo "❌ Keystore generation failed"
fi
