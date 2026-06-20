%% GEI1013 — MODULE 4a : Correcteur C2 — Boucle vitesse (I + Avance de phase)
%
%  NOTIONS ABORDÉES :
%    - Méthode de Bode pour la synthèse d'un correcteur
%    - Réseau d'avance de phase : rôle, formules de α, T, K
%    - Action intégrale : élimination de l'erreur statique, effet sur la phase
%    - Correcteur I + Avance : combinaison des deux
%    - Validation en boucle fermée : marges, D%, Ts
%
%  BOUCLE VITESSE :
%    Plante G_BO_v de CLASSE 0 → erreur statique ≠ 0 sans intégrateur
%    Spécifications : ωcp = 50 rad/s, Pm ≥ 50°
%
%  CORRECTEUR : C2(s) = (K/s) × (Ts+1)/(αTs+1)
%                         ←I→     ←Lead→

clear; clc; close all;

fprintf('================================================================\n');
fprintf('  GEI1013 - Module 4a : Correcteur vitesse C2 (I + Avance)\n');
fprintf('================================================================\n\n');

%% CHARGEMENT DU MODÈLE
if exist('../01_Modelisation_Systeme/modele_systeme.mat', 'file')
    load('../01_Modelisation_Systeme/modele_systeme.mat');
else
    uB=24; Lm=1.577e-3; Rm=1.3; km=0.0742; kv=0.0742;
    Jr=1.558e-4; M=2.5; G=20; r=0.125; Bm=0.0015;
    Cf=300e-6; Lf=50e-6; Rf=100e3;
    Jm = Jr + M*(r^2)/(G^2);
    s  = tf('s');
    den_filtre = Lf*Cf*s^2 + (Lf/Rf)*s + 1;
    G_conv = uB/den_filtre; Z_conv = (Lf*s)/den_filtre;
    den_mot = (Lm*s+Rm)*(Jm*s+Bm) + km*kv;
    Y_mot = (Jm*s+Bm)/den_mot; G_mot = km/den_mot;
    G_Uc_alpha = minreal(G_conv/(1+Z_conv*Y_mot));
    G_BO_v = minreal(G_mot*G_Uc_alpha);
end

%% -----------------------------------------------------------------------
%  SECTION 1 : SPÉCIFICATIONS DE CONCEPTION
% ------------------------------------------------------------------------

wcp_star   = 50;    % Pulsation de coupure cible [rad/s]
phi_m_cible = 50;   % Marge de phase cible [degrés]

fprintf('--- Spécifications de la boucle vitesse ---\n');
fprintf('  ωcp cible  = %d rad/s\n', wcp_star);
fprintf('  Pm cible   = %d °\n\n', phi_m_cible);

%% -----------------------------------------------------------------------
%  SECTION 2 : ÉVALUATION DU SYSTÈME NON CORRIGÉ À ωcp
%
%  On évalue G_BO_v(j·ωcp) pour mesurer :
%    - Le gain |G_BO_v(j·ωcp)| → à annuler par le gain du correcteur
%    - La phase ∠G_BO_v(j·ωcp) → à comparer à la phase requise
%
%  La fonction bode(sys, ω) retourne [magnitude_linéaire, phase_degrés].
% ------------------------------------------------------------------------

[mag_val, phase_val] = bode(G_BO_v, wcp_star);
mag_val   = squeeze(mag_val);    % valeur scalaire de |G_BO_v(j·ωcp)|
phase_val = squeeze(phase_val);  % valeur scalaire de ∠G_BO_v(j·ωcp) [°]

fprintf('--- Évaluation à ωcp = %d rad/s ---\n', wcp_star);
fprintf('  |G_BO_v(j·ωcp)| = %.4e  (= %.2f dB)\n', mag_val, 20*log10(mag_val));
fprintf('  ∠G_BO_v(j·ωcp) = %.2f °\n\n', phase_val);

