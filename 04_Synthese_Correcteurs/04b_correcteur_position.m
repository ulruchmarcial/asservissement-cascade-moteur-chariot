%% GEI1013 — MODULE 4b : Correcteur C1 — Boucle position (Lead seul)
%
%  NOTIONS ABORDÉES :
%    - Réseau d'avance de phase pour système de CLASSE 1
%    - Différence avec C2 : pas d'intégrateur car boucle déjà classe 1
%    - Cas particulier : si φmax ≤ 0, un gain proportionnel suffit
%    - Validation : Pm, D%, Ts
%
%  BOUCLE POSITION :
%    G_BO_p est de CLASSE 1 (intégrateur cinématique r/Gs inclus)
%    Spécifications : ωcp = 15 rad/s, Pm ≥ 50°
%
%  CORRECTEUR : C1(s) = Kp × (Ts+1)/(αTs+1)   [Lead seul, sans 1/s]

clear; clc; close all;

fprintf('================================================================\n');
fprintf('  GEI1013 - Module 4b : Correcteur position C1 (Lead seul)\n');
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
    G_BO_p = minreal(G_BO_v * (r/(G*tf('s'))));
end

%% -----------------------------------------------------------------------
%  SECTION 1 : RAPPEL — POURQUOI PAS D'INTÉGRATEUR ICI ?
%
%  La boucle position G_BO_p contient DÉJÀ un intégrateur :
%    G_BO_p = G_BO_v × r/(G·s)  ← intégrateur cinématique
%
%  Ajouter un 2ème intégrateur (classe 2) est inutile et déstabiliserait.
%  La phase à -180° est déjà atteinte plus tôt → marges de phase plus petites.
%
%  Pour la boucle position :
%    Phase de C1 à ωcp = 0° (pas de 1/s) + φmax
%    Condition : ∠C1 + ∠G_BO_p = -180° + Pm_cible
%    0° + φmax + phase_val_p = -180° + Pm_cible
%    φmax = Pm_cible - 180° - phase_val_p
% ------------------------------------------------------------------------

fprintf('--- Rappel : classe de G_BO_p ---\n');
fprintf('  G_BO_p contient un intégrateur r/(G·s) → CLASSE 1\n');
fprintf('  Erreur statique nulle à un échelon → pas besoin d''ajouter K/s\n\n');

%% -----------------------------------------------------------------------
%  SECTION 2 : SPÉCIFICATIONS ET ÉVALUATION À ωcp
% ------------------------------------------------------------------------

wcp_p_star   = 15;    % Pulsation de coupure cible [rad/s]
phi_m_p_cible = 50;   % Marge de phase cible [degrés]

[mag_p, phase_p] = bode(G_BO_p, wcp_p_star);
mag_p   = squeeze(mag_p);
phase_p = squeeze(phase_p);

fprintf('--- Spécifications et évaluation à ωcp = %d rad/s ---\n', wcp_p_star);
fprintf('  Pm cible = %d °\n', phi_m_p_cible);
fprintf('  |G_BO_p(j·ωcp)| = %.4e  (= %.2f dB)\n', mag_p, 20*log10(mag_p));
fprintf('  ∠G_BO_p(j·ωcp) = %.2f °\n\n', phase_p);

%% -----------------------------------------------------------------------
%  SECTION 3 : CALCUL DE L'AVANCE REQUISE
%
%  φmax = Pm_cible - 180° - ∠G_BO_p(j·ωcp)
%
%  Note : on soustrait 180° (et non 90° comme pour C2) car la phase de
%  référence pour la stabilité est -180°, et C1 n'a pas de terme 1/s.
%
%  Si φmax ≤ 0 : le système a DÉJÀ assez de marge de phase à ωcp.
%  Un simple gain proportionnel suffit alors.
% ------------------------------------------------------------------------

phi_max_p = phi_m_p_cible - 180 - phase_p;

