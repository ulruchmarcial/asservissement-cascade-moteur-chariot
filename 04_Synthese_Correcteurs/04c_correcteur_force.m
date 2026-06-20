%% GEI1013 — MODULE 4c : Correcteur C3 — Boucle force (Intégrateur pur)
%
%  NOTIONS ABORDÉES :
%    - Correcteur intégral pur (action I)
%    - Boucle de force externe (lente) sur la bande élastique
%    - Calcul du gain Ki par imposition de la pulsation de coupure
%    - Validation : marges, D%, Ts
%
%  BOUCLE FORCE :
%    La force dans la bande élastique est : F = k_elas × x
%    Plante vue de la boucle force : G_sys3(s) = k_elas × T_position(s)
%    Spécifications : ωcp = 2.5 rad/s  (boucle lente, externe)
%
%  CORRECTEUR : C3(s) = Ki/s   [intégrateur pur]
%
%  PRÉREQUIS : Exécuter 04a et 04b (ou charger correcteur_position.mat)

clear; clc; close all;

fprintf('================================================================\n');
fprintf('  GEI1013 - Module 4c : Correcteur force C3 (Intégrateur pur)\n');
fprintf('================================================================\n\n');

%% CHARGEMENT DES MODÈLES
loaded = false;

if exist('correcteur_position.mat', 'file')
    load('correcteur_position.mat');   % T_position
    loaded = true;
    fprintf('correcteur_position.mat chargé.\n');
end

if exist('../01_Modelisation_Systeme/modele_systeme.mat', 'file')
    load('../01_Modelisation_Systeme/modele_systeme.mat', 'k_elas');
else
    k_elas = 50;
end

if ~loaded
    fprintf('⚠ correcteur_position.mat non trouvé.\n');
    fprintf('  Exécutez 04a_correcteur_vitesse.m et 04b_correcteur_position.m d''abord.\n');
    fprintf('  Re-dérivation du système en ligne...\n\n');

    % Re-dériver tout
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
    G_BO_p = minreal(G_BO_v * (r/(G*s)));

    % Synthèse rapide de C1 (Lead position)
    wcp_p=15; phi_m_p=50;
    [mag_p, phase_p] = bode(G_BO_p, wcp_p);
    mag_p=squeeze(mag_p); phase_p=squeeze(phase_p);
    phi_max_p = phi_m_p - 180 - phase_p;
    if phi_max_p <= 0
        K_p=1/mag_p; alpha_p=1; T_p=0;
        C1_position = K_p;
    else
        alpha_p=(1-sind(phi_max_p))/(1+sind(phi_max_p));
        T_p=1/(wcp_p*sqrt(alpha_p)); K_p=sqrt(alpha_p)/mag_p;
        C1_position = K_p*(T_p*s+1)/(alpha_p*T_p*s+1);
    end
    L_position = minreal(C1_position * G_BO_p);
    T_position = feedback(L_position, 1);
end

%% -----------------------------------------------------------------------
%  SECTION 1 : RAPPEL — POURQUOI UNE BOUCLE DE FORCE ?
%
%  La bande élastique transmet la force : F = k_elas × x
%  Si on ne contrôle que la position, la force n'est pas régulée.
%  Une perturbation (changement de k_elas, frottement) change F sans
%  que le système le détecte ou le compense.
%
%  La boucle de force règle x pour obtenir la FORCE souhaitée.
%  Puisque F = k_elas × x, on a : x_ref = F_ref / k_elas
%
%  Structure de la plante vue de la boucle force :
%    G_sys3(s) = k_elas × T_position(s)
%             = k_elas × [boucle position BF]
%
%  C'est la composition : boucle de force → boucle de position → boucle vitesse
% ------------------------------------------------------------------------

fprintf('--- Construction de la plante G_sys3 ---\n');
fprintf('  G_sys3(s) = k_elas × T_position(s)\n');
fprintf('  k_elas = %d N/m\n\n', k_elas);

s = tf('s');
G_sys3 = k_elas * T_position;
G_sys3 = minreal(G_sys3);

fprintf('  Gain statique G_sys3(0) = %.4f N/m\n\n', dcgain(G_sys3));

%% -----------------------------------------------------------------------
%  SECTION 2 : SPÉCIFICATIONS ET ÉVALUATION
%
%  La boucle de force est la plus externe → elle doit être la plus LENTE.
%  On choisit ωcp = 2.5 rad/s, soit ~6× plus lent que la boucle position.
% ------------------------------------------------------------------------

