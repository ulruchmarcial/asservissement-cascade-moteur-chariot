%% GEI1013 — MODULE 3 : Analyse temporelle
%
%  NOTIONS ABORDÉES :
%    - Réponse indicielle en boucle ouverte (BO) et boucle fermée (BF)
%    - Dépassement D%, temps de réponse Ts (5%), temps de montée Tm
%    - Classe du système (nombre d'intégrateurs en BO)
%    - Gain statique Kp (classe 0) et gain de vitesse Kv (classe 1)
%    - Erreur statique à un échelon et erreur de traînage à une rampe
%    - Théorème de la valeur finale
%
%  PRÉREQUIS : Exécuter 01_Modelisation_Systeme/01_modelisation.m d'abord

clear; clc; close all;

fprintf('================================================================\n');
fprintf('  GEI1013 - Module 3 : Analyse temporelle\n');
fprintf('================================================================\n\n');

%% CHARGEMENT DU MODÈLE
if exist('../01_Modelisation_Systeme/modele_systeme.mat', 'file')
    load('../01_Modelisation_Systeme/modele_systeme.mat');
else
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
end

%% -----------------------------------------------------------------------
%  SECTION 1 : CLASSE DU SYSTÈME ET ERREURS STATIQUES
%
%  La CLASSE est le nombre d'intégrateurs (1/s^k) dans la boucle ouverte.
%
%  Pour un système en boucle fermée unitaire :
%    T(s) = G(s)/(1+G(s))
%
%  Erreur en régime permanent à un échelon unitaire :
%    ε(∞) = 1 / (1 + lim[s→0] G(s))
%         = 1 / (1 + Kp)     [Kp : gain statique de la BO]
%
%  Classe 0 : Kp = G(0) est FINI  → erreur ≠ 0
%  Classe 1 : G(0) = ∞ (1 pôle en s=0) → erreur = 0 à l'échelon
%             mais erreur à une rampe = 1/Kv, avec Kv = lim[s→0] s·G(s)
% ------------------------------------------------------------------------

fprintf('--- Classe du système et erreurs statiques ---\n\n');

% ----- Boucle vitesse (CLASSE 0) -----
Kp_v = dcgain(G_BO_v);   % Kp = G_BO_v(0)
erreur_stat_v = 1 / (1 + Kp_v);

fprintf('Boucle VITESSE — G_BO_v :\n');
fprintf('  Classe : 0  (pas d''intégrateur en BO)\n');
fprintf('  Gain statique Kp = G_BO_v(0) = %.4f\n', Kp_v);
fprintf('  Erreur statique à un échelon = 1/(1+Kp) = %.2f %%\n', erreur_stat_v*100);
fprintf('  → Un INTÉGRATEUR dans le correcteur est nécessaire pour ε = 0\n\n');

% ----- Boucle position (CLASSE 1) -----
% G_BO_p a un intégrateur 1/s (cinématique), donc G_BO_p(0) = ∞
% On calcule Kv = lim[s→0] s·G_BO_p(s)
s_sym = tf('s');
Kv_p = dcgain(s_sym * G_BO_p);   % Kv = lim[s→0] s·G_BO_p(s)

fprintf('Boucle POSITION — G_BO_p :\n');
fprintf('  Classe : 1  (1 intégrateur cinématique r/(G·s))\n');
fprintf('  Erreur à un échelon de position = 0  (classe ≥ 1)\n');
fprintf('  Gain de vitesse  Kv = lim[s→0]s·G_BO_p(s) = %.4f [1/s]\n', Kv_p);
fprintf('  Erreur de traînage (rampe) = 1/Kv = %.4f m/(m/s)\n\n', 1/Kv_p);

%% -----------------------------------------------------------------------
%  SECTION 2 : RÉPONSE INDICIELLE EN BOUCLE OUVERTE
%
%  On applique un échelon unitaire à l'entrée et on observe la sortie.
%  En BO, il n'y a PAS de rétroaction : le système ne se "corrige" pas.
%
%  Valeur finale (théorème de la valeur finale) :
%    y(∞) = lim[s→0] s · Y(s) = lim[s→0] s · G(s)/s = G(0)
%
%  Pour G_BO_p : G(0) = ∞ (classe 1), donc la sortie diverge en BO.
% ------------------------------------------------------------------------

fprintf('--- Réponse indicielle en boucle ouverte ---\n\n');

% Figure 1 : BO vitesse
figure('Name', 'Fig.1 - Réponse indicielle BO vitesse', 'NumberTitle', 'off');
step(G_BO_v, 2);
title('Réponse à un échelon — G_{BO\_v} (vitesse) en Boucle Ouverte', 'FontSize', 13);
xlabel('Temps [s]'); ylabel('Vitesse angulaire [rad/s]'); grid on;

% Figure 2 : BO position
figure('Name', 'Fig.2 - Réponse indicielle BO position', 'NumberTitle', 'off');
step(G_BO_p, 2);
title('Réponse à un échelon — G_{BO\_p} (position) en Boucle Ouverte', 'FontSize', 13);
xlabel('Temps [s]'); ylabel('Position [m]'); grid on;

%% -----------------------------------------------------------------------
%  SECTION 3 : RÉPONSE INDICIELLE EN BOUCLE FERMÉE UNITAIRE
%
%  La boucle fermée T(s) = G(s)/(1+G(s)) compare la sortie à la référence
%  et corrige l'erreur automatiquement.
%
%  Indicateurs de performance :
%    D%  = (y_max - y_inf) / y_inf × 100   [dépassement]
%    Ts  = temps pour que |y-y_inf| < 5%   [temps de réponse à 5%]
%    Tm  = temps de 10% à 90% de y_inf     [temps de montée]
% ------------------------------------------------------------------------

fprintf('--- Réponse indicielle en boucle fermée (retour unitaire, sans correcteur) ---\n\n');

T_v_BF = feedback(G_BO_v, 1);
T_p_BF = feedback(G_BO_p, 1);

% Figure 3 : BF vitesse
figure('Name', 'Fig.3 - Réponse indicielle BF vitesse', 'NumberTitle', 'off');
step(T_v_BF, 2);
title('Réponse indicielle BF unitaire — Vitesse (sans correcteur)', 'FontSize', 13);
xlabel('Temps [s]'); ylabel('Vitesse angulaire normalisée'); grid on;

% Figure 4 : BF position
figure('Name', 'Fig.4 - Réponse indicielle BF position', 'NumberTitle', 'off');
step(T_p_BF, 5);
title('Réponse indicielle BF unitaire — Position (sans correcteur)', 'FontSize', 13);
xlabel('Temps [s]'); ylabel('Position normalisée'); grid on;

%% -----------------------------------------------------------------------
%  SECTION 4 : INDICATEURS DE PERFORMANCE TEMPORELLE
% ------------------------------------------------------------------------

fprintf('================================================================\n');
fprintf('  RÉSULTATS : Indicateurs de performance (BF sans correcteur)\n');
fprintf('================================================================\n\n');

info_v = stepinfo(T_v_BF);
fprintf('Boucle VITESSE en BF :\n');
fprintf('  Dépassement       D%%  = %.2f %%\n', info_v.Overshoot);
fprintf('  Temps de montée   Tm  = %.4f s\n', info_v.RiseTime);
fprintf('  Temps de réponse  Ts  = %.4f s  (±5%%)\n', info_v.SettlingTime);
fprintf('  Valeur finale         = %.4f  (≠ 1 car erreur statique)\n\n', ...
        dcgain(T_v_BF));

info_p = stepinfo(T_p_BF);
fprintf('Boucle POSITION en BF :\n');
fprintf('  Dépassement       D%%  = %.2f %%\n', info_p.Overshoot);
fprintf('  Temps de montée   Tm  = %.4f s\n', info_p.RiseTime);
fprintf('  Temps de réponse  Ts  = %.4f s  (±5%%)\n', info_p.SettlingTime);
fprintf('  Valeur finale         ≈ 1  (classe 1 → erreur = 0)\n\n');

fprintf('  ⚠ Ces performances sont SANS correcteur.\n');
fprintf('    Elles ne respectent pas nécessairement les spécifications.\n');
fprintf('    → Passer au Module 4 pour synthétiser les correcteurs.\n\n');

fprintf('→ Module 3 terminé.\n');
