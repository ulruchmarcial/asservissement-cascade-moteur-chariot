# Module 02 — Analyse fréquentielle

> **Objectif :** Analyser la stabilité et le comportement fréquentiel des boucles ouvertes à l'aide des diagrammes de Bode, de la carte pôles–zéros et des marges de stabilité.

---

## Notions abordées

- Carte des pôles et zéros (plan complexe)
- Critère de stabilité (pôles en demi-plan gauche)
- Amortissement ξ et fréquence naturelle ω_n
- Diagrammes de Bode (gain et phase)
- Pulsation de coupure à 0 dB (ω_cp)
- Marge de phase (Pm) et marge de gain (Gm)
- Lieu des racines (pzmap)

---

## 1. Carte des pôles et zéros

Les pôles d'un système $H(s)$ sont les racines de son dénominateur. Leur **position dans le plan complexe** détermine la stabilité :

```
       Im(s)
        │
   ×    │    ×          ← pôles complexes conjugués
        │               (Re < 0 → amortis → STABLES)
────────┼──────── Re(s)
        │
   ×    │    ×
        │
        │
   Demi-plan gauche │ Demi-plan droit
     (stable)       │  (instable)
```

| Position des pôles | Type | Réponse temporelle |
|-------------------|------|-------------------|
| Réels, Re < 0 | Apériodique stable | Exponentielle décroissante |
| Complexes, Re < 0 | Pseudo-périodique stable | Oscillations amorties |
| Imaginaires purs | Marginalement stable | Oscillations entretenues |
| Re > 0 | Instable | Divergence exponentielle |

**Dans MATLAB :**

```matlab
pzmap(G_BO_v)   % affiche pôles (×) et zéros (○) dans le plan complexe
damp(G_BO_v)    % affiche ω_n et ξ pour chaque pôle
```

---

## 2. Amortissement ξ

Pour une paire de pôles complexes conjugués $p_{1,2} = -\sigma \pm j\omega_d$ :

```math
\xi = \frac{\sigma}{\omega_n}, \qquad \omega_n = \sqrt{\sigma^2 + \omega_d^2}
```

Le facteur d'amortissement $\xi$ contrôle le dépassement en réponse indicielle :

```math
D\% = 100\,e^{-\pi\xi/\sqrt{1-\xi^2}}
```

| $\xi$ | $D\%$ | Régime |
|-------|-------|--------|
| 0.1 | 73% | Très sous-amorti |
| 0.3 | 37% | Sous-amorti |
| 0.5 | 16% | Sous-amorti modéré |
| 0.7 | 4.6% | Quasi-critique |
| 1.0 | 0% | Critique |

---

## 3. Diagramme de Bode

Le diagramme de Bode représente $H(j\omega)$ pour $\omega \in [0, +\infty)$ :

- **Courbe de gain :** $G_{dB}(\omega) = 20\log_{10}|H(j\omega)|$ [dB]
- **Courbe de phase :** $\phi(\omega) = \angle H(j\omega)$ [degrés]

### Asymptotes des éléments de base

| Élément | Gain (dB/décade) | Phase |
|---------|-----------------|-------|
| Gain pur $K$ | 0 | 0° |
| Intégrateur $1/s$ | −20 | −90° |
| Double intégrateur $1/s^2$ | −40 | −180° |
| Pôle réel $1/(1+\tau s)$ | 0 puis −20 (à $\omega=1/\tau$) | 0° → −90° |
| Zéro réel $(1+\tau s)$ | 0 puis +20 | 0° → +90° |

### Lecture des marges de stabilité

```
Gain [dB]
    │                              ← Marge de gain Gm (dB)
  0─┼──────────╲─────────────────────────
    │            ╲          ← ωcp     │
    │             ╲                   ▼
    │              ╲_________________
Phase [°]          ╲
  0─┼────────────────╲───────────────────
    │                 ╲ ← Pm
-180┼──────────────────╲─────────────────
                         ╲ ← ωcg
```

---

## 4. Marges de stabilité

### Marge de phase (Pm)

Mesurée à la **pulsation de coupure à 0 dB** $\omega_{cp}$ :

```math
P_m = 180° + \angle G_{BO}(j\omega_{cp})
```

Elle représente le **retard de phase supplémentaire** qu'on pourrait ajouter avant que le système devienne instable.

### Marge de gain (Gm)

Mesurée à la **pulsation de croisement de phase** $\omega_{cg}$ (là où la phase = −180°) :

```math
G_m = -20\log_{10}|G_{BO}(j\omega_{cg})|\ \text{[dB]}
```

Elle représente l'**amplification supplémentaire** qu'on pourrait appliquer avant instabilité.

### Critères de bonne conception

| Critère | Valeur minimale | Valeur visée dans le projet |
|---------|-----------------|---------------------------|
| Marge de phase $P_m$ | ≥ 45° | **50°** |
| Marge de gain $G_m$ | ≥ 6 dB | — |

> Un système avec $P_m \geq 50°$ présente un dépassement ≤ 16% en réponse indicielle en boucle fermée, ce qui est acceptable pour la plupart des applications.

### Dans MATLAB

```matlab
[Gm, Pm, Wcg, Wcp] = margin(G_BO_v);
fprintf('Marge de phase : %.1f deg à ωcp = %.1f rad/s\n', Pm, Wcp);
fprintf('Marge de gain  : %.1f dB   à ωcg = %.1f rad/s\n', 20*log10(Gm), Wcg);

margin(G_BO_v);   % trace Bode avec marges en surimpression
```

---

## 5. Résultats sur le système non corrigé

| Grandeur | Boucle vitesse ($G_{BO\_v}$) | Boucle position ($G_{BO\_p}$) |
|----------|------------------------------|-------------------------------|
| Ordre | 4 | 5 |
| Classe | 0 | 1 |
| $\omega_{cp}$ (non corrigé) | à déterminer | à déterminer |
| Marge de phase (non corrigée) | à déterminer | à déterminer |

> Exécuter [02_analyse_frequentielle.m](02_analyse_frequentielle.m) pour obtenir les valeurs numériques.

---

## 6. Lieu des racines

Le **lieu des racines** (root locus) montre comment les pôles en **boucle fermée** se déplacent dans le plan complexe lorsque le gain $K$ varie de 0 à $+\infty$.

```math
T(s) = \frac{K\,G(s)}{1 + K\,G(s)}
```

Les pôles BF partent des pôles BO ($K=0$) et convergent vers les zéros BO ($K\to\infty$).

```matlab
rlocus(G_BO_v);   % trace le lieu des racines
```

---

## Script MATLAB associé

→ [02_analyse_frequentielle.m](02_analyse_frequentielle.m)

