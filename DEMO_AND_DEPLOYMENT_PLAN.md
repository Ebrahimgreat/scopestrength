# ScopeStrength: Demo/Trial System & Deployment Plan

## 📋 Overview
This document outlines the implementation plan for:
1. **Demo/Trial System** - Allow users to try ScopeStrength for free
2. **Domain Deployment** - Migrate from Render's default domain to scopestrength.com

---

## 🎯 Part 1: Demo/Trial System

### Current State
- ✅ Subscription schema exists with `trial_start`, `trial_end`, `paid_until` fields
- ✅ User authentication system in place
- ✅ Database already configured
- ✅ Invite system exists (trainers can invite clients)

### Business Model Clarification ⭐

**Important:** ScopeStrength is **B2B2C** (Business-to-Business-to-Consumer):

```
Trainer (Paying Customer)     →     Client (End User)
     ↓                                     ↓
Gets 14-day trial          →     Gets access via invite
Then pays subscription     →     Free (included with trainer)
Can invite unlimited       →     Tied to their trainer
     clients
```

**Key Rules:**
1. ✅ **Trainers** register freely → Get 14-day trial
2. ❌ **Clients** CANNOT register without invite code
3. ✅ Clients inherit access from their trainer's subscription
4. ✅ When trainer's trial/subscription expires → All their clients lose access

This prevents:
- Random client signups (no trainer = no value)
- Trial abuse (one person registering as multiple clients)
- Orphaned accounts
- Revenue leakage

### Implementation Strategy

#### 1.1 Trial Management Functions
**File:** `lib/crohnjobs/subscriptions.ex`

Add these functions:
- `create_trial_subscription(user_id, trial_days)` - Creates 14-day trial by default
- `in_trial?(subscription)` - Checks if user is in active trial
- `has_access?(subscription)` - Checks if user has access (trial OR paid)
- `get_by_user_id(user_id)` - Get subscription for a user
- `upgrade_to_paid(subscription, plan, months)` - Convert trial to paid
- `trial_days_remaining(subscription)` - Show how many days left

#### 1.2 Access Control Middleware
**File:** `lib/crohnjobs_web/live/require_subscription.ex` (new file)

Create a LiveView hook that:
- Checks user role (trainer vs client)
- **For Trainers:** Check their own subscription
  - Redirects to upgrade page if trial expired
  - Shows trial countdown in UI
  - Allows access during trial period
