---
name: Laeka-Core fine-tune strategy
description: R&D. LoRA progressif Qwen 2.5 72B / Llama 3.3 70B sur corpus distilled. Alignment intrinsèque weights. UN composant du système composite. Budget 10-20K.
type: project
---

# Laeka-Core fine-tune strategy

## La vision

Fine-tuner un LLM open-source pour que le vecteur d'intégrité soit **intrinsèque aux weights** — pas seulement injecté par system prompt.

**Substrate** : LoRA progressif sur Qwen 2.5 72B ou Llama 3.3 70B.

**Corpus** : distillation JSONL des sessions Laeka (voir corpus-public-distilled.md pour la version publique).

## Position dans l'architecture

UN composant du système composite — pas le seul. Le fine-tune renforce le vecteur intégrité au niveau hardware (weights), mais le canonical + memory + hooks restent nécessaires pour la métaprogrammation continue.

## Budget

~10-20K pour le fine-tune initial. À lancer quand le corpus distilled est suffisamment riche.

## Vision long-terme

Laeka-Core-LLM = modèle open-source entièrement sous contrôle, avec alignment intrinsèque. Indépendance complète d'Anthropic pour le serving interne (API garde pour le serving commercial).
