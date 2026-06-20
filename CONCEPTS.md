# Glossaire des notions d'asservissement — GEI1013

> Référence rapide pour tous les concepts théoriques du cours. Chaque notion est définie, formulée et reliée au projet.

---

## 1. Transformée de Laplace

**Définition :** Outil mathématique qui transforme une équation différentielle (domaine temporel) en équation algébrique (domaine fréquentiel) :

$$\mathcal{L}\{f(t)\} = F(s) = \int_0^\infty f(t)\,e^{-st}\,dt$$

**Propriété clé :** la dérivée devient une multiplication par $s$ :

$$\mathcal{L}\left\{\frac{d^n f}{dt^n}\right\} = s^n F(s) \quad \text{(c.i. nulles)}$$

**Dans le projet :** chaque équation différentielle du moteur ou du filtre est transformée en FT via cette propriété.

---

## 2. Fonction de transfert (FT)

**Définition :** Rapport de la transformée de Laplace de la sortie sur celle de l'entrée, à conditions initiales nulles :

$$H(s) = \frac{Y(s)}{U(s)}$$

**Forme générale :**

$$H(s) = K\,\frac{b_m s^m + \cdots + b_0}{a_n s^n + \cdots + a_0}$$

**Dans le projet :**
- $G_{conv}(s) = \frac{U_B}{L_f C_f s^2 + \frac{L_f}{R_f}s + 1}$ (convertisseur)
- $G_{mot}(s) = \frac{k_m}{(L_m s + R_m)(J_m s + B_m) + k_m k_v}$ (moteur CC)
- $G_{cin}(s) = \frac{r}{G \cdot s}$ (cinématique)

---

## 3. Schéma bloc et assemblage

**Mise en série :** $H_{tot}(s) = H_1(s) \cdot H_2(s)$

**Boucle fermée unitaire :**

$$T(s) = \frac{G(s)}{1 + G(s)}$$

**Blocs internes (couplage) :** quand deux blocs interagissent via une impédance de sortie $Z$ et une admittance d'entrée $Y$ :

$$G_{couplé}(s) = \frac{G_{conv}(s)}{1 + Z_{conv}(s) \cdot Y_{mot}(s)}$$

> Ce modèle est plus fidèle que la simple mise en série, car il capture la **rétroaction interne** du courant moteur sur la tension convertisseur.

---

## 4. Inertie équivalente

Lorsqu'une masse $M$ est transmise par un réducteur (rapport $G$) et une poulie (rayon $r$), son inertie vue par l'arbre moteur est :

$$J_{équiv} = M \cdot \left(\frac{r}{G}\right)^2$$

L'inertie totale à l'arbre moteur est donc :

$$J_m = J_r + M\left(\frac{r}{G}\right)^2$$

---

## 5. Pôles et zéros

**Pôles** : racines du dénominateur de $H(s)$ → les $p_i$ tels que $H(p_i) \to \infty$

**Zéros** : racines du numérateur de $H(s)$ → les $z_i$ tels que $H(z_i) = 0$

**Critère de stabilité (BIBO) :** un système est stable si et seulement si **tous ses pôles ont une partie réelle strictement négative** (demi-plan gauche).

| Position des pôles | Comportement |
|-------------------|-------------|
| Réels négatifs | Exponentielle décroissante (stable, apériodique) |
| Complexes conjugués, Re < 0 | Oscillations amorties (stable, pseudo-périodique) |
| Imaginaires purs | Oscillations entretenues (marginalement stable) |
| Re > 0 | Divergence (instable) |

---

## 6. Amortissement ξ

Pour un système du 2ème ordre : $H(s) = \frac{\omega_n^2}{s^2 + 2\xi\omega_n s + \omega_n^2}$

| ξ | Régime |
|---|--------|
| $\xi > 1$ | Sur-amorti (pas de dépassement) |
| $\xi = 1$ | Critiquement amorti |
| $0 < \xi < 1$ | Sous-amorti (dépassement) |
| $\xi = 0$ | Oscillations non amorties |

