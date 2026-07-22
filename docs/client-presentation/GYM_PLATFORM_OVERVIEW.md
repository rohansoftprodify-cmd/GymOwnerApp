---
title: Gym Management Platform
subtitle: Product Overview for Client Presentation
date: June 2026
---

<div class="cover-page">

# Gym Management Platform

**Multi-tenant SaaS for fitness businesses**

Product overview — what we are building, what works today, and where we are headed.

*Prepared for client presentation · June 2026*

</div>

<div class="page-break"></div>

## Executive Summary

The **Gym Management Platform** is a complete software ecosystem for running modern fitness businesses at scale. One shared cloud backend powers three dedicated applications — each tailored to a specific role in the gym value chain.

| Role | Application | Purpose |
|------|-------------|---------|
| **Platform Admin** | Super Admin Web Portal | Onboard gyms, monitor the platform, manage all tenant data |
| **Gym Owner** | Gym Owner Mobile App | Run daily operations — members, attendance, fees, store, content |
| **Gym Member** | Gym Member Mobile App | Self-service check-in, subscription visibility, gym discovery, shop browsing |

**Current status:** Core operations are live — gym onboarding, member management, attendance, subscriptions, in-gym store, diet and exercise content, and **owner-side AI** (diet generation, gym analytics, churn radar). A broader **AI vision** for members (24/7 fitness coach, progress tracking) and owners (retention prediction, marketing assistant, sales forecasting) is on the roadmap.

**The opportunity:** Replace fragmented spreadsheets, paper registers, and disconnected tools with a single, mobile-first platform that grows with the business — from a single gym to a multi-location chain — with **multi-language support** planned so owners and members can use the apps in their preferred language.

---

<div class="page-break"></div>

## Platform Architecture

All three applications connect to one secure cloud backend. Each gym’s data is fully isolated — owners and members only see their own gym, while platform administrators have controlled cross-tenant access for support and operations.

```
┌─────────────────────────────────────────────────────────────┐
│                    CLIENT APPLICATIONS                       │
├──────────────────┬──────────────────┬───────────────────────┤
│  Super Admin     │   Gym Owner      │    Gym Member         │
│  Web Portal      │   Mobile App     │    Mobile App         │
│  (React / Web)   │   (Flutter)      │    (Flutter)          │
└────────┬─────────┴────────┬─────────┴──────────┬────────────┘
         │                  │                     │
         └──────────────────┼─────────────────────┘
                            ▼
         ┌──────────────────────────────────────────┐
         │           SUPABASE BACKEND               │
         ├──────────────────────────────────────────┤
         │  • Authentication & user accounts        │
         │  • PostgreSQL database (multi-tenant)    │
         │  • File storage (images, media)          │
         │  • Serverless functions (provisioning, AI) │
         │  • Real-time updates & security (RLS)    │
         └──────────────────────────────────────────┘
```

**Key design principles:**

- **Multi-tenant by design** — hundreds of gyms on one platform, each with private data
- **Role-based access** — admins, owners, staff, and members each see only what they need
- **Mobile-first** — owners and members operate from their phones; admins use a web console
- **Secure sessions** — single-device login prevents account sharing and unauthorized access
- **Localization-ready** — Flutter and React stacks support full internationalization; language rollout is on the roadmap

---

<div class="page-break"></div>

## Super Admin Web Portal

*Platform operations console for your team*

The Super Admin Web Portal gives platform operators full visibility and control without touching raw databases. It is a React web application secured so that only designated platform administrators can sign in.

### What is available today

| Feature | Description |
|---------|-------------|
| **Secure admin login** | Email/password authentication; only approved platform admins can access the portal |
| **Platform dashboard** | Live counts of gyms, members, user profiles, and products across the entire platform |
| **Provision gym owner** | One-step onboarding: creates the gym, owner account, and role assignment — owner completes setup in the mobile app |
| **Data browser** | Browse, search, create, edit, and delete records across 21 data tables |
| **Cross-tenant visibility** | View and manage data for any gym — members, subscriptions, attendance, products, diet plans, exercises, promotions, and more |

