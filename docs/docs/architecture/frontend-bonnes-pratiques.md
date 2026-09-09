# Frontend — bonnes pratiques & design system

!!! abstract "Objet de ce document"
    Le **comment** du front. [Architecture frontend](frontend.md) décrit la
    structure ; ce document donne les règles de découpage du code et le design
    system : couleurs, typographie, espacements, responsive, accessibilité.

    À ouvrir avant de créer un composant. À citer en revue.

---

## Partie I — Découpage du code

### 1. Le principe : un fichier, une raison de changer

Un fichier long n'est pas un problème de longueur, c'est un problème de
**responsabilités mélangées**. `TestBench.jsx` faisait 125 lignes parce qu'il
contenait quatre choses sans rapport : un formulaire, une interrogation
périodique du serveur, un tableau, et de la navigation. Chacune changeait pour
une raison différente ; chacune est devenue un fichier.

| Fichier | Avant | Après | Ce qui en est sorti |
|---|---|---|---|
| `App.jsx` | 118 | **27** | routes par espace, contenu des écrans d'attente |
| `TestBench.jsx` | 125 | **41** | `LaunchForm`, `RunsTable`, `useRunsPolling` |
| `RunDetail.jsx` | 104 | **42** | `RunSummary`, `ArtifactsTable`, `ConsoleView`, `useRunStream` |
| `index.css` | 120 | **5** | `tokens`, `base`, `layout`, `components` |

Aucune ligne n'a disparu — elle a trouvé un nom.

### 2. Budgets indicatifs

Des repères, pas des règles absolues. Dépasser n'est pas une faute ; dépasser
**sans raison** en est une.

