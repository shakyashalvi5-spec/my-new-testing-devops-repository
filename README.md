# cloudwithshalvi.online — EC2 + CodePipeline + CodeDeploy Project

## Project Flow
GitHub (code) → CodePipeline (Source) → CodeDeploy (Deploy on EC2) → App runs on port 3000 → Domain (Hostinger) points to EC2

---

## PART 1 — EC2 Setup (Website pehle manually chalao)

### Step 1: EC2 Launch
1. AWS Console → EC2 → Launch Instance
2. AMI: **Amazon Linux 2023**
3. Instance type: t2.micro (free tier)
4. Key pair: naya banao ya existing use karo (.pem download karo)
5. **Security Group** — inbound rules add karo:
   - SSH (22) — Your IP
   - Custom TCP (3000) — Anywhere (0.0.0.0/0) → ye tumhara website port hai
   - HTTP (80) / HTTPS (443) — agar baad me Nginx reverse proxy lagana ho
6. Launch karo, Elastic IP allocate karke instance se associate karo (taaki IP fix rahe, domain pointing ke liye zaroori hai)

### Step 2: EC2 me connect karo aur software install karo
```bash
ssh -i your-key.pem ec2-user@<ELASTIC_IP>

# Node.js install (NVM ke through)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
. ~/.nvm/nvm.sh
nvm install 20
node -v

# pm2 install (app ko background me continuously chalane ke liye)
npm install -g pm2

# Ruby + CodeDeploy agent install (Amazon Linux 2023)
sudo dnf install -y ruby wget
cd /home/ec2-user
wget https://aws-codedeploy-<YOUR_REGION>.s3.<YOUR_REGION>.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
sudo systemctl status codedeploy-agent
```
> `<YOUR_REGION>` ki jagah apna AWS region daalna (jaise ap-south-1)

### Step 3: App manually test karo (pipeline banane se pehle)
```bash
mkdir -p /home/ec2-user/app
# server.js aur package.json is folder me copy karo (SCP se ya manually create karke)
cd /home/ec2-user/app
npm install
PORT=3000 node server.js
```
Browser me kholo: `http://<ELASTIC_IP>:3000` — website dikhni chahiye.
Ye confirm karega ki EC2, port, aur app sab sahi chal rahe hain. Uske baad Ctrl+C karke rok do, kyunki pipeline isko manage karegi.

---

## PART 2 — IAM Roles (Pipeline banane se pehle zaroori)

### A. EC2 Instance Role
1. IAM → Roles → Create Role → EC2
2. Attach policy: `AmazonEC2RoleforAWSCodeDeploy`
3. Role name: `EC2-CodeDeploy-Role`
4. EC2 instance pr attach karo: EC2 Console → Instance select → Actions → Security → Modify IAM Role

### B. CodeDeploy Service Role
1. IAM → Roles → Create Role → CodeDeploy → CodeDeploy
2. Attach policy: `AWSCodeDeployRole`
3. Role name: `CodeDeployServiceRole`

### C. CodePipeline Service Role
Pipeline banate time AWS console khud ek default role create kar dega — usko allow kar dena.

---

## PART 3 — CodeDeploy Setup

1. Code ko GitHub repo me push karo (ye poora folder — `app/`, `scripts/`, `appspec.yml`)
2. AWS Console → CodeDeploy → Applications → Create Application
   - Name: `cloudwithshalvi-app`
   - Platform: EC2/On-premises
3. Create Deployment Group:
   - Name: `cloudwithshalvi-deployment-group`
   - Service role: `CodeDeployServiceRole`
   - Deployment type: In-place
   - Environment: Amazon EC2 instances → EC2 ko tag ke through select karo (pehle EC2 ko ek Tag do jaise `Name = cloudwithshalvi-server`)
   - Load balancer: skip (single instance hai)

---

## PART 4 — CodePipeline Setup

1. AWS Console → CodePipeline → Create Pipeline
2. **Source stage**: GitHub (via GitHub App connection) → apna repo aur branch select karo
3. **Build stage**: Skip kar sakte ho (simple Node app hai, build ki zaroorat nahi) — agar aage TypeScript/React use karogi to CodeBuild add kar dena
4. **Deploy stage**: Provider = CodeDeploy → Application = `cloudwithshalvi-app` → Deployment Group select karo
5. Create Pipeline

