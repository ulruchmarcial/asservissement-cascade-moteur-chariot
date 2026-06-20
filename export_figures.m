%% GEI1013 — EXPORT DES FIGURES POUR LE DÉPÔT
%
%  Ce script génère toutes les figures du projet et les sauvegarde en PNG
%  dans le sous-dossier figures/ du projet (à côté de ce fichier .m).
%
%  UTILISATION :
%    - Ouvrir ce fichier dans MATLAB et appuyer sur Run (F5), OU
%    - Dans la console MATLAB : run('C:\...\export_figures.m')
%
%  Le dossier figures/ est créé automatiquement dans le même répertoire
%  que ce script, peu importe où MATLAB est ouvert.

clear; clc; close all;

% ── Chemin absolu basé sur l'emplacement de CE script ───────────────────
script_dir  = fileparts(mfilename('fullpath'));
if isempty(script_dir)
    % Fallback si le script est collé dans la console MATLAB
    script_dir = 'C:\Projet_session_asservissement_lineare';
end
figures_dir = fullfile(script_dir, 'figures');

if ~exist(figures_dir, 'dir')
    mkdir(figures_dir);
    fprintf('Dossier créé : %s\n', figures_dir);
end

fprintf('================================================================\n');
fprintf('  Export des figures — GEI1013 Asservissement H2026\n');
fprintf('================================================================\n');
fprintf('  Dossier cible : %s\n\n', figures_dir);

% Raccourci : f(nom) = chemin complet vers figures/nom.png
f = @(nom) fullfile(figures_dir, [nom '.png']);

%% -----------------------------------------------------------------------
%  PARAMÈTRES ET MODÈLE
% ------------------------------------------------------------------------
uB=24; Lm=1.577e-3; Rm=1.3; km=0.0742; kv=0.0742;
Jr=1.558e-4; M=2.5; G=20; r=0.125; Bm=0.0015;
Cf=300e-6; Lf=50e-6; Rf=100e3; k_elas=50;
Jm = Jr + M*(r^2)/(G^2);
s  = tf('s');
den_filtre = Lf*Cf*s^2 + (Lf/Rf)*s + 1;
G_conv = uB/den_filtre;  Z_conv = (Lf*s)/den_filtre;
den_mot = (Lm*s+Rm)*(Jm*s+Bm) + km*kv;
Y_mot = (Jm*s+Bm)/den_mot;  G_mot = km/den_mot;
G_Uc_alpha  = minreal(G_conv/(1+Z_conv*Y_mot));
G_BO_v      = minreal(G_mot*G_Uc_alpha);
G_cinematique = r/(G*s);
G_BO_p      = minreal(G_BO_v*G_cinematique);

%% -----------------------------------------------------------------------
%  MODULE 2 — Analyse fréquentielle
% ------------------------------------------------------------------------
fprintf('Module 2 : Analyse fréquentielle...\n');

fig = figure('Visible','off');
pzmap(G_BO_v); grid on;
title('Carte pôles-zéros — G_{BO\_v} (vitesse)');
saveas(fig, f('02a_pzmap_vitesse')); close(fig);

fig = figure('Visible','off');
pzmap(G_BO_p); grid on;
title('Carte pôles-zéros — G_{BO\_p} (position)');
saveas(fig, f('02b_pzmap_position')); close(fig);

fig = figure('Visible','off');
margin(G_BO_v); grid on;
title('Bode + Marges — G_{BO\_v} (vitesse, non corrigé)');
saveas(fig, f('02c_bode_vitesse_BO')); close(fig);

fig = figure('Visible','off');
margin(G_BO_p); grid on;
title('Bode + Marges — G_{BO\_p} (position, non corrigé)');
saveas(fig, f('02d_bode_position_BO')); close(fig);

fig = figure('Visible','off');
rlocus(G_BO_v); grid on;
title('Lieu des racines — G_{BO\_v} (vitesse)');
saveas(fig, f('02e_rlocus_vitesse')); close(fig);

fig = figure('Visible','off');
rlocus(G_BO_p); grid on;
title('Lieu des racines — G_{BO\_p} (position)');
saveas(fig, f('02f_rlocus_position')); close(fig);

%% -----------------------------------------------------------------------
%  MODULE 3 — Analyse temporelle
% ------------------------------------------------------------------------
fprintf('Module 3 : Analyse temporelle...\n');

fig = figure('Visible','off');
step(G_BO_v, 2); grid on;
title('Réponse indicielle BO — Vitesse (sans correcteur)');
xlabel('Temps [s]'); ylabel('Vitesse [rad/s]');
saveas(fig, f('03a_step_vitesse_BO')); close(fig);

fig = figure('Visible','off');
step(feedback(G_BO_v,1), 2); grid on;
title('Réponse indicielle BF — Vitesse (retour unitaire, sans correcteur)');
xlabel('Temps [s]');
saveas(fig, f('03b_step_vitesse_BF_brut')); close(fig);

fig = figure('Visible','off');
step(feedback(G_BO_p,1), 5); grid on;
title('Réponse indicielle BF — Position (retour unitaire, sans correcteur)');
xlabel('Temps [s]'); ylabel('Position [m]');
saveas(fig, f('03c_step_position_BF_brut')); close(fig);

%% -----------------------------------------------------------------------
%  MODULE 4 — Synthèse des correcteurs
% ------------------------------------------------------------------------
fprintf('Module 4 : Synthèse des correcteurs...\n');