**Tables accessible from the portal:**

| Category | Data |
|----------|------|
| Core | Gyms, profiles, gym roles, platform admins |
| Members | Members, attendance records |
| Billing | Subscription plans, member subscriptions |
| Shop | Products, categories, sales orders, promotions |
| Gym setup | Operating hours |
| Fitness | Exercise categories, exercises |
| Diet | Diet categories, plans, meals, food items |
| Security | Active user sessions |

### Why this matters for your business

- **Faster gym onboarding** — add a new gym customer in minutes, not days
- **Centralised support** — troubleshoot any gym’s data from one console
- **No manual database work** — safe, audited access without SQL or technical staff
- **Enterprise-grade security** — admin credentials never expose sensitive backend keys; access is enforced at the database level

---

<div class="page-break"></div>

## Gym Owner Mobile App

*All-in-one gym operations from a smartphone*

The Gym Owner App is a Flutter mobile application (iOS and Android) built for gym owners and staff. It covers the full operational lifecycle — from first-time setup through daily management of members, attendance, fees, and retail.

### What is available today

#### Getting started

| Feature | Description |
|---------|-------------|
| **Onboarding experience** | Guided introduction to platform capabilities on first launch |
| **Secure login** | Email/password sign-in with single-device session enforcement |
| **Setup wizard** | 4-step first-time setup: gym contact details, operating hours, and first membership plan |
| **Light / dark theme** | Appearance preference in gym profile settings |

#### Dashboard — three main tabs

**Home tab**

| Feature | Description |
|---------|-------------|
| Overview cards | Member count, today’s check-ins, product count, overdue dues |
| Active promotions | Carousel of current exclusive offers |
| Pending fees | Members with outstanding payments |
| Upcoming renewals | Subscriptions expiring within 15 days |

**Attendance tab**

| Feature | Description |
|---------|-------------|
| Check-in / check-out | Manual member check-in and check-out from the front desk |
| Open sessions | View members currently checked in (including multi-day sessions) |
| Attendance history | Searchable history with date filters (today, yesterday, 7 days, 30 days, all) |

**Store tab**

| Feature | Description |
|---------|-------------|
| Product catalog | Grid view of gym products with price and stock |
| Categories | Filter and manage product categories |
| Record sales | Log a sale with quantity, optional member link, automatic stock decrement |
| Product images | Display product images when uploaded |

#### Members management

| Feature | Description |
|---------|-------------|
| Member list | All members with subscription summary |
| Add member | Create member profile, assign plan, set payment status, optional app login |
| Member detail | Edit profile, status, subscription, and payment information |
| Member app login | Provision login credentials for the member mobile app |
| Reset password | Reset member app password from the owner app |
| Share credentials | Share login details with new members |

#### Gym Profile hub

| Section | Description |
|---------|-------------|
| **Gym details** | Name, address, contact information |
| **Operating hours** | Weekly schedule, timezone, closed days |
| **Fee structure** | Create and manage subscription plans; activate or deactivate |
| **Exclusive offers** | Create promotions with date ranges; show on member home screens |
| **Exercise library** | Categories, exercises with sets/reps, benefits, precautions, and images |
| **Diet plans** | Goal-based categories (weight loss, muscle gain, healthy living), full meal plans with macros and food items |
| **AI tools** | Diet generation, gym intelligence report, and churn radar — see **AI & Gym Intelligence** |

### Why this matters for your business

- **Run the gym from one app** — no switching between registers, spreadsheets, and messaging apps
- **Less front-desk friction** — quick check-in/out and instant fee visibility
- **Content ready for members** — owners build exercise and diet libraries; members can already browse assigned diet plans
- **Smarter decisions** — built-in AI highlights growth, retention, and content creation without extra tools
- **Professional onboarding** — new gym customers get a polished first-login experience
- **Revenue visibility** — overdue fees and renewals surfaced on the home screen every morning

---

<div class="page-break"></div>

## Gym Member Mobile App

*Modern self-service experience for gym members*

