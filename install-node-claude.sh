#!/bin/bash
set -euo pipefail

NODE_VERSION="v24.16.0"
NODE_DIR="$HOME/.local/node"
BIN_DIR="$HOME/.local/bin"
ARCH="darwin-arm64"
TARBALL="node-${NODE_VERSION}-${ARCH}.tar.gz"
URL="https://nodejs.org/dist/${NODE_VERSION}/${TARBALL}"

mkdir -p "$NODE_DIR" "$BIN_DIR"

echo "==> Installing Node.js ${NODE_VERSION} (${ARCH})..."
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
cd "$TMPDIR"
curl -fsSL -o "$TARBALL" "$URL"
tar -xzf "$TARBALL"
EXTRACTED="node-${NODE_VERSION}-${ARCH}"
rm -rf "$NODE_DIR/current"
mv "$EXTRACTED" "$NODE_DIR/current"

ln -sf "$NODE_DIR/current/bin/node" "$BIN_DIR/node"
ln -sf "$NODE_DIR/current/bin/npm" "$BIN_DIR/npm"
ln -sf "$NODE_DIR/current/bin/npx" "$BIN_DIR/npx"

export PATH="$BIN_DIR:$PATH"

echo "Node: $(node --version)"
echo "npm:  $(npm --version)"

echo "==> Installing latest Claude Code via npm (with native binaries)..."
npm install -g '@anthropic-ai/claude-code@latest' --include=optional

PKG="$(npm root -g)/@anthropic-ai/claude-code"
if [ -f "$PKG/install.cjs" ]; then
  echo "==> Running Claude Code postinstall..."
  node "$PKG/install.cjs"
fi

# Global bin lives next to node (same prefix)
if [ -x "$NODE_DIR/current/bin/claude" ]; then
  ln -sf "$NODE_DIR/current/bin/claude" "$BIN_DIR/claude"
elif [ -x "$PKG/bin/claude.exe" ]; then
  ln -sf "$PKG/bin/claude.exe" "$BIN_DIR/claude"
fi

echo "==> Verifying Claude Code..."
claude --version

echo "==> Done. Add to ~/.zshrc if needed:"
echo 'export PATH="$HOME/.local/bin:$PATH"'