Ab jab bhi GitHub repo me `main` branch pr push karogi, pipeline automatically:
Source pull → CodeDeploy trigger → EC2 pr scripts chalenge (stop → install → start → validate) → naya code live ho jayega.

---

## PART 5 — Domain Pointing (Hostinger → AWS EC2)

1. Hostinger login karo → Domains → `cloudwithshalvi.online` → DNS / Nameservers
2. DNS Zone Editor me jao, ek **A Record** add karo:
   - Type: A
   - Name: `@` (ya jo subdomain chahiye)
   - Points to: `<EC2 Elastic IP>`
   - TTL: default
3. Agar `www` bhi chahiye to ek aur A record: Name = `www`, same IP
4. DNS propagate hone me 10 min – 24 hrs lag sakte hain
5. Test: `http://cloudwithshalvi.online:3000`

> Note: Port 3000 domain ke sath directly dikhega (`domain.com:3000`) jab tak Nginx reverse proxy na lagao. Agar clean URL chahiye (bina port ke, `domain.com` pr hi khule), bata dena — Nginx reverse proxy (port 80 → 3000) aur free SSL (Let's Encrypt) ka setup bhi de dungi.

---

## PART 6 — Nginx Reverse Proxy + Free SSL (Clean URL, bina port ke)

Ye setup karne ke baad `http://cloudwithshalvi.online:3000` ki jagah seedha `https://cloudwithshalvi.online` pr website khulegi. Nginx port 80/443 pr requests le kar internally port 3000 (tumhari Node app) pr forward karega.

**Zaroori:** Domain ka DNS A record pehle se EC2 Elastic IP pr point hona chahiye (Part 5), aur DNS propagate ho chuka ho (check karo: `nslookup cloudwithshalvi.online`).

### Step 1: Security Group update karo
EC2 Security Group me inbound rules check karo — ye dono open hone chahiye:
- HTTP (80) — Anywhere (0.0.0.0/0)
- HTTPS (443) — Anywhere (0.0.0.0/0)

(Port 3000 ko public se band bhi kar sakti ho ab, kyunki traffic ab Nginx ke through jayega — sirf localhost se 3000 accessible rahe to zyada secure)

### Step 2: Nginx install karo (EC2 pr)
```bash
sudo dnf install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
```

### Step 3: Reverse proxy config banao
```bash
sudo nano /etc/nginx/conf.d/cloudwithshalvi.conf
```
Ye content daalo:
```nginx
server {
    listen 80;
    server_name cloudwithshalvi.online www.cloudwithshalvi.online;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
    }
}
```
Config test karo aur Nginx reload karo:
```bash
sudo nginx -t
sudo systemctl reload nginx
```
Ab `http://cloudwithshalvi.online` (bina port) pr website khulni chahiye.

### Step 4: Free SSL lagao (Let's Encrypt via Certbot)
```bash
sudo dnf install -y certbot python3-certbot-nginx
sudo certbot --nginx -d cloudwithshalvi.online -d www.cloudwithshalvi.online
```
- Email aur agree to terms poochega — fill kar do
- Certbot automatically Nginx config update kar dega (port 443 + redirect http→https add ho jayega)
- Auto-renewal already ho jata hai, test karne ke liye: `sudo certbot renew --dry-run`

Ab `https://cloudwithshalvi.online` pr website secure (SSL lock ke saath) khulegi.

### Note (CodeDeploy ke sath compatibility)
Isme koi change nahi karna padega — CodeDeploy sirf `/home/ec2-user/app` folder update karta hai aur pm2 se Node app port 3000 pr hi restart karta hai. Nginx alag se background me chalta rehta hai aur hamesha localhost:3000 ko forward karta hai. Dono independent hain.

---

## Quick Checklist
- [ ] EC2 launched, Elastic IP attached, Security Group me port 3000 open
- [ ] Node, pm2, CodeDeploy agent installed on EC2
- [ ] App manually test ho chuki (port 3000 pr)
- [ ] IAM roles (EC2, CodeDeploy, CodePipeline) ready
- [ ] Code GitHub pr pushed
- [ ] CodeDeploy Application + Deployment Group created
- [ ] CodePipeline created aur ek test push se deploy verify kiya
- [ ] Hostinger DNS A record EC2 IP pr point kiya
- [ ] Nginx reverse proxy + Certbot SSL setup (clean HTTPS URL)