The Gym Member App is a Flutter mobile application that puts members in control of their gym experience — from discovering gyms to checking in, tracking subscriptions, and browsing the in-gym shop.

### What is available today

#### Before joining

| Feature | Description |
|---------|-------------|
| **Gym directory** | Browse and search all gyms on the platform — no login required |
| **Gym detail page** | View contact info, weekly hours, and active promotions |
| **Discovery funnel** | Prospective members can explore before signing up at the front desk |

#### After joining

| Feature | Description |
|---------|-------------|
| **Member login** | Secure sign-in linked to one home gym |
| **Profile setup wizard** | Weight, height, age, and fitness goal on first use |
| **Single-device session** | Same security model as the owner app |

#### Main app — four tabs

**Home tab**

| Feature | Description |
|---------|-------------|
| Welcome header | Personal greeting, fitness goal, visit count, check-in status |
| Quick actions | Shortcuts to attendance, gym profile, and directory |
| Today’s stats | Attendance status and today’s operating hours |
| Subscription card | Plan name, dates, payment progress, renewal and due alerts |
| Active offers | Carousel of gym promotions |
| Recent attendance | Last five visits with link to full history |

**Attendance tab**

| Feature | Description |
|---------|-------------|
| **GPS check-in/out** | Automatic proximity check-in when within the gym’s location radius |
| **QR check-in/out** | Scan a gym QR code for instant check-in or check-out |
| **Visit history** | Full attendance history grouped by day |
| **Status dashboard** | Total visits, today’s status, currently checked-in indicator |

**Gyms tab**

| Feature | Description |
|---------|-------------|
| Directory | Browse all gyms with your home gym highlighted |
| Search | Find gyms by name, address, or phone |
| Gym detail | Hours, contact, promotions for any gym |

**Buy tab**

| Feature | Description |
|---------|-------------|
| Product catalog | Browse gym products in a two-column grid |
| Category filter | Filter by product category |
| Product details | Name, price, stock level, and image |

#### Profile

| Feature | Description |
|---------|-------------|
| Profile view | BMI, visit stats, subscription, personal and gym information |
| Edit profile | Phone, emergency contact, address, date of birth, weight, height, age, gender, fitness goal |
| Quick actions | Edit profile, diet plans, attendance history, view gym, sign out |
| **Diet plans** | Browse gym-assigned meal plans, filter by goal, view full daily meals and nutrition details |

### Why this matters for your business

- **Self-service check-in** — reduces queue time at the front desk; supports contactless entry
- **Member engagement** — promotions and subscription status keep members informed and motivated
- **Discovery and growth** — public gym directory helps attract new members before they walk in
- **Modern brand perception** — a dedicated member app signals a professional, tech-forward gym
- **AI-powered coaching (planned)** — 24/7 fitness assistant, progress insights, and adaptive workouts — see **AI & Gym Intelligence**

---

<div class="page-break"></div>

## AI & Gym Intelligence

*Practical intelligence today — a full AI vision for members and owners*

The platform includes a dedicated **AI layer** across both mobile apps. **Core analytics run on your gym’s own data** (fast, private, no external API). **Generative AI** (OpenAI) is used where it adds clear value — diet enhancement, chat, marketing copy — with quotas to control cost.

### Live today (Gym Owner App)

| Capability | What it does |
|------------|--------------|
| **AI diet generation** | One-tap meal plans from curated Indian templates (veg / eggetarian / non-veg); optional OpenAI enhancement with monthly quota; flows into the diet editor |
| **Gym intelligence report** | 6–24 month dashboard: joins, churn, store revenue, top products, check-in methods (QR, GPS, staff), loyal members, actionable insights |
| **Churn radar** | Scores at-risk members from attendance gaps, payment status, and subscription expiry — with reasons and suggested follow-up on the home screen |

### Planned — Gym Members

