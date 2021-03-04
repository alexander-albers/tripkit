#!/bin/sh

# Decrypt the file
# --batch to prevent interactive command
# --yes to assume "yes" for questions
gpg --quiet --batch --yes --decrypt --passphrase="$SECRETS_PASSPHRASE" \
--output Sources/TripKit/secrets.json Sources/TripKit/secrets.json.gpg