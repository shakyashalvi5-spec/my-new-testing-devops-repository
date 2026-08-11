#!/bin/bash

cd /home/ubuntu/my-new-testing-devops-repository/app

export PORT=3000

pm2 start server.js --name cloudwithshalvi-nodejs

pm2 save

exit 0