| Feature | What members get |
|---------|------------------|
| **Smart progress tracking** | AI analyzes weight changes, strength gains, and workout consistency — surfaces trends and milestones in one progress view |
| **AI chat fitness assistant** | 24/7 in-app coach. Ask anything: *“How many calories in 2 rotis and paneer?”* · *“What workout should I do today?”* · *“Why am I not losing weight?”* Answers grounded in profile, gym content, and Indian nutrition context |
| **Workout recommendation engine** | Missed sessions? AI suggests shorter alternatives. Feeling fatigued? Recommends recovery workouts instead of pushing through |
| **Injury prevention** | Analyzes workout history to detect overtraining, recommend rest days, and suggest stretching routines before problems escalate |

### Planned — Gym Owners

| Feature | What owners get |
|---------|-----------------|
| **AI member retention prediction** | Evolves today’s Churn Radar with richer signals — reduced attendance, missed payments, **lower app engagement** — to flag cancellations before they happen |
| **Automated fitness plan generation** | Trainer enters goal, age, and weight; AI instantly drafts **workout + diet plans** — dramatically reducing manual planning workload |
| **AI attendance analytics** | Peak hours, quiet hours, and equipment usage patterns with plain-language insights — e.g. *“6 PM–8 PM is overcrowded. Consider adding another trainer.”* |
| **Membership sales forecasting** | Predict monthly revenue, renewals, and churn rate so owners can plan staffing, offers, and marketing with confidence |
| **AI marketing assistant** | Generate Instagram posts, transformation captions, festival offers, and push notifications — e.g. *“Create a Diwali membership promotion.”* |
| **Member support bot** | Handles common questions 24/7 — gym timings, membership plans, trainer availability, diet queries — reducing front-desk and phone support load |

### How it fits together

```
┌──────────────────────────────┐     ┌──────────────────────────────┐
│     GYM MEMBER APP           │     │     GYM OWNER APP            │
│  Progress · Chat coach       │     │  Plans · Analytics · Marketing│
│  Workout recs · Injury guard │     │  Retention · Support bot     │
└──────────────┬───────────────┘     └──────────────┬───────────────┘
               │                                    │
               └────────────────┬───────────────────┘
                                ▼
         ┌──────────────────────────────────────────────────────┐
         │              SUPABASE + AI SERVICES                   │
         ├──────────────────────────────────────────────────────┤
         │  PostgreSQL intelligence (live)                     │
         │  • Gym analysis · Churn scoring · Attendance patterns │
         │  Edge Functions + OpenAI (generative, quota-based)  │
         │  • Diet/workout drafts · Chat · Marketing copy      │
         └──────────────────────────────────────────────────────┘
```

**Design principles:** Privacy-first analytics on gym data · Quota-controlled generative AI · Owners review all published plans · Members get answers tied to their gym’s real content and policies

---

<div class="page-break"></div>

## Multi-Language Support

*Reach every member and staff member in the language they prefer*

Gyms serve diverse communities. A trainer in Mumbai, a member in Chennai, and a front-desk assistant in Ahmedabad should all be able to use the same platform comfortably. **Multi-language support** is a planned capability across all three client applications.

### Current state

| Aspect | Today |
|--------|--------|
| **Interface language** | English across owner app, member app, and admin portal |
| **Numbers & currency** | Indian Rupee (₹) formatting and locale-aware dates via the `intl` package |
| **Gym content** | Owners create diet plans, exercises, and promotions in any language they choose (free text) |
| **Technical foundation** | Flutter (`flutter_localizations`) and React i18n libraries are standard fits for the existing stack |

### Planned capabilities

| Capability | Description |
|------------|-------------|
| **In-app language picker** | Members and owners choose their language in profile or settings; preference saved per account |
| **Full UI translation** | Navigation, buttons, labels, errors, and system messages translated — not just dates and currency |
| **Launch languages** | **English** and **Hindi** first, followed by regional languages based on demand (e.g. Marathi, Gujarati, Tamil, Telugu, Kannada, Bengali) |
| **Admin portal** | Super admin console available in English and Hindi for platform operations teams |
| **Consistent experience** | Same language available on iOS and Android from the shared Flutter codebase |
| **Device locale detection** | Suggest the best match on first launch based on phone language settings |

### Scope by application

