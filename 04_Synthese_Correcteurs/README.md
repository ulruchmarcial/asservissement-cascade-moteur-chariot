# Module 04 — Synthèse des correcteurs

> **Objectif :** Concevoir analytiquement trois correcteurs en utilisant la **méthode de Bode** : imposer une pulsation de coupure $\omega_{cp}$ et une marge de phase $P_m$ cibles.

---

## Notions abordées

- Méthode de synthèse fréquentielle par Bode
- Réseau d'avance de phase (Lead) : calcul de α, T, K
- Action intégrale : effet sur la classe et la phase
- Correcteur I + Avance de phase (boucle vitesse C2)
- Correcteur Lead seul (boucle position C1)
- Correcteur intégral pur (boucle force C3)

---

## Principe de la méthode de Bode

L'idée est d'imposer deux spécifications en **boucle ouverte corrigée** $L(s) = C(s)\cdot G(s)$ :

1. **$\omega_{cp}$ cible** : la pulsation où $|L(j\omega_{cp})| = 1$ (0 dB)
2. **$P_m$ cible** : la marge de phase à $\omega_{cp}$, c'est-à-dire $\angle L(j\omega_{cp}) = -180° + P_m$

Le correcteur $C(s)$ doit donc apporter :
- La **phase manquante** : $\Delta\phi = P_{m,cible} - (180° + \angle G(j\omega_{cp}))$
- L'**ajustement de gain** : $|C(j\omega_{cp})| = 1/|G(j\omega_{cp})|$

---

## 1. Réseau d'avance de phase (Lead compensator)

### Structure

$$C_{lead}(s) = K\cdot\frac{Ts+1}{\alpha Ts+1}, \qquad 0 < \alpha < 1$$

Le paramètre $\alpha < 1$ garantit que le zéro $\omega_z = 1/T$ est à une fréquence **inférieure** au pôle $\omega_p = 1/(\alpha T)$, ce qui produit une **avance** (et non un retard) de phase.

### Diagramme de Bode du Lead

```
Gain [dB]
         ╱──────────────
        ╱
───────╱
      ωz         ωp

Phase [°]
   +φmax
      ╭──╮
     ╱    ╲
────╱      ╲─────────
   ωz  ωmax  ωp
```

La phase maximale $\phi_{max}$ est atteinte à $\omega_{max} = \sqrt{\omega_z \cdot \omega_p} = \frac{1}{T\sqrt{\alpha}}$.

### Formules de calcul

**Étape 1 — Phase maximale requise :**

$$\phi_{max} = \phi_{m,cible} - 180° - \angle G_{BO}(j\omega_{cp})$$