Lien dépassement : $D\% = 100\,e^{-\pi\xi/\sqrt{1-\xi^2}}$

---

## 7. Diagramme de Bode

Représentation du comportement fréquentiel d'un système :

- **Courbe de gain** : $|H(j\omega)|$ en décibels → $20\log_{10}|H(j\omega)|$ [dB]
- **Courbe de phase** : $\angle H(j\omega)$ en degrés

**Pulsation de coupure à 0 dB ($\omega_{cp}$) :** fréquence à laquelle le gain = 1 (0 dB)  
**Pulsation de gain nul ($\omega_{cg}$) :** fréquence à laquelle la phase = −180°

---

## 8. Marges de stabilité

**Marge de phase (Pm) :** phase supplémentaire disponible avant d'atteindre −180° à $\omega_{cp}$ :

$$P_m = 180° + \angle G_{BO}(j\omega_{cp})$$

**Marge de gain (Gm) :** rapport (en dB) qu'on peut ajouter au gain avant instabilité, mesuré à $\omega_{cg}$ :

$$G_m = -20\log_{10}|G_{BO}(j\omega_{cg})|\ \text{[dB]}$$

**Règle de bonne pratique :**

$$P_m \geq 45°\quad\text{et}\quad G_m \geq 6\,\text{dB}$$

> Dans ce projet, la cible de conception est $P_m \geq 50°$ pour les trois boucles.

---

## 9. Classe du système et erreurs statiques

La **classe** d'un système est le nombre d'intégrateurs ($1/s$) présents en boucle ouverte.

| Classe | Erreur à un échelon | Erreur à une rampe | Gain caractéristique |
|--------|--------------------|--------------------|----------------------|
| 0 | $\varepsilon = \frac{1}{1+K_p}$ | $\infty$ | $K_p = G_{BO}(0)$ |
| 1 | 0 | $\varepsilon = \frac{1}{K_v}$ | $K_v = \lim_{s\to 0} s\,G_{BO}(s)$ |
| 2 | 0 | 0 | $K_a = \lim_{s\to 0} s^2 G_{BO}(s)$ |

