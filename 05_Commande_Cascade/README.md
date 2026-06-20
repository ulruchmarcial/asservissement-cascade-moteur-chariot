# Module 05 — Commande en cascade

> **Objectif :** Comprendre et assembler l'architecture de commande en cascade à 3 boucles, valider la séparation des bandes passantes et analyser les performances globales du système.

---

## Notions abordées

- Principe de la commande en cascade (multi-boucle)
- Séparation des bandes passantes
- Construction progressive (de l'intérieur vers l'extérieur)
- Validation des performances globales

---

## 1. Pourquoi la commande en cascade ?

Le système comporte **trois grandeurs physiques à contrôler** :

| Grandeur | Variable | Capteur associé |
|----------|----------|-----------------|
| Vitesse du chariot | $\omega_m$ | Encodeur moteur |
| Position du chariot | $x$ | Potentiomètre / encodeur |
| Force dans la bande élastique | $F = k_{elas}\cdot x$ | Capteur de force / calcul |

### Approche mono-boucle (non retenue)

Un seul correcteur global force → courant n'exploite pas la structure interne du système. Il est difficile à régler, peu robuste aux perturbations mécaniques internes.

### Approche cascade (retenue)

Chaque variable est régulée par sa propre boucle. Les boucles sont imbriquées de l'intérieur vers l'extérieur :

```
┌────────────────────────────────────────────────────────────────┐
│  BOUCLE FORCE (externe, lente)                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  BOUCLE POSITION (intermédiaire)                        │   │
│  │  ┌────────────────────────────────────────────────┐     │   │
│  │  │  BOUCLE VITESSE (interne, rapide)              │     │   │
│  │  │  C2 ──► G_BO_v ──► ωm                         │     │   │
│  │  └────────────────────────────────────────────────┘     │   │
│  │  C1 ──► [Boucle Vitesse BF] ──► G_cin ──► x            │   │
│  └─────────────────────────────────────────────────────────┘   │
│  C3 ──► [Boucle Position BF] ──► k_elas ──► F                 │
└────────────────────────────────────────────────────────────────┘
```

**Avantages de la cascade :**
- Chaque perturbation interne est rejetée par la boucle qui la concerne
- Réglage séquentiel : boucle vitesse d'abord, puis position, puis force
- Plus grande robustesse aux non-linéarités et aux variations de paramètres

---

## 2. Séparation des bandes passantes

### Condition fondamentale

Pour que les boucles se comportent de façon **indépendante** (sans interaction dynamique), les bandes passantes doivent être suffisamment séparées :

$$\omega_{cp,externe} \leq \frac{\omega_{cp,interne}}{5}$$

### Application au projet

```
        ωcp_force        ωcp_position        ωcp_vitesse
           │                   │                   │
        2.5 rad/s          15 rad/s            50 rad/s
           │                   │                   │
           └──────────── ×5 ───┘                   │
                               └──────── ×3.3 ─────┘
                                        ↑
                                    (≈ ×5/1.5)
```

| Rapport | Valeur | Condition ×5 | Verdict |
|---------|--------|--------------|---------|
| $\omega_{cp,vitesse}/\omega_{cp,position}$ | 50/15 ≈ 3.3 | ≥ 5 | ⚠ Limite |
| $\omega_{cp,position}/\omega_{cp,force}$ | 15/2.5 = 6 | ≥ 5 | ✓ |

> Le rapport vitesse/position (3.3) est légèrement inférieur au facteur 5 idéal. En pratique, cela est acceptable si les deux boucles sont bien amorties individuellement.

---

## 3. Construction de la cascade

### Étape 1 — Boucle vitesse fermée

$$T_{vitesse}(s) = \frac{C_2(s)\cdot G_{BO\_v}(s)}{1 + C_2(s)\cdot G_{BO\_v}(s)}$$

Pour la boucle de position, $T_{vitesse}$ est une "boîte noire" (idéalement : $T_{vitesse}\approx 1$ dans la BP de position).

### Étape 2 — Boucle position fermée

On boucle sur la sortie position :

$$G_{pos}(s) = T_{vitesse}(s)\cdot G_{cin}(s) = T_{vitesse}(s)\cdot\frac{r}{G\cdot s}$$

$$T_{position}(s) = \frac{C_1(s)\cdot G_{pos}(s)}{1 + C_1(s)\cdot G_{pos}(s)}$$

### Étape 3 — Boucle force fermée

La force est $F = k_{elas}\cdot x$, donc le système vu de la boucle force est :

$$G_{force}(s) = k_{elas}\cdot T_{position}(s)$$

$$T_{force}(s) = \frac{C_3(s)\cdot G_{force}(s)}{1 + C_3(s)\cdot G_{force}(s)}$$

### Ordre de réglage

```
1. Régler C2 (vitesse)
      ↓  valider Ts, D% en BF vitesse
2. Régler C1 (position)
      ↓  valider Ts, D% en BF position
3. Régler C3 (force)
      ↓  valider Ts, D% en BF force
```

---

## 4. Validation des performances

### Spécifications globales attendues

| Boucle | $P_m$ obtenue | $D\%$ | $T_s$ (5%) |
|--------|--------------|-------|------------|
| Vitesse (C2) | ≥ 50° | ≤ 16% | — |
| Position (C1) | ≥ 50° | ≤ 16% | — |
| Force (C3) | ≥ 45° | ≤ 16% | — |

### Vérification dans MATLAB

```matlab
% Boucle vitesse
[~, Pm_v] = margin(C2_vitesse * G_BO_v);
info_v = stepinfo(feedback(C2_vitesse * G_BO_v, 1));

% Boucle position
[~, Pm_p] = margin(C1_position * G_BO_p_sys);
info_p = stepinfo(feedback(C1_position * G_BO_p_sys, 1));

% Boucle force
[~, Pm_f] = margin(C3_force * G_force);
info_f = stepinfo(feedback(C3_force * G_force, 1));
```

---

## 5. Schéma Simulink

Le fichier [Modele_Projet_H2026_Gabarit.slx](../Modele_Projet_H2026_Gabarit.slx) implémente la cascade complète avec :
- Les blocs physiques (convertisseur, moteur, mécanique)
- Les trois correcteurs imbriqués
- Les signaux de référence et de mesure
- Les graphiques de sortie

---

## Script MATLAB associé

→ [05_cascade_complet.m](05_cascade_complet.m)

---

## Questions de révision

1. Dans quel ordre règle-t-on les boucles d'une cascade ? Pourquoi cet ordre ?
2. Que se passe-t-il si la bande passante de la boucle externe dépasse celle de la boucle interne ?
3. Pourquoi approxime-t-on $T_{vitesse}(s) \approx 1$ lorsqu'on règle la boucle de position ?
4. Quelle grandeur physique la boucle de force régule-t-elle exactement ? Comment est-elle mesurée ?
5. Si on voulait ajouter une 4ème boucle (courant moteur), quelle serait sa bande passante minimale ?
