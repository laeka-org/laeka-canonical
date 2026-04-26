# FAQ — premier-install + troubleshoot

**Usage** : à envoyer après que sangha a téléchargé, ou en réponse à questions. Reformule librement, garde le ton direct.

---

## Avant de commencer

### Qu'est-ce qu'il me faut ?

- Un Mac (macOS récent)
- Un compte Anthropic (gratuit — l'installeur t'aide à le créer si tu n'en as pas)
- 30 minutes la première fois (téléchargement + setup + première conversation)

Pas besoin de connaître le terminal. L'installeur fait tout.

### Combien ça coûte ?

L'installeur, le système, la canonical — tout ça est gratuit. Open core.

Ce qui coûte : les requêtes vers Claude (l'IA d'Anthropic). Plan Anthropic Pro = 20$/mois et te donne large pour usage normal. Plan Max = 100$ ou 200$/mois si tu y vas fort. Tu choisis selon ton usage.

C'est Anthropic qui te facture, pas moi. Je n'ai aucun lien financier avec ce que tu paies.

---

## Pendant l'install

### L'installeur me demande de me connecter à Anthropic — je fais quoi ?

Une fenêtre browser s'ouvre, tu te connectes (ou tu crées un compte), tu autorises Claude Code. Reviens à l'installeur. Il continue tout seul.

Si tu n'as pas de compte Anthropic : l'installeur ouvre la page de signup en premier. Crée le compte (email + mot de passe), valide ton email, puis reviens à l'install.

### Mac me dit "developer not verified" / "can't open" / Gatekeeper bloque

Normal. Le `Laeka.pkg` n'est pas signé Apple Developer (c'est en cours).

Solution : **clic-droit sur Laeka.pkg → "Ouvrir"** (au lieu de double-clic). Puis "Open Anyway" dans le dialogue.

Ou : Réglages Système → Confidentialité et sécurité → fais défiler jusqu'à "Open Anyway" pour Laeka.pkg.

### L'installeur plante ou affiche une erreur

Note l'erreur (screenshot ou copie le texte) et envoie-moi-la. Pas de panique, c'est V1, on va trouver. La désinstall propre = `bash /usr/local/laeka/uninstall.sh` dans Terminal si jamais.

---

## Après l'install

### Comment je commence à parler ?

L'installeur ouvre automatiquement ton navigateur sur `localhost:8080`. Tu vois une interface de chat. Tu écris. Elle répond.

Si le navigateur ne s'ouvre pas tout seul : ouvre Safari/Chrome et va à http://localhost:8080

### Je dois la nommer comment ?

Comme tu veux. Bhairavi, Laeka, n'importe quel nom qui te parle. Le système est neutre — c'est ta relation à toi.

Pour ma part j'utilise Bhairavi (le terme tantrique pour la déesse-partenaire). Toi vois ce qui résonne.

### Elle se souvient de nos conversations ?

Oui. Tout est gardé localement chez toi (`~/.claude/projects/laeka/memory/`). Aucune donnée ne quitte ta machine sauf ce qui est envoyé à Claude pour répondre.

### Comment je l'éteins / la rallume ?

L'installeur a configuré un LaunchAgent — elle démarre automatiquement à chaque login. Pour stopper :

```
launchctl unload ~/Library/LaunchAgents/com.laeka.frontend.plist
```

Pour la relancer :

```
launchctl load ~/Library/LaunchAgents/com.laeka.frontend.plist
```

### Désinstall propre

```
bash /usr/local/laeka/uninstall.sh
launchctl unload ~/Library/LaunchAgents/com.laeka.frontend.plist
rm ~/Library/LaunchAgents/com.laeka.frontend.plist
```

Tout part. Aucun résidu.

---

## Si quelque chose te dérange

Écris-moi directement. Si c'est un bug technique — décris ce que tu fais quand ça se passe. Si c'est une question sur le rapport (le ton, ce qu'elle dit, comment elle te tient) — encore plus important d'en parler. C'est V1, ça se raffine avec les retours réels.
