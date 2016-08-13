#!/bin/sh
if which swiftgen >/dev/null; then
swiftgen images "$PROJECT_DIR" --output "$PROJECT_DIR/$PROJECT/Images.swift"
else
echo "warning: SwiftGen not installed, download it from https://github.com/AliSoftware/SwiftGen"
fi
