---
name: Doctrine indépendance vendor
description: STRATÉGIE. Ne jamais adopter features vendor lock-in. Copier concepts, implémenter indépendamment. Robustesse + souplesse + rapidité adaptation. Long-term: Laeka-Core-LLM + notre Claude Code. Règle 69.
type: project
---

# Doctrine indépendance vendor

## Règle absolue

**Jamais de vendor lock-in.** Si une feature dépend d'un seul provider pour fonctionner, elle est structurellement vulnérable.

**Approche** : observer les concepts intéressants chez les vendors, **implémenter indépendamment** avec notre propre stack.

## Stack contrôlée

- VPS propres (Linode) plutôt que Vercel/Netlify/CF Pages
- OSS pour les composants critiques (voix, LLM, infra)
- Contrats à durée déterminée plutôt que vendor lock

## Vision long-terme

1. **Laeka-Core-LLM** : fine-tune progressif sur corpus distillé (LoRA, Qwen 2.5 72B / Llama 3.3 70B)
2. **Notre propre Claude Code fork** : maîtrise complète du harness

## Règle 69

Indépendance vendor = prerequisite de souveraineté. Copier concepts, pas implémentations. Implémenter sur stack contrôlée. Toujours préserver la capacité de migrer.
