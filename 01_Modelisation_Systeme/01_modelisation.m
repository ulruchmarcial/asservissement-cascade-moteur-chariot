%% GEI1013 — MODULE 1 : Modélisation du système
%
%  NOTIONS ABORDÉES :
%    - Transformée de Laplace et fonctions de transfert
%    - Modèle du convertisseur de puissance (filtre LC, 2ème ordre)
%    - Modèle du moteur à courant continu (2 équations couplées)
%    - Inertie équivalente ramenée à l'arbre moteur
%    - Assemblage par blocs internes (couplage convertisseur-moteur)
%    - Cinématique de la transmission (réducteur + poulie)
%
%  SYSTÈME : Moteur CC → Réducteur G=20 → Poulie r=0.125m → Chariot M=2.5kg
%            Alimentation via convertisseur (filtre LC), bande élastique k_elas
%
%  FICHIER ASSOCIÉ : ../README.md, ../01_Modelisation_Systeme/README.md

clear; clc; close all;

fprintf('================================================================\n');
fprintf('  GEI1013 - Module 1 : Modélisation du système physique\n');
fprintf('================================================================\n\n');

%% -----------------------------------------------------------------------
%  SECTION 1 : PARAMÈTRES DU SYSTÈME
%  Chaque paramètre a une signification physique précise.
%  Unités SI tout au long.
% ------------------------------------------------------------------------

% --- Convertisseur de puissance (filtre LC) ---
uB  = 24;        % Tension d'alimentation bus continu [V]
Lf  = 50e-6;     % Inductance du filtre de sortie [H]
Cf  = 300e-6;    % Capacité du filtre de sortie [F]
Rf  = 100e3;     % Résistance de charge du filtre [Ω] (grande → filtre passe-bas)

% --- Moteur à courant continu (MCC) ---
Lm  = 1.577e-3;  % Inductance de l'induit [H]
Rm  = 1.3;       % Résistance de l'induit [Ω]
km  = 0.0742;    % Constante de FEM (force électromotrice) [V·s/rad]
kv  = 0.0742;    % Constante de couple [N·m/A]   → km = kv en SI
Jr  = 1.558e-4;  % Moment d'inertie du rotor [kg·m²]
Bm  = 0.0015;    % Coefficient de frottement visqueux [N·m·s/rad]

% --- Transmission mécanique ---
G   = 20;        % Rapport de réduction du réducteur [-]
r   = 0.125;     % Rayon de la poulie d'entraînement [m]
M   = 2.5;       % Masse du chariot [kg]

% --- Bande élastique ---
k_elas = 50;     % Raideur du ressort (bande élastique) [N/m]

%% -----------------------------------------------------------------------
%  SECTION 2 : INERTIE ÉQUIVALENTE RAMENÉE À L'ARBRE MOTEUR
%
%  La masse M du chariot, transmise par le réducteur (G) et la poulie (r),
%  est "vue" par le moteur comme une inertie supplémentaire :
%
%       v_chariot = (r/G) × ωm
%       Énergie cinétique chariot = ½·M·v² = ½·M·(r/G)²·ωm²
%
%  → Inertie équivalente du chariot à l'arbre moteur = M·(r/G)²
%  → Inertie totale équivalente : Jm = Jr + M·(r/G)²
% ------------------------------------------------------------------------

Jm = Jr + M * (r^2) / (G^2);

fprintf('--- Inertie équivalente ---\n');
fprintf('  Jr seul       = %.4e kg·m²\n', Jr);
fprintf('  M·(r/G)²      = %.4e kg·m²  (masse chariot ramenée)\n', M*(r/G)^2);
fprintf('  Jm = Jr + M(r/G)² = %.4e kg·m²\n\n', Jm);

%% -----------------------------------------------------------------------
%  SECTION 3 : MODÈLE DU CONVERTISSEUR DE PUISSANCE
%
%  Équation différentielle du filtre LC de sortie :
%    Lf·Cf·d²Uc/dt² + (Lf/Rf)·dUc/dt + Uc = uB·α
%
%  En Laplace → FT: Uc(s)/α(s) = uB / [Lf·Cf·s² + (Lf/Rf)·s + 1]
%
%  Système du 2ème ordre :
%    ωn = 1/√(Lf·Cf)  [rad/s]
%    ξ  = (1/2Rf)·√(Lf/Cf)  [-]
%  (Rf très grand → filtre très peu amorti → quasi LC idéal)
% ------------------------------------------------------------------------

s = tf('s');   % Variable de Laplace dans MATLAB

den_filtre = Lf*Cf*s^2 + (Lf/Rf)*s + 1;

% FT tension de sortie / rapport cyclique
G_conv = uB / den_filtre;

% Impédance de sortie du filtre : chute de tension due au courant moteur Im
% Z_conv(s) = Uc/Im = Lf·s / [même dénominateur]
Z_conv = (Lf*s) / den_filtre;

wn_filtre = 1/sqrt(Lf*Cf);
xi_filtre = (1/(2*Rf))*sqrt(Lf/Cf);

fprintf('--- Convertisseur de puissance (filtre LC) ---\n');
fprintf('  Fréquence naturelle ωn = %.0f rad/s  (fn = %.0f Hz)\n', wn_filtre, wn_filtre/(2*pi));
fprintf('  Amortissement      ξ  = %.2e  (très faiblement amorti)\n\n', xi_filtre);

