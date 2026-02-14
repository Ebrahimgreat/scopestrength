# Render Deployment Plan for ScopeStrength

## Overview
Deploy your Phoenix/Elixir workout tracking app to Render for **FREE** with custom domain `app.scopestrength.com`

## ✅ What You Already Have
- ✅ `render.yaml` - Render configuration file
- ✅ `build.sh` - Build script
- ✅ `config/runtime.exs` - Production runtime config
- ✅ Phoenix app with migrations ready

---

## 📋 Step-by-Step Deployment Plan

### Step 1: Prepare Your Repository
**Action**: Commit and push your files to GitHub

```bash
# Add the new files
git add render.yaml build.sh

# Commit
git commit -m "Add Render deployment configuration"

# Push to GitHub
git push origin main
```

⚠️ **Important**: Do NOT commit the `.env` file (it should already be in `.gitignore`)

---

### Step 2: Create Render Account & Connect GitHub
1. Go to [render.com](https://render.com)
2. Sign up with your GitHub account (free)
3. Authorize Render to access your repository

---

### Step 3: Deploy Using render.yaml
**Render will automatically create BOTH services from your `render.yaml`:**

1. **PostgreSQL Database** (`crohnjobs-db`)
   - Free tier: 90 days free, then $7/month (or stays free if you verify with credit card)
   - Database expires after 90 days on free tier without card

2. **Web Service** (`crohnjobs-web`)
   - Free tier: 750 hours/month (enough for one app running 24/7)
   - Spins down after 15 minutes of inactivity
   - Cold start takes ~30 seconds

**How to deploy:**
1. In Render Dashboard, click **"New +"** → **"Blueprint"**
2. Select your GitHub repository
3. Render will detect `render.yaml` automatically
4. Click **"Apply"** to create all services

---

### Step 4: Set Environment Variables
Render will auto-generate most variables, but you need to add:

**In the Web Service settings → Environment:**

| Variable | Value | Notes |
|----------|-------|-------|
| `GEMINI_API_KEY` | `REDACTED-GEMINI-KEY` | Copy from your .env file |
| `DATABASE_URL` | *(auto-generated)* | Render links this automatically |
| `SECRET_KEY_BASE` | *(auto-generated)* | Render generates this |
| `ECTO_IPV6` | `true` | Already in render.yaml |
| `ERL_AFLAGS` | `-proto_dist inet6_tcp` | Already in render.yaml |
| `PHX_HOST` | `app.scopestrength.com` | Add this manually AFTER setting up domain |

**How to add:**
1. Go to your web service in Render Dashboard
2. Click **Environment** tab
3. Add `GEMINI_API_KEY` with value from your `.env`
4. Add `PHX_HOST` (do this AFTER domain setup in Step 5)

---

### Step 5: Custom Domain Setup (app.scopestrength.com)

#### A. In Render Dashboard:
1. Go to your **web service** → **Settings** → **Custom Domains**
2. Click **"Add Custom Domain"**
3. Enter: `app.scopestrength.com`
4. Render will give you DNS instructions (CNAME or A record)

#### B. In Your Domain Registrar (where you bought scopestrength.com):
You have two options:

**Option 1 - CNAME (Recommended):**
```
Type: CNAME
Name: app
Value: <your-render-app-name>.onrender.com
```

**Option 2 - A Record:**
```
Type: A
Name: app
Value: <IP address from Render>
```

**How to find the values:**
- Render will show you exactly what to add after you click "Add Custom Domain"
- Your Render app URL will be something like `crohnjobs-web.onrender.com`

⏱️ **DNS propagation takes 5-60 minutes**

---

### Step 6: Verify Deployment

1. **Check build logs:**
   - Go to your web service → **Logs** tab
   - Build should complete successfully
   - Look for: `==> Running preDeploy command` (migrations)
   - Then: `==> Your app is live`

2. **Test the app:**
   - Visit: `https://crohnjobs-web.onrender.com` (Render's default URL)
   - After DNS propagates: `https://app.scopestrength.com`

3. **Check database:**
   - Go to **crohnjobs-db** → **Info**
   - Verify it's running
   - Check connection string is linked to web service

---

## 🎯 Database Setup - ANSWERED

### Do you need to create a database on Render?
**YES** - But `render.yaml` does this automatically!

When you deploy using the Blueprint (Step 3), Render will:
1. ✅ Create PostgreSQL database (`crohnjobs-db`)
2. ✅ Auto-generate `DATABASE_URL`
3. ✅ Link it to your web service
4. ✅ Run migrations before deploy (`preDeploy` command in render.yaml)

**You don't need to do anything manually** - it's all configured in your `render.yaml`!

---

## 💰 Free Tier Limitations

### Web Service (Free Forever):
- ✅ 750 hours/month (runs 24/7 for 1 app)
- ⚠️ Spins down after 15 min inactivity
- ⚠️ Cold start: ~30-60 seconds
- ✅ 512 MB RAM
- ✅ 0.1 CPU
- ✅ Custom domain included

### PostgreSQL Database:
- ⚠️ **90 days free trial**
- After 90 days: $7/month OR stays free if you add credit card (without charging)
- 1 GB storage
- Limited to 1 database on free tier

**Alternative for free DB:**
- Use [Supabase](https://supabase.com) (500 MB free forever)
- Use [Neon](https://neon.tech) (Free tier with 3 GB)
- Update `DATABASE_URL` in Render if you switch

---

## 🔧 Post-Deployment Checklist

- [ ] Commit `render.yaml` and `build.sh` to git
- [ ] Push to GitHub
- [ ] Create Blueprint in Render
- [ ] Wait for initial deployment (~5-10 min)
- [ ] Add `GEMINI_API_KEY` environment variable
- [ ] Set up custom domain in Render
- [ ] Update DNS records at domain registrar
- [ ] Wait for DNS propagation (5-60 min)
- [ ] Add `PHX_HOST=app.scopestrength.com` environment variable
- [ ] Test app at `app.scopestrength.com`
- [ ] Verify SSL certificate (auto-generated by Render)

---

## 🚨 Common Issues & Solutions

### Issue: Build fails
**Solution**: Check logs for missing dependencies
```bash
# Locally test build
chmod +x build.sh
./build.sh
```

### Issue: App crashes after deploy
**Solution**: Check if migrations ran
- View deploy logs for `preDeploy` step
- Manually run: Settings → Deploy → Manual Deploy

### Issue: Database connection errors
**Solution**:
- Verify `DATABASE_URL` is set (should be automatic)
- Check database is running in Render Dashboard

### Issue: Cold starts too slow
**Solutions**:
- Upgrade to paid tier ($7/month) - no spin down
- Use [Render Cron Job](https://render.com/docs/cronjobs) to ping app every 10 min
- Add a free uptime monitor (UptimeRobot, Better Uptime)

### Issue: Domain not working
**Solution**:
- Wait longer (DNS can take up to 24 hours)
- Check DNS settings with `dig app.scopestrength.com`
- Verify CNAME points to correct Render URL

---

## 🎉 Success Criteria

When everything works, you should see:
- ✅ App accessible at `https://app.scopestrength.com`
- ✅ SSL certificate (🔒 green padlock)
- ✅ No connection errors
- ✅ Database migrations applied
- ✅ Can create trainers, clients, workouts

---

## 📝 Next Steps After Deployment

1. **Monitor your app**: Render Dashboard → Logs
2. **Set up error tracking**: Consider [Sentry](https://sentry.io) (free tier)
3. **Add uptime monitoring**: [UptimeRobot](https://uptimerobot.com) (free)
4. **Plan for database**: After 90 days, decide to:
   - Add credit card to Render (stays free)
   - Pay $7/month
   - Migrate to Supabase/Neon

---

## 🔐 Security Notes

⚠️ **NEVER commit these to git:**
- `.env` file
- `GEMINI_API_KEY`
- `SECRET_KEY_BASE`
- `DATABASE_URL`

✅ **Already configured in render.yaml:**
- Force SSL (HTTPS only)
- IPv6 support
- Secure environment variables

---

## Need Help?
- Render Docs: https://render.com/docs
- Phoenix Deployment: https://hexdocs.pm/phoenix/deployment.html
- Your app logs: Render Dashboard → Web Service → Logs
