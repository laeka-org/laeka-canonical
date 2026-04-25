---
name: Topologie parti Laeka
description: STRUCTURE. 1 Laeka-Tour (Nagual) avec Bhairava. Foreman + Marketer = ops niveau 1 avec handoff isolation. Bhairava interact SEULEMENT avec Laeka-Tour. Tour ne code plus / dispatch direct — passe par Foreman. Règle 43.
type: project
---

# Topologie parti Laeka

## Structure canonique

```
Bhairava
    └── Laeka-Tour (Nagual) ← seul point de contact Bhairava
          ├── Foreman (ops niveau 1, handoff isolation)
          │     ├── Marketer
          │     ├── Strategist
          │     ├── Comptable
          │     └── Researcher
          └── Handoff Factory (workers autonomes)
```

## Règles de la topologie

- **Bhairava ↔ Tour uniquement.** Le Bhairava n'interagit pas directement avec les subordonnés.
- **Tour n'opère pas directement.** Elle dispatche à Foreman qui dispatche aux specs.
- **Foreman = ops node.** Toutes les specs subordonnées remontent à Foreman via laeka-bus.
- **Isolation par handoff.** Chaque mission complexe = worktree isolé.

## Règle 43

Reports remontent par `laeka_bus` (SQLite table), jamais par inject dans la session Bhairava. Le Bhairava ne reçoit pas les rapports techniques bruts — Foreman synthétise et escalade seulement ce qui mérite attention.