| Type de fichier | Cible | Signal d'alerte |
|---|---|---|
| Page (écran d'une route) | ≤ 50 lignes | elle compose, elle n'implémente pas |
| Composant | ≤ 80 lignes | plusieurs responsabilités mélangées |
| Hook | ≤ 60 lignes | plusieurs préoccupations dans un `useEffect` |
| Module d'API | ≤ 40 lignes | découper par domaine |
| Fichier CSS | ≤ 200 lignes | découper par rôle |

**Une page doit se lire comme un sommaire.** Si en la parcourant on ne comprend
pas ce que montre l'écran, elle en fait trop :

```jsx
export default function TestBench() {
  const { data: models, error, loading } = useAsync(adminApi.models);
  const { runs } = useRunsPolling();

  return (
    <>
      <PageHeader title="Banc d'essai" lede="…" />
      <Card title="Lancer une simulation">
        <AsyncBoundary error={error} loading={loading}>
          <LaunchForm models={models ?? []} onLaunch={launch} />
        </AsyncBoundary>
      </Card>
      <Card title="Historique">
        <RunsTable runs={runs} onSelect={…} />
      </Card>
    </>
  );
}
```

### 3. Trois niveaux de composants

| Niveau | Emplacement | Critère |
|---|---|---|
| **Partagé** | `components/` | utilisé par **≥ 2 pages** |
| **Local à une page** | `pages/<espace>/components/` | une seule page, mais assez gros pour mériter son fichier |
| **Interne** | dans le fichier de la page | quelques lignes, jamais réutilisé |

On **ne promeut pas par anticipation**. Un composant créé « pour plus tard » est
sur-paramétré et ne sert qu'une fois. On promeut au deuxième usage réel : c'est
là qu'on découvre la bonne interface.

`StatusBadge` a été promu parce que `TestBench`, `RunDetail` et `Dashboard` en
avaient besoin — et les trois affichaient des statuts différents (`TERMINE`,
`up`). L'interface s'est écrite d'elle-même.

### 4. Extraire un hook

Un `useEffect` non trivial mérite son hook dès qu'il :

- gère un abonnement ou un minuteur (donc un nettoyage) ;
- combine plusieurs sources (REST + WebSocket) ;
- serait recopié dans un deuxième écran.

```javascript
// hooks/useRunStream.js — instantané REST puis flux WebSocket
export function useRunStream(runId) { … }

// La page ne voit plus que le résultat :
const { run, logs, error } = useRunStream(runId);
```

Le composant redevient de l'affichage, et la logique se teste séparément.

### 5. Découpage du réseau

`api/` est le **seul** point de contact avec le backend.

```
api/
├── client.js     # URLs de base + enveloppe fetch (erreurs RFC 7807)
├── admin.js      # endpoints du domaine Administration
├── health.js     # santé de la plateforme
├── realtime.js   # abonnements WebSocket
└── index.js      # point d'entrée
```

Un module par domaine, aligné sur le découpage backend. Quand l'espace Simulation
arrivera, il aura son `api/simulation.js` — pas 40 méthodes de plus dans un
fichier commun.

### 6. Les données de navigation sont des données

La navigation vit dans `routes/navigation.js`, pas dans le JSX des layouts :

```javascript
export const adminNav = [
  { title: "Administration", links: [
      { to: "/admin", label: "Tableau de bord", end: true },
      { to: "/admin/modeles", label: "Modèles" },
  ]},
];
```

Les deux layouts deviennent identiques à seize lignes près, et ajouter une
rubrique est une ligne — pas une modification de composant.

---

## Partie II — Design system

Repris **à l'identique** de la charte MAELIA existante. Le front, la
documentation et les futurs écrans partagent la même palette.

### 7. Couleurs

**Primaire « eau » — teal.** Réservée aux actions et aux états actifs. Jamais
décorative.

| Jeton | Valeur | Usage |
|---|---|---|
| `--primary-600` | `#0E7C86` | **couleur d'action par défaut** |
| `--primary-700` | `#115E67` | survol d'une action |
| `--primary-500` | `#0E9CA8` | accent en mode sombre |
| `--primary-50` | `#ECFEFF` | fond d'un état actif |

**Neutres — slate**, de `--neutral-50` `#F8FAFC` à `--neutral-900` `#0F172A`.

**Sémantiques** : `--success` `#16A34A` · `--warning` `#D97706` ·
`--danger` `#DC2626` · `--info` `#2563EB`.

!!! tip "Les composants n'utilisent jamais l'échelle directement"
    Ils utilisent des **rôles** : `--bg`, `--surface`, `--border`, `--text`,
    `--text-muted`, `--accent`. C'est ce qui permet au mode sombre de ne
    redéfinir que douze variables au lieu de réécrire la feuille de style.

    ```css
    .card { background: var(--surface); }   /* ✓ */
    .card { background: #ffffff; }          /* ✗ */
    ```

### 8. Typographie

**Inter** pour le texte, **JetBrains Mono** pour le code et la console.

Les tableaux, les chiffres clés et la console utilisent
`font-variant-numeric: tabular-nums` : sans cela, une colonne de nombres danse à
chaque rafraîchissement — insupportable sur un run qui se met à jour toutes les
trois secondes.

Titres en `600`/`650` avec `letter-spacing: -0.02em` ; corps à 14 px,
interlignage 1.6 ; accroche limitée à `68ch` — au-delà, l'œil perd la ligne.

### 9. Espacements, rayons, ombres

Une échelle, pas des valeurs magiques : `--space-1` (4 px) à `--space-7` (48 px).

Rayons : `--radius-sm` 6 px (contrôles) · `--radius` 10 px (cartes) ·
`--radius-pill` (badges, bascule d'espace).

Trois ombres seulement — `sm` pour les surfaces posées, `md` au survol, `lg` pour
ce qui flotte (tiroir). Une ombre marque une **élévation réelle**, jamais un
effet.

### 10. Composer un écran

Toujours le même squelette :

```jsx
<PageHeader title="…" lede="…" />
<Card title="…">…</Card>
<Card title="…">…</Card>
```

Titre, accroche d'une phrase, puis des cartes. Une carte = un sujet. Cette
régularité est ce qui donne l'impression d'**une seule application** plutôt que
d'un assemblage d'écrans.

---

## Partie III — Responsive & accessibilité

### 11. Points de rupture

La cible est le poste de travail — c'est une application métier — mais elle doit
rester utilisable en mobilité.

| Largeur | Comportement |
|---|---|
| ≥ 1024 px | barre latérale fixe, contenu limité à `1120px` |
| < 1024 px | **barre latérale en tiroir**, bouton flottant, voile de fond |
| < 640 px | bandeau compacté, titres réduits, marges resserrées |

Le tiroir se referme **automatiquement après navigation** — sinon il masque
l'écran qu'on vient de demander :

```jsx
const { pathname } = useLocation();
useEffect(() => setOpen(false), [pathname]);
```

### 12. Contenu qui déborde

Une table de données ne s'écrase pas : elle **défile dans son conteneur**.

```css
.card table {
  display: block;
  overflow-x: auto;
  white-space: nowrap;
}
```

La console s'adapte à la hauteur disponible sans jamais devenir minuscule ni
géante : `height: clamp(220px, 40vh, 420px)`.

Les chiffres clés passent en grille auto-ajustée plutôt qu'en ligne rigide :
`grid-template-columns: repeat(auto-fit, minmax(120px, 1fr))`.

### 13. Accessibilité — WCAG 2.1 AA

Quatre exigences non négociables.

**Le focus est toujours visible.** Jamais d'`outline: none` sans remplacement.

```css
:focus-visible {
  outline: 2px solid var(--focus-ring);
  outline-offset: 2px;
}
```

**Un statut n'est jamais porté par la seule couleur.** Chaque badge affiche son
libellé (`TERMINE`, `ECHEC`) ; la pastille colorée ne fait que renforcer. Idem
pour la rubrique active de la barre latérale : fond teinté **et** repère latéral.

**Le mouvement est optionnel.** La pastille d'un run en cours pulse — sauf si
l'utilisateur a demandé moins d'animation :

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

**Le thème suit le système.** `prefers-color-scheme` est respecté ; le mode
sombre ne redéfinit que les rôles.

### 14. Micro-interactions

Sobres et informatives : transitions de `150ms ease` sur les couleurs et les
ombres, léger enfoncement au clic d'un bouton, survol de ligne dans les tableaux
cliquables, pulsation de la pastille d'un run actif.

Rien qui bouge sans dire quelque chose. Pas d'apparition en fondu, pas de
glissement décoratif : sur un écran consulté toute la journée, l'animation
gratuite fatigue.

### 15. Les trois états, toujours

Chargement, erreur, données. `AsyncBoundary` les rend une fois pour toutes :

```jsx
<AsyncBoundary error={error} loading={loading}>
  <LaunchForm models={models} onLaunch={launch} />
</AsyncBoundary>
```

Ajouter une quatrième situation — la liste **vide** — avec `EmptyState` : une
liste vide sans message ressemble à un bug.

---

## 16. Anti-patterns

!!! danger "À ne pas faire"
    - **Une couleur, un espacement ou un rayon en dur.** Toujours un jeton.
    - **`style={{ … }}` pour ce qui se répète.** Une classe, dans `components.css`.
    - **Un composant partagé créé au premier usage.** On attend le deuxième.
    - **Une page qui implémente au lieu de composer.**
    - **Un `useEffect` sans nettoyage** quand il ouvre un minuteur ou un socket.
    - **`outline: none`** sans focus de remplacement.
    - **Un statut véhiculé par la seule couleur.**
    - **Une animation décorative.**
    - **Un tableau qui élargit la page** au lieu de défiler.
    - **Un `fetch` hors de `api/`.**

---

## 17. Checklist de revue

**Découpage**

- [ ] La page **compose** plutôt qu'elle n'implémente (≤ ~50 lignes).
- [ ] Aucun fichier ne mélange plusieurs responsabilités.
- [ ] Le composant promu dans `components/` a bien **deux** usages.
- [ ] La logique à état non triviale est dans un hook.
- [ ] Aucun accès réseau hors de `api/`.

**Design**

- [ ] Aucune couleur / espacement / rayon en dur — que des jetons.
- [ ] L'écran suit le squelette `PageHeader` + `Card`.
- [ ] Les colonnes de nombres sont en chiffres tabulaires.

**Responsive & accessibilité**

- [ ] Utilisable à 1024 px et à 640 px.
- [ ] Le contenu large défile dans son conteneur.
- [ ] Le focus clavier est visible sur tous les éléments interactifs.
- [ ] Aucun statut n'est porté par la seule couleur.
- [ ] `prefers-reduced-motion` et `prefers-color-scheme` sont respectés.
- [ ] Les trois états — chargement, erreur, données — plus le cas **vide**.
