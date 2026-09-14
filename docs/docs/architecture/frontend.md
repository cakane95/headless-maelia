# Architecture frontend

!!! abstract "Objet de ce document"
    Décrire la structure du SPA React, les règles qui la tiennent, et les
    conventions d'implémentation. Il s'adresse à toute personne qui écrit du code
    dans `headless-maelia-front/`.

    Le front reflète le découpage du backend : **deux domaines, deux espaces, deux
    layouts.**

---

## 1. Deux espaces

| | **Administration** (`/admin`) | **Simulation** (`/simulation`) |
|---|---|---|
| Utilisateur | administrateur de la plateforme | modélisateur, observateur |
| Objet | *décrire* un modèle | *exploiter* un modèle sur un territoire |
| Rubriques | tableau de bord, modèles, banc d'essai, catalogues (entrées, paramètres, sorties) | projets, données d'entrée, scénarios, simulations, résultats |
| Layout | `AdminLayout` | `SimulationLayout` |

Chaque espace a **son propre layout avec sa barre latérale**. Seul le bandeau
supérieur est commun (`AppShell`), et il ne porte qu'une chose : la bascule entre
les deux espaces.

Ce n'est pas une préférence esthétique : les deux espaces ont des utilisateurs,
des rythmes et des vocabulaires différents. Les mélanger dans une navigation
unique obligerait chacun à ignorer la moitié des entrées.

---

## 2. Pile technique

| Rôle | Choix |
|---|---|
| Bibliothèque | React 19 |
| Build & dev | Vite 8 (HMR, `usePolling` — les bind-mounts Docker ne propagent pas inotify) |
| Routage | `react-router` 7 |
| Graphiques | `recharts` |
| Styles | CSS natif + variables — pas de framework |
| Paquets | `pnpm` |

**Pas de bibliothèque d'état global.** L'essentiel de l'état de cette application
est de l'**état serveur** (des runs, des datasets, des catalogues) : il se
rafraîchit, il ne se « gère » pas dans un store. Le reste est local à un écran.
Introduire Redux ou Zustand aujourd'hui ajouterait de la cérémonie sans problème
à résoudre. Si un besoin réel de cache partagé apparaît (invalidations croisées,
requêtes dupliquées), la réponse sera TanStack Query, pas un store maison.

---

## 3. Arborescence

```
headless-maelia-front/src/
├── main.jsx                  # point d'entrée
├── App.jsx                   # arbre de routes — la carte du site
├── index.css                 # n'assemble que les modules de styles/
├── api/                      # SEUL accès réseau — un module par domaine
│   ├── client.js             # fetch, upload, URLs de base
│   ├── admin.js  catalog.js  health.js  realtime.js
│   ├── simulation.js         # projets, datasets, scénarios, runs
│   └── result.js             # sorties : profil, séries, comparaison
├── layouts/
│   ├── AppShell.jsx          # bandeau + bascule d'espace + thème
│   ├── AdminLayout.jsx       # barre latérale Administration
│   ├── SimulationShell.jsx   # liste des projets — sans barre latérale
│   └── ProjectLayout.jsx     # barre latérale d'UN projet
├── pages/
│   ├── RunDetail.jsx         # suivi d'un run — partagé par les deux espaces
│   ├── admin/                # un fichier par rubrique
│   └── simulation/           # projets, données, scénarios, runs, résultats
├── components/               # composants réutilisés par ≥ 2 pages
├── hooks/                    # useAsync, useDraft, useRunStream, useChart…
├── styles/                   # tokens · base · layout · components
│                             # tables · feedback · charts
└── utils/                    # formatage, libellés de statut, séries
```

**Règles de placement.**

| Ce que c'est | Où |
|---|---|
| Un écran atteignable par une URL | `pages/<espace>/` |
| Un composant utilisé par **au moins deux** pages | `components/` |
| Un composant utilisé par une seule page | dans le fichier de la page |
| De la logique réutilisable avec état | `hooks/` |
| Un appel réseau | `api/` — **et nulle part ailleurs** |

Un composant n'est promu dans `components/` qu'au **deuxième** usage. Anticiper la
réutilisation produit des composants sur-paramétrés qui ne servent qu'une fois.

---

## 4. La règle centrale : le réseau est isolé

**Aucun `fetch` ni `new WebSocket` en dehors de `api.js`.**

```javascript
// api.js
const API = import.meta.env.VITE_API_URL ?? "http://localhost:8000";

async function request(path, options = {}) {
  const response = await fetch(`${API}${path}`, {
    headers: { "Content-Type": "application/json" },
    ...options,
  });
  if (!response.ok) {
    const body = await response.json().catch(() => ({}));
    throw new Error(body.detail ? JSON.stringify(body.detail) : `HTTP ${response.status}`);
  }
  return response.json();
}

export const api = {
  models: () => request("/api/v1/admin/models"),
  runs: () => request("/api/v1/admin/runs"),
  launch: (payload) => request("/api/v1/admin/runs", { method: "POST", body: JSON.stringify(payload) }),
};
```

