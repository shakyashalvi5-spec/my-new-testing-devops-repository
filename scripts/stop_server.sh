#!/bin/bash
# Agar app pehle se pm2 me chal rahi hai to usse stop karo
if pm2 list | grep -q "cloudwithshalvi-app"; then
  pm2 stop cloudwithshalvi-app
  pm2 delete cloudwithshalvi-app
fi
exit 0
