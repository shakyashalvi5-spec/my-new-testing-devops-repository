#!/bin/bash
cd /home/ec2-user/app

# Yahan apna custom port set karo (jaise 3000, 5000, 8080 etc)
export PORT=3000

pm2 start server.js --name cloudwithshalvi-app
pm2 save
exit 0