*(Pour C2, ajouter −90° car l'intégrateur décale la phase de −90°)*

**Étape 2 — Calcul de α :**

$$\alpha = \frac{1 - \sin\phi_{max}}{1 + \sin\phi_{max}}$$

> Vérification : $\phi_{max} \leq 65°$ pour que $\alpha \geq 0.02$ (éviter l'amplification excessive du bruit).

**Étape 3 — Calcul de T** (placer $\omega_{max}$ à $\omega_{cp}$) :

$$T = \frac{1}{\omega_{cp}\sqrt{\alpha}}$$

**Étape 4 — Calcul de K** (normaliser le gain à $\omega_{cp}$) :

$$K_{lead} = \frac{\sqrt{\alpha}}{|G_{BO}(j\omega_{cp})|}$$

---

## 2. Correcteur C2 — Boucle vitesse : I + Avance

### Justification

La boucle vitesse ($G_{BO\_v}$) est de **classe 0** : erreur statique non nulle. Pour l'éliminer, on ajoute un **intégrateur** $K/s$.

**Problème :** l'intégrateur ajoute −90° de phase, ce qui dégrade la marge de phase. Il faut compenser avec le réseau d'avance.

### Structure du correcteur

$$\boxed{C_2(s) = \frac{K}{s}\cdot\frac{Ts+1}{\alpha Ts+1}}$$

### Procédure complète

| Étape | Formule | Valeur projet |
|-------|---------|---------------|
| Cible | $\omega_{cp} = 50$ rad/s, $P_m = 50°$ | — |
| Phase de $G_{BO\_v}$ à $\omega_{cp}$ | `bode(G_BO_v, 50)` → $\angle G$ | à calculer |
| Phase requise | $\phi_{max} = 50° - 90° - \angle G_{BO\_v}(j\omega_{cp})$ | — |
| Alpha | $\alpha = \frac{1-\sin\phi_{max}}{1+\sin\phi_{max}}$ | — |
| T | $T = \frac{1}{\omega_{cp}\sqrt{\alpha}}$ | — |
| K | $K = \frac{\omega_{cp}\sqrt{\alpha}}{|G_{BO\_v}(j\omega_{cp})|}$ | — |

> Les −90° dans la phase requise proviennent du terme intégrateur $K/s$ qui décale la phase de −90°.

**Vérification après synthèse :**

```matlab
L_vitesse = C2_vitesse * G_BO_v;
[~, Pm_new, ~, Wcp_new] = margin(L_vitesse);
fprintf('Pm corrigée = %.1f° à ωcp = %.1f rad/s\n', Pm_new, Wcp_new);
```

---

## 3. Correcteur C1 — Boucle position : Lead seul

### Justification

La boucle position ($G_{BO\_p}$) est de **classe 1** (intégrateur cinématique $r/Gs$). Pas besoin d'ajouter un intégrateur. Un **réseau d'avance seul** suffit.

### Structure du correcteur

$$\boxed{C_1(s) = K_p\cdot\frac{Ts+1}{\alpha Ts+1}}$$

### Différence clé avec C2

La formule de l'avance requise devient :

$$\phi_{max} = P_{m,cible} - 180° - \angle G_{BO\_p}(j\omega_{cp})$$

*(Pas de −90° : l'intégrateur de la boucle est déjà dans $G_{BO\_p}$)*

**Cas particulier :** si $\phi_{max} \leq 0$, le système a déjà assez de phase à $\omega_{cp}$. Un simple **gain proportionnel** suffit :

$$\phi_{max} \leq 0 \quad\Rightarrow\quad C_1(s) = K_p = \frac{1}{|G_{BO\_p}(j\omega_{cp})|}$$

| Étape | Formule | Valeur projet |
|-------|---------|---------------|
| Cible | $\omega_{cp} = 15$ rad/s, $P_m = 50°$ | — |
| Phase requise | $\phi_{max} = 50° - 180° - \angle G_{BO\_p}(j15)$ | à calculer |
| Alpha, T, Kp | mêmes formules que C2 (sans K/s) | — |

---

## 4. Correcteur C3 — Boucle force : Intégrateur pur

### Justification

La boucle externe contrôle la **force dans la bande élastique** :

$$F = k_{elas} \cdot x \quad\Rightarrow\quad G_{sys3}(s) = k_{elas}\cdot T_{position}(s)$$

Un **intégrateur pur** assure une erreur statique nulle sur la force et une bande passante très faible (2.5 rad/s) pour ne pas perturber les boucles internes.

### Structure du correcteur

$$\boxed{C_3(s) = \frac{K_i}{s}}$$

### Calcul du gain

On impose $|L_{force}(j\omega_{cp})| = 1$ à $\omega_{cp} = 2.5$ rad/s :

$$|C_3(j\omega_{cp})|\cdot|G_{sys3}(j\omega_{cp})| = 1 \quad\Rightarrow\quad \frac{K_i}{\omega_{cp}}\cdot|G_{sys3}(j\omega_{cp})| = 1$$

$$\boxed{K_i = \frac{\omega_{cp}}{|G_{sys3}(j\omega_{cp})|}}$$

---

## 5. Tableau récapitulatif des trois correcteurs

| | C2 — Vitesse | C1 — Position | C3 — Force |
|--|--|--|--|
| **Structure** | $K/s \cdot (Ts+1)/(\alpha Ts+1)$ | $K_p(Ts+1)/(\alpha Ts+1)$ | $K_i/s$ |
| **$\omega_{cp}$ cible** | 50 rad/s | 15 rad/s | 2.5 rad/s |
| **$P_m$ cible** | 50° | 50° | ≥ 45° (implicite) |
| **Classe avant** | 0 | 1 | — |
| **Classe après** | 1 | 1 | — |
| **Justification** | Erreur statique vitesse | Avance pour marge de phase | Erreur force nulle |

---

## Scripts MATLAB associés

- [04a_correcteur_vitesse.m](04a_correcteur_vitesse.m) — C2 : I + Avance
- [04b_correcteur_position.m](04b_correcteur_position.m) — C1 : Lead seul
- [04c_correcteur_force.m](04c_correcteur_force.m) — C3 : Intégrateur pur

---

## Questions de révision

1. Pourquoi le correcteur C2 (vitesse) contient-il un intégrateur mais pas C1 (position) ?
2. Si $\phi_{max}$ calculé dépasse 65°, que se passe-t-il physiquement ? Quelle solution adopter ?
3. Pour la boucle position, si $\phi_{max} < 0$, pourquoi un gain proportionnel suffit-il ?
4. Comment vérifier que la synthèse a bien atteint les spécifications ? (Bode et stepinfo)
5. Quel serait l'effet d'augmenter $\omega_{cp}$ de 50 à 100 rad/s pour C2 ? Quels compromis cela implique-t-il ?
