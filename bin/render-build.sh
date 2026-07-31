#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install

# Precompile assets (Propshaft + Tailwind + Importmap)
bundle exec rails assets:precompile
bundle exec rails assets:clean

# Run any pending migrations (primary + solid_cache + solid_queue + solid_cable)
bundle exec rails db:migrate

# Seed super admin (idempotent - safe to run on every deploy)
bundle exec rails db:seed