wcp3_star = 2.5;   % Pulsation de coupure cible [rad/s]

fprintf('--- Spécification de la boucle force ---\n');
fprintf('  ωcp cible = %.1f rad/s  (≈ 6× plus lent que la boucle position à 15 rad/s)\n', wcp3_star);
fprintf('  → Séparation des bandes passantes : 2.5 << 15 << 50 ✓\n\n');

[mag3, phase3] = bode(G_sys3, wcp3_star);
mag3   = squeeze(mag3);
phase3 = squeeze(phase3);

fprintf('  |G_sys3(j·ωcp)| = %.4f  (= %.2f dB)\n', mag3, 20*log10(mag3));
fprintf('  ∠G_sys3(j·ωcp) = %.2f °\n\n', phase3);

%% -----------------------------------------------------------------------
%  SECTION 3 : CALCUL DU GAIN Ki
%
%  Le correcteur est un intégrateur pur : C3(s) = Ki/s
%
%  On impose |L_force(j·ωcp)| = 1 (0 dB) à ωcp = 2.5 rad/s :
%    |C3(j·ωcp)| × |G_sys3(j·ωcp)| = 1
%    Ki/ωcp × |G_sys3(j·ωcp)| = 1
%    Ki = ωcp / |G_sys3(j·ωcp)|
%
%  Note : on ne peut pas calculer φmax ici car l'intégrateur seul ne peut
%  pas apporter de phase. La marge de phase sera ce qu'elle sera.
%  Si elle est insuffisante, il faudrait un correcteur I+Lead pour C3.
% ------------------------------------------------------------------------

K_i = wcp3_star / mag3;

fprintf('--- Calcul du gain Ki ---\n');
fprintf('  Ki = ωcp / |G_sys3(j·ωcp)|\n');
fprintf('     = %.2f / %.4f\n', wcp3_star, mag3);
fprintf('     = %.4e\n\n', K_i);

C3_force = K_i / s;

fprintf('--- Fonction de transfert C3(s) ---\n');
display(C3_force);

%% -----------------------------------------------------------------------
%  SECTION 4 : VALIDATION
% ------------------------------------------------------------------------

L_force = C3_force * G_sys3;
L_force = minreal(L_force);
T_force = feedback(L_force, 1);

[~, Pm_f, ~, Wcp_f] = margin(L_force);

fprintf('--- Validation après correction ---\n');
fprintf('  Pm obtenue = %.2f °  à ωcp = %.2f rad/s\n', Pm_f, Wcp_f);
if Pm_f >= 45
    fprintf('  ✓ Marge de phase ≥ 45° RESPECTÉE\n');
else
    fprintf('  ✗ Marge de phase < 45° — Envisager un correcteur I+Lead\n');
end

info_C3 = stepinfo(T_force);
fprintf('\n  Réponse indicielle BF corrigée :\n');
fprintf('    Dépassement       D%%  = %.2f %%\n', info_C3.Overshoot);
fprintf('    Temps de réponse  Ts  = %.4f s  (±5%%)\n\n', info_C3.SettlingTime);

% Figure 1 : Bode G_sys3 avant correction
figure('Name', 'Fig.1 - Bode G_sys3 (avant correction)', 'NumberTitle', 'off');
margin(G_sys3);
title('Bode — G_{sys3} = k_{elas} \cdot T_{position} (avant correction)', 'FontSize', 13);
grid on;

% Figure 2 : Bode BO corrigée force
figure('Name', 'Fig.2 - Bode BO corrigée force', 'NumberTitle', 'off');
margin(L_force);
title('Bode — Boucle ouverte corrigée L_{force} = C_3 \cdot G_{sys3}', 'FontSize', 13);
grid on;

% Figure 3 : Réponse indicielle BF force
figure('Name', 'Fig.3 - Réponse indicielle BF force', 'NumberTitle', 'off');
step(T_force, 10);
title('Réponse indicielle BF — Boucle force avec C_3(s)', 'FontSize', 13);
xlabel('Temps [s]'); ylabel('Force normalisée'); grid on;

fprintf('→ Module 4c terminé.\n');
fprintf('→ Passer au Module 5 pour l''assemblage complet de la cascade.\n');

% Sauvegarder
save('correcteur_force.mat', 'C3_force', 'T_force', 'L_force', 'G_sys3');