%% -----------------------------------------------------------------------
%  SECTION 3 : CALCUL DE L'AVANCE DE PHASE REQUISE
%
%  Le correcteur C2(s) = K/s × Lead(s) apporte à ωcp :
%    Phase de C2 = -90° (intégrateur) + φmax (réseau d'avance)
%
%  Pour que la phase totale de la BO corrigée L = C2·G_BO_v soit :
%    ∠L(j·ωcp) = -180° + Pm_cible
%  Il faut :
%    ∠C2 + ∠G_BO_v = -180° + Pm_cible
%    (-90° + φmax) + phase_val = -180° + Pm_cible
%    φmax = Pm_cible - 90° - phase_val
% ------------------------------------------------------------------------

phi_max = phi_m_cible - 90 - phase_val;

fprintf('--- Avance de phase requise ---\n');
fprintf('  φmax = Pm_cible - 90° - ∠G_BO_v\n');
fprintf('       = %d° - 90° - (%.2f°)\n', phi_m_cible, phase_val);
fprintf('       = %.2f °\n\n', phi_max);

if phi_max > 65
    warning('φmax > 65° → α trop petit → amplification excessive du bruit haute fréquence !');
    fprintf('  ⚠ Envisager d''augmenter Pm_cible ou de réduire ωcp.\n\n');
end

%% -----------------------------------------------------------------------
%  SECTION 4 : CALCUL DES PARAMÈTRES DU RÉSEAU D'AVANCE
%
%  Réseau d'avance : (Ts+1)/(αTs+1),  avec 0 < α < 1
%
%  Phase maximale apportée à ωmax = 1/(T√α) :
%    φmax = arcsin((1-α)/(1+α))
%    → α = (1 - sin(φmax)) / (1 + sin(φmax))
%
%  On place ωmax = ωcp :
%    T = 1/(ωcp·√α)
%
%  Gain du correcteur I+Lead à ωcp (pour avoir |L(j·ωcp)| = 1) :
%    |C2(j·ωcp)| = K/ωcp × 1/√α
%    K × 1/(ωcp·√α) × |G_BO_v(j·ωcp)| = 1
%    K = ωcp·√α / |G_BO_v(j·ωcp)|
% ------------------------------------------------------------------------

alpha = (1 - sind(phi_max)) / (1 + sind(phi_max));
T     = 1 / (wcp_star * sqrt(alpha));
K     = wcp_star * sqrt(alpha) / mag_val;

fprintf('--- Paramètres du correcteur C2(s) ---\n');
fprintf('  α = (1-sin(φmax))/(1+sin(φmax)) = %.4f\n', alpha);
fprintf('  T = 1/(ωcp·√α)                  = %.6e s\n', T);
fprintf('  K = ωcp·√α / |G_BO_v(j·ωcp)|   = %.4e\n\n', K);

% Vérification : fréquence du zéro et du pôle du Lead
wz = 1/T;
wp = 1/(alpha*T);
fprintf('  Zéro du Lead    ωz = 1/T        = %.2f rad/s\n', wz);
fprintf('  Pôle du Lead    ωp = 1/(αT)     = %.2f rad/s\n', wp);
fprintf('  Centre géom.    √(ωz·ωp)       = %.2f rad/s  (≈ ωcp = %d)\n\n', sqrt(wz*wp), wcp_star);

%% -----------------------------------------------------------------------
%  SECTION 5 : CONSTRUCTION DE C2(s) ET VALIDATION
%
%  C2(s) = K/s × (Ts+1)/(αTs+1)
% ------------------------------------------------------------------------

s = tf('s');
C2_vitesse = (K / s) * (T*s + 1) / (alpha*T*s + 1);
C2_vitesse = minreal(C2_vitesse);

fprintf('--- Fonction de transfert du correcteur C2(s) ---\n');
display(C2_vitesse);

% Boucle ouverte corrigée
L_vitesse = C2_vitesse * G_BO_v;
L_vitesse = minreal(L_vitesse);

% Boucle fermée corrigée
T_vitesse = feedback(L_vitesse, 1);

%% -----------------------------------------------------------------------
%  SECTION 6 : VALIDATION DES PERFORMANCES
% ------------------------------------------------------------------------

[~, Pm_new, ~, Wcp_new] = margin(L_vitesse);

fprintf('--- Validation après correction ---\n');
fprintf('  Pm obtenue = %.2f °  à ωcp = %.2f rad/s\n', Pm_new, Wcp_new);
if Pm_new >= phi_m_cible
    fprintf('  ✓ Spécification Pm ≥ %d° RESPECTÉE\n', phi_m_cible);
else
    fprintf('  ✗ Spécification Pm ≥ %d° NON respectée\n', phi_m_cible);
end

info_C2 = stepinfo(T_vitesse);
fprintf('\n  Réponse indicielle BF corrigée :\n');
fprintf('    Dépassement       D%%  = %.2f %%\n', info_C2.Overshoot);
fprintf('    Temps de réponse  Ts  = %.4f s  (±5%%)\n', info_C2.SettlingTime);

% Figure 1 : Bode BO corrigée
figure('Name', 'Fig.1 - Bode BO corrigée vitesse', 'NumberTitle', 'off');
margin(L_vitesse);
title('Bode — Boucle ouverte corrigée L_{vitesse} = C_2 \cdot G_{BO\_v}', 'FontSize', 13);
grid on;

% Figure 2 : Réponse indicielle BF corrigée
figure('Name', 'Fig.2 - Réponse indicielle BF vitesse', 'NumberTitle', 'off');
step(T_vitesse, 1);
title('Réponse indicielle BF — Boucle vitesse avec C_2(s)', 'FontSize', 13);
xlabel('Temps [s]'); ylabel('Vitesse normalisée'); grid on;

fprintf('\n→ Module 4a terminé. Passer à 04b_correcteur_position.m\n');

% Sauvegarder pour les modules suivants
save('correcteur_vitesse.mat', 'C2_vitesse', 'T_vitesse', 'L_vitesse');