% --- C2 Vitesse (I + Lead, wcp=50 rad/s) ---
[mv, pv] = bode(G_BO_v, 50);  mv=squeeze(mv);  pv=squeeze(pv);
phi_max_v  = 50 - 90 - pv;
alpha_v    = (1-sind(phi_max_v))/(1+sind(phi_max_v));
T_v        = 1/(50*sqrt(alpha_v));
K_v        = 50*sqrt(alpha_v)/mv;
C2_vitesse = minreal((K_v/s)*(T_v*s+1)/(alpha_v*T_v*s+1));
L_vitesse  = minreal(C2_vitesse*G_BO_v);
T_vitesse  = feedback(L_vitesse, 1);

fig = figure('Visible','off');
margin(L_vitesse); grid on;
title('Bode BO corrigée — L_{vitesse} = C_2 \cdot G_{BO\_v}');
saveas(fig, f('04a_bode_L_vitesse')); close(fig);

fig = figure('Visible','off');
step(T_vitesse, 1); grid on;
title('Réponse indicielle BF — Boucle vitesse avec C_2(s)');
xlabel('Temps [s]'); ylabel('Vitesse normalisée');
saveas(fig, f('04b_step_BF_vitesse')); close(fig);

% --- C1 Position (Lead, wcp=15 rad/s) ---
[mp, pp] = bode(G_BO_p, 15);  mp=squeeze(mp);  pp=squeeze(pp);
phi_max_p  = 50 - 180 - pp;
G_pos_sys  = minreal(T_vitesse * G_cinematique);
if phi_max_p <= 0
    C1_position = 1/mp;
else
    alpha_p = (1-sind(phi_max_p))/(1+sind(phi_max_p));
    T_p     = 1/(15*sqrt(alpha_p));
    K_p     = sqrt(alpha_p)/mp;
    C1_position = minreal(K_p*(T_p*s+1)/(alpha_p*T_p*s+1));
end
L_position = minreal(C1_position * G_pos_sys);
T_position = feedback(L_position, 1);

fig = figure('Visible','off');
margin(L_position); grid on;
title('Bode BO corrigée — L_{position} = C_1 \cdot G_{sys\_pos}');
saveas(fig, f('04c_bode_L_position')); close(fig);

fig = figure('Visible','off');
step(T_position, 5); grid on;
title('Réponse indicielle BF — Boucle position avec C_1(s)');
xlabel('Temps [s]'); ylabel('Position normalisée');
saveas(fig, f('04d_step_BF_position')); close(fig);

% --- C3 Force (Intégrateur, wcp=2.5 rad/s) ---
G_sys3  = minreal(k_elas * T_position);
[m3, ~] = bode(G_sys3, 2.5);  m3=squeeze(m3);
K_i     = 2.5 / m3;
C3_force = K_i / s;
L_force  = minreal(C3_force * G_sys3);
T_force  = feedback(L_force, 1);

fig = figure('Visible','off');
margin(G_sys3); grid on;
title('Bode — G_{sys3} = k_{elas} \cdot T_{position} (avant correction)');
saveas(fig, f('04e_bode_Gsys3')); close(fig);

fig = figure('Visible','off');
margin(L_force); grid on;
title('Bode BO corrigée — L_{force} = C_3 \cdot G_{sys3}');
saveas(fig, f('04f_bode_L_force')); close(fig);

fig = figure('Visible','off');
step(T_force, 10); grid on;
title('Réponse indicielle BF — Boucle force avec C_3(s)');
xlabel('Temps [s]'); ylabel('Force normalisée');
saveas(fig, f('04g_step_BF_force')); close(fig);

%% -----------------------------------------------------------------------
%  MODULE 5 — Cascade complète
% ------------------------------------------------------------------------
fprintf('Module 5 : Commande en cascade...\n');

fig = figure('Visible','off', 'Position',[100 100 800 700]);
subplot(3,1,1); step(T_vitesse,  1);  title('BF Vitesse (C_2)');   grid on;
subplot(3,1,2); step(T_position, 5);  title('BF Position (C_1)');  grid on;
subplot(3,1,3); step(T_force,   10);  title('BF Force (C_3)');     grid on;
xlabel('Temps [s]');
sgtitle('Réponses indicielles — Commande en cascade 3 boucles', 'FontSize', 13);
saveas(fig, f('05_cascade_step_responses')); close(fig);

fig = figure('Visible','off', 'Position',[100 100 800 450]);
w = logspace(-1, 4, 500);
[mv_w,~]=bode(L_vitesse, w);   mv_w=20*log10(squeeze(mv_w));
[mp_w,~]=bode(L_position, w);  mp_w=20*log10(squeeze(mp_w));
[mf_w,~]=bode(L_force, w);     mf_w=20*log10(squeeze(mf_w));
semilogx(w, mv_w, 'b', 'LineWidth', 2); hold on;
semilogx(w, mp_w, 'r', 'LineWidth', 2);
semilogx(w, mf_w, 'g', 'LineWidth', 2);
yline(0, 'k--', '0 dB', 'LineWidth', 1.2);
xlabel('\omega [rad/s]'); ylabel('Gain [dB]');
title('Gains des 3 boucles ouvertes corrigées — séparation des BP');
legend('L_{vitesse} (ω_{cp}=50)','L_{position} (ω_{cp}=15)','L_{force} (ω_{cp}=2.5)', ...
       'Location','southwest');
grid on; xlim([1e-1 1e4]);
saveas(fig, f('05_bode_comparaison_3_boucles')); close(fig);

%% -----------------------------------------------------------------------
%  RÉSUMÉ
% ------------------------------------------------------------------------
files = dir(fullfile(figures_dir, '*.png'));
fprintf('\n================================================================\n');
fprintf('  Export terminé ! %d figures dans :\n', length(files));
fprintf('  %s\n', figures_dir);
fprintf('================================================================\n\n');
for k = 1:length(files)
    fprintf('  ✓ %s\n', files(k).name);
end
fprintf('\n→ Committez le dossier figures/ dans votre dépôt GitHub.\n');