fprintf('--- Avance de phase requise ---\n');
fprintf('  φmax = Pm_cible - 180° - ∠G_BO_p\n');
fprintf('       = %d° - 180° - (%.2f°)\n', phi_m_p_cible, phase_p);
fprintf('       = %.2f °\n\n', phi_max_p);

%% -----------------------------------------------------------------------
%  SECTION 4 : CALCUL DES PARAMÈTRES DU CORRECTEUR C1(s)
% ------------------------------------------------------------------------

if phi_max_p <= 0
    fprintf('  → φmax ≤ 0 : le système a déjà assez de phase à ωcp.\n');
    fprintf('    Un gain proportionnel P suffit.\n\n');
    alpha_p = 1;
    T_p     = 0;
    K_p     = 1 / mag_p;

    s = tf('s');
    C1_position = K_p;
    fprintf('  C1(s) = Kp = %.4e  (gain pur)\n\n', K_p);
else
    alpha_p = (1 - sind(phi_max_p)) / (1 + sind(phi_max_p));
    T_p     = 1 / (wcp_p_star * sqrt(alpha_p));
    K_p     = sqrt(alpha_p) / mag_p;

    fprintf('  α  = (1-sin(φmax))/(1+sin(φmax)) = %.4f\n', alpha_p);
    fprintf('  T  = 1/(ωcp·√α)                  = %.6e s\n', T_p);
    fprintf('  Kp = √α / |G_BO_p(j·ωcp)|         = %.4e\n\n', K_p);

    s = tf('s');
    C1_position = K_p * (T_p*s + 1) / (alpha_p*T_p*s + 1);
    C1_position = minreal(C1_position);

    wz_p = 1/T_p; wp_p = 1/(alpha_p*T_p);
    fprintf('  Zéro : ωz = %.2f rad/s | Pôle : ωp = %.2f rad/s\n\n', wz_p, wp_p);
end

fprintf('--- Fonction de transfert C1(s) ---\n');
display(C1_position);

%% -----------------------------------------------------------------------
%  SECTION 5 : VALIDATION
% ------------------------------------------------------------------------

L_position = C1_position * G_BO_p;
T_position = feedback(L_position, 1);

[~, Pm_p_new, ~, Wcp_p_new] = margin(L_position);

fprintf('--- Validation après correction ---\n');
fprintf('  Pm obtenue = %.2f °  à ωcp = %.2f rad/s\n', Pm_p_new, Wcp_p_new);
if Pm_p_new >= phi_m_p_cible
    fprintf('  ✓ Spécification Pm ≥ %d° RESPECTÉE\n', phi_m_p_cible);
else
    fprintf('  ✗ Spécification Pm ≥ %d° NON respectée\n', phi_m_p_cible);
end

info_C1 = stepinfo(T_position);
fprintf('\n  Réponse indicielle BF corrigée :\n');
fprintf('    Dépassement       D%%  = %.2f %%\n', info_C1.Overshoot);
fprintf('    Temps de réponse  Ts  = %.4f s  (±5%%)\n\n', info_C1.SettlingTime);

% Figure 1 : Bode BO corrigée position
figure('Name', 'Fig.1 - Bode BO corrigée position', 'NumberTitle', 'off');
margin(L_position);
title('Bode — Boucle ouverte corrigée L_{position} = C_1 \cdot G_{BO\_p}', 'FontSize', 13);
grid on;

% Figure 2 : Réponse indicielle BF position
figure('Name', 'Fig.2 - Réponse indicielle BF position', 'NumberTitle', 'off');
step(T_position, 5);
title('Réponse indicielle BF — Boucle position avec C_1(s)', 'FontSize', 13);
xlabel('Temps [s]'); ylabel('Position normalisée'); grid on;

fprintf('→ Module 4b terminé. Passer à 04c_correcteur_force.m\n');

% Sauvegarder
save('correcteur_position.mat', 'C1_position', 'T_position', 'L_position');
