#!/bin/bash
sleep 5
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health)

if [ "$STATUS" -eq 200 ]; then
  echo "Service is healthy"
  exit 0
else
  echo "Service validation failed with status $STATUS"
  exit 1
fi