Ce que cette règle achète :

- l'URL de base et les en-têtes sont définis **une fois** ;
- la gestion d'erreur est **uniforme** — un statut non-2xx lève toujours ;
- changer un chemin d'API touche **un fichier** ;
- lire `api.js` donne la surface complète du contrat back/front.

Les composants appellent `api.<méthode>()` et ne connaissent ni URL, ni verbe HTTP,
ni format d'erreur.

---

## 5. Chargement des données

### Le triplet obligatoire

Tout écran qui charge des données gère **trois** états. En oublier un produit un
écran blanc que l'utilisateur ne sait pas interpréter.

```jsx
const [data, setData] = useState(null);
const [error, setError] = useState(null);

useEffect(() => {
  api.models().then(setData).catch((e) => setError(e.message));
}, []);

if (error) return <p className="error">{error}</p>;
if (!data) return <p className="muted">Chargement…</p>;
return <Liste items={data} />;
```

### Rafraîchissement adaptatif

Ne jamais interroger le serveur à cadence fixe « au cas où ». On interroge
rapidement **tant que quelque chose bouge**, lentement sinon :

```jsx
useEffect(() => {
  let timer;
  const refresh = () =>
    api.runs().then((list) => {
      setRuns(list);
      const active = list.some((r) => r.status === "EN_COURS" || r.status === "EN_ATTENTE");
      timer = setTimeout(refresh, active ? 3000 : 15000);
    });
  refresh();
  return () => clearTimeout(timer);   // ← nettoyage obligatoire
}, []);
```

!!! warning "Toujours nettoyer"
    Tout `useEffect` qui ouvre quelque chose — minuteur, WebSocket, abonnement —
    **doit** renvoyer une fonction de nettoyage. Sans elle, quitter l'écran laisse
    des requêtes en vol qui écrivent dans un composant démonté.

### Temps réel

Le suivi d'un run passe par WebSocket, pas par du polling : le worker publie sur
Redis, l'API relaie. Plusieurs onglets peuvent suivre le même run, et un
rechargement n'interrompt pas la simulation.

```jsx
useEffect(() => {
  let closed = false;

  api.run(runId).then((data) => { if (!closed) setRun(data); });

  const unsubscribe = subscribeRun(runId, (event) => {
    if (event.kind === "log") setLogs((c) => [...c.slice(-400), event.line]);
    else setRun((c) => ({ ...c, ...event.run }));
  });

  return () => { closed = true; unsubscribe(); };
}, [runId]);
```

Deux points à retenir : l'**instantané REST d'abord** (un client qui arrive en
cours de route ne doit pas voir un écran vide en attendant le prochain
événement), et les **journaux bornés** (`slice(-400)`) — un run long produit des
milliers de lignes.

---

## 6. Composants

### Règles

1. **Fonctions, hooks, pas de classes.**
2. **Un composant = une responsabilité.** Au-delà de ~150 lignes, découper.
3. **Pas de logique métier.** Le front affiche et transmet ; il ne décide pas ce
   qu'est un scénario valide. Cette règle vit dans le catalogue, côté backend.
4. **Props explicites.** Pas de `{...props}` opaque sur un composant métier.
5. **Clés de liste stables.** L'identifiant du domaine, jamais l'index.

### Formulaires

État local, soumission désactivée pendant l'envoi, erreur affichée au même
endroit que le formulaire :

```jsx
async function submit(event) {
  event.preventDefault();
  setBusy(true);
  setError(null);
  try {
    const run = await api.launch({ model_id: modelId, parameters });
    navigate(`/admin/banc-essai/${run.id}`);
  } catch (e) {
    setError(e.message);
  } finally {
    setBusy(false);   // ← toujours, même en cas d'échec
  }
}
```

---

## 6 bis. Le module de graphiques

Les sorties d'une simulation ne sont pas des indicateurs nommés : ce sont des
tableaux larges, différents d'un fichier à l'autre, et dont les colonnes changent
avec le modèle. **Aucun graphique n'est donc écrit en dur.**

```
ProjectResults            écran : runs cochés → fichier choisi
├── FinishedRuns          cases à cocher = comparaison de scénarios
├── OutputFiles           fichiers du run, avec leur nature
├── OutputExplorer        assemble les quatre pièces ci-dessous
│   ├── ChartSuggestions  lectures proposées par le backend
│   ├── ChartBuilder      axe · agrégat · répartition · mesures
│   ├── ChartView         tracé recharts, couleurs du thème
│   └── OutputPreview     lignes brutes, repliées
└── OutputText            fichiers non tabulaires
```

