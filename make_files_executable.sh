#!/usr/bin/env bash
find init wsl . -maxdepth 1 -type f -name "*.sh" -exec chmod +x {} \;
