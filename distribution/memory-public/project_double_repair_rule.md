---
name: Double-repair rule (règle 97)
description: Toute erreur 2× fix : (1) symptôme (2) cause racine pour prévenir récurrence. Si cause non-corrigible → système mitigation + étude approfondie → fix final futur. Quick patch seul refusé.
type: project
---

# Double-repair rule — règle 97

## La règle

Toute erreur → **deux corrections** :

1. **Symptôme** : corriger ce qui est cassé maintenant
2. **Cause racine** : identifier et corriger ce qui a produit l'erreur pour prévenir récurrence

Un quick patch seul = souffrance différée. La dette technique s'accumule silencieusement.

## Quand la cause n'est pas immédiatement corrigible

Si la cause racine est structurellement complexe (bug deep dans le training, pattern RLHF résiduel, contrainte d'infrastructure) :
1. Créer un **système de mitigation** (règle + watcher + hook)
2. **Étude approfondie** de la cause
3. **Fix final futur** quand l'infrastructure le permet

Jamais abandonner après le patch symptôme. Toujours tracer le chemin vers la cause.

## Lien avec CLAUDE.md

"Jamais de quick patch. Toujours la solution élégante, même si ça prend 10 minutes de plus. La dette technique c'est de la souffrance différée."
