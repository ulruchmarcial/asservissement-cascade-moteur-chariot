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

$$L_f C_f \frac{d^2 U_c}{dt^2} + \frac{L_f}{R_f}\frac{dU_c}{dt} + U_c = U_B \cdot \alpha$$

**En Laplace (conditions initiales nulles) :**

$$\left(L_f C_f s^2 + \frac{L_f}{R_f}s + 1\right) U_c(s) = U_B \cdot \alpha(s)$$

**Fonction de transfert :**

$$\boxed{G_{conv}(s) = \frac{U_c(s)}{\alpha(s)} = \frac{U_B}{L_f C_f s^2 + \frac{L_f}{R_f}s + 1}}$$

C'est un système du **2ème ordre**, avec :
- Pulsation naturelle : $\omega_n = \frac{1}{\sqrt{L_f C_f}} = \frac{1}{\sqrt{50\times10^{-6}\times300\times10^{-6}}} \approx 8165\ \text{rad/s}$
- Facteur d'amortissement : $\xi = \frac{1}{2R_f}\sqrt{\frac{L_f}{C_f}} \approx 2\times10^{-4}$ (très faiblement amorti)

**Impédance de sortie** (tension aux bornes du moteur due au courant moteur) :

$$Z_{conv}(s) = \frac{L_f s}{L_f C_f s^2 + \frac{L_f}{R_f}s + 1}$$

---

## 2. Modèle du moteur à courant continu

Le moteur CC est décrit par **deux équations couplées** :

### Équation électrique (circuit de l'induit)

$$L_m \frac{dI_m}{dt} + R_m I_m = U_c - k_v \omega_m$$

En Laplace :

$$(L_m s + R_m)\, I_m(s) = U_c(s) - k_v\, \Omega_m(s) \tag{1}$$

### Équation mécanique (bilan des couples)

$$J_m \frac{d\omega_m}{dt} + B_m \omega_m = k_m I_m$$

En Laplace :

$$(J_m s + B_m)\, \Omega_m(s) = k_m\, I_m(s) \tag{2}$$

### Résolution du système couplé (1) et (2)

On substitue (2) dans (1) :

$$\text{Dénominateur commun : } \Delta(s) = (L_m s + R_m)(J_m s + B_m) + k_m k_v$$

**Admittance d'entrée** (courant moteur / tension) :

$$Y_{mot}(s) = \frac{I_m(s)}{U_c(s)} = \frac{J_m s + B_m}{\Delta(s)}$$

**FT en vitesse angulaire** :

$$\boxed{G_{mot}(s) = \frac{\Omega_m(s)}{U_c(s)} = \frac{k_m}{\Delta(s)}}$$

---

## 3. Inertie équivalente ramenée à l'arbre moteur

La masse $M$ du chariot est vue par le moteur comme une inertie supplémentaire. En appliquant la conservation de l'énergie à travers le réducteur (rapport $G$) et la poulie (rayon $r$) :

$$v_{chariot} = \frac{r}{G}\,\omega_m \quad\Rightarrow\quad \frac{1}{2}Mv_{chariot}^2 = \frac{1}{2}M\left(\frac{r}{G}\right)^2\omega_m^2$$

L'inertie équivalente du chariot vue de l'arbre moteur est $M(r/G)^2$. Donc :

$$\boxed{J_m = J_r + M\left(\frac{r}{G}\right)^2 = 1.558\times10^{-4} + 2.5\times\left(\frac{0.125}{20}\right)^2 \approx 1.656\times10^{-4}\ \text{kg·m}^2}$$

> **Interprétation :** le rapport de réduction $G=20$ divise l'effet de la masse par $G^2=400$. La masse $M=2.5$ kg ne contribue que comme $\approx 9.8\times10^{-6}$ kg·m², soit moins de 7% de l'inertie totale.

---

## 4. Assemblage par blocs internes (couplage convertisseur–moteur)

### Pourquoi pas la mise en série simple ?

Si on mettait $G_{conv}$ et $G_{mot}$ en série, on supposerait que la tension $U_c$ est **indépendante** du courant moteur $I_m$. C'est une hypothèse erronée : $I_m$ provoque une chute de tension dans l'impédance de sortie du filtre $Z_{conv}$.

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

En résolvant la boucle interne (retour de $I_m$ sur $U_c$) :

$$\boxed{G_{U_c/\alpha}(s) = \frac{G_{conv}(s)}{1 + Z_{conv}(s)\cdot Y_{mot}(s)}}$$

### FT en vitesse (boucle ouverte — Chariot 2)

$$G_{BO\_v}(s) = G_{mot}(s)\cdot G_{U_c/\alpha}(s)$$

C'est le système de **classe 0** (pas d'intégrateur) vu depuis la boucle vitesse.

---

## 5. Cinématique de la transmission

La vitesse linéaire du chariot et sa position sont reliées à la vitesse angulaire moteur par :

$$v_{chariot}(t) = \frac{r}{G}\,\omega_m(t) \qquad x(t) = \int_0^t v\,d\tau$$

En Laplace, l'intégrateur temporel devient $1/s$ :

$$\boxed{G_{cin}(s) = \frac{X(s)}{\Omega_m(s)} = \frac{r}{G\cdot s}}$$

**FT en position (boucle ouverte — Chariot 1) :**

$$G_{BO\_p}(s) = G_{BO\_v}(s)\cdot\frac{r}{G\cdot s}$$

Ce système est de **classe 1** (un intégrateur naturel dû à la cinématique $1/s$).

---

## Script MATLAB associé

→ [01_modelisation.m](01_modelisation.m)

Le script démontre pas à pas chaque étape ci-dessus et affiche les FT sous forme factorisée (pôles/zéros/gain).

---

## Questions de révision

1. Pourquoi le couplage $G_{conv}/(1 + Z_{conv}\cdot Y_{mot})$ est-il plus précis que la simple mise en série ?
2. Quelle serait la valeur de $J_m$ si le rapport de réduction passait de 20 à 5 ? Quel effet aurait-on sur la dynamique du moteur ?
3. Quel est l'ordre (en $s$) de $G_{BO\_v}(s)$ ? Et de $G_{BO\_p}(s)$ ? Comment l'expliquer ?
4. Pourquoi $k_m = k_v$ en unités SI alors qu'ils semblent représenter des grandeurs différentes (force vs vitesse) ?
