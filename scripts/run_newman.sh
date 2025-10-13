#!/usr/bin/env bash
set -e

echo "Running Newman API tests..."

newman run tests/api/clearbox.postman_collection.json \
  -e tests/api/env.test.json \
  --reporters cli,junit \
  --reporter-junit-export tests/api/newman-report.xml \
  --bail \
  --color on

echo "API tests complete!"


