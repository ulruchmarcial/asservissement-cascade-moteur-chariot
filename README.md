# GEI1013 — Asservissements Linéaires | Projet de Conception H2026

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![MATLAB](https://img.shields.io/badge/MATLAB-R2021a%2B-blue)

> Modélisation, analyse et synthèse d'un système d'asservissement en **cascade à 3 boucles** (force → position → vitesse) pour un actionneur moteur CC – réducteur – chariot – ressort élastique.  
> Chaque module est documenté de façon **progressive et pédagogique** pour mettre en évidence les notions fondamentales de la théorie de commande.

---

## Système physique

![Photo du système physique](figures/photo_systeme.jpg)

> **Pour ajouter votre photo :** déposez votre image dans `figures/` sous le nom `photo_systeme.jpg` (ou `.png`).

---

## Schéma fonctionnel du système

![Schéma fonctionnel](figures/schema_fonctionnel.jpg)

> **Pour ajouter le schéma :** déposez une photo ou scan de votre schéma bloc dans `figures/` sous le nom `schema_fonctionnel.jpg`.

---

## Architecture de commande — Cascade à 3 boucles

```
   Fréf ──► [C3 : I] ──► xréf ──► [C1 : Lead] ──► αréf ──► [C2 : I+Lead] ──► α ──► SYSTÈME ──► x ──► F
              Force                  Position                  Vitesse
            ωcp = 2.5 rad/s        ωcp = 15 rad/s           ωcp = 50 rad/s
              (lent)                  (moyen)                    (rapide)
```

> **Règle de séparation :** chaque boucle est **5× plus lente** que la boucle interne qu'elle englobe, garantissant leur découplage dynamique.

---

## Carte des notions d'asservissement couvertes

| # | Notion | Description | Module |
|---|--------|-------------|--------|
| 1 | Transformée de Laplace | Passage domaine temporel → fréquentiel | [01](01_Modelisation_Systeme/) |
| 2 | Fonction de transfert (FT) | Rapport Y(s)/U(s) à conditions initiales nulles | [01](01_Modelisation_Systeme/) |
| 3 | Schéma bloc | Représentation graphique des FT interconnectées | [01](01_Modelisation_Systeme/) |
| 4 | Blocs internes (couplage) | Interaction convertisseur–moteur via Z·Y | [01](01_Modelisation_Systeme/) |
| 5 | Inertie équivalente | Ramener les masses au référentiel moteur | [01](01_Modelisation_Systeme/) |
| 6 | Pôles et zéros | Racines du dénominateur / numérateur de H(s) | [02](02_Analyse_Frequentielle/) |
| 7 | Critère de stabilité | Pôles à partie réelle strictement négative | [02](02_Analyse_Frequentielle/) |
| 8 | Amortissement ξ | Lien entre pôles complexes et oscillations | [02](02_Analyse_Frequentielle/) |
| 9 | Diagramme de Bode | Gain [dB] et phase [°] en fonction de ω | [02](02_Analyse_Frequentielle/) |
| 10 | Marge de phase (Pm) | Retard de phase avant instabilité à ωcp | [02](02_Analyse_Frequentielle/) |
| 11 | Marge de gain (Gm) | Amplification avant instabilité à ωcg | [02](02_Analyse_Frequentielle/) |
| 12 | Lieu des racines | Trajectoire des pôles BF en fonction du gain | [02](02_Analyse_Frequentielle/) |
| 13 | Réponse indicielle | Sortie y(t) pour une entrée échelon unitaire | [03](03_Analyse_Temporelle/) |
| 14 | Dépassement D% | Écart relatif au-delà de la valeur finale | [03](03_Analyse_Temporelle/) |
| 15 | Temps de réponse Ts | Temps pour rester dans ±5% de y∞ | [03](03_Analyse_Temporelle/) |
| 16 | Classe du système | Nombre d'intégrateurs en boucle ouverte | [03](03_Analyse_Temporelle/) |
| 17 | Erreur statique | Erreur résiduelle en régime permanent | [03](03_Analyse_Temporelle/) |
| 18 | Erreur de traînage (Kv) | Erreur à une rampe pour système de classe 1 | [03](03_Analyse_Temporelle/) |
| 19 | Réseau d'avance de phase | Correcteur Lead : ajoute de la phase à ωcp | [04](04_Synthese_Correcteurs/) |
| 20 | Action intégrale | Élimine l'erreur statique, ajoute −90° de phase | [04](04_Synthese_Correcteurs/) |
| 21 | Correcteur I + Avance (C2) | Boucle vitesse : intégrale + réseau d'avance | [04](04_Synthese_Correcteurs/) |
| 22 | Correcteur Lead seul (C1) | Boucle position : avance de phase pure | [04](04_Synthese_Correcteurs/) |
| 23 | Correcteur intégral pur (C3) | Boucle force : asservissement de force | [04](04_Synthese_Correcteurs/) |
| 24 | Méthode de Bode (synthèse) | Calcul analytique de α, T, K à partir du diagramme | [04](04_Synthese_Correcteurs/) |
| 25 | Commande en cascade | Imbrication de boucles pour contrôler plusieurs variables | [05](05_Commande_Cascade/) |
| 26 | Séparation des bandes passantes | Condition ωcp_externe ≪ ωcp_interne | [05](05_Commande_Cascade/) |

---

## Parcours d'apprentissage recommandé

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   MODULE 01     │ ──► │   MODULE 02     │ ──► │   MODULE 03     │
│ Modélisation    │     │ Analyse         │     │ Analyse         │
│ (FT, blocs)     │     │ fréquentielle   │     │ temporelle      │
│                 │     │ (Bode, marges)  │     │ (step, erreurs) │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                          │
                        ┌─────────────────┐     ┌────────▼────────┐
                        │   MODULE 05     │ ◄── │   MODULE 04     │
                        │ Commande        │     │ Synthèse des    │
                        │ en cascade      │     │ correcteurs     │
                        │ (architecture)  │     │ (Lead, I, I+L)  │
                        └─────────────────┘     └─────────────────┘
```

---

## Structure du dépôt

```
GEI1013-Asservissement/
├── README.md                          ← Ce fichier (vue d'ensemble)
├── CONCEPTS.md                        ← Glossaire complet des notions
├── projet_session.mlx                 ← Script MATLAB Live (code complet)
├── Modele_Projet_H2026_Gabarit.slx   ← Modèle Simulink
├── Rapport_projet_session.pdf         ← Rapport final
├── GEI1013_ProjetConception_H2026.pdf ← Cahier des charges
│
├── 01_Modelisation_Systeme/
│   ├── README.md                      ← Théorie : FT, blocs internes
│   └── 01_modelisation.m             ← Script MATLAB commenté
│
├── 02_Analyse_Frequentielle/
│   ├── README.md                      ← Théorie : Bode, marges, lieu des racines
│   └── 02_analyse_frequentielle.m    ← Script MATLAB commenté
│
├── 03_Analyse_Temporelle/
│   ├── README.md                      ← Théorie : step, classe, erreurs
│   └── 03_analyse_temporelle.m       ← Script MATLAB commenté
│
├── 04_Synthese_Correcteurs/
│   ├── README.md                      ← Théorie : Lead, I, I+Lead, méthode Bode
│   ├── 04a_correcteur_vitesse.m      ← C2 : I + Avance (ωcp = 50 rad/s)
│   ├── 04b_correcteur_position.m     ← C1 : Lead seul (ωcp = 15 rad/s)
│   └── 04c_correcteur_force.m        ← C3 : Intégrateur pur (ωcp = 2.5 rad/s)
│
└── 05_Commande_Cascade/
    ├── README.md                      ← Théorie : cascade, séparation des BP
    └── 05_cascade_complet.m          ← Assemblage des 3 boucles
```

---

## Prérequis

- **MATLAB** R2021a ou plus récent
- **Toolbox requise** : Control System Toolbox (`tf`, `bode`, `margin`, `step`, `feedback`)
- Notions de base en **transformée de Laplace**
- Connaissance élémentaire des **circuits électriques RLC** et des **moteurs CC**

---

## Paramètres du système

| Symbole | Valeur | Unité | Signification |
|---------|--------|-------|---------------|
| `uB` | 24 | V | Tension d'alimentation bus continu |
| `Lm` | 1.577×10⁻³ | H | Inductance de l'induit |
| `Rm` | 1.3 | Ω | Résistance de l'induit |
| `km = kv` | 0.0742 | V·s/rad / N·m/A | Constantes électromécaniques |
| `Jr` | 1.558×10⁻⁴ | kg·m² | Inertie du rotor |
| `M` | 2.5 | kg | Masse du chariot |
| `G` | 20 | — | Rapport de réduction |
| `r` | 0.125 | m | Rayon de la poulie |
| `Bm` | 1.5×10⁻³ | N·m·s/rad | Frottement visqueux |
| `Lf` | 50×10⁻⁶ | H | Inductance du filtre LC |
| `Cf` | 300×10⁻⁶ | F | Capacité du filtre LC |
| `Rf` | 100×10³ | Ω | Résistance de charge du filtre |
| `k_elas` | 50 | N/m | Raideur de la bande élastique |

---

## Résultats de conception

| Boucle | Correcteur | ωcp cible | Marge de phase cible | Structure |
|--------|-----------|-----------|---------------------|-----------|
| Vitesse (C2) | I + Avance | 50 rad/s | ≥ 50° | $C_2(s) = \frac{K}{s}\cdot\frac{Ts+1}{\alpha Ts+1}$ |
| Position (C1) | Lead | 15 rad/s | ≥ 50° | $C_1(s) = K_p\cdot\frac{Ts+1}{\alpha Ts+1}$ |
| Force (C3) | Intégrateur | 2.5 rad/s | ≥ 50° | $C_3(s) = \frac{K_i}{s}$ |

---

## Figures et résultats

> **Générer les figures :** exécuter `export_figures.m` dans MATLAB pour produire tous les graphiques ci-dessous dans le dossier `figures/`.

### Analyse fréquentielle — Boucles non corrigées

| Boucle vitesse | Boucle position |
|:-:|:-:|
| ![Carte pôles-zéros vitesse](figures/02a_pzmap_vitesse.png) | ![Carte pôles-zéros position](figures/02b_pzmap_position.png) |
| Carte pôles-zéros — $G_{BO\_v}$ | Carte pôles-zéros — $G_{BO\_p}$ |

| Bode vitesse (non corrigé) | Bode position (non corrigé) |
|:-:|:-:|
| ![Bode vitesse BO](figures/02c_bode_vitesse_BO.png) | ![Bode position BO](figures/02d_bode_position_BO.png) |
| Marges de $G_{BO\_v}$ | Marges de $G_{BO\_p}$ |

| Lieu des racines vitesse | Lieu des racines position |
|:-:|:-:|
| ![Lieu racines vitesse](figures/02e_rlocus_vitesse.png) | ![Lieu racines position](figures/02f_rlocus_position.png) |

---

### Analyse temporelle — Réponses sans correcteur

| Échelon BO vitesse | Échelon BF vitesse (gain=1) | Échelon BF position (gain=1) |
|:-:|:-:|:-:|
| ![Step BO vitesse](figures/03a_step_vitesse_BO.png) | ![Step BF vitesse brut](figures/03b_step_vitesse_BF_brut.png) | ![Step BF position brut](figures/03c_step_position_BF_brut.png) |

---

### Synthèse des correcteurs — Validation

#### Boucle vitesse C₂ (I + Avance, ωcp = 50 rad/s)

| Bode BO corrigée | Réponse indicielle BF |
|:-:|:-:|
| ![Bode L vitesse](figures/04a_bode_L_vitesse.png) | ![Step BF vitesse](figures/04b_step_BF_vitesse.png) |

#### Boucle position C₁ (Lead, ωcp = 15 rad/s)

| Bode BO corrigée | Réponse indicielle BF |
|:-:|:-:|
| ![Bode L position](figures/04c_bode_L_position.png) | ![Step BF position](figures/04d_step_BF_position.png) |

#### Boucle force C₃ (Intégrateur, ωcp = 2.5 rad/s)

| Bode G_sys3 (avant correction) | Bode BO corrigée | Réponse indicielle BF |
|:-:|:-:|:-:|
| ![Bode Gsys3](figures/04e_bode_Gsys3.png) | ![Bode L force](figures/04f_bode_L_force.png) | ![Step BF force](figures/04g_step_BF_force.png) |

---

### Commande en cascade — Vue globale

| Réponses indicielles des 3 boucles | Comparaison des gains en BO |
|:-:|:-:|
| ![Cascade step responses](figures/05_cascade_step_responses.png) | ![Bode comparaison 3 boucles](figures/05_bode_comparaison_3_boucles.png) |

La séparation des bandes passantes est clairement visible : $\omega_{cp,force} \ll \omega_{cp,pos} \ll \omega_{cp,vitesse}$.
