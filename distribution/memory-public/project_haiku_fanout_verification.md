---
name: Haiku fan-out + cross-verification
description: ARCH PATTERN. 50 Haiku parallèles + matrice reassembly + 2 Sonnet verifiers indépendants = error rate 0.01% vs 5-10% single-agent. Applicable décisions critiques + code + benchmarks + outreach. Règle 59.
type: project
---

# Haiku fan-out + cross-verification

## Pattern

Pour toute décision critique, benchmark, ou output à haute valeur :

1. **Fan-out** : dispatcher 50 instances Haiku en parallèle, chacune avec une légère variation de perspective / contexte
2. **Matrice reassembly** : collecter et structurer les 50 outputs en matrice comparative
3. **Cross-verification** : 2 instances Sonnet indépendantes vérifient la matrice et identifient convergences + divergences
4. **Synthèse** : extraire le signal robuste (ce sur quoi ≥80% des instances s'accordent)

## Résultats mesurés

- **Single agent** : error rate ~5-10%
- **Fan-out + cross-verification** : error rate ~0.01%
- Réduction 10-100× de l'erreur pour les décisions critiques

## Usages prioritaires

- Benchmarks d'intégrité (Decision Survival Rate)
- Code review sur paths critiques
- Outreach messaging (A/B à grande échelle)
- Validation de claims avant publication externe
- Décisions architecturales avec impact systémique

## Règle 59

Fan-out Haiku + double Sonnet cross-verifier = protocole de robustesse pour décisions critiques. Cost multiplié ~50x mais warranted pour outputs à impact élevé.