%% -----------------------------------------------------------------------
%  SECTION 4 : MODÈLE DU MOTEUR À COURANT CONTINU
%
%  Deux équations couplées en Laplace (c.i. nulles) :
%    [Électrique] (Lm·s + Rm)·Im(s) = Uc(s) - kv·Ωm(s)   ... (1)
%    [Mécanique]  (Jm·s + Bm)·Ωm(s) = km·Im(s)             ... (2)
%
%  Dénominateur commun Δ(s) = (Lm·s+Rm)·(Jm·s+Bm) + km·kv
%
%  Admittance d'entrée  : Y_mot(s) = Im(s)/Uc(s) = (Jm·s+Bm)/Δ(s)
%  FT en vitesse angulaire : G_mot(s) = Ωm(s)/Uc(s) = km/Δ(s)
% ------------------------------------------------------------------------

den_mot = (Lm*s + Rm)*(Jm*s + Bm) + km*kv;

Y_mot = (Jm*s + Bm) / den_mot;   % Admittance : Im/Uc
G_mot = km / den_mot;              % FT vitesse  : Ωm/Uc

fprintf('--- Moteur CC ---\n');
fprintf('  Ordre de G_mot : %d\n', order(G_mot));
p_mot = pole(G_mot);
for k = 1:length(p_mot)
    fprintf('  Pôle p%d = %.2f + %.2fj  (Re<0 → stable)\n', k, real(p_mot(k)), imag(p_mot(k)));
end
fprintf('\n');

%% -----------------------------------------------------------------------
%  SECTION 5 : ASSEMBLAGE PAR BLOCS INTERNES
%
%  Erreur à éviter : mettre G_conv et G_mot en série suppose que Uc
%  n'est pas affectée par Im. Or Im crée une chute de tension Z_conv·Im.
%
%  Modèle correct (blocs internes / rétroaction interne) :
%
%    α ──► G_conv ──►[+]──► Uc ──► G_mot ──► ωm
%                    [-]◄─── Z_conv ◄─── Im ◄─── Y_mot
%
%  En résolvant cette boucle interne :
%    G_Uc_alpha(s) = G_conv(s) / [1 + Z_conv(s)·Y_mot(s)]
% ------------------------------------------------------------------------

G_Uc_alpha = minreal(G_conv / (1 + Z_conv * Y_mot));

fprintf('--- Assemblage par blocs internes ---\n');
fprintf('  Sans couplage : G_conv·G_mot (série simple)\n');
fprintf('  Avec couplage : G_conv/(1+Z_conv·Y_mot)·G_mot ← PLUS PRÉCIS\n');
fprintf('  Gain statique Uc/α(0) = %.2f V\n\n', dcgain(G_Uc_alpha));

%% -----------------------------------------------------------------------
%  SECTION 6 : FONCTIONS DE TRANSFERT EN BOUCLE OUVERTE
%
%  G_BO_v(s) = G_mot(s) × G_Uc_alpha(s)   [Ωm(s)/α(s)]
%            → Boucle VITESSE (Chariot 2), CLASSE 0
%
%  G_BO_p(s) = G_BO_v(s) × r/(G·s)        [X(s)/α(s)]
%            → Boucle POSITION (Chariot 1), CLASSE 1 (intégrateur 1/s)
% ------------------------------------------------------------------------

G_BO_v = minreal(G_mot * G_Uc_alpha);

% Cinématique : x = ∫ (r/G)·ωm dt  →  X(s)/Ωm(s) = r/(G·s)
G_cinematique = r / (G * s);

G_BO_p = minreal(G_BO_v * G_cinematique);

fprintf('================================================================\n');
fprintf('  RÉSULTATS : Fonctions de transfert en boucle ouverte\n');
fprintf('================================================================\n\n');

fprintf('G_BO_v — Vitesse (Chariot 2) :\n');
fprintf('  Ordre : %d | Classe : 0 | Gain statique : %.4f\n', order(G_BO_v), dcgain(G_BO_v));
G_BO_v
zpk(G_BO_v)

fprintf('\nG_BO_p — Position (Chariot 1) :\n');
fprintf('  Ordre : %d | Classe : 1 (intégrateur cinématique)\n', order(G_BO_p));
G_BO_p
zpk(G_BO_p)

fprintf('\n→ Ces FT seront utilisées dans les modules 02, 03 et 04.\n');
fprintf('→ Sauvegarder les variables pour les modules suivants :\n');
fprintf('  save(''modele_systeme.mat'', ''G_BO_v'', ''G_BO_p'', ''k_elas'', ''s'');\n\n');

% Sauvegarder pour utilisation dans les autres modules
save('modele_systeme.mat', 'G_BO_v', 'G_BO_p', 'G_cinematique', ...
     'G_conv', 'G_mot', 'G_Uc_alpha', 'Z_conv', 'Y_mot', 'k_elas', 's', ...
     'uB','Lm','Rm','km','kv','Jr','M','G','r','Bm','Cf','Lf','Rf','Jm');
fprintf('Variables sauvegardées dans modele_systeme.mat\n');
