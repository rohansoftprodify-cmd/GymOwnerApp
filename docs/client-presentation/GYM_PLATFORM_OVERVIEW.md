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

**Current status:** Core operations are live and working — gym onboarding, member management, attendance (manual and self-service), subscriptions, in-gym store, diet and exercise content management, and platform-wide administration. Additional features are identified and planned for the next phases.

**The opportunity:** Replace fragmented spreadsheets, paper registers, and disconnected tools with a single, mobile-first platform that grows with the business — from a single gym to a multi-location chain.

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
         │  • Serverless functions (provisioning)   │
         │  • Real-time updates & security (RLS)    │
         └──────────────────────────────────────────┘
```

**Key design principles:**

- **Multi-tenant by design** — hundreds of gyms on one platform, each with private data
- **Role-based access** — admins, owners, staff, and members each see only what they need
- **Mobile-first** — owners and members operate from their phones; admins use a web console
- **Secure sessions** — single-device login prevents account sharing and unauthorized access

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

### Why this matters for your business

- **Run the gym from one app** — no switching between registers, spreadsheets, and messaging apps
- **Less front-desk friction** — quick check-in/out and instant fee visibility
- **Content ready for members** — owners build exercise and diet libraries that can be surfaced to members in future phases
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
| Quick actions | Edit profile, attendance history, view gym, sign out |

### Why this matters for your business

- **Self-service check-in** — reduces queue time at the front desk; supports contactless entry
- **Member engagement** — promotions and subscription status keep members informed and motivated
- **Discovery and growth** — public gym directory helps attract new members before they walk in
- **Modern brand perception** — a dedicated member app signals a professional, tech-forward gym

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
| Promotions and exclusive offers | **Built** |
| Public gym directory | **Built** |
| Single-device session security | **Built** |
| Member diet and exercise consumption | **Coming soon** |
| Member in-app purchase / checkout | **Coming soon** |
| Payment gateway (UPI, cards) | **Coming soon** |
| Owner analytics and reports dashboard | **Coming soon** |
| Push notifications | **Coming soon** |
| Product image upload (owner app) | **Coming soon** |
| Forgot-password self-service | **Coming soon** |

---

<div class="page-break"></div>

## Future Roadmap

The following ideas are planned for upcoming phases. They build on the foundation already in place.

### Member experience

- Surface owner-created **diet plans** and **exercise library** in the member app, filtered by fitness goal
- Workout logging and progress tracking over time
- Personalised recommendations based on profile and gym content

### Commerce and payments

- Member **in-app checkout** for gym products
- Payment gateway integration (UPI, cards, wallets)
- Online membership renewal and fee payment
- Order history for members and sales reports for owners

### Owner analytics

- Dedicated **reports dashboard** — attendance trends, revenue, dues aging, member growth
- Export to CSV or PDF for accounting
- Daily, weekly, and monthly summary views

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
| **Serverless functions** | Supabase Edge Functions | Secure provisioning of gym owners and member accounts |
| **Security** | Row-Level Security (RLS) | Database-enforced data isolation — not just application-level checks |

**Deployment flexibility:** Mobile apps publish to Apple App Store and Google Play. The admin portal deploys to any static web host. The backend is fully managed in the cloud — no servers to maintain.

---

<div class="page-break"></div>

## Closing

The Gym Management Platform is a working product with a clear vision. The core operational loop — **onboard a gym, manage members, track attendance, handle fees, run a store, and engage members** — is built and functional across three coordinated applications.

The roadmap above extends this foundation into payments, analytics, richer member experiences, and enterprise-scale features. We are cooking something substantial — and we are ready to show it.

---

*Document version: June 2026 · Gym Management Platform*
