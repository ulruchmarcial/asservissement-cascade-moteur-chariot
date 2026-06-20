# Module 01 — Modélisation du système

> **Objectif :** Construire les fonctions de transfert du système complet à partir des équations physiques. Comprendre le concept de **blocs internes** et d'**inertie équivalente**.

---

## Notions abordées

- Transformée de Laplace et passage aux fonctions de transfert
- Modèle du convertisseur de puissance (filtre LC du 2ème ordre)
- Modèle du moteur à courant continu (deux équations couplées)
- Inertie équivalente ramenée à l'arbre moteur
- Assemblage par **blocs internes** (couplage convertisseur–moteur)
- Cinématique de la transmission (réducteur + poulie)

---

## 1. Modèle du convertisseur de puissance

Le convertisseur (hacheur + filtre LC) transforme le rapport cyclique $\alpha$ en tension $U_c$.

**Équation différentielle du filtre LC :**

```math
L_f C_f \frac{d^2 U_c}{dt^2} + \frac{L_f}{R_f}\frac{dU_c}{dt} + U_c = U_B \cdot \alpha
```

**En Laplace (conditions initiales nulles) :**

```math
\left(L_f C_f s^2 + \frac{L_f}{R_f}s + 1\right) U_c(s) = U_B \cdot \alpha(s)
```

**Fonction de transfert :**

```math
G_{conv}(s) = \frac{U_c(s)}{\alpha(s)} = \frac{U_B}{L_f C_f s^2 + \dfrac{L_f}{R_f}s + 1}
```

C'est un système du **2ème ordre**, avec :
- Pulsation naturelle : $\omega_n = 1/\sqrt{L_f C_f} \approx 8165$ rad/s
- Facteur d'amortissement : $\xi = (1/2R_f)\sqrt{L_f/C_f} \approx 2\times10^{-4}$ (très faiblement amorti)

**Impédance de sortie** du filtre (chute de tension due au courant moteur) :

```math
Z_{conv}(s) = \frac{L_f \, s}{L_f C_f s^2 + \dfrac{L_f}{R_f}s + 1}
```

---

## 2. Modèle du moteur à courant continu

Le moteur CC est décrit par **deux équations couplées** :

### Équation électrique (circuit de l'induit)

```math
L_m \frac{dI_m}{dt} + R_m I_m = U_c - k_v \,\omega_m
```

En Laplace :

```math
(L_m s + R_m)\, I_m(s) = U_c(s) - k_v\, \Omega_m(s) \qquad (1)
```

### Équation mécanique (bilan des couples)

```math
J_m \frac{d\omega_m}{dt} + B_m \omega_m = k_m \, I_m
```

En Laplace :

```math
(J_m s + B_m)\, \Omega_m(s) = k_m\, I_m(s) \qquad (2)
```

### Résolution du système couplé (1) et (2)

En substituant (2) dans (1), le dénominateur commun est :

```math
\Delta(s) = (L_m s + R_m)(J_m s + B_m) + k_m k_v
```

**Admittance d'entrée** $I_m(s)/U_c(s)$ :

```math
Y_{mot}(s) = \frac{J_m s + B_m}{\Delta(s)}
```

**FT en vitesse angulaire** $\Omega_m(s)/U_c(s)$ :

```math
G_{mot}(s) = \frac{k_m}{\Delta(s)}
```

---

## 3. Inertie équivalente ramenée à l'arbre moteur

La masse $M$ du chariot, transmise par le réducteur (rapport $G$) et la poulie (rayon $r$), est vue par le moteur comme une inertie supplémentaire :

```math
v_{chariot} = \frac{r}{G}\,\omega_m
\quad\Rightarrow\quad
\frac{1}{2}M v_{chariot}^2 = \frac{1}{2}M\!\left(\frac{r}{G}\right)^{\!2}\omega_m^2
```

L'inertie totale équivalente à l'arbre moteur est donc :

```math
J_m = J_r + M\left(\frac{r}{G}\right)^2
    = 1.558\times10^{-4} + 2.5\times\left(\frac{0.125}{20}\right)^2
    \approx 1.656\times10^{-4}\ \text{kg·m}^2
```

> **Interprétation :** le réducteur $G=20$ divise l'effet de la masse par $G^2=400$. La masse $M=2.5$ kg ne contribue qu'à environ 7 % de l'inertie totale vue par le moteur.

---

## 4. Assemblage par blocs internes (couplage convertisseur–moteur)

### Pourquoi pas la mise en série simple ?

Si on mettait $G_{conv}$ et $G_{mot}$ en série, on supposerait que $U_c$ est **indépendante** du courant moteur $I_m$. C'est faux : $I_m$ crée une chute de tension dans l'impédance de sortie $Z_{conv}$.

### Modèle de couplage correct

```
        α      ┌──────────┐       ┌──────────┐
  ──────────►  │  G_conv  │──►────│  G_mot   │──► ωm
               └──────────┘   Uc  └──────────┘
                     ▲               │
                     │  Z_conv       │ Y_mot = Im/Uc
                     └───────────────┘
                      (courant Im affecte Uc)
```

En résolvant la boucle interne :

```math
G_{U_c/\alpha}(s) = \frac{G_{conv}(s)}{1 + Z_{conv}(s)\cdot Y_{mot}(s)}
```

### Fonctions de transfert en boucle ouverte

**Boucle vitesse** (Chariot 2, classe 0) :

```math
G_{BO\_v}(s) = G_{mot}(s)\cdot G_{U_c/\alpha}(s)
```

**Boucle position** (Chariot 1, classe 1) :

```math
G_{BO\_p}(s) = G_{BO\_v}(s)\cdot\frac{r}{G\cdot s}
```

---

## 5. Cinématique de la transmission

La position du chariot est l'intégrale de sa vitesse :

```math
x(t) = \int_0^t \frac{r}{G}\,\omega_m\,d\tau
\quad\xrightarrow{\mathcal{L}}\quad
G_{cin}(s) = \frac{X(s)}{\Omega_m(s)} = \frac{r}{G\cdot s}
```

Ce terme $1/s$ est l'**intégrateur naturel** qui confère à la boucle position sa classe 1.

---

## Script MATLAB associé

→ [01_modelisation.m](01_modelisation.m)
