#!/bin/sh

# Decrypt the file
# --batch to prevent interactive command
# --yes to assume "yes" for questions
gpg --quiet --batch --yes --decrypt --passphrase="$SECRETS_PASSPHRASE" \
--output "Sources/TripKit/Resources/secrets.json" ".github/res/secrets.json.gpg"
