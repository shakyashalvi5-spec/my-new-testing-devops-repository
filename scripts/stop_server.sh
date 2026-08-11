#!/bin/bash

if pm2 list | grep -q "cloudwithshalvi-nodejs"; then
    pm2 stop cloudwithshalvi-nodejs
    pm2 delete cloudwithshalvi-nodejs
fi

exit 0