**Dans le projet :**
- Boucle vitesse (`G_BO_v`) : **classe 0** (gain statique fini, erreur statique non nulle sans correcteur I)
- Boucle position (`G_BO_p`) : **classe 1** (intégrateur cinématique $r/Gs$, erreur nulle à l'échelon)

---

## 10. Réponse temporelle — Indicateurs

Pour une réponse indicielle en boucle fermée :

| Indicateur | Définition | MATLAB |
|-----------|-----------|--------|
| **Dépassement** $D\%$ | $100\,\frac{y_{max}-y_\infty}{y_\infty}$ | `stepinfo().Overshoot` |
| **Temps de montée** $t_m$ | Temps de 10% à 90% de $y_\infty$ | `stepinfo().RiseTime` |
| **Temps de réponse** $T_s$ | Temps pour rester dans $\pm5\%$ de $y_\infty$ | `stepinfo().SettlingTime` |
| **Valeur finale** $y_\infty$ | $\lim_{t\to\infty}y(t) = \lim_{s\to 0}s\,Y(s)$ | Théorème valeur finale |

---

## 11. Réseau d'avance de phase (Lead compensator)

**Fonction de transfert :**

$$C_{lead}(s) = K\,\frac{Ts + 1}{\alpha Ts + 1}, \quad 0 < \alpha < 1$$

Le paramètre $\alpha < 1$ garantit que le réseau **avance** la phase (contrairement à un réseau retard où $\alpha > 1$).

**Phase maximale apportée :**

$$\phi_{max} = \arcsin\left(\frac{1-\alpha}{1+\alpha}\right) \quad\Leftrightarrow\quad \alpha = \frac{1-\sin\phi_{max}}{1+\sin\phi_{max}}$$

**Fréquence du maximum de phase** (où on place $\omega_{cp}$) :

$$\omega_{max} = \frac{1}{T\sqrt{\alpha}} \quad\Rightarrow\quad T = \frac{1}{\omega_{cp}\sqrt{\alpha}}$$

**Gain à $\omega_{cp}$** (on normalise pour ne pas décaler la coupure) :

$$|C_{lead}(j\omega_{cp})| = \frac{K}{\sqrt{\alpha}} \quad\Rightarrow\quad K = \frac{\sqrt{\alpha}}{|G_{BO}(j\omega_{cp})|}$$

---

## 12. Action intégrale

**Forme :** $C_I(s) = K_I / s$

**Effet sur la phase :** ajoute **−90°** à toutes les fréquences.

**Effet sur le gain :** augmente le gain aux basses fréquences → élimine l'erreur statique.

**Effet sur la classe :** augmente la classe du système de 1.

---

## 13. Correcteur I + Avance (C2 — boucle vitesse)

Combinaison d'un intégrateur et d'un réseau d'avance :

$$C_2(s) = \frac{K}{s}\cdot\frac{Ts+1}{\alpha Ts+1}$$

**Procédure de synthèse à $\omega_{cp}$ cible :**

1. Mesurer phase et gain de $G_{BO_v}(j\omega_{cp})$
2. Calculer l'avance requise : $\phi_{max} = \phi_{m,cible} - 90° - \angle G_{BO_v}(j\omega_{cp})$
3. Calculer $\alpha = \frac{1-\sin\phi_{max}}{1+\sin\phi_{max}}$
4. Calculer $T = \frac{1}{\omega_{cp}\sqrt{\alpha}}$
5. Calculer $K = \frac{\omega_{cp}\sqrt{\alpha}}{|G_{BO_v}(j\omega_{cp})|}$

> Les −90° de la formule viennent du terme $K/s$ qui décale la phase d'autant.

---

## 14. Correcteur Lead seul (C1 — boucle position)

La boucle position est déjà de **classe 1** grâce à l'intégrateur cinématique. Pas besoin d'ajouter un intégrateur. Un simple réseau d'avance suffit :

$$C_1(s) = K_p\cdot\frac{Ts+1}{\alpha Ts+1}$$

**Procédure :**

1. Mesurer phase et gain de $G_{BO_p}(j\omega_{cp})$
2. Calculer l'avance requise : $\phi_{max} = \phi_{m,cible} - 180° - \angle G_{BO_p}(j\omega_{cp})$
3. Si $\phi_{max} \leq 0$ : un gain proportionnel $K_p = 1/|G_{BO_p}(j\omega_{cp})|$ suffit
4. Sinon : même formules $\alpha$, $T$, $K_p = \sqrt{\alpha}/|G_{BO_p}(j\omega_{cp})|$

---

## 15. Correcteur intégral pur (C3 — boucle force)

$$C_3(s) = \frac{K_i}{s}$$

La boucle externe contrôle la **force** dans la bande élastique. L'intégrateur assure une erreur statique nulle sur la force. Le gain $K_i$ est calculé pour placer $\omega_{cp}$ à 2.5 rad/s :

$$K_i = \frac{\omega_{cp}}{|G_{sys3}(j\omega_{cp})|}$$

---

## 16. Commande en cascade

**Principe :** imbriquer plusieurs boucles de régulation pour contrôler des grandeurs de nature différente (force, position, vitesse).

**Avantages :**
- Meilleur rejet des perturbations internes
- Chaque variable d'état est régulée indépendamment
- Facilite le réglage (on règle de l'intérieur vers l'extérieur)

**Condition de découplage — séparation des bandes passantes :**

$$\omega_{cp,externe} \leq \frac{\omega_{cp,interne}}{5}$$

**Dans ce projet :**

$$\underbrace{2.5}_{\text{force}} \leq \frac{\underbrace{15}_{\text{position}}}{5} = 3 \quad\checkmark$$
$$\underbrace{15}_{\text{position}} \leq \frac{\underbrace{50}_{\text{vitesse}}}{5} = 10 \quad\approx\checkmark$$
