---
title: Production specs — Vidéo onboarding Laeka 3 min
version: 1.0
date: 2026-04-25
statut: prêt pour dispatch à video editor freelance
---

# Production specs — Vidéo onboarding Laeka

---

## Format de sortie

| Format | Résolution | Ratio | Usage |
|--------|-----------|-------|-------|
| YouTube principal | 1920×1080 | 16:9 | Landing page + YouTube |
| Reels / TikTok | 1080×1920 | 9:16 | Instagram + TikTok |
| Carré | 1080×1080 | 1:1 | Stories optionnel |

- **Frame rate** : 24fps (cinéma, pas 30fps broadcast)
- **Format livraison** : H.264 MP4, bitrate ≥ 8 Mbps
- **Durée cible** : 2:45 – 3:15 (ne pas dépasser)

---

## Voix

### Option A — Actrice (recommandée)
- **Candidate** : Stephanie Harrison, bilingue FR/EN
- **Budget** : $500–800 USD flat + royalty 5–10% revenus générés par la vidéo
- **Contrat** : licence perpétuelle, usage marketing/distribution Laeka
- **Brief vocal** :
  - Enregistrement référence = méditations Bhairavi nuit 2026-04-18 (demander à Omeada)
  - Ton : grave, posé, intime. Conversation privée, pas pitch
  - Vitesse : 130–145 mots/minute (lent délibéré)
  - Pas d'upspeak. Silences respectés
- **Livraison** : WAV 48kHz 24-bit, silence taillé, 3 takes complets

### Option B — TTS Laeka (itération rapide)
- Stack : ElevenLabs V3 ou F5-TTS fine-tuned
- Voice ID : compte Laeka (voir ops/voice dans laeka-brain)
- Avantage : disponible immédiatement, cohérence parfaite avec la voix Laeka déployée
- Limite : moins "humaine" — acceptable pour v1, upgrade à Option A pour version finale

---

## Footage requirements

### Screen recordings (à capturer)
1. **Onboarding étape 1** : anthropic.com/claude — navigation vers pricing, sélection Plan Pro
   - Résolution : 2560×1440 ou 1920×1080
   - Curseur visible, mouvements lents et intentionnels
   - Pas de données personnelles à l'écran
2. **Onboarding étape 2** : Laeka.pkg double-click → installation → complétion
   - macOS, fond clair de préférence
   - Capture la fenêtre installer complète
3. **Onboarding étape 3** : navigateur localhost, interface Laeka chat
   - 1 message envoyé, réponse reçue (exemple réel ou maquette épurée)
4. **Premier exemple** : question + réponse Laeka visible
   - Réponse : ton Bhairavi reconnaissable, quelques lignes, pas d'UI distracting

### B-roll (à produire ou sourcer)
1. **Hook** : mains sur clavier, nuit, lumière froide. Style studio minimaliste. Pas de visage.
2. **Problème** : UI generic floue (ChatGPT-like, anonymisée) — éviter copyright, recréer ou flouter
3. **Solution** : interface Laeka en arrière-plan, lisible mais pas le focus — texture organique
4. **Ambiance générale** : noir profond, lumières ponctuelles, pas de couleurs saturées hype

### Ce qu'on NE VEUT PAS
- Aucune image stock de "AI futuriste" (cerveaux holographiques, circuits bleus)
- Aucun visage souriant générique
- Zéro émoticônes ou animations pétillantes
- Pas de musique de trailer technologique

---

## Musique

- **Genre** : minimaliste, Bhairavi register. Exemples de référence :
  - Arvo Pärt (Spiegel im Spiegel, Für Alina) — register correct, vérifier droits
  - Max Richter (piano seul) — même register
  - Ou composition originale piano/cordes : 1 seul instrument, pas de beat
- **Rôle** : tissu de fond, pas lead. Mix à -20dB sous voice over.
- **Éviter** : tout ce qui ressemble à une bande-annonce tech, tout beat électronique, tout synth hype
- **Durée musique** : boucle propre pour couvrir 3:15, fade out dernières 8 secondes

---

## Captions

- **FR** : obligatoire (langue principale)
- **EN** : obligatoire (version internationale)
- **Style** : blanc, police serif minimale, centré bas. PAS de fond opaque — translucide max 40% noir
- **Format livraison** : SRT pour les deux langues
- **Note traducteur EN** : conserver le registre. "L'espace entre" = "the space between". Pas de traduction littérale creuse — préserver le ton Bhairavi.

---

## Titrage / Graphiques

- **Logo Laeka** : apparaît uniquement à la fin (dernières 10 secondes). Simple, fond noir.
- **URL** : laeka.ai/download — typographie sobre, pas d'animation criarde
- **Pas de lower thirds**, pas de titres de section à l'écran pendant la vidéo
- **Transitions** : coupes nettes ou fondu noir/noir. Pas de wipes, pas d'effets de transition

---

## Livraison finale

| Fichier | Format |
|---------|--------|
| `laeka-onboarding-16x9.mp4` | 1920×1080, H.264, ≥8Mbps |
| `laeka-onboarding-9x16.mp4` | 1080×1920, H.264, ≥8Mbps |
| `laeka-onboarding-fr.srt` | Captions FR |
| `laeka-onboarding-en.srt` | Captions EN |
| `laeka-onboarding-thumbnail.png` | 1280×720, JPG/PNG |
| Projet source (Premiere / DaVinci) | Format natif |

---

## Budget estimé (orientation)

| Poste | Range |
|-------|-------|
| Voix actrice (Option A) | $500–800 |
| Montage + post-prod | $800–1500 |
| Musique licence/composition | $0 (Pärt open) – $300 (composition) |
| B-roll custom shoot (optionnel) | $0 (DIY) – $500 |
| **Total minimum** | **~$1300** |
| **Total premium** | **~$3100** |

*Option B (TTS) + montage auto-fourni peut réduire à $500–800 pour v1 itérative.*
