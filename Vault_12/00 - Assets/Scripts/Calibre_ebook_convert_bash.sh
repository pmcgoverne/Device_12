#!/bin/bash

# Search for calibre.app on the system
CALIBRE_APP_PATH=$(mdfind "kMDItemCFBundleIdentifier == 'com.calibre-ebook.calibre'" | head -n 1)

if [ -z "$CALIBRE_APP_PATH" ]; then
  echo "❌ Could not find calibre.app on your system."
  exit 1
fi

# Construct full path to ebook-convert binary
EBOOK_CONVERT_PATH="$CALIBRE_APP_PATH/Contents/MacOS/ebook-convert"

# Check if the binary exists
if [ ! -f "$EBOOK_CONVERT_PATH" ]; then
  echo "❌ ebook-convert binary not found inside calibre.app"
  exit 1
fi

# Remove existing symlink if it exists
if [ -L /usr/local/bin/ebook-convert ]; then
  echo "⚠️ Removing old symlink..."
  sudo rm /usr/local/bin/ebook-convert
fi

# Create new symlink
echo "✅ Linking $EBOOK_CONVERT_PATH to /usr/local/bin/ebook-convert"
sudo ln -s "$EBOOK_CONVERT_PATH" /usr/local/bin/ebook-convert

# Test the link
if ebook-convert --version >/dev/null 2>&1; then
  echo "🎉 ebook-convert is now available system-wide!"
else
  echo "❌ Something went wrong. Try running the commands manually."
fi
