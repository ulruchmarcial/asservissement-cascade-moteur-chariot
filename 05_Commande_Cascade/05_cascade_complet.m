%% GEI1013 — MODULE 5 : Commande en cascade — Assemblage des 3 boucles
%
%  NOTIONS ABORDÉES :
%    - Architecture de commande en cascade (multi-boucle imbriquée)
%    - Séparation des bandes passantes (règle des ×5)
%    - Construction progressive : vitesse → position → force
%    - Validation globale des performances
%    - Visualisation de la réponse de chaque boucle fermée
%
%  ARCHITECTURE :
%    Fréf → [C3:I] → xréf → [C1:Lead] → αréf → [C2:I+Lead] → MOTEUR → x → F
%     Force (2.5 r/s)   Position (15 r/s)       Vitesse (50 r/s)
%
%  PRÉREQUIS : Modules 01 à 04

clear; clc; close all;

fprintf('================================================================\n');
fprintf('  GEI1013 - Module 5 : Commande en cascade (3 boucles)\n');
fprintf('================================================================\n\n');

%% -----------------------------------------------------------------------
%  SECTION 1 : CHARGEMENT OU RE-DÉRIVATION DE TOUT LE SYSTÈME
% ------------------------------------------------------------------------

if exist('../01_Modelisation_Systeme/modele_systeme.mat','file') && ...
   exist('../04_Synthese_Correcteurs/correcteur_vitesse.mat','file') && ...
   exist('../04_Synthese_Correcteurs/correcteur_position.mat','file') && ...
   exist('../04_Synthese_Correcteurs/correcteur_force.mat','file')

    load('../01_Modelisation_Systeme/modele_systeme.mat');
    load('../04_Synthese_Correcteurs/correcteur_vitesse.mat');
    load('../04_Synthese_Correcteurs/correcteur_position.mat');
    load('../04_Synthese_Correcteurs/correcteur_force.mat');
    fprintf('Tous les modèles chargés depuis les fichiers .mat\n\n');

else
    fprintf('Re-dérivation complète du système...\n\n');

    % --- Paramètres ---
    uB=24; Lm=1.577e-3; Rm=1.3; km=0.0742; kv=0.0742;
    Jr=1.558e-4; M=2.5; G=20; r=0.125; Bm=0.0015;
    Cf=300e-6; Lf=50e-6; Rf=100e3; k_elas=50;
    Jm = Jr + M*(r^2)/(G^2);
    s  = tf('s');

    % --- Modèle ---
    den_filtre = Lf*Cf*s^2 + (Lf/Rf)*s + 1;
    G_conv = uB/den_filtre; Z_conv = (Lf*s)/den_filtre;
    den_mot = (Lm*s+Rm)*(Jm*s+Bm) + km*kv;
    Y_mot = (Jm*s+Bm)/den_mot; G_mot = km/den_mot;
    G_Uc_alpha = minreal(G_conv/(1+Z_conv*Y_mot));
    G_BO_v = minreal(G_mot*G_Uc_alpha);
    G_cinematique = r/(G*s);
    G_BO_p = minreal(G_BO_v*G_cinematique);

    % --- C2 : Vitesse (I + Lead) ---
    wcp_v=50; phi_m_v=50;
    [mv, pv] = bode(G_BO_v, wcp_v); mv=squeeze(mv); pv=squeeze(pv);
    phi_max_v = phi_m_v - 90 - pv;
    alpha_v=(1-sind(phi_max_v))/(1+sind(phi_max_v));
    T_v=1/(wcp_v*sqrt(alpha_v)); K_v=wcp_v*sqrt(alpha_v)/mv;
    C2_vitesse = minreal((K_v/s)*(T_v*s+1)/(alpha_v*T_v*s+1));

    % --- C1 : Position (Lead) ---
    wcp_p=15; phi_m_p=50;
    [mp, pp] = bode(G_BO_p, wcp_p); mp=squeeze(mp); pp=squeeze(pp);
    phi_max_p = phi_m_p - 180 - pp;
    if phi_max_p <= 0
        C1_position = 1/mp;
    else
        alpha_p=(1-sind(phi_max_p))/(1+sind(phi_max_p));
        T_p=1/(wcp_p*sqrt(alpha_p)); K_p=sqrt(alpha_p)/mp;
        C1_position = minreal(K_p*(T_p*s+1)/(alpha_p*T_p*s+1));
    end

    % Boucle vitesse BF
    L_vitesse  = minreal(C2_vitesse * G_BO_v);
    T_vitesse  = feedback(L_vitesse, 1);

    % Boucle position BF
    G_pos_sys  = minreal(T_vitesse * G_cinematique);
    L_position = minreal(C1_position * G_pos_sys);
    T_position = feedback(L_position, 1);

    % --- C3 : Force (Intégrateur) ---
    wcp3=2.5;
    G_sys3 = minreal(k_elas * T_position);
    [m3, ~] = bode(G_sys3, wcp3); m3=squeeze(m3);
    K_i = wcp3/m3;
    C3_force = K_i/s;
    L_force  = minreal(C3_force * G_sys3);
    T_force  = feedback(L_force, 1);
end

%% -----------------------------------------------------------------------
%  SECTION 2 : VÉRIFICATION DE LA SÉPARATION DES BANDES PASSANTES
%
%  Règle de la cascade : ωcp_externe ≤ ωcp_interne / 5
%
%  Si les bandes passantes sont trop proches, les boucles s'influencent
%  mutuellement et le réglage n'est plus valide.
% ------------------------------------------------------------------------

fprintf('================================================================\n');
fprintf('  Vérification de la séparation des bandes passantes\n');
fprintf('================================================================\n\n');