| Application | What gets translated |
|-------------|----------------------|
| **Gym Owner App** | Dashboard, attendance, members, store, profile hub, AI analysis, diet/exercise editors, setup wizard |
| **Gym Member App** | Home, attendance, gyms directory, shop, profile, diet plans, onboarding |
| **Super Admin Portal** | Login, dashboard, data browser, gym provisioning flows |

**Note:** Gym-created content (custom diet meal names, exercise descriptions, promotion text) remains authored by the owner in their chosen language. Optional **AI-assisted translation** of published gym content is envisioned as a later enhancement.

### Why this matters for your business

- **Higher adoption** — staff and members who are more comfortable in Hindi or a regional language are more likely to use the app daily
- **Reduced support burden** — fewer “how do I…?” questions when the interface matches the user’s language
- **Broader market** — sell the platform to gyms across India and eventually other markets without rebuilding apps per region
- **Inclusive brand** — signals that the product is built for local fitness businesses, not only English-speaking metros

### Future enhancements (language roadmap)

- Per-gym default language (owner sets preferred language for new member accounts)
- AI translation of owner-published diet and exercise content for members
- Right-to-left (RTL) layout support for Arabic and similar languages — for international expansion
- Localized push notification templates (renewal reminders, payment alerts)

---

<div class="page-break"></div>

## Platform Strengths

What sets this platform apart for gym operators and platform owners:

| Strength | Benefit |
|----------|---------|
| **Complete three-role ecosystem** | Admin, owner, and member each have a purpose-built experience — no compromises |
| **Multi-tenant SaaS** | One platform serves unlimited gyms; economies of scale for you, low cost per gym |
| **Real-time operations** | Attendance, fees, renewals, and stock update live — no end-of-day reconciliation |
| **Mobile-first design** | Owners and members work from their phones; no desktop required for daily tasks |
| **Content ownership** | Each gym manages its own exercises, diet plans, and promotions |
| **Secure by design** | Data isolation per gym, single-device login, admin allowlist, encrypted cloud backend |
| **Scalable infrastructure** | Cloud-native backend handles growth from 1 gym to 1,000 without architecture changes |
| **Single codebase per app** | Flutter delivers iOS and Android from one project — faster updates, lower maintenance |
| **Rapid gym onboarding** | Super admin provisions a new gym in one step; owner completes setup on first login |
| **Built-in AI intelligence** | Live owner tools today; full member + owner AI vision on the roadmap — no separate BI, nutrition, or marketing tools required |
| **Localization-ready architecture** | Flutter and React stacks prepared for Hindi and regional language rollout |

---

<div class="page-break"></div>

## Built Today vs. Coming Soon

Transparency on what is live versus planned — so expectations are clear.

| Capability | Status |
|------------|--------|
| Super admin portal with full data access | **Built** |
| Gym owner provisioning (one-step) | **Built** |
| Owner setup wizard | **Built** |
| Member management and subscriptions | **Built** |
| Manual attendance (owner app) | **Built** |
| GPS and QR self check-in (member app) | **Built** |
| In-gym store — owner sales recording | **Built** |
| Product catalog browse (member app) | **Built** |
| Exercise library management (owner app) | **Built** |
| Diet plan management (owner app) | **Built** |
| AI diet plan generation (templates + OpenAI enhance) | **Built** |
| Gym intelligence / AI Analysis report | **Built** |
| Churn radar (at-risk member scoring) | **Built** |
| Member diet plan browsing (member app) | **Built** |
| Promotions and exclusive offers | **Built** |
| Public gym directory | **Built** |
| Single-device session security | **Built** |
| Product images (owner store + member browse) | **Built** |
| Member exercise library consumption | **Coming soon** |
| Member in-app purchase / checkout | **Coming soon** |
| Payment gateway (UPI, cards) | **Coming soon** |
| Advanced owner reports (CSV/PDF export) | **Coming soon** |
| Push notifications | **Coming soon** |
| Forgot-password self-service | **Coming soon** |
| Multi-language UI (English + Hindi, then regional) | **Planned** |
| **Member AI:** progress tracking, 24/7 fitness chat, workout recommendations, injury prevention | **Planned** |
| **Owner AI:** retention prediction, auto workout+diet plans, attendance insights, sales forecasting, marketing assistant, support bot | **Planned** |