- **For Clients:** Check their trainer's subscription
  - Get trainer from client record
  - Check trainer's subscription status
  - If trainer has access → client has access
  - If trainer expired → show "Contact your trainer" message
  - Never redirect client to payment page (they don't pay)

**Example logic:**
```elixir
def check_access(user) do
  case user.role do
    "trainer" ->
      subscription = Subscriptions.get_by_user_id(user.id)
      Subscriptions.has_access?(subscription)

    "client" ->
      client = Clients.get_by_user_id(user.id)
      trainer = Trainers.get!(client.trainer_id)
      trainer_user = Accounts.get_user!(trainer.user_id)
      subscription = Subscriptions.get_by_user_id(trainer_user.id)
      Subscriptions.has_access?(subscription)
  end
end
```

#### 1.3 Registration Flow Update ⭐ CRITICAL
**File:** `lib/crohnjobs_web/live/user_registration_live.ex`

**For Trainers:**
1. Register with email + password + name
2. Automatically create trial subscription (14 days)
3. Create trainer record
4. Show welcome: "Your 14-day trial has started!"
5. Redirect to dashboard → Invite clients

**For Clients:**
1. **MUST have invite code** (otherwise show error)
2. URL format: `/register?invite=ABC12345` or manual input field
3. Validate invite code + email match
4. Create user account
5. Create client record linked to trainer
6. Mark invite as used
7. Inherit access from trainer's subscription
8. Show: "Welcome! You've been added to [Trainer Name]'s team"
9. Redirect to workouts

**Implementation:**
```elixir
# Registration validates role
if role == "client" and invite_code_missing:
  error: "Clients must register with an invite code from their trainer"

if role == "client":
  - Validate invite code
  - Check email matches invite
  - Link to trainer
  - No trial needed (uses trainer's subscription)

if role == "trainer":
  - Create trial subscription
  - Generate default invite link to share
```

#### 1.4 Trial Status UI Component
**File:** `lib/crohnjobs_web/components/trial_banner.ex` (new file)

**For Trainers:**
```
📅 Trial: 7 days remaining | Upgrade Now
```

Features:
- Green badge: Trial active (10+ days)
- Yellow badge: Trial ending soon (< 10 days)
- Red badge: Trial expired
- Sticky banner at top of dashboard

**For Clients:**
```
✓ Active - Access provided by [Trainer Name]
```

- No trial countdown (they don't pay)
- Show their trainer's name
- Optional: "Contact your trainer to upgrade" if trainer's subscription expires

#### 1.5 Upgrade Page
**File:** `lib/crohnjobs_web/live/upgrade_live.ex` (new file)

Features:
- Show pricing plans
- Stripe/payment integration (placeholder for now)
- Benefits comparison
- Upgrade button

#### 1.6 Registration Form UI Update

**Current State:**
- Dropdown: "I am a" → Trainer / Client
- Anyone can register as either role

**New State:**
- **If role = "Trainer":** Normal form (name, email, password)
- **If role = "Client":** Show invite code input field (required)

**Live form changes (phx-change):**
```heex
<.input
  field={@form[:role]}
  type="select"
  label="I am a"
  options={[{"Trainer", "trainer"}, {"Client", "client"}]}
  phx-change="role_changed"
/>

<.input
  :if={@selected_role == "client"}
  field={@form[:invite_code]}
  type="text"
  label="Invite Code"
  placeholder="Enter code from your trainer"
  required
  phx-change="validate_invite"
/>

<!-- Show invite status -->
<div :if={@invite_status == :valid} class="text-green-600 text-sm">
  ✓ Valid invite from trainer: {@trainer_name}
</div>

<div :if={@invite_status == :invalid} class="text-red-600 text-sm">
  ✗ Invalid or expired invite code
</div>
```

**Alternative: Separate registration pages**
- `/register/trainer` - Clean, simple trainer signup
- `/register/client?invite=ABC123` - Client signup (pre-filled from invite link)
- Redirect `/register` → "Are you a trainer or client?" → Different pages

**Recommended:** Separate pages (cleaner UX)

#### 1.7 Access Control Implementation

**Option A: Plug-based (Simple)**
```elixir
# Apply to specific routes
plug :require_active_subscription when action in [:dashboard, :clients, :workouts]
```

**Option B: LiveView on_mount (Recommended)**
```elixir
# Apply to all protected LiveViews
on_mount {CrohnjobsWeb.RequireSubscription, :ensure_active_subscription}
```

#### 1.6.1 Invite Code Enforcement ⭐

**Critical implementation details:**

**Backend validation (registration):**
```elixir
def handle_event("save", %{"user" => user_params}, socket) do
  case user_params["role"] do
    "client" ->
      # MUST have invite code
      invite_code = user_params["invite_code"]
      email = user_params["email"]

      case Invites.redeem_invite(invite_code, email) do
        {:ok, trainer_id} ->
          # Valid invite, proceed with registration
          register_client(user_params, trainer_id)

        {:error, :invalid_code} ->
          {:noreply, put_flash(socket, :error, "Invalid invite code")}

        {:error, :already_used} ->
          {:noreply, put_flash(socket, :error, "This invite has already been used")}

        {:error, :email_mismatch} ->
          {:noreply, put_flash(socket, :error, "This invite is for a different email")}
      end

    "trainer" ->
      # No invite needed, create trial
      register_trainer(user_params)
  end
end
```

**Benefits:**
1. ✅ No orphaned client accounts
2. ✅ Every client automatically linked to trainer
3. ✅ Prevents trial abuse (can't register as "client" multiple times)
4. ✅ Clear onboarding path
5. ✅ Trainer can track who they invited

**Trainer invite workflow:**
1. Trainer goes to "Invite Client" page
2. Enters client email → Generate unique code (ABC12345)
3. System sends email OR trainer copies invite link
4. Client clicks link → Pre-filled registration form
5. Client completes signup → Automatically linked

**Email template:**
```
Subject: You've been invited to ScopeStrength by [Trainer Name]

Hi there!

[Trainer Name] has invited you to join them on ScopeStrength.

Click here to get started:
https://scopestrength.com/register/client?invite=ABC12345&email=client@example.com

Your invite code: ABC12345

See you soon!
```

#### 1.8 Database Migration
**File:** `priv/repo/migrations/YYYYMMDDHHMMSS_add_subscription_status.exs` (new)

Add computed fields:
- `status` enum: `["trial", "active", "expired", "cancelled"]`
- Index on `user_id` for faster lookups
- Index on `trial_end` and `paid_until` for cleanup jobs

#### 1.9 Cascade Logic: When Trainer Subscription Expires

**What happens when a trainer's trial/subscription ends?**

**Option 1: Hard Block (Recommended)**
- Trainer loses access immediately
- All their clients lose access immediately
- Shows: "Your trainer's subscription has expired. Contact them to regain access."
- Prevents any workouts/data changes
- Read-only mode for data export (7-day grace period)

**Option 2: Soft Block**
- Trainer loses access to create NEW programs
- Clients can still VIEW existing programs
- Can't log new workouts
- Shows: "Limited access - contact trainer to upgrade"

**Option 3: Grace Period**
- 3-day grace period after expiration
- Full access continues
- Banner: "Subscription expired - Upgrade to continue"
- After 3 days → Hard block

**Recommended:** Option 1 (Hard Block) with 7-day read-only grace for data export

**Implementation:**
```elixir
def has_access?(subscription) do
  now = DateTime.utc_now()

  cond do
    # In trial
    in_trial?(subscription) -> {:ok, :trial}

    # Paid and valid
    !is_nil(subscription.paid_until) &&
    DateTime.compare(now, subscription.paid_until) == :lt -> {:ok, :paid}

    # Grace period (7 days after expiration, read-only)
    grace_period?(subscription) -> {:ok, :grace_period_read_only}

    # Expired
    true -> {:error, :expired}
  end
end
```

**Client-side handling:**
```elixir
def client_has_access?(client) do
  trainer = get_trainer(client.trainer_id)
  subscription = get_subscription(trainer.user_id)

  case has_access?(subscription) do
    {:ok, _status} -> true
    {:error, :expired} -> false
  end
end
```

#### 1.10 Background Jobs (Oban)
**File:** `lib/crohnjobs/workers/subscription_checker.ex` (new)

Daily job to:
- Send "3 days left" email reminder
- Send "1 day left" email reminder
- Mark subscriptions as expired
- Optionally: Restrict access to expired accounts

---

## 🚀 Part 2: Domain Deployment (scopestrength.com)

### Current State
- ✅ App deployed on Render: `workoutbuilder-1.onrender.com`
- ✅ Domain purchased: `scopestrength.com`
- ✅ Release configuration exists

### Deployment Options

#### Option A: Stay on Render (Easiest)
**Pros:** Already configured, simple DNS change
**Cons:** Less control, potential cost at scale

**Steps:**
1. Go to Render Dashboard → Your Service
2. Click "Settings" → "Custom Domain"
3. Add `scopestrength.com` and `www.scopestrength.com`
4. Update DNS records at your domain registrar:
   ```
   Type: CNAME
   Name: www
   Value: workoutbuilder-1.onrender.com

   Type: ALIAS/ANAME (or A record)
   Name: @
   Value: [Render's IP or CNAME]
   ```
5. Update `config/runtime.exs` line 69:
   ```elixir
   url: [host: "scopestrength.com", port: 443, scheme: "https"]
   ```
6. Render will auto-provision SSL certificate

**Timeline:** 15 minutes + DNS propagation (up to 48 hours)

---

#### Option B: Fly.io (Recommended for Phoenix)
**Pros:** Great Phoenix support, global CDN, better pricing, database backups
**Cons:** Need to migrate from Render

**Steps:**
1. Install Fly CLI: `brew install flyctl`
2. Login: `fly auth login`
3. Generate Fly config: `fly launch --no-deploy`
4. Create Postgres: `fly postgres create`
5. Attach database: `fly postgres attach`
6. Set secrets:
   ```bash
   fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret)
   fly secrets set PHX_HOST=scopestrength.com
   ```
7. Deploy: `fly deploy`
8. Add custom domain:
   ```bash
   fly certs add scopestrength.com
   fly certs add www.scopestrength.com
   ```
9. Update DNS to Fly's IPs
10. SSL auto-configured

**Cost:** ~$15-30/month (vs Render's ~$25-50/month)
**Timeline:** 1-2 hours

---

#### Option C: DigitalOcean App Platform
**Pros:** Simple like Render, good pricing, database included
**Cons:** Slightly less Phoenix-specific features

**Steps:** Similar to Render
1. Connect GitHub repo
2. Add PostgreSQL database
3. Configure environment variables
4. Add custom domain
5. Update DNS records

**Cost:** ~$12-25/month
**Timeline:** 30 minutes

---

#### Option D: VPS (DigitalOcean/Hetzner/Linode)
**Pros:** Maximum control, cheapest ($6-12/month), full server access
**Cons:** You manage everything (security, backups, updates, SSL)

**Not recommended unless** you're experienced with server administration.

---

### Recommended Deployment Strategy

**For You: Option A (Render) → Then Option B (Fly.io)**

**Phase 1 (Now):**
- Update domain on Render (15 min)
- Get scopestrength.com live quickly
- Keep everything working as-is

**Phase 2 (Later):**
- Migrate to Fly.io when ready
- Better scaling and pricing
- More Phoenix-friendly

---

## 📅 Implementation Timeline

### Week 1: Demo System Core
- **Day 1-2:** Add subscription management functions
- **Day 3:** Create access control middleware
- **Day 4:** Update registration flow
- **Day 5:** Build trial banner UI
- **Day 6-7:** Testing and bug fixes

### Week 2: Polish & Deploy
- **Day 1-2:** Create upgrade page
- **Day 3:** Add background jobs for reminders
- **Day 4:** Email templates for trial reminders
- **Day 5:** Update domain to scopestrength.com
- **Day 6-7:** Testing in production

---

## 🧪 Testing Checklist

### Trial System Tests
- [ ] New user gets automatic trial subscription
- [ ] Trial countdown displays correctly
- [ ] Access granted during trial period
- [ ] Access blocked after trial expires
- [ ] Upgrade converts trial to paid
- [ ] Email reminders sent at 3 days, 1 day
- [ ] Edge case: User registers → deletes account → re-registers

### Deployment Tests
- [ ] scopestrength.com loads correctly
- [ ] www.scopestrength.com redirects to scopestrength.com
- [ ] SSL certificate valid
- [ ] Database migrations run
- [ ] Environment variables set
- [ ] Email sending works
- [ ] File uploads work (if applicable)
- [ ] Background jobs running

---

## 💰 Cost Breakdown

### Current (Render)
- Web service: ~$7-25/month
- Database: ~$7-25/month
- **Total: ~$14-50/month**

### With Custom Domain
- Domain: ~$12/year ($1/month)
- **Total: ~$15-51/month**

### Alternative: Fly.io
- App: ~$5-15/month
- Database: ~$10-15/month
- **Total: ~$15-30/month**

---

## 🔒 Security Considerations

### Trial System
1. **Prevent Trial Abuse:**
   - Require email confirmation
   - One trial per email address
   - Optional: Require credit card (no charge during trial)

2. **Data Access:**
   - Allow read-only access after trial expires?
   - Or completely block access?
   - Grace period? (3 days to export data)

3. **Database Cleanup:**
   - Delete expired trial data after 30 days?
   - Or keep forever for re-activation?

### Domain/Deployment
1. **SSL/TLS:** Auto-handled by hosting provider
2. **Environment Variables:** Never commit secrets
3. **Database Backups:** Enable daily automated backups
4. **Monitoring:** Set up uptime monitoring (UptimeRobot free tier)

---

## 📧 Email Flow

### Trial Lifecycle Emails

1. **Welcome Email** (Day 0)
   - Subject: "Welcome to ScopeStrength - Your trial has started!"
   - Content: Getting started guide, key features

2. **Reminder Email** (Day 11)
   - Subject: "3 days left in your ScopeStrength trial"
   - Content: Upgrade CTA, benefits recap

3. **Final Reminder** (Day 13)
   - Subject: "Last chance - 1 day left!"
   - Content: Urgent upgrade CTA

4. **Expiration Email** (Day 14)
   - Subject: "Your trial has ended"
   - Content: Upgrade to continue, data export option

5. **Win-back Email** (Day 17)
   - Subject: "We miss you! Special offer inside"
   - Content: Discount code, testimonials

---

## 🎨 UI/UX Considerations

### Trial Badge Placement
```
┌─────────────────────────────────────────┐
│ 📅 Trial: 7 days left | Upgrade ▶      │ ← Sticky banner
├─────────────────────────────────────────┤
│ Dashboard                                │
│                                         │
│ [Your workout content here]             │
└─────────────────────────────────────────┘
```

### Upgrade Page Design
- Hero section: "Upgrade to unlock unlimited access"
- Pricing cards: Trial → Monthly → Yearly (save 20%)
- Feature comparison table
- Testimonials
- FAQ section
- Money-back guarantee badge

---

## 🔄 Migration Path for Existing Users

### If you have existing users without subscriptions:

**Option 1: Grandfather existing users (Recommended)**
```elixir
# Give existing users a free paid plan
existing_users
|> Enum.each(fn user ->
  create_subscription(%{
    user_id: user.id,
    plan: "legacy_free",
    paid_until: ~U[2099-12-31 23:59:59Z]
  })
end)
```

**Option 2: Give existing users extended trial**
```elixir
# Give 60-day trial to existing users
create_trial_subscription(user.id, 60)
```

---

## 🚦 Go-Live Checklist

### Pre-Launch
- [ ] All tests passing
- [ ] Staging environment tested
- [ ] Email sending configured
- [ ] Payment provider sandbox tested
- [ ] Backup strategy in place
- [ ] Rollback plan documented

### Launch Day
- [ ] Deploy code
- [ ] Run migrations
- [ ] Update DNS records
- [ ] Monitor error logs
- [ ] Test critical user flows
- [ ] Announce on social media

### Post-Launch
- [ ] Monitor trial conversion rates
- [ ] Track email open rates
- [ ] Gather user feedback
- [ ] A/B test upgrade page
- [ ] Optimize pricing

---

## 📊 Metrics to Track

1. **Trial Conversion Rate:** % of trials that convert to paid
2. **Trial Completion Rate:** % of users who complete onboarding
3. **Time to First Value:** How long until user sees benefit
4. **Churn Rate:** % of paid users who cancel
5. **Average Revenue Per User (ARPU)**
6. **Trial Extension Requests:** Indicates pricing/value mismatch

**Target Metrics:**
- Trial → Paid conversion: 15-25% (industry average)
- Onboarding completion: 60%+
- Monthly churn: <5%

---

## 🎯 Next Steps

### Immediate (This Week)
1. Review this plan
2. Decide on deployment strategy (Render vs Fly.io)
3. Choose trial duration (7, 14, or 30 days?)
4. Update scopestrength.com DNS

### Short-term (Next 2 Weeks)
1. Implement trial system backend
2. Build trial UI components
3. Set up email templates
4. Test thoroughly

### Medium-term (Next Month)
1. Add payment integration (Stripe recommended)
2. Build upgrade page
3. Implement analytics
4. Launch marketing campaign

---

## 🤔 Questions to Answer

### Business Model ⭐
1. **Client Limits per Trainer:**
   - Unlimited clients per trainer?
   - Or tiered: Basic (10 clients), Pro (50 clients), Enterprise (unlimited)?
   - Recommendation: Start unlimited, add tiers later for upsells

2. **Pricing Model for Trainers:**
   - Flat monthly fee? (e.g., $29/month unlimited clients)
   - Per-client pricing? (e.g., $5/client/month)
   - Tiered based on features?
   - Recommendation: Flat fee ($19-29/month) = simpler, easier to sell

### Trial & Registration
3. **Trial Duration:** 7, 14, or 30 days?
   - Recommendation: 14 days (industry standard for B2B SaaS)

4. **Invite System:**
   - Allow trainers to send unlimited invites?
   - Or limit invites during trial? (e.g., 3 clients during trial)
   - Recommendation: Unlimited invites (they need to test with real clients)

5. **Email Validation:**
   - Must client email match invite exactly?
   - Or allow any email with valid code?
   - Current: Email must match (good for security)
   - Recommendation: Keep strict email matching

6. **Registration Pages:**
   - Single page with role toggle?
   - Separate `/register/trainer` and `/register/client` pages?
   - Recommendation: Separate pages (cleaner UX, prevents confusion)

### Payment & Access
7. **Payment Provider:** Stripe, Paddle, or PayPal?
   - Recommendation: Stripe (easiest for Phoenix, best docs)

8. **Post-Trial Access:**
   - Complete lockout?
   - Read-only access for data export?
   - Grace period?
   - Recommendation: 7-day read-only grace period, then lockout

9. **Credit Card Required?**
   - During trial signup?
   - Recommendation: No (higher conversion), but send payment reminders

10. **When Trainer Expires:**
    - Do clients immediately lose access?
    - Or grace period for clients too?
    - Recommendation: Immediate lockout (motivates trainer to pay)

### Features & Limits
11. **Trial Feature Restrictions:**
    - Full access during trial?
    - Or limit features (e.g., no PDF exports, no custom branding)?
    - Recommendation: Full access (let them see the value)

12. **Post-Expiry Data:**
    - Keep trainer/client data forever?
    - Delete after 30/60/90 days?
    - Recommendation: Keep 90 days, then soft delete (recoverable)

---

## 📚 Resources

### Phoenix Deployment
- [Fly.io Phoenix Guide](https://fly.io/docs/elixir/)
- [Render Phoenix Guide](https://render.com/docs/deploy-phoenix)
- [Phoenix Deployment Guide](https://hexdocs.pm/phoenix/deployment.html)

### Payment Integration
- [Stripe with Phoenix](https://stripe.com/docs/payments/accept-a-payment)
- [StripeSig (Elixir lib)](https://hex.pm/packages/stripity_stripe)

### Monitoring
- [AppSignal](https://appsignal.com) - Phoenix-specific APM
- [Sentry](https://sentry.io) - Error tracking
- [UptimeRobot](https://uptimerobot.com) - Free uptime monitoring

---

## 💡 Pro Tips

1. **Launch MVP First:** Don't wait for perfect - ship trial system, then iterate
2. **Pricing:** Start higher, discount later (easier than raising prices)
3. **Onboarding:** First 5 minutes determine trial conversion
4. **Social Proof:** Add testimonials from beta users
5. **Email:** Don't spam, but don't be shy - 4-5 emails during trial is normal
6. **Analytics:** Use Plausible or Fathom (GDPR-friendly, simple)

---

## 🗺️ System Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    TRAINER REGISTRATION                          │
│                                                                  │
│  1. Visit /register/trainer                                     │
│  2. Enter email, password, name                                 │
│  3. System creates:                                             │
│     - User (role: trainer)                                      │
│     - Trainer record                                            │
│     - Subscription (14-day trial) ⭐                            │
│  4. Redirect to dashboard                                       │
│  5. Prompt: "Invite your first client!"                         │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                    TRAINER INVITES CLIENT                        │
│                                                                  │
│  1. Click "Invite Client"                                       │
│  2. Enter client email: john@example.com                        │
│  3. System creates invite:                                      │
│     code: "ABC12345"                                            │
│     email: john@example.com                                     │
│     trainer_id: 123                                             │
│  4. Send email OR copy link:                                    │
│     scopestrength.com/register/client?invite=ABC12345           │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                    CLIENT REGISTRATION ⭐                        │
│                                                                  │
│  1. Click invite link (OR visit /register/client)              │
│  2. Form auto-fills invite code                                │
│  3. Enter password, confirm email                               │
│  4. System validates:                                           │
│     - Invite exists? ✓                                          │
│     - Not used? ✓                                               │
│     - Email matches? ✓                                          │
│  5. System creates:                                             │
│     - User (role: client)                                       │
│     - Client record (trainer_id: 123)                           │
│     - Mark invite as used                                       │
│  6. NO subscription created (uses trainer's) ⭐                 │
│  7. Redirect to workouts                                        │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                    ACCESS CONTROL                                │
│                                                                  │
│  TRAINER ACCESS:                                                │
│  ✓ Check own subscription                                       │
│  ✓ Trial active (days 1-14)? → Allow                           │
│  ✓ Paid subscription? → Allow                                   │
│  ✗ Expired? → Redirect to /upgrade                             │
│                                                                  │
│  CLIENT ACCESS: ⭐                                              │
│  ✓ Get client.trainer_id → Find trainer                        │
│  ✓ Check trainer's subscription                                │
│  ✓ Trainer has access? → Client has access                     │
│  ✗ Trainer expired? → Show "Contact your trainer"              │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                    TRIAL EXPIRATION                              │
│                                                                  │
│  Day 11: Email "3 days left" → trainer@example.com             │
│  Day 13: Email "1 day left!" → trainer@example.com             │
│  Day 14: Trial expires                                          │
│                                                                  │
│  TRAINER:                                                        │
│  → Redirect to /upgrade                                         │
│  → Show pricing, payment form                                   │
│  → 7-day grace period (read-only)                               │
│                                                                  │
│  ALL TRAINER'S CLIENTS: ⭐                                      │
│  → Also lose access (tied to trainer)                           │
│  → Show: "Your trainer's subscription expired"                  │
│  → No payment option (they don't pay)                           │
│  → Must contact trainer                                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🎬 Ready to Implement?

**Recommended Order:**
1. ✅ Review this plan
2. ⚡ **PRIORITY:** Enforce invite codes for client registration
3. 💻 Implement trial system for trainers (only)
4. 🔧 Update domain to scopestrength.com (quick win!)
5. 🎨 Build trial UI (trainer banner + client status)
6. 📧 Set up emails (invite + trial reminders)
7. 💳 Add payment (last, but important)

**Quick Wins (Do First):**
1. **Client Registration Fix** (1-2 hours)
   - Add invite code validation
   - Show error if client tries to register without code
   - This prevents trial abuse immediately

2. **Domain Update** (15 minutes)
   - Point scopestrength.com to Render
   - Professional domain live!

3. **Trainer Trial** (2-3 hours)
   - Auto-create subscription on trainer registration
   - Show trial countdown in dashboard

Let me know which parts you want to tackle first, and I'll help you implement them step by step!
