# Module 03 — Analyse temporelle

> **Objectif :** Caractériser le comportement dynamique du système dans le domaine temporel : réponse indicielle, dépassement, temps de réponse, classe et erreurs statiques.

---

## Notions abordées

- Réponse indicielle en boucle ouverte et boucle fermée
- Indicateurs de performance temporelle (D%, Ts, Tm)
- Classe du système et erreurs statiques
- Théorème de la valeur finale
- Erreur de position, de vitesse (traînage) et d'accélération

---

## 1. Réponse indicielle

La **réponse indicielle** est la sortie $y(t)$ obtenue pour une entrée échelon $u(t) = 1(t)$ :

```math
U(s) = \frac{1}{s} \quad\Rightarrow\quad Y(s) = H(s)\cdot\frac{1}{s}
```

**Valeur finale** (théorème de la valeur finale) :

```math
y(\infty) = \lim_{t\to\infty}y(t) = \lim_{s\to 0}s\cdot Y(s) = H(0)
```

### Indicateurs graphiques

```
y(t)
│          D% = (ymax - y∞)/y∞ × 100%
│    ╭──╮  ←── ymax
│   ╱    ╲
│  ╱      ╲___________  ←── y∞ (valeur finale)
│ ╱         ±5%
│╱
│───────────────────────────────────►  t
0    Tm    Ts
     ↑      ↑
  montée  réponse à 5%
```

| Indicateur | Définition | Formule |
|-----------|-----------|---------|
| **Dépassement** $D\%$ | Écart relatif maximal au-dessus de $y_\infty$ | $D\% = 100\frac{y_{max}-y_\infty}{y_\infty}$ |
| **Temps de montée** $T_m$ | Durée de 10% à 90% de $y_\infty$ | `stepinfo().RiseTime` |
| **Temps de réponse** $T_s$ | Temps pour rester dans ±5% de $y_\infty$ | `stepinfo().SettlingTime` |
| **Valeur finale** $y_\infty$ | Régime permanent | $\lim_{s\to 0}H(s)$ |

**Lien avec la marge de phase :** pour un système du 2ème ordre, $P_m \approx 100\xi$ (en degrés), donc :
- $P_m = 50°$ → $\xi \approx 0.5$ → $D\% \approx 16\%$
- $P_m = 65°$ → $\xi \approx 0.65$ → $D\% \approx 8\%$

---

## 2. Classe du système

La **classe** est le nombre d'intégrateurs $1/s^k$ présents en **boucle ouverte**.

### Erreur statique à un échelon

Pour un système bouclé avec retour unitaire et gain de boucle $G_{BO}(s)$ :

```math
\varepsilon(\infty) = \frac{1}{1 + K_p}
```

avec $K_p = \lim_{s\to 0}G_{BO}(s)$ (gain statique de la boucle ouverte).

| Classe | $G_{BO}(0)$ | Erreur à un échelon | Erreur à une rampe |
|--------|------------|--------------------|--------------------|
| 0 | $K_p$ fini | $\varepsilon = \frac{1}{1+K_p}$ | $\infty$ |
| 1 | $\infty$ (1 intégrateur) | **0** | $\varepsilon = \frac{1}{K_v}$ avec $K_v = \lim_{s\to 0}s\cdot G_{BO}$ |
| 2 | $\infty$ (2 intégrateurs) | **0** | **0** |

### Application au projet

**Boucle vitesse $G_{BO\_v}$ — Classe 0 :**

```math
K_p = G_{BO\_v}(0) = \frac{k_m \cdot U_B}{R_m B_m + k_m k_v} \quad\text{(fini)}
\qquad\Rightarrow\qquad
\varepsilon_{statique} = \frac{1}{1 + K_p} \neq 0
```

→ En l'état, le correcteur de vitesse devra inclure un **intégrateur** pour annuler cette erreur.

**Boucle position $G_{BO\_p}$ — Classe 1 :**

```math
G_{BO\_p}(s) = G_{BO\_v}(s)\cdot\frac{r}{G\cdot s}
\quad\Rightarrow\quad
\varepsilon_{\text{échelon}} = 0
\qquad
\varepsilon_{\text{rampe}} = \frac{1}{K_v}
```

---

## 3. Boucle ouverte vs boucle fermée

Un système **en boucle ouverte** n'a pas de retour d'information. La sortie ne peut pas se corriger.

Un système **en boucle fermée** (retour unitaire) :

```math
T(s) = \frac{G(s)}{1 + G(s)}
```

**La boucle fermée modifie :**
- Les pôles du système (les pôles BF ne sont pas les pôles BO)
- L'erreur statique (selon la classe)
- La bande passante (en général, BF est plus lente que BO)

**Dans MATLAB :**

```matlab
% Boucle ouverte
step(G_BO_p);

% Boucle fermée unitaire
step(feedback(G_BO_p, 1));

% Indicateurs de performance
info = stepinfo(feedback(G_BO_p, 1));
fprintf('Dépassement : %.2f %%\n',  info.Overshoot);
fprintf('Temps de réponse : %.3f s\n', info.SettlingTime);
```

---

## 4. Analyse des boucles ouvertes non corrigées

### Boucle vitesse (Classe 0)

Le gain statique $K_p = G_{BO\_v}(0)$ est fini. En boucle fermée unitaire (sans correcteur), l'erreur à un échelon de vitesse est :

```math
\varepsilon_v = \frac{1}{1 + K_p} \neq 0
```

→ **Conclusion :** il faut ajouter un intégrateur au correcteur de vitesse pour ramener l'erreur à zéro.

### Boucle position (Classe 1)

L'intégrateur $r/(Gs)$ est naturellement présent. En boucle fermée, l'erreur à un échelon de position est **nulle**. Cependant, l'erreur à une rampe (traînage) est :

```math
\varepsilon_{\text{trainage}} = \frac{1}{K_v} = \frac{G\,R_m B_m + G\,k_m k_v}{r\,k_m\,U_B}
```

---

## Script MATLAB associé

→ [03_analyse_temporelle.m](03_analyse_temporelle.m)