**Ce qui vient du backend.** Le profil des colonnes (rôle, unité, valeurs), les
lectures proposées, et les points agrégés. Le front ne calcule ni moyenne ni
somme : il ne saurait pas le faire sur 435 lignes sans les télécharger toutes.

**Ce qui appartient au front.** Le type de tracé, la palette et la superposition
des runs — `utils/chart.js` fusionne les séries de plusieurs runs en préfixant
chaque clé par le libellé du run.

!!! tip "Couleurs et thème"
    Recharts pose ses couleurs en **attributs SVG**, où `var(--chart-1)` ne serait
    pas résolu. `useChartPalette` lit donc les jetons calculés sur `<html>` et
    observe `data-theme` : la bascule clair/sombre repeint les courbes sans
    remonter d'état.

!!! warning "Chargement à la demande"
    La bibliothèque de graphiques pèse ~400 ko. L'écran de résultats est donc
    chargé en `lazy()` : le reste de l'application n'en paie pas le prix.

---

## 7. Styles

CSS natif, variables déclarées sur `:root`, classes sémantiques.

```css
:root {
  --bg: #f6f7f9;
  --surface: #ffffff;
  --border: #e3e6ea;
  --text: #1c2024;
  --muted: #697280;
  --accent: #1f6f4a;
  --danger: #b4232c;
}
```

**Conventions.** Aucune couleur en dur dans un composant : toujours une variable ·
classes sémantiques (`.card`, `.badge.TERMINE`) plutôt qu'utilitaires · styles
partagés dans `index.css`, styles vraiment locaux en `style={{}}` · les statuts
métier deviennent des classes (`.badge.EN_COURS`), ce qui rend la palette de
statuts modifiable en un point.

---

## 8. Routage

`App.jsx` est la **carte du site** : on doit y lire l'application entière.

```jsx
<Route element={<AppShell />}>
  <Route index element={<Navigate to="/admin" replace />} />

  <Route path="admin" element={<AdminLayout />}>
    <Route index element={<Dashboard />} />
    <Route path="banc-essai" element={<TestBench />} />
    <Route path="banc-essai/:runId" element={<RunDetail />} />
  </Route>

  <Route path="simulation" element={<SimulationLayout />}>
    ...
  </Route>
</Route>
```

**Conventions.** Chemins en français, en minuscules, avec tirets
(`/admin/banc-essai`) · l'état d'un écran adressable vit dans l'URL, pas dans un
state (un run consultable doit avoir son lien partageable) · une rubrique prévue
mais non implémentée reçoit un `Placeholder` décrivant ce qui viendra, jamais une
route absente ou un lien mort.

---

## 9. Anti-patterns

!!! danger "À ne pas faire"
    - **`fetch` dans un composant.** Tout passe par `api.js`.
    - **Un `useEffect` sans nettoyage** quand il ouvre un minuteur ou un socket.
    - **Une règle métier dans le front.** La validation fait autorité côté backend ;
      la dupliquer, c'est garantir une divergence.
    - **Un composant partagé créé au premier usage.** On attend le deuxième.
    - **Une couleur en dur.** Toujours une variable CSS.
    - **Un `index` de tableau comme clé** de liste.
    - **Un store global** pour de l'état serveur.
    - **Des journaux non bornés** dans un état React.

---

## 10. Checklist de revue

- [ ] Aucun `fetch` / `WebSocket` hors de `api.js`.
- [ ] Les trois états (chargement, erreur, données) sont gérés.
- [ ] Chaque `useEffect` qui ouvre quelque chose nettoie.
- [ ] Aucune règle métier n'a été dupliquée depuis le backend.
- [ ] Les clés de liste sont des identifiants stables.
- [ ] Aucune couleur ni espacement en dur là où une variable existe.
- [ ] Un écran adressable est atteignable par son URL.
- [ ] Le nouveau composant partagé a bien **deux** usages.

---

## 11. État actuel

**Fait.** `AppShell` avec bascule d'espace · `AdminLayout` et son espace
opérationnel (tableau de bord des dépendances, modèles, banc d'essai avec
lancement, historique, et détail temps réel : console GAMA en direct, date
simulée, artefacts) · layout Simulation et navigation en place.

**À faire.** Les trois écrans de catalogue de l'espace Administration (entrées,
paramètres, sorties) · l'ensemble de l'espace Simulation · l'extraction de
`useRunStream` dans `hooks/` dès qu'un deuxième écran suivra un run · les
graphiques de résultats (`recharts` est déjà installé).
