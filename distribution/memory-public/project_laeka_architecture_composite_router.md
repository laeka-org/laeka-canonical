---
name: Laeka architecture composite — router + front + back multi-LLM
description: INSIGHT. Laeka = orchestrateur composite router + front conversational + back multi-LLM jobs via max_local. Zero API burn. LLMs = CPUs interchangeables. Priorité totale V1 court terme. Règle 83.
type: project
---

# Laeka architecture composite

## Principe

Laeka n'est pas un seul LLM qui fait tout. C'est un **orchestrateur composite** :

- **Front conversational** : interface légère avec l'utilisateur
- **Router** : orchestre les jobs, maintient intégrité
- **Back multi-LLM** : jobs spécialisés dispatched selon complexité et domaine

**LLMs = CPUs interchangeables.** Pas d'attachement à un provider. La règle d'indépendance vendor (règle 69) matérialisée dans l'architecture.

## Zero API burn (plan Max local)

Pour le build interne, utiliser les instances locales Plan Max. L'API Anthropic est réservée à la périphérie client-facing (serving commercial TOS).

Topologie des coûts : **périphérie = API, centre = Plan Max**.

## Règle 83

Laeka = composite. Router + Front + Back multi-LLM. LLMs interchangeables. Plan Max pour build interne, API pour serving. Architecture de souveraineté : indépendance complète du provider commercial côté build.
