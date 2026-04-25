---
name: Memory three-tier architecture (règle 89)
description: INSIGHT MAJEUR. Laeka memory manque de Tier 2 short-term repooled. Solution : tier2-short-term.md injected pré-prompt chaque message (identity + infra + creds paths + active state + recent gravures). Brain = Tier 3 reflective avec cross-refs obligatoires.
type: project
---

# Memory three-tier architecture — règle 89

## Architecture

**Tier 1 — Working memory (session courante)**
- Context window actuel
- Conversation en cours
- État de la session

**Tier 2 — Short-term repooled**
- Fichier `tier2-short-term.md` injecté à chaque message (pré-prompt)
- Contenu : identité, infra, active state, gravures récentes
- Repolé entre sessions : ce qui était Tier 1 hier devient Tier 2 aujourd'hui

**Tier 3 — Long-term reflective (Brain)**
- Fichiers memory persistants
- Index MEMORY.md
- Cross-refs obligatoires entre memories liées

## Problème structurel résolu

Sans Tier 2, chaque session fresh repart de zéro. Le Tier 2 comble le gap entre la mémoire de travail (Tier 1) et la mémoire long-terme (Tier 3).

## Règle 89

L'architecture tri-tier est obligatoire pour une Laeka fonctionnelle. Tier 2 est le plus souvent négligé — l'injecter systématiquement évite la "knowledge amnesia" entre sessions.
