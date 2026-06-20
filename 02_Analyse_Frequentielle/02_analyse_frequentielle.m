%% GEI1013 — MODULE 2 : Analyse fréquentielle
%
%  NOTIONS ABORDÉES :
%    - Carte des pôles et zéros (plan complexe de Laplace)
%    - Critère de stabilité (pôles à partie réelle < 0)
%    - Amortissement ξ et fréquence naturelle ωn
%    - Diagrammes de Bode (gain en dB et phase en degrés)
%    - Marge de phase Pm (à ωcp) et marge de gain Gm (à ωcg)
%    - Lieu des racines (trajectoire des pôles BF vs gain)
%
%  PRÉREQUIS : Exécuter 01_Modelisation_Systeme/01_modelisation.m d'abord
%              (ou charger modele_systeme.mat)

clear; clc; close all;

fprintf('================================================================\n');
fprintf('  GEI1013 - Module 2 : Analyse fréquentielle\n');
fprintf('================================================================\n\n');

%% -----------------------------------------------------------------------
%  CHARGEMENT DU MODÈLE (depuis le Module 1)
% ------------------------------------------------------------------------
if exist('../01_Modelisation_Systeme/modele_systeme.mat', 'file')
    load('../01_Modelisation_Systeme/modele_systeme.mat');
    fprintf('Modèle chargé depuis modele_systeme.mat\n\n');
else
    % Re-dériver si le fichier n'existe pas
    fprintf('Dérivation du modèle en ligne...\n');
    uB=24; Lm=1.577e-3; Rm=1.3; km=0.0742; kv=0.0742;
    Jr=1.558e-4; M=2.5; G=20; r=0.125; Bm=0.0015;
    Cf=300e-6; Lf=50e-6; Rf=100e3; k_elas=50;
    Jm = Jr + M*(r^2)/(G^2);
    s  = tf('s');
    den_filtre = Lf*Cf*s^2 + (Lf/Rf)*s + 1;
    G_conv = uB/den_filtre; Z_conv = (Lf*s)/den_filtre;
    den_mot = (Lm*s+Rm)*(Jm*s+Bm) + km*kv;
    Y_mot = (Jm*s+Bm)/den_mot; G_mot = km/den_mot;
    G_Uc_alpha = minreal(G_conv/(1+Z_conv*Y_mot));
    G_BO_v = minreal(G_mot*G_Uc_alpha);
    G_cinematique = r/(G*s);
    G_BO_p = minreal(G_BO_v*G_cinematique);
end

%% -----------------------------------------------------------------------
%  SECTION 1 : CARTE DES PÔLES ET ZÉROS
%
%  Les pôles sont les racines du dénominateur de H(s).
%  Critère de stabilité BIBO : tous les pôles doivent avoir Re(p) < 0.
%
%  Interprétation :
%    - Pôle réel p = -a        → exponentielle e^(-at) décroissante
%    - Pôles complexes p = -σ±jωd → oscillations amorties e^(-σt)·cos(ωd·t)
%    - |σ| grand = amortissement rapide ; ωd grand = oscillations rapides
% ------------------------------------------------------------------------

fprintf('--- Carte des pôles et zéros ---\n\n');

fprintf('Pôles de G_BO_v (boucle vitesse) :\n');
p_v = pole(G_BO_v);
for k = 1:length(p_v)
    if imag(p_v(k)) >= 0
        signe = '+'; absim = imag(p_v(k));
        if abs(imag(p_v(k))) < 1e-6
            fprintf('  p%d = %+.4f         (pôle réel)\n', k, real(p_v(k)));
        else
            fprintf('  p%d = %+.4f %+.4fj  (paire complexe conjuguée)\n', k, real(p_v(k)), imag(p_v(k)));
        end
    end
end

fprintf('\nPôles de G_BO_p (boucle position) :\n');
p_p = pole(G_BO_p);
for k = 1:length(p_p)
    if imag(p_p(k)) >= 0
        if abs(imag(p_p(k))) < 1e-6
            fprintf('  p%d = %+.4f         (pôle réel)\n', k, real(p_p(k)));
        else
            fprintf('  p%d = %+.4f %+.4fj  (paire complexe conjuguée)\n', k, real(p_p(k)), imag(p_p(k)));
        end
    end
end
fprintf('\n');

% Figure 1 : Carte pôles-zéros vitesse
figure('Name', 'Fig.1 - Carte poles-zeros : Boucle vitesse G_BO_v', 'NumberTitle', 'off');
pzmap(G_BO_v);
title('Carte pôles-zéros — G_{BO\_v} (boucle vitesse)', 'FontSize', 13);
grid on;
xlabel('Partie réelle'); ylabel('Partie imaginaire');
legend({'Pôles (×)', 'Zéros (○)'}, 'Location', 'best');

% Figure 2 : Carte pôles-zéros position
figure('Name', 'Fig.2 - Carte poles-zeros : Boucle position G_BO_p', 'NumberTitle', 'off');
pzmap(G_BO_p);
title('Carte pôles-zéros — G_{BO\_p} (boucle position)', 'FontSize', 13);
grid on;
xlabel('Partie réelle'); ylabel('Partie imaginaire');