[~, Pm_v_val, ~, Wcp_v_val] = margin(L_vitesse);
[~, Pm_p_val, ~, Wcp_p_val] = margin(L_position);
[~, Pm_f_val, ~, Wcp_f_val] = margin(L_force);

fprintf('  Boucle vitesse  : ωcp = %6.2f rad/s | Pm = %.1f °\n', Wcp_v_val, Pm_v_val);
fprintf('  Boucle position : ωcp = %6.2f rad/s | Pm = %.1f °\n', Wcp_p_val, Pm_p_val);
fprintf('  Boucle force    : ωcp = %6.2f rad/s | Pm = %.1f °\n\n', Wcp_f_val, Pm_f_val);

ratio_vp = Wcp_v_val / Wcp_p_val;
ratio_pf = Wcp_p_val / Wcp_f_val;

fprintf('  Rapport ωcp_v / ωcp_p = %.1f  (recommandé ≥ 5) %s\n', ...
    ratio_vp, char('✓'*(ratio_vp>=5) + '⚠'*(ratio_vp<5)));
fprintf('  Rapport ωcp_p / ωcp_f = %.1f  (recommandé ≥ 5) %s\n\n', ...
    ratio_pf, char('✓'*(ratio_pf>=5) + '⚠'*(ratio_pf<5)));

%% -----------------------------------------------------------------------
%  SECTION 3 : PERFORMANCES DE CHAQUE BOUCLE FERMÉE
% ------------------------------------------------------------------------

fprintf('================================================================\n');
fprintf('  Performances des boucles fermées\n');
fprintf('================================================================\n\n');

loops = {T_vitesse, T_position, T_force};
noms  = {'Vitesse (C2)',  'Position (C1)', 'Force (C3)'};

for k = 1:3
    info = stepinfo(loops{k});
    fprintf('  %s :\n', noms{k});
    fprintf('    Dépassement       D%%  = %.2f %%\n',  info.Overshoot);
    fprintf('    Temps de montée   Tm  = %.4f s\n',   info.RiseTime);
    fprintf('    Temps de réponse  Ts  = %.4f s\n\n', info.SettlingTime);
end

%% -----------------------------------------------------------------------
%  SECTION 4 : VISUALISATIONS
% ------------------------------------------------------------------------

% Figure 1 : Bode des 3 boucles ouvertes corrigées
figure('Name', 'Fig.1 - Bode des 3 boucles ouvertes corrigées', 'NumberTitle', 'off');
subplot(2,1,1);
semilogx(frspecs(L_vitesse)); hold on;
title('Gain des 3 boucles ouvertes corrigées', 'FontSize', 13);
legend('L_{vitesse}'); grid on;

% Bode séparé
figure('Name', 'Fig.2 - Bode Boucle Vitesse corrigée', 'NumberTitle', 'off');
margin(L_vitesse);
title('Bode — L_{vitesse} = C_2 \cdot G_{BO\_v} (corrigée)', 'FontSize', 13);
grid on;

figure('Name', 'Fig.3 - Bode Boucle Position corrigée', 'NumberTitle', 'off');
margin(L_position);
title('Bode — L_{position} = C_1 \cdot G_{BO\_p\_sys} (corrigée)', 'FontSize', 13);
grid on;

figure('Name', 'Fig.4 - Bode Boucle Force corrigée', 'NumberTitle', 'off');
margin(L_force);
title('Bode — L_{force} = C_3 \cdot G_{sys3} (corrigée)', 'FontSize', 13);
grid on;

% Figure 5 : Réponses indicielle des 3 BF
figure('Name', 'Fig.5 - Réponses indicielles des 3 BF', 'NumberTitle', 'off');

subplot(3,1,1);
step(T_vitesse, 1); title('BF Vitesse (C_2)'); grid on;
ylabel('Vitesse normalisée');

subplot(3,1,2);
step(T_position, 5); title('BF Position (C_1)'); grid on;
ylabel('Position normalisée');

subplot(3,1,3);
step(T_force, 20); title('BF Force (C_3)'); grid on;
ylabel('Force normalisée'); xlabel('Temps [s]');

sgtitle('Réponses indicielles — Commande en cascade à 3 boucles', 'FontSize', 14);

fprintf('================================================================\n');
fprintf('  SYNTHÈSE FINALE DE LA CASCADE\n');
fprintf('================================================================\n\n');
fprintf('  Bandes passantes (rad/s)   :  %.1f  →  %.1f  →  %.1f\n', ...
    Wcp_f_val, Wcp_p_val, Wcp_v_val);
fprintf('  Marges de phase (degrés)   :  %.1f°    %.1f°    %.1f°\n\n', ...
    Pm_f_val, Pm_p_val, Pm_v_val);
fprintf('  Tous les correcteurs sont conçus par la méthode de Bode :\n');
fprintf('    C2 : I + Avance (ωcp=50 r/s, φmax compensé par lead)\n');
fprintf('    C1 : Lead seul  (ωcp=15 r/s, boucle déjà classe 1)\n');
fprintf('    C3 : I pur      (ωcp=2.5 r/s, régulation de force)\n\n');
fprintf('→ Module 5 terminé. Consulter le Simulink pour la simulation complète.\n');
fprintf('   Fichier : ../Modele_Projet_H2026_Gabarit.slx\n');

%% -----------------------------------------------------------------------
%  Fonction utilitaire locale
% ------------------------------------------------------------------------
function [w, mag_db, phase_deg] = frspecs(sys)
    w = logspace(-1, 4, 500);
    [m, p] = bode(sys, w);
    mag_db    = 20*log10(squeeze(m));
    phase_deg = squeeze(p);
end