---

<div class="page-break"></div>

## Future Roadmap

Planned capabilities beyond what is live today. **AI features for members and owners are detailed in the AI & Gym Intelligence section** — not repeated here.

### Member experience

- Surface owner-created **exercise library** in the member app, filtered by fitness goal
- Workout logging to feed **Smart Progress Tracking** (see AI section)

### Commerce and payments

- Member **in-app checkout** for gym products
- Payment gateway integration (UPI, cards, wallets)
- Online membership renewal and fee payment
- Order history for members and sales reports for owners

### Owner analytics & reporting

- Export gym intelligence reports to CSV or PDF for accounting
- Dues aging and payment collection funnel views
- Daily, weekly, and monthly automated summary emails

### Admin portal enhancements

- Visual charts and trend graphs on the platform dashboard
- CSV export for any data table
- Manage platform admin accounts from the UI (no SQL required)
- Audit log of admin actions

### Operations and staff

- **Push notifications** — renewal reminders, payment due alerts, new offers
- **Staff role permissions** — restrict sensitive actions (e.g. fee edits) to owners only
- Geo-radius configuration UI for member check-in zones
- Forgot-password and contact-admin flows on login screens

### Multi-language & accessibility

- **English + Hindi** as first translated locales across owner, member, and admin apps
- **Regional languages** — Marathi, Gujarati, Tamil, Telugu, Kannada, Bengali based on gym demand
- **Per-user language preference** stored in profile; auto-detect from device on first launch
- **Localized notifications** — renewal and payment alerts in the member’s chosen language
- Optional **AI translation** of owner-published diet and exercise content

### Growth and scale

- **White-label branding** — custom logo and colours per gym
- **Multi-location chains** — one owner account managing multiple gym branches
- Referral and loyalty programmes
- Integration with access control hardware (turnstiles, RFID)

---

<div class="page-break"></div>

## Technology Summary

A modern, maintainable technology stack chosen for speed, security, and cross-platform reach.

| Layer | Technology | Why |
|-------|------------|-----|
| **Owner & member apps** | Flutter (Dart) | Single codebase for iOS and Android; fast UI; large talent pool |
| **Admin web portal** | React + TypeScript | Fast, responsive web console; easy to deploy and update |
| **Backend** | Supabase | Managed PostgreSQL, authentication, file storage, and serverless functions |
| **Database** | PostgreSQL | Reliable, scalable relational database with row-level security |
| **Authentication** | Supabase Auth | Industry-standard email/password auth with session management |
| **File storage** | Supabase Storage | Exercise images, diet plan images, product photos |
| **Serverless functions** | Supabase Edge Functions | Gym owner provisioning, member accounts, AI diet generation |
| **Generative AI** | OpenAI (gpt-4o-mini) | Optional diet plan enhancement — quota-controlled per gym |
| **On-device intelligence** | PostgreSQL RPCs + Flutter | Gym analytics, churn scoring, offline diet templates |
| **Internationalization** | Flutter `intl` + ARB files (planned) | UI strings, dates, and currency; Hindi and regional languages on roadmap |
| **Security** | Row-Level Security (RLS) | Database-enforced data isolation — not just application-level checks |

**Deployment flexibility:** Mobile apps publish to Apple App Store and Google Play. The admin portal deploys to any static web host. The backend is fully managed in the cloud — no servers to maintain.

---

<div class="page-break"></div>

## Closing

The Gym Management Platform is a working product with a clear vision. The core operational loop — **onboard a gym, manage members, track attendance, handle fees, run a store, engage members, and act on AI-powered insights** — is built and functional across three coordinated applications.

The roadmap extends this foundation into **member and owner AI**, payments, **multi-language access**, and enterprise-scale features. Intelligence is not a bolt-on — it is woven into how gyms retain members, reduce trainer workload, and grow revenue.

---

*Document version: June 2026 · Gym Management Platform*
