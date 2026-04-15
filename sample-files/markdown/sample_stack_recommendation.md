# Fullstack Webapp Toolkit — Stack Recommendation

> **Synthesized:** 2026-04-12
> **Decision Framework:** Security (highest) > Quality/UX (very high) > Integration (high) > Simplicity (high) > Cost (medium)
> **Status:** Ready for review and approval

---

## Table of Contents

1. [Recommended Stack](#1-recommended-stack)
2. [Security Tooling Stack](#2-security-tooling-stack)
3. [Compliance Roadmap](#3-compliance-roadmap)
4. [Cost Summary](#4-cost-summary)
5. [Open Questions & Risks](#5-open-questions--risks)

---

## 1. Recommended Stack

### Core Platform

| Layer | Recommendation | Version | Runner-Up | Why | Cost | Risk |
|-------|---------------|---------|-----------|-----|------|------|
| **Hosting** | Vercel (Pro) | — | Cloudflare Workers | WAF on all plans (OWASP rulesets), native framework support (zero adapters), SOC 2 Type II certified | $20/mo base | Alternative cheaper at scale; WAF limited to 40 rules on Pro |
| **Database** | Supabase (Pro) | — | Neon (DB-only) | All-in-one (Postgres + Auth + Storage + Realtime + Edge Functions), database-level RLS, SOC 2 Type II, full local dev via Docker | $25/mo base | Branching still in alpha; Edge Function 2s CPU limit |
| **Auth** | Clerk | — | Self-hosted auth | Covers passkeys, MFA/TOTP, RBAC, multi-tenant orgs, GDPR deletion, rate limiting, SOC 2 Type 2 | Free to 10K MAU | Vendor lock-in at scale. Mitigate with abstraction layer |
| **Frontend** | Next.js 15 (App Router) | 15.2.4 | Next.js 16 (when stable) | Production-stable, React 19, RSC mature for SaaS, best AI tooling integration | Free | React ecosystem dependency |
| **UI Components** | shadcn/ui | Latest | Mantine | Copy-paste model (zero lock-in), 111K+ stars, polished aesthetic | Free | Must keep up with releases |
| **CSS** | Tailwind CSS v4 | 4.2.0 | — | Rust engine (2-5x faster), CSS-native design tokens, OKLCH color space | Free | Safari 16.4+ floor |
| **ORM** | Drizzle | Latest | Prisma | 130x smaller bundle (~7.4KB vs ~1.6MB), native edge/serverless, first-class RLS support | Free | Younger ecosystem |

### Supporting Libraries

| Purpose | Library | Why |
|---------|---------|-----|
| **Animation** | Motion | Industry standard for React, ~32KB. CSS transitions for simple states. |
| **Icons** | Lucide | Default icon set, 29M+ weekly downloads, tree-shakeable |
| **Charts** | Recharts v3 + Tremor | Dashboard components + chart library |
| **Forms** | React Hook Form + Zod | Single schema drives client + server validation + TypeScript types |
| **Server State** | TanStack Query | ~5M downloads/week, caching, refetching, loading states |
| **Client State** | Zustand | ~3KB, minimal API, auth/UI preference stores |
| **Data Tables** | TanStack Table | Virtual scrolling, faceted filters, URL-persisted state |
| **Notifications** | Sonner | Integrated toast library |
| **Command Palette** | cmdk | Integrated command menu |
| **Validation** | Zod | Runtime + compile-time validation, server action integration |

### Design System

- **Token Architecture:** 3-layer (base > semantic > component) using CSS custom properties
- **Color Space:** OKLCH for perceptually uniform colors; generate shade scales from single hue
- **Theming:** CSS variables with semantic naming. Base neutral theme ships by default; projects override via theme attributes
- **Design Token Format:** W3C DTCG 2025.10 specification, transformed via Style Dictionary v4

---

## 2. Security Tooling Stack

### 7-Layer Security Architecture

```text
Layer 7: PERIODIC REVIEW
  Quarterly AI pentesting, dependency review, compliance review

Layer 6: POST-DEPLOY
  Header checks, log drains, audit logging pipeline

Layer 5: RUNTIME
  Edge DDoS protection, WAF (OWASP rules), CSP/HSTS headers,
  Rate limiting + bot detection, Row-level security, Input validation

Layer 4: SCHEDULED
  Weekly DAST scans, full dependency scans, automated dependency PRs

Layer 3: CI PIPELINE
  SAST (CodeQL, Semgrep), SCA (Trivy), supply chain (Socket.dev),
  Secret scanning, code review, post-preview DAST

Layer 2: PRE-COMMIT
  Secret scanning (98.6% recall), security linting, quick SAST on staged files

Layer 1: DEV TIME
  Real-time SAST, dependency scanning, security linting,
  Deny rules for secrets and destructive commands
```

### Security Tools Inventory

| Tool | Layer | Cost | Purpose |
|------|-------|------|---------|
| SAST Scanner A | 1 (Dev) | Existing | Real-time static analysis during development |
| SAST Scanner B | 1, 2, 3 | Free | Real-time, pre-commit, cross-file CI analysis |
| Dependency Scanner | 1, 3, 4 | Free | SCA scanning, container scanning |
| Security Linting | 1, 2 | Free | Code pattern checks |
| Secret Scanner (pre-commit) | 2 | Free | Secret scanning (98.6% recall) |
| GitHub SAST | 3 | Free | SAST for JS/TS |
| Supply Chain Scanner | 3 | Free | Supply chain attack detection |
| Secret Scanner (CI) | 3 | Free | Verified secret scanning with live API checks |
| AI Code Review | 3 | Existing | AI code review with security focus |
| DAST Scanner A | 3 | Free | CI DAST scanner against preview URLs |
| DAST Scanner B | 3 | Free | Template-based DAST against preview URLs |
| Full DAST | 4 | Free | Full DAST scan (weekly) |
| Dependency Updater | 4 | Free | Automated dependency updates with security config |
| WAF | 5 | Included | OWASP managed rulesets, bot filter, IP/geo blocking |
| Security Headers | 5 | Free | CSP, HSTS, and other security headers |
| Rate Limiter | 5 | Free | Rate limiting, bot detection, brute force protection |
| Row-Level Security | 5 | Included | Database row-level security with auth helpers |
| Input Validation | 5 | Free | Runtime input validation at all API boundaries |
| Header Checker | 6 | Free | Deployed security header verification |

---

## 3. Compliance Roadmap

### Standards Priority Order

| Priority | Standard | When | Why | Automated? | Cost |
|----------|----------|------|-----|------------|------|
| **1** | OWASP ASVS Level 2 | Day 1 | Free, practical foundation, most requirements automatable | ~70% | $0 |
| **2** | NIST CSF 2.0 | Day 1 | Free organizing framework; maps to workflow (Identify > Protect > Detect > Respond > Recover) | Framework only | $0 |
| **3** | GDPR | Day 1 (if applicable) | Retrofitting is expensive; must be built into architecture from the start | ~50% | $0 |
| **4** | PCI DSS SAQ-A | Day 1 (if payments) | Use hosted checkout (redirect) to stay SAQ-A (~30 requirements) | ~60% | $0 |
| **5** | SOC 2 Type II | When enterprise demands | First-year cost $20-60K; build controls from day 1 so audit is a formality | ~60-80% evidence | $13-22K/yr |
| **6** | CCPA/CPRA | After GDPR | Mostly covered by GDPR compliance; region-specific additions | Covered by GDPR | $0 |

### Day-One Architecture Requirements

These MUST be built into the app from the start — they cannot be retrofitted easily:

1. **Data inventory and flow mapping** — document what data is collected, where it's stored, who processes it
2. **Consent management** — granular options with recorded timestamps
3. **User data endpoints** — delete, export, access, rectification with 30-day processing queue
4. **Cascade deletion** — delete across all stores (DB, storage, logs, third-party services)
5. **Minimum data collection** — only collect what's needed
6. **Automated retention/deletion** — data lifecycle policies
7. **Encryption** — at rest (AES-256) and in transit (TLS)
8. **MFA for admin** — required for admin accounts
9. **Audit logging** — log all data access
10. **Breach notification** — 72-hour authority notification process

---

## 4. Cost Summary

### Monthly Cost at Different Scales

| Category | Tool | Free / <100 users | 1K users | 10K users | 100K users |
|----------|------|--------------------|----------|-----------|------------|
| **Hosting** | Vercel Pro | $20 | $20 | $25-40 | $60-150 |
| **Database** | Supabase Pro | $25 | $25 | $25-50 | $35-75 |
| **Auth** | Clerk | $0 | $0 | $25 | $1,825 |
| **Monitoring** | Stack (recommended) | $0 | $10 | $30 | $115-145 |
| **Security** | All free-tier tools | $0 | $0 | $0 | $0 |
| **Prototyping** | V0 | $0-20 | $0-20 | $0-20 | $0-20 |
| **TOTAL** | | **$45-65** | **$55-75** | **$105-165** | **$2,035-2,215** |

> **Cost cliff:** Auth costs jump at 10K+ MAU. Plan migration to self-hosted auth when cost exceeds value. The abstraction layer in `/lib/auth/` makes this a code change, not an architecture change.

---

## 5. Open Questions & Risks

### Decisions Needed Before Implementation

1. **Auth cost threshold** — At what MAU count do we migrate from managed auth to self-hosted? Recommended: begin evaluation at 25K MAU, hard deadline at 50K MAU
2. **SOC 2 timing** — Do we need SOC 2 before first enterprise deal, or can we use a compliance platform bridge?
3. **Multi-region** — Is data residency required from day 1, or can we start single-region?

### Top Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Auth vendor lock-in at scale | High | `/lib/auth/` abstraction layer; evaluate alternatives quarterly |
| Edge Function CPU limits | Medium | Profile hot paths; offload to background jobs if needed |
| Database branching instability | Low | Use separate staging database; don't depend on branching for CI |
| Framework major version churn | Medium | Pin versions; evaluate upgrades quarterly, not immediately |
| Security tool sprawl | Low | Consolidate tools annually; prefer fewer tools with broader coverage |
