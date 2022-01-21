#!/bin/sh

gpg --symmetric --cipher-algo AES256 --output ".github/res/secrets.json.gpg" "Sources/TripKit/Resources/secrets.json"