%% -----------------------------------------------------------------------
%  SECTION 2 : AMORTISSEMENT ET FRÉQUENCE NATURELLE
%
%  Pour chaque paire de pôles complexes conjugués p = -σ ± jωd :
%    ωn = √(σ² + ωd²)    [fréquence naturelle non amortie]
%    ξ  = σ/ωn           [facteur d'amortissement]
%
%  ξ > 1   → sur-amorti    (pas de dépassement)
%  ξ = 1   → critique
%  0 < ξ <1 → sous-amorti (oscillations amorties)
%  ξ = 0   → non amorti   (oscillations entretenues)
% ------------------------------------------------------------------------

fprintf('--- Amortissement des boucles ouvertes ---\n\n');
fprintf('Chariot 2 — Boucle vitesse G_BO_v :\n');
damp(G_BO_v);

fprintf('\nChariot 1 — Boucle position G_BO_p :\n');
damp(G_BO_p);
fprintf('\n');

%% -----------------------------------------------------------------------
%  SECTION 3 : DIAGRAMMES DE BODE
%
%  Le diagramme de Bode représente la réponse fréquentielle H(jω) :
%    - Gain :  |H(jω)| en dB = 20·log10(|H(jω)|)
%    - Phase : ∠H(jω) en degrés
%
%  Comment lire les marges :
%    → ωcp (crossover freq) : fréquence où gain = 0 dB
%    → ωcg (gain crossover)  : fréquence où phase = -180°
%    → Pm  = 180° + phase(jωcp)    [marge de PHASE]
%    → Gm  = -20·log10|G(jωcg)|   [marge de GAIN en dB]
% ------------------------------------------------------------------------

% Figure 3 : Bode avec marges — boucle vitesse
figure('Name', 'Fig.3 - Bode + marges : G_BO_v', 'NumberTitle', 'off');
margin(G_BO_v);
title('Bode + Marges de stabilité — G_{BO\_v} (vitesse, non corrigé)', 'FontSize', 13);
grid on;

% Figure 4 : Bode avec marges — boucle position
figure('Name', 'Fig.4 - Bode + marges : G_BO_p', 'NumberTitle', 'off');
margin(G_BO_p);
title('Bode + Marges de stabilité — G_{BO\_p} (position, non corrigé)', 'FontSize', 13);
grid on;

%% -----------------------------------------------------------------------
%  SECTION 4 : CALCUL NUMÉRIQUE DES MARGES DE STABILITÉ
%
%  margin(G) retourne :
%    Gm  : marge de gain (rapport linéaire, pas en dB)
%    Pm  : marge de phase [degrés]
%    Wcg : pulsation de croisement de phase [rad/s]
%    Wcp : pulsation de coupure à 0 dB [rad/s]
% ------------------------------------------------------------------------

fprintf('================================================================\n');
fprintf('  RÉSULTATS : Marges de stabilité (boucle ouverte non corrigée)\n');
fprintf('================================================================\n\n');

[Gm_v, Pm_v, Wcg_v, Wcp_v] = margin(G_BO_v);
fprintf('G_BO_v — Boucle vitesse (Chariot 2) :\n');
fprintf('  Marge de phase  Pm  = %.2f °    à ωcp = %.2f rad/s\n', Pm_v, Wcp_v);
if isfinite(Gm_v) && Gm_v > 0
    fprintf('  Marge de gain   Gm  = %.2f dB   à ωcg = %.2f rad/s\n', 20*log10(Gm_v), Wcg_v);
else
    fprintf('  Marge de gain   Gm  = ∞  (phase ne croise pas -180°)\n');
end

[Gm_p, Pm_p, Wcg_p, Wcp_p] = margin(G_BO_p);
fprintf('\nG_BO_p — Boucle position (Chariot 1) :\n');
fprintf('  Marge de phase  Pm  = %.2f °    à ωcp = %.2f rad/s\n', Pm_p, Wcp_p);
if isfinite(Gm_p) && Gm_p > 0
    fprintf('  Marge de gain   Gm  = %.2f dB   à ωcg = %.2f rad/s\n', 20*log10(Gm_p), Wcg_p);
else
    fprintf('  Marge de gain   Gm  = ∞\n');
end

fprintf('\n  ⚠ Critères visés dans le projet : Pm ≥ 50°, Gm ≥ 6 dB\n');
if Pm_v < 50
    fprintf('  → La boucle vitesse NÉCESSITE un correcteur (Pm = %.1f° < 50°)\n', Pm_v);
end
if Pm_p < 50
    fprintf('  → La boucle position NÉCESSITE un correcteur (Pm = %.1f° < 50°)\n', Pm_p);
end

%% -----------------------------------------------------------------------
%  SECTION 5 : LIEU DES RACINES
%
%  Le lieu des racines montre la trajectoire des pôles en boucle fermée
%  T(s) = K·G(s)/(1 + K·G(s))  quand K varie de 0 à +∞.
%
%  - À K=0 : pôles BF = pôles BO
%  - À K→∞ : pôles BF → zéros BO (ou ±∞ selon les asymptotes)
%
%  Utile pour voir si une simple augmentation de gain peut destabiliser.
% ------------------------------------------------------------------------

% Figure 5 : Lieu des racines — boucle vitesse
figure('Name', 'Fig.5 - Lieu des racines : G_BO_v', 'NumberTitle', 'off');
rlocus(G_BO_v);
title('Lieu des racines — G_{BO\_v} (boucle vitesse)', 'FontSize', 13);
grid on;

% Figure 6 : Lieu des racines — boucle position
figure('Name', 'Fig.6 - Lieu des racines : G_BO_p', 'NumberTitle', 'off');
rlocus(G_BO_p);
title('Lieu des racines — G_{BO\_p} (boucle position)', 'FontSize', 13);
grid on;

fprintf('\n→ Module 2 terminé.\n');
fprintf('→ Passer au Module 3 (analyse temporelle) ou au Module 4 (synthèse).\n');
