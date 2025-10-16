# 🚀 Deploy Your Parking Backend to Render.com

This guide will help you deploy your backend server to Render.com so it runs 24/7 in the cloud.

---

## 📋 Prerequisites

- A GitHub account (free)
- Your parking system code
- 10 minutes of your time

---

## 🎯 Step-by-Step Deployment

### Step 1: Create a GitHub Repository

1. **Go to GitHub**: https://github.com/new
2. **Create a new repository**:
   - Name: `parking-intelligent-backend` (or any name)
   - Description: "Smart Car Parking Backend API"
   - Visibility: **Public** (required for Render free tier)
   - ✅ Check "Add a README file"
3. **Click "Create repository"**

---

### Step 2: Push Your Code to GitHub

Open your terminal and run these commands:

```bash
# Navigate to your project
cd c:\Users\MBHmaidi10\Desktop\parking_intelligent-main

# Initialize git (if not already done)
git init

# Add all files
git add .

# Commit your code
git commit -m "Initial commit - Smart Parking Backend"

# Connect to your GitHub repository
# Replace YOUR_USERNAME with your actual GitHub username
git remote add origin https://github.com/YOUR_USERNAME/parking-intelligent-backend.git

# Push to GitHub
git branch -M main
git push -u origin main
```

**Note:** If you get an error about authentication, GitHub will guide you to create a Personal Access Token.

---

### Step 3: Deploy to Render

1. **Go to Render**: https://render.com/
2. **Sign up** using your GitHub account (click "Get Started for Free")
3. **Authorize Render** to access your GitHub repositories
4. **Click "New +"** → Select **"Web Service"**
5. **Connect your repository**:
   - Find `parking-intelligent-backend` in the list
   - Click **"Connect"**

6. **Configure your service**:
   ```
   Name: parking-backend
   Region: Choose closest to you (e.g., Frankfurt for Europe)
   Branch: main
   Root Directory: backend
   Runtime: Node
   Build Command: npm install
   Start Command: npm start
   Instance Type: Free
   ```

7. **Click "Create Web Service"**

8. **Wait for deployment** (2-3 minutes)
   - You'll see logs showing the build process
   - When done, you'll see "Your service is live 🎉"

---

### Step 4: Get Your Backend URL

After deployment, Render will give you a URL like:
```
https://parking-backend-xxxx.onrender.com
```

**Copy this URL** - you'll need it for the next steps!

---

### Step 5: Test Your Backend

Open your browser and visit:
```
https://parking-backend-xxxx.onrender.com
```

You should see:
```json
{
  "message": "Smart Car Parking API is running",
  "version": "1.0.0",
  "timestamp": "2025-10-16T09:30:00.000Z"
}
```

✅ **Success!** Your backend is now running in the cloud!

---

## 🔧 Next Steps

After deployment, you need to update your app and ESP32-CAM to use the new cloud URL.

### Update Flutter App

I'll help you update the API service to use your Render URL instead of localhost.

### Update ESP32-CAM

You'll need to change the `SERVER_URL` in both:
- `esp32cam_entry_gate.ino`
- `esp32cam_exit_gate.ino`

From:
```cpp
const char* SERVER_URL = "http://192.168.1.100:3000/api/parking/entry";
```

To:
```cpp
const char* SERVER_URL = "https://parking-backend-xxxx.onrender.com/api/parking/entry";
```

---

## 🐛 Troubleshooting

### Build Failed
- Check that `package.json` exists in the `backend` folder
- Verify all dependencies are listed in `package.json`

### Service Won't Start
- Check the logs in Render dashboard
- Ensure `PORT` environment variable is used in `server.js`

### Can't Access URL
- Wait 30 seconds (free tier spins down after inactivity)
- First request will wake it up

---

## 💡 Tips

### Keep Your Service Awake
Free tier spins down after 15 minutes of inactivity. To keep it awake:

1. Use a service like **UptimeRobot** (free):
   - https://uptimerobot.com/
   - Create a monitor that pings your URL every 5 minutes

2. Or add this to your Flutter app (ping every 10 minutes):
   ```dart
   Timer.periodic(Duration(minutes: 10), (timer) {
     http.get(Uri.parse('$baseUrl/'));
   });
   ```

### View Logs
- Go to Render dashboard
- Click on your service
- Click "Logs" tab
- See real-time server logs

### Update Your Code
Just push to GitHub:
```bash
git add .
git commit -m "Update backend"
git push
```
Render will automatically redeploy! 🎉

---

## 📊 What You Get (Free Tier)

- ✅ 750 hours/month (enough for 24/7 usage)
- ✅ Automatic HTTPS
- ✅ Auto-deploy from GitHub
- ✅ Free SSL certificate
- ✅ 512 MB RAM
- ✅ Shared CPU

---

## 🎉 You're Done!

Your backend is now running in the cloud 24/7. Your app and ESP32-CAM can access it from anywhere!

**Need help?** Let me know your Render URL and I'll update all the code for you.
