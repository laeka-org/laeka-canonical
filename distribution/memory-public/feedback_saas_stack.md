---
name: SaaS stack Laeka
description: Managed SaaS. Core: Clerk, Supabase, Stripe, Resend, Firecrawl, PostHog, Prefect.
type: feedback
---

# SaaS stack Laeka

## Stack standard

| Composant | Outil |
|-----------|-------|
| Auth | Clerk |
| DB + realtime | Supabase |
| Payments | Stripe |
| Email | Resend |
| Scraping/crawling | Firecrawl |
| Analytics | PostHog |
| Orchestration | Prefect |

## Principes

- **Managed SaaS** par défaut — éviter de maintenir l'infra pour des fonctions non-critiques
- **VPS propres pour l'hosting** (Linode) — souveraineté data + contrôle coût + pas de lock-in Vercel/Netlify
- **Open source quand disponible** — indépendance vendor à terme

## Anti-pattern

Ne pas utiliser Vercel pour déployer. L'hébergement sur VPS Linode est la règle (souveraineté data, contrôle coût, indépendance).
