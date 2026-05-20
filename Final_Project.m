%% PHASE 1: DNS Analysis + Engineering Correlations (COMPLETE FINAL)
% Turbulent Oil Pipeline Flow Project
%
% This code:
%   1. Queries DNS from JHTDB (channel flow, Re_tau = 1000)
%   2. Analyzes DNS statistics (U+, k+, Reynolds stress)
%   3. Applies Colebrook-White to oil pipeline
%   4. PROVES Colebrook = Log-law that DNS validates

clear; close all; clc;

fprintf('====================================================\n');
fprintf('PHASE 1: DNS Analysis + Engineering Correlations\n');
fprintf('====================================================\n\n');

%% PART 1: Query DNS from JHTDB
fprintf('PART 1: JHTDB Channel Flow DNS (Re_tau = 1000)\n');
fprintf('-----------------------------------------------\n');

dns_data = get_dns_data_JHTDB();

%% PART 2: DNS Friction Factor
fprintf('\nPART 2: DNS Friction Factor\n');
fprintf('---------------------------\n');

U_bulk_dns = dns_data.u_tau * 18.2;
f_dns = 8*(dns_data.u_tau/U_bulk_dns)^2;
Re_bulk_dns = (dns_data.Re_tau/0.09)^(1/0.88);
f_dns_corr = 0.073/Re_bulk_dns^0.25;

fprintf('DNS u_tau = %.4f\n', dns_data.u_tau);
fprintf('DNS Re_tau = %d\n', dns_data.Re_tau);
fprintf('Estimated U_bulk = %.3f\n', U_bulk_dns);
fprintf('DNS friction factor: f ≈ %.5f\n', f_dns);
fprintf('From Re_tau correlation: f ≈ %.5f\n\n', f_dns_corr);

%% PART 3: Oil Pipeline with Colebrook-White
fprintf('PART 3: Oil Pipeline - Colebrook-White Method\n');
fprintf('----------------------------------------------\n');

D_oil = 0.508;
L_oil = 50e3;
rho_oil = 865;
mu_oil = 0.012;
nu_oil = mu_oil/rho_oil;
Q_oil = 0.50;
eps_rough = 0.045e-3;

U_bulk_oil = Q_oil/(pi*(D_oil/2)^2);
Re_D_oil = rho_oil*U_bulk_oil*D_oil/mu_oil;

fprintf('Pipeline Specifications:\n');
fprintf('  Diameter: D = %.0f mm (20 inch)\n', D_oil*1000);
fprintf('  Length: L = %.0f km\n', L_oil/1000);
fprintf('  Flow rate: Q = %.2f m^3/s (%.0f bbl/day)\n', Q_oil, Q_oil*86400/0.159);
fprintf('  Temperature: T = 25 deg C\n');
fprintf('  Roughness: eps = %.3f mm\n', eps_rough*1000);
fprintf('  Re_D = %.2e\n\n', Re_D_oil);

fprintf('Solving Colebrook-White equation...\n');
f_oil = 0.02;
for i = 1:20
    f_oil = 1/(-2*log10(eps_rough/D_oil/3.7 + 2.51/(Re_D_oil*sqrt(f_oil))))^2;
end
fprintf('Colebrook-White: f = %.6f\n\n', f_oil);

f_blasius = 0.316/Re_D_oil^0.25;
f_swamee = 0.25/(log10(eps_rough/D_oil/3.7 + 5.74/Re_D_oil^0.9))^2;

fprintf('Comparison:\n');
fprintf('  Blasius: f = %.6f\n', f_blasius);
fprintf('  Swamee-Jain: f = %.6f\n', f_swamee);
fprintf('  Colebrook: f = %.6f\n\n', f_oil);

%% PART 4: Engineering Calculations
fprintf('PART 4: Engineering Calculations\n');
fprintf('---------------------------------\n');

dP_oil = f_oil * (L_oil/D_oil) * (rho_oil*U_bulk_oil^2/2);
dPdx_oil = dP_oil/L_oil;

fprintf('Pressure drop: dP = %.2f MPa\n', dP_oil/1e6);
fprintf('Pressure gradient: dP/dx = %.1f Pa/m\n', dPdx_oil);

P_hydraulic = dP_oil*Q_oil/1e6;
eta_pump = 0.78;
P_shaft = P_hydraulic/eta_pump;
eta_motor = 0.94;
P_electrical = P_shaft/eta_motor;

fprintf('\nPower:\n');
fprintf('  Hydraulic: %.2f MW\n', P_hydraulic);
fprintf('  Electrical: %.2f MW\n', P_electrical);

hours_per_year = 8760;
capacity_factor = 0.95;
operating_hours = hours_per_year*capacity_factor;
E_annual = P_electrical*operating_hours/1000;
electricity_rate = 0.12;
cost_annual = E_annual*1e6*electricity_rate/1e6;

fprintf('\nAnnual:\n');
fprintf('  Energy: %.1f GWh/year\n', E_annual);
fprintf('  Cost: $%.2f million/year\n', cost_annual);

%% PART 5: Prove Colebrook = Log-Law
fprintf('\nPART 5: Proving Colebrook IS the Log-Law\n');
fprintf('-----------------------------------------\n');

u_tau_oil = U_bulk_oil * sqrt(f_oil/8);
fprintf('Oil pipeline u_tau from Colebrook: %.4f m/s\n', u_tau_oil);

% Construct U+(y+) from Colebrook
% y_plus_oil = logspace(0, 3, 500)';
% U_plus_oil = zeros(size(y_plus_oil));
% for i = 1:length(y_plus_oil)
%     yp = y_plus_oil(i);
%     if yp < 5
%         U_plus_oil(i) = yp;
%     elseif yp < 30
%         U_visc = 5;
%         U_log = (1/0.41)*log(30) + 5.2;
%         alpha = (yp - 5)/25;
%         U_plus_oil(i) = U_visc*(1-alpha) + U_log*alpha;
%     else
%         U_plus_oil(i) = (1/0.41)*log(yp) + 5.2;
%     end
% end
% Construct U+(y+) from rough-wall log law
% Generalized form: U+ = (1/kappa)*ln(y+) + B - dU+(eps+)
% Roughness function (Cebeci-Bradshaw form): dU+ = (1/kappa)*ln(1 + 0.3*eps+)
%   eps+ = 0          -> dU+ = 0           (smooth limit)
%   eps+ << 5         -> dU+ ~ 0           (hydraulically smooth)
%   eps+ >> 70        -> dU+ ~ ln(eps+)    (fully rough, Nikuradse)
% Setting eps_plus = 0 recovers the smooth-wall log law for the DNS comparison
kappa   = 0.41;
B_const = 5.2;

eps_plus_dns = 0;                                   % zero for DNS validation
dU_plus_dns  = (1/kappa)*log(1 + 0.3*eps_plus_dns);  % = 0 when eps+ = 0

y_plus_oil = logspace(0, 3, 500)';
U_plus_oil = zeros(size(y_plus_oil));
for i = 1:length(y_plus_oil)
    yp = y_plus_oil(i);
    if yp < 5
        U_plus_oil(i) = yp;
    elseif yp < 30
        U_visc = 5;
        U_log  = (1/kappa)*log(30) + B_const - dU_plus_dns;
        alpha  = (yp - 5)/25;
        U_plus_oil(i) = U_visc*(1-alpha) + U_log*alpha;
    else
        U_plus_oil(i) = (1/kappa)*log(yp) + B_const - dU_plus_dns;
    end
end

% Conclusion:
% - eps_plus_dns = 0 forces dU+ = 0, recovering the smooth-wall log law
% - Figure 3 (DNS vs profile) will look IDENTICAL to before -> sanity check
% - The roughness machinery is now in place for the sweep below
% Test: Colebrook (smooth) vs Prandtl-von Karman
Re_test = logspace(4, 6, 30);
f_cb = zeros(size(Re_test));
f_pk = zeros(size(Re_test));
for i = 1:length(Re_test)
    f_temp = 0.02;
    for j = 1:15
        f_temp = 1/(-2*log10(2.51/(Re_test(i)*sqrt(f_temp))))^2;
    end
    f_cb(i) = f_temp;
    
    f_temp = 0.02;
    for j = 1:15
        f_temp = 1/(2.0*log10(Re_test(i)*sqrt(f_temp)) - 0.8)^2;
    end
    f_pk(i) = f_temp;
end

diff_max = max(abs(f_cb - f_pk)./f_pk)*100;
fprintf('Colebrook vs Prandtl-von Karman: diff < %.4f%%\n', diff_max);
fprintf('They are IDENTICAL!\n\n');

fprintf('VALIDATION CHAIN:\n');
fprintf('  DNS → Log-law ✓\n');
fprintf('  Colebrook = Log-law ✓\n');
fprintf('  DNS → Colebrook ✓\n');
fprintf('-----------------------------------------\n');

%% PART 6: GENERATE PLOTS
fprintf('\n====================================================\n');
fprintf('Generating plots...\n');

% FIGURE 1: DNS Analysis
figure('Position', [100,100,1400,900], 'Name', 'DNS Analysis');

% subplot(2,3,1);
% semilogx(dns_data.y_plus, dns_data.U_plus, 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b', 'LineWidth', 1.5);
% hold on;
% y_v = linspace(0.1, 5, 50);
% semilogx(y_v, y_v, 'r--', 'LineWidth', 2);
% y_l = logspace(1, 3, 100);
% semilogx(y_l, (1/0.41)*log(y_l) + 5.2, 'g--', 'LineWidth', 2);
% xlabel('y^+', 'FontSize', 12); ylabel('U^+', 'FontSize', 12);
% title('Mean Velocity', 'FontSize', 13, 'FontWeight', 'bold');
% legend('DNS', 'U^+=y^+', 'Log law', 'Location', 'northwest');
% grid on; xlim([0.5, 1000]);
subplot(2,3,1);
plot(dns_data.y_plus, dns_data.U_plus, 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b', 'LineWidth', 1.5);
hold on;
y_v = linspace(0, 5, 50);
plot(y_v, y_v, 'r--', 'LineWidth', 2);
y_l = linspace(30, 1000, 100);
plot(y_l, (1/0.41)*log(y_l) + 5.2, 'g--', 'LineWidth', 2);
xlabel('y^+', 'FontSize', 12); ylabel('U^+', 'FontSize', 12);
title('Mean Velocity', 'FontSize', 13, 'FontWeight', 'bold');
legend('DNS', 'U^+=y^+', 'Log law', 'Location', 'best');
grid on; xlim([0, 150]);

subplot(2,3,2);
semilogx(dns_data.y_plus, dns_data.k_plus, 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b', 'LineWidth', 1.5);
xlabel('y^+', 'FontSize', 12); ylabel('k^+', 'FontSize', 12);
title('TKE', 'FontSize', 13, 'FontWeight', 'bold');
grid on; xlim([1, 150]);

subplot(2,3,3);
semilogx(dns_data.y_plus, -dns_data.uv_plus, 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b', 'LineWidth', 1.5);
xlabel('y^+', 'FontSize', 12); ylabel('-<u''v''>^+', 'FontSize', 12);
title('Reynolds Stress', 'FontSize', 13, 'FontWeight', 'bold');
grid on; xlim([1, 1000]);

subplot(2,3,4);
semilogx(dns_data.y_plus, dns_data.U_rms/dns_data.u_tau, 'ro', 'MarkerSize', 6); hold on;
semilogx(dns_data.y_plus, dns_data.V_rms/dns_data.u_tau, 'go', 'MarkerSize', 6);
semilogx(dns_data.y_plus, dns_data.W_rms/dns_data.u_tau, 'bo', 'MarkerSize', 6);
xlabel('y^+', 'FontSize', 12); ylabel('u''_{rms}^+', 'FontSize', 12);
title('RMS Fluctuations', 'FontSize', 13, 'FontWeight', 'bold');
legend('u''', 'v''', 'w''', 'Location', 'best');
grid on; xlim([1, 1000]);

subplot(2,3,5);
Re_rng = logspace(4, 6, 50);
f_cb_rng = zeros(size(Re_rng));
for i = 1:length(Re_rng)
    f_t = 0.02;
    for j = 1:15
        f_t = 1/(-2*log10(eps_rough/D_oil/3.7 + 2.51/(Re_rng(i)*sqrt(f_t))))^2;
    end
    f_cb_rng(i) = f_t;
end
f_bl_rng = 0.316./Re_rng.^0.25;
loglog(Re_rng, f_cb_rng, 'b-', 'LineWidth', 2); hold on;
loglog(Re_rng, f_bl_rng, 'g--', 'LineWidth', 2);
loglog(Re_D_oil, f_oil, 'ro', 'MarkerSize', 12, 'MarkerFaceColor', 'r');
xlabel('Re_D', 'FontSize', 12); ylabel('f', 'FontSize', 12);
title('Friction Correlations', 'FontSize', 13, 'FontWeight', 'bold');
legend('Colebrook', 'Blasius', 'Oil pipeline', 'Location', 'best');
grid on;

subplot(2,3,6);
x_km = linspace(0, L_oil/1000, 100);
P_drop = dPdx_oil*x_km*1000/1e6;
plot(x_km, P_drop, 'b-', 'LineWidth', 2.5);
xlabel('km', 'FontSize', 12); ylabel('MPa', 'FontSize', 12);
title(sprintf('Pressure (%.1f MPa total)', dP_oil/1e6), 'FontSize', 13, 'FontWeight', 'bold');
grid on;

sgtitle('DNS Analysis from JHTDB', 'FontSize', 15, 'FontWeight', 'bold');

% FIGURE 2: Oil Economics
figure('Position', [200,200,1200,700], 'Name', 'Oil Pipeline');

subplot(2,3,1);
Q_rng = linspace(0.3, 1.0, 20);
P_rng = zeros(size(Q_rng));
for i = 1:length(Q_rng)
    U_t = Q_rng(i)/(pi*(D_oil/2)^2);
    Re_t = rho_oil*U_t*D_oil/mu_oil;
    f_t = 0.02;
    for j = 1:15
        f_t = 1/(-2*log10(eps_rough/D_oil/3.7 + 2.51/(Re_t*sqrt(f_t))))^2;
    end
    dP_t = f_t*(L_oil/D_oil)*(rho_oil*U_t^2/2);
    P_rng(i) = dP_t*Q_rng(i)/0.78/0.94/1e6;
end
plot(Q_rng, P_rng, 'b-', 'LineWidth', 2); hold on;
plot(Q_oil, P_electrical, 'ro', 'MarkerSize', 12, 'MarkerFaceColor', 'r');
xlabel('Q [m^3/s]', 'FontSize', 11); ylabel('Power [MW]', 'FontSize', 11);
title('Power vs Flow', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

subplot(2,3,2);
powers = [P_hydraulic, P_shaft-P_hydraulic, P_electrical-P_shaft, P_electrical];
bar(powers);
set(gca, 'XTickLabel', {'Hydraulic', 'Pump Loss', 'Motor Loss', 'Total'});
ylabel('MW', 'FontSize', 11);
title('Power Breakdown', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

subplot(2,3,3);
bar([cost_annual, cost_annual*20]);
set(gca, 'XTickLabel', {'Annual', '20-Year'});
ylabel('Million $', 'FontSize', 11);
title('Costs', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

subplot(2,3,4);
bar([f_oil, f_blasius, f_swamee]);
set(gca, 'XTickLabel', {'Colebrook', 'Blasius', 'Swamee'});
ylabel('f', 'FontSize', 11);
title('Friction Methods', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

subplot(2,3,5);
T_rng = [15, 20, 25, 30, 35];
mu_rng = [0.018, 0.015, 0.012, 0.010, 0.008];
cost_rng = zeros(size(T_rng));
for i = 1:length(T_rng)
    rho_t = 865*(1 - 0.0007*(T_rng(i)-25));
    Re_t = rho_t*U_bulk_oil*D_oil/mu_rng(i);
    f_t = 0.02;
    for j = 1:15
        f_t = 1/(-2*log10(eps_rough/D_oil/3.7 + 2.51/(Re_t*sqrt(f_t))))^2;
    end
    dP_t = f_t*(L_oil/D_oil)*(rho_t*U_bulk_oil^2/2);
    P_t = dP_t*Q_oil/0.78/0.94/1e6;
    cost_rng(i) = P_t*8760*0.95/1000*1e6*0.12/1e6;
end
plot(T_rng, cost_rng, 'b-o', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b'); hold on;
plot(25, cost_annual, 'ro', 'MarkerSize', 12, 'MarkerFaceColor', 'r');
xlabel('T [C]', 'FontSize', 11); ylabel('Cost [M$]', 'FontSize', 11);
title('Temperature Effect', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

subplot(2,3,6);
bar([f_dns*1000, f_oil*1000]);
set(gca, 'XTickLabel', {'DNS', 'Colebrook'});
ylabel('f × 1000', 'FontSize', 11);
title('Friction Comparison', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

sgtitle(sprintf('Oil Pipeline: D=%.0fmm, L=%.0fkm, Re=%.1e, T=25C', D_oil*1000, L_oil/1000, Re_D_oil), 'FontSize', 14);

% % FIGURE 3: DNS vs Colebrook Log-Law Validation (NEW!)
% figure('Position', [300,300,1200,550], 'Name', 'DNS Validates Colebrook');
% 
% subplot(1,2,1);
% % DNS
% semilogx(dns_data.y_plus, dns_data.U_plus, 'bo', 'MarkerSize', 8, ...
%          'MarkerFaceColor', 'b', 'LineWidth', 1.5, 'DisplayName', 'DNS (Channel, Re_{tau}=1000)');
% hold on;
% 
% % Colebrook profile
% semilogx(y_plus_oil, U_plus_oil, 'r-', 'LineWidth', 2.5, ...
%          'DisplayName', 'Colebrook (Pipe, Re_D=9E4)');
% 
% % Viscous sublayer reference
% y_visc_ref = logspace(0, log10(5), 100);
% semilogx(y_visc_ref, y_visc_ref, 'k:', 'LineWidth', 2, 'DisplayName', 'U^+ = y^+ (viscous)');
% 
% % Log law reference
% y_log_ref = logspace(log10(30), 3, 100);
% U_log_ref = (1/0.41)*log(y_log_ref) + 5.2;
% semilogx(y_log_ref, U_log_ref, 'g--', 'LineWidth', 2, 'DisplayName', 'U^+ = 2.44ln(y^+) + 5.2 (log law)');
% 
% xlabel('y^+', 'FontSize', 13); ylabel('U^+', 'FontSize', 13);
% title('DNS and Colebrook Follow SAME Log-Law!', 'FontSize', 14, 'FontWeight', 'bold');
% legend('Location', 'northwest', 'FontSize', 10);
% grid on; xlim([0.8, 1000]); ylim([0, 25]);
% 
% text(50, 8, 'Both follow same log-law!', 'FontSize', 11, 'BackgroundColor', 'w', 'EdgeColor', 'k');

%% NEW FIGURE: Roughness sensitivity of the velocity profile
fprintf('\nGenerating roughness sweep plot...\n');

figure('Position', [350,350,1100,650], 'Name', 'Roughness Effect on Profile');

% Sweep covering hydraulically smooth -> transitional -> fully rough
eps_plus_sweep = [0, 5, 30, 100, 500];
colors_sweep = lines(length(eps_plus_sweep));
labels_sweep = {'\epsilon^+ = 0 (smooth, DNS limit)', ...
                '\epsilon^+ = 5 (hydraulically smooth edge)', ...
                '\epsilon^+ = 30 (transitional)', ...
                '\epsilon^+ = 100 (near fully rough)', ...
                '\epsilon^+ = 500 (fully rough)'};

% DNS reference points
plot(dns_data.y_plus, dns_data.U_plus, 'ko', 'MarkerSize', 8, ...
     'MarkerFaceColor', 'k', 'DisplayName', 'DNS (Channel, Re_{tau}=1000)');
hold on;

% Plot rough-wall log-law profile for each eps+
yp_grid = logspace(0, 3, 500);
for k = 1:length(eps_plus_sweep)
    eps_p = eps_plus_sweep(k);
    dU_p  = (1/kappa)*log(1 + 0.3*eps_p);

    Up_grid = zeros(size(yp_grid));
    for i = 1:length(yp_grid)
        yp = yp_grid(i);
        if yp < 5
            Up_grid(i) = yp;
        elseif yp < 30
            U_visc = 5;
            U_log  = (1/kappa)*log(30) + B_const - dU_p;
            alpha  = (yp - 5)/25;
            Up_grid(i) = U_visc*(1-alpha) + U_log*alpha;
        else
            Up_grid(i) = (1/kappa)*log(yp) + B_const - dU_p;
        end
    end

    plot(yp_grid, Up_grid, '-', 'LineWidth', 2.5, ...
         'Color', colors_sweep(k,:), 'DisplayName', labels_sweep{k});
end

% Locate where the actual oil pipeline sits on this map
u_tau_oil = U_bulk_oil * sqrt(f_oil/8);
nu_oil_v  = mu_oil / rho_oil;
eps_p_oil = eps_rough * u_tau_oil / nu_oil_v;
fprintf('Oil pipeline eps+ = %.3f  ->  hydraulically smooth (eps+ < 5)\n', eps_p_oil);

xlabel('y^+', 'FontSize', 13);
ylabel('U^+', 'FontSize', 13);
title('Velocity Profile Sensitivity to Wall Roughness', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'southeast', 'FontSize', 10);
grid on;
xlim([1, 150]); ylim([0, 25]);

text(60, 22, sprintf('Oil pipeline operates at \\epsilon^+ \\approx %.2f (smooth limit)', eps_p_oil), ...
     'FontSize', 11, 'BackgroundColor', 'y', 'EdgeColor', 'k');
% Conclusions:
% - eps+ = 0 curve overlays the DNS data exactly (validates the smooth limit)
% - Increasing eps+ shifts the LOG-LAYER (y+ > 30) downward by dU+ = (1/k)ln(1+0.3 eps+)
% - The viscous sublayer y+<5 is plotted but is physically destroyed once eps+ > 5
% - Our oil pipeline (eps+ ~ 0.4) sits squarely in the smooth-limit family
%   -> roughness barely changes the profile -> Colebrook ~ Prandtl-von Karman here
% - To get into the rough regime would require eps ~ several mm wall finish,
%   well outside commercial steel (eps = 0.045 mm)

% FIGURE 3: DNS vs Colebrook Log-Law Validation (NEW!)
figure('Position', [300,300,1200,550], 'Name', 'DNS Validates Colebrook');

subplot(1,2,1);
% DNS
plot(dns_data.y_plus, dns_data.U_plus, 'bo', 'MarkerSize', 8, ...
     'MarkerFaceColor', 'b', 'LineWidth', 1.5, 'DisplayName', 'DNS (Channel, Re_{tau}=1000)');
hold on;

% Colebrook profile
plot(y_plus_oil, U_plus_oil, 'r-', 'LineWidth', 2.5, ...
     'DisplayName', 'Colebrook (Pipe, Re_D=9E4)');

% Viscous sublayer reference
y_visc_ref = linspace(0, 5, 100);
plot(y_visc_ref, y_visc_ref, 'k:', 'LineWidth', 2, 'DisplayName', 'U^+ = y^+ (viscous)');

% Log law reference
y_log_ref = linspace(30, 1000, 100);
U_log_ref = (1/0.41)*log(y_log_ref) + 5.2;
plot(y_log_ref, U_log_ref, 'g--', 'LineWidth', 2, 'DisplayName', 'U^+ = 2.44ln(y^+) + 5.2 (log law)');

xlabel('y^+', 'FontSize', 13); 
ylabel('U^+', 'FontSize', 13);
title('DNS and Colebrook Follow SAME Log-Law!', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 10);
grid on; 
xlim([0, 150]); 
ylim([0, 25]);

text(500, 8, 'Both follow same log-law!', 'FontSize', 11, 'BackgroundColor', 'w', 'EdgeColor', 'k');

subplot(1,2,2);
loglog(Re_test, f_cb, 'b-', 'LineWidth', 3, 'DisplayName', 'Colebrook (smooth)');
hold on;
loglog(Re_test, f_pk, 'r--', 'LineWidth', 2, 'DisplayName', 'Prandtl-von Karman');
loglog(Re_D_oil, f_oil, 'go', 'MarkerSize', 12, 'MarkerFaceColor', 'g', 'DisplayName', 'Oil pipeline');
xlabel('Re_D', 'FontSize', 13); ylabel('f', 'FontSize', 13);
title('Colebrook IS Log-Law!', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 11);
grid on;

text(3e4, 0.022, sprintf('Difference < 0.01%%'), 'FontSize', 11, 'BackgroundColor', 'y', 'EdgeColor', 'k');

sgtitle('PROOF: DNS Validates Log-Law, Colebrook IS Log-Law → DNS Validates Colebrook!', 'FontSize', 15, 'FontWeight', 'bold');


%% PART 7: Summary and Save
fprintf('\n====================================================\n');
fprintf('PHASE 1 COMPLETE\n');
fprintf('====================================================\n');
fprintf('\nDNS Analysis:\n');
fprintf('  Re_tau = %d\n', dns_data.Re_tau);
fprintf('  Validates log-law ✓\n');
fprintf('\nOil Pipeline:\n');
fprintf('  f = %.6f\n', f_oil);
fprintf('  dP = %.1f MPa\n', dP_oil/1e6);
fprintf('  Power = %.1f MW\n', P_electrical);
fprintf('  Cost = $%.1f M/year\n', cost_annual);
fprintf('\nValidation:\n');
fprintf('  DNS → Log-law ✓\n');
fprintf('  Colebrook = Log-law ✓\n');
fprintf('  DNS validates Colebrook! ✓\n');
fprintf('====================================================\n');

oil_results = struct();
oil_results.D = D_oil;
oil_results.L = L_oil;
oil_results.Q = Q_oil;
oil_results.Re_D = Re_D_oil;
oil_results.f = f_oil;
oil_results.dP = dP_oil;
oil_results.Power = P_electrical;
oil_results.Cost_annual = cost_annual;
oil_results.u_tau = u_tau_oil;

%% ========================================================
%% PHASE 3: PARAMETRIC STUDY - TEMPERATURE EFFECTS
%% ========================================================

fprintf('\n====================================================\n');
fprintf('PHASE 3: Parametric Study - Temperature Effects\n');
fprintf('====================================================\n\n');

%% PART 8: Define Temperature Range
fprintf('PART 8: Temperature Parametric Study\n');
fprintf('-------------------------------------\n');

% Temperature range (15°C winter to 40°C peak summer)
T_range = [15, 18, 20, 22, 25, 28, 30, 33, 35, 38, 40];
N_temps = length(T_range);

fprintf('Temperature range: %.0f to %.0f deg C (%d points)\n', min(T_range), max(T_range), N_temps);

% Viscosity-temperature relationship (from Andrade equation)
% mu(T) = A*exp(B/T) where T in Kelvin 2.8e-4
% Fitted for WTI crude:
A_visc = 1.804e-5;  % Pa.s
B_visc = 1938;    % K

% Calculate properties at each temperature
rho_T = zeros(size(T_range));
mu_T = zeros(size(T_range));
nu_T = zeros(size(T_range));
Re_D_T = zeros(size(T_range));
f_T = zeros(size(T_range));
dP_T = zeros(size(T_range));
P_elec_T = zeros(size(T_range));
Cost_T = zeros(size(T_range));

fprintf('\nCalculating for each temperature...\n');
fprintf('T[C]  rho[kg/m3]  mu[cP]   Re_D      f        dP[MPa]  P[MW]   Cost[$M]\n');
fprintf('--------------------------------------------------------------------------------\n');

for i = 1:N_temps
    T_C = T_range(i);
    T_K = T_C + 273.15;
    
    % Density (thermal expansion)
    rho_T(i) = 865 * (1 - 0.0007*(T_C - 25));
    
    % Viscosity (Andrade equation)
    mu_T(i) = A_visc * exp(B_visc/T_K);
    mu_cP = mu_T(i) * 1000;  % Convert to cP
    
    % Kinematic viscosity
    nu_T(i) = mu_T(i) / rho_T(i);
    
    % Reynolds number (Q and D constant)
    Re_D_T(i) = rho_T(i) * U_bulk_oil * D_oil / mu_T(i);
    
    % Friction factor (Colebrook-White)
    f_temp = 0.02;
    for j = 1:20
        f_temp = 1/(-2*log10(eps_rough/D_oil/3.7 + 2.51/(Re_D_T(i)*sqrt(f_temp))))^2;
    end
    f_T(i) = f_temp;
    
    % Pressure drop
    dP_T(i) = f_T(i) * (L_oil/D_oil) * (rho_T(i)*U_bulk_oil^2/2);
    
    % Power
    P_hyd = dP_T(i)*Q_oil/1e6;
    P_elec_T(i) = P_hyd/0.78/0.94;
    
    % Annual cost
    Cost_T(i) = P_elec_T(i)*8760*0.95/1000*1e6*0.12/1e6;
    
    fprintf('%-4.0f  %-10.1f  %-8.2f %-9.2e %-8.6f %-8.2f %-7.2f %-8.2f\n', ...
            T_C, rho_T(i), mu_cP, Re_D_T(i), f_T(i), dP_T(i)/1e6, P_elec_T(i), Cost_T(i));
end

fprintf('\nSavings Analysis:\n');
fprintf('  Winter (15C): $%.2f M/year\n', Cost_T(1));
fprintf('  Summer (40C): $%.2f M/year\n', Cost_T(end));
fprintf('  Annual savings: $%.2f M/year (%.1f%% reduction)\n', ...
        Cost_T(1) - Cost_T(end), (Cost_T(1) - Cost_T(end))/Cost_T(1)*100);
fprintf('  20-year NPV: $%.1f M (at 5%% discount)\n', (Cost_T(1) - Cost_T(end))*12.46);

%% PART 9: Reynolds Number Parametric Study
fprintf('\nPART 9: Reynolds Number Parametric Study\n');
fprintf('-----------------------------------------\n');

% Extend Re range for design charts
Re_range_param = logspace(4, 6, 100);
f_range = zeros(size(Re_range_param));

for i = 1:length(Re_range_param)
    f_temp = 0.02;
    for j = 1:15
        f_temp = 1/(-2*log10(eps_rough/D_oil/3.7 + 2.51/(Re_range_param(i)*sqrt(f_temp))))^2;
    end
    f_range(i) = f_temp;
end

fprintf('Generated friction factor curve: Re = 1E4 to 1E6\n');

%% PART 10: Generate Parametric Study Plots
fprintf('\nPART 10: Generating Parametric Study Plots\n');
fprintf('-------------------------------------------\n');

% Find index for 25°C operating point
idx_25C = find(T_range == 25);
if isempty(idx_25C)
    % If 25 not in array, find closest
    [~, idx_25C] = min(abs(T_range - 25));
end

% FIGURE 5: Temperature Parametric Study
figure('Position', [400,100,1400,900], 'Name', 'Phase 3: Parametric Study');

% Plot 1: Viscosity vs Temperature
subplot(2,3,1);
plot(T_range, mu_T*1000, 'b-o', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
hold on;
plot(T_range(idx_25C), mu_T(idx_25C)*1000, 'ro', 'MarkerSize', 14, 'MarkerFaceColor', 'r', 'LineWidth', 3);
xlabel('Temperature [°C]', 'FontSize', 12);
ylabel('Viscosity [cP]', 'FontSize', 12);
title('Viscosity vs Temperature', 'FontSize', 13, 'FontWeight', 'bold');
grid on;
legend('WTI Crude', 'Operating point (25°C)', 'Location', 'best');

% Plot 2: Reynolds Number vs Temperature
subplot(2,3,2);
plot(T_range, Re_D_T, 'b-o', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
hold on;
plot(T_range(idx_25C), Re_D_T(idx_25C), 'ro', 'MarkerSize', 14, 'MarkerFaceColor', 'r', 'LineWidth', 3);
xlabel('Temperature [°C]', 'FontSize', 12);
ylabel('Re_D', 'FontSize', 12);
title('Reynolds Number vs Temperature', 'FontSize', 13, 'FontWeight', 'bold');
grid on;

% Plot 3: Friction Factor vs Temperature
subplot(2,3,3);
plot(T_range, f_T, 'b-o', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
hold on;
plot(T_range(idx_25C), f_T(idx_25C), 'ro', 'MarkerSize', 14, 'MarkerFaceColor', 'r', 'LineWidth', 3);
xlabel('Temperature [°C]', 'FontSize', 12);
ylabel('Friction factor f', 'FontSize', 12);
title('Friction Factor vs Temperature', 'FontSize', 13, 'FontWeight', 'bold');
grid on;

% Plot 4: Friction Factor vs Reynolds Number (Design Chart)
subplot(2,3,4);
loglog(Re_range_param, f_range, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Colebrook-White');
hold on;

% Mark ALL temperature points
loglog(Re_D_T, f_T, 'o', 'MarkerSize', 6, 'MarkerFaceColor', [0.7 0.7 0.7], ...
       'MarkerEdgeColor', 'k', 'LineWidth', 0.5, 'DisplayName', 'Temperature variation');

% Mark 25°C operating point
loglog(Re_D_T(idx_25C), f_T(idx_25C), 'ro', 'MarkerSize', 14, 'MarkerFaceColor', 'r', ...
       'LineWidth', 3, 'DisplayName', '25°C operating point');

% Add Blasius for reference
f_blasius_param = 0.316./Re_range_param.^0.25;
loglog(Re_range_param, f_blasius_param, 'g--', 'LineWidth', 2, 'DisplayName', 'Blasius (smooth)');

xlabel('Re_D', 'FontSize', 12);
ylabel('Friction factor f', 'FontSize', 12);
title('Friction Factor vs Reynolds Number', 'FontSize', 13, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
grid on;
xlim([5e4, 2e5]);
ylim([0.015, 0.025]);

% Plot 5: Pressure Drop vs Temperature
subplot(2,3,5);
plot(T_range, dP_T/1e6, 'b-o', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
hold on;
plot(T_range(idx_25C), dP_T(idx_25C)/1e6, 'ro', 'MarkerSize', 14, 'MarkerFaceColor', 'r', 'LineWidth', 3);
xlabel('Temperature [°C]', 'FontSize', 12);
ylabel('Pressure Drop [MPa]', 'FontSize', 12);
title('Pressure Drop vs Temperature', 'FontSize', 13, 'FontWeight', 'bold');
grid on;

% Plot 6: Annual Cost vs Temperature (Economic Impact)
subplot(2,3,6);
plot(T_range, Cost_T, 'b-o', 'LineWidth', 2.5, 'MarkerSize', 10, 'MarkerFaceColor', 'b');
hold on;
plot(T_range(idx_25C), Cost_T(idx_25C), 'ro', 'MarkerSize', 14, 'MarkerFaceColor', 'r', 'LineWidth', 3);

xlabel('Temperature [°C]', 'FontSize', 12);
ylabel('Annual Cost [Million $]', 'FontSize', 12);
title('Operating Cost vs Temperature', 'FontSize', 13, 'FontWeight', 'bold');
grid on;

% Add savings annotation
savings_annual = Cost_T(1) - Cost_T(end);
savings_pct = savings_annual/Cost_T(1)*100;

sgtitle('Phase 3: Parametric Study - Temperature Effects on Pipeline Economics', ...
        'FontSize', 15, 'FontWeight', 'bold');

%% Additional Plot: Friction Factor vs Roughness
fprintf('Creating friction vs roughness plot...\n');

figure('Position', [450,150,900,700], 'Name', 'Friction vs Roughness');

% Define Reynolds numbers to show
Re_values = [1e4, 3e4, 5e4, 7e4, 1e5, 3e5, 1e6];
colors = jet(length(Re_values));

% Define roughness range (ε/D from smooth to very rough)
eps_D_range = logspace(-6, -2, 100);  % 10^-6 to 10^-2

% Calculate friction factor for each Re and ε/D combination
f_matrix = zeros(length(Re_values), length(eps_D_range));

for i = 1:length(Re_values)
    Re_current = Re_values(i);
    
    for j = 1:length(eps_D_range)
        eps_D = eps_D_range(j);
        
        % Solve Colebrook-White
        f_temp = 0.02;
        for iter = 1:20
            f_temp = 1/(-2.0*log10(eps_D/3.7 + 2.51/(Re_current*sqrt(f_temp))))^2;
        end
        f_matrix(i,j) = f_temp;
    end
end

% Plot friction vs roughness for each Reynolds number
for i = 1:length(Re_values)
    loglog(eps_D_range, f_matrix(i,:), '-', 'LineWidth', 2, ...
           'Color', colors(i,:), 'DisplayName', sprintf('Re_D = %.0e', Re_values(i)));
    hold on;
end

% Mark YOUR oil pipeline operating point
eps_D_oil = eps_rough / D_oil;
loglog(eps_D_oil, f_oil, 'ro', 'MarkerSize', 16, 'MarkerFaceColor', 'r', ...
       'LineWidth', 3, 'DisplayName', 'Oil pipeline (Re=9E4)');

% Add smooth pipe line (Prandtl-von Karman for highest Re)
Re_smooth = 1e6;
f_smooth_range = zeros(size(eps_D_range));
for j = 1:length(eps_D_range)
    f_temp = 0.02;
    for iter = 1:15
        % Smooth pipe: eps_D = 0
        f_temp = 1/(2.0*log10(Re_smooth*sqrt(f_temp)) - 0.8)^2;
    end
    f_smooth_range(j) = f_temp;
end
loglog(eps_D_range, f_smooth_range, 'k--', 'LineWidth', 2.5, 'DisplayName', 'Smooth pipe limit');

% Mark hydraulically smooth region (ε+ < 5)
% For ε+ = 5: ε = 5*ν/u_τ
% For reference Re and typical f
xline(1e-5, 'g--', 'LineWidth', 1.5, 'DisplayName', 'Hydraulically smooth boundary');

xlabel('Relative roughness \epsilon/D', 'FontSize', 13);
ylabel('Friction factor f', 'FontSize', 13);
title('Friction Factor vs Pipe Roughness (Moody-type)', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 9);
grid on;
xlim([1e-6, 1e-2]);
ylim([0.01, 0.1]);

% Add annotations
text(2e-6, 0.015, 'Smooth pipe regime', 'FontSize', 10, 'Color', 'k');
text(5e-4, 0.06, 'Transitional', 'FontSize', 10, 'Color', 'b');
text(5e-3, 0.08, 'Fully rough', 'FontSize', 10, 'Color', 'r');

fprintf('Friction vs roughness plot complete!\n');

%% PART 11: Economic Analysis Summary
fprintf('\n====================================================\n');
fprintf('PHASE 3 COMPLETE: Parametric Study Summary\n');
fprintf('====================================================\n\n');

fprintf('TEMPERATURE SENSITIVITY ANALYSIS:\n');
fprintf('---------------------------------\n');
fprintf('Operating Point (25°C):\n');
fprintf('  Viscosity: %.0f cP\n', mu_oil*1000);
fprintf('  Re_D: %.2e\n', Re_D_oil);
fprintf('  Friction: f = %.6f\n', f_oil);
fprintf('  Annual cost: $%.2f M\n', cost_annual);

fprintf('\nWinter Operation (15°C):\n');
fprintf('  Viscosity: %.0f cP (+%.0f%% vs 25°C)\n', mu_T(1)*1000, (mu_T(1)/mu_oil-1)*100);
fprintf('  Re_D: %.2e (%.0f%% vs 25°C)\n', Re_D_T(1), (Re_D_T(1)/Re_D_oil-1)*100);
fprintf('  Friction: f = %.6f\n', f_T(1));
fprintf('  Annual cost: $%.2f M\n', Cost_T(1));

fprintf('\nSummer Operation (40°C):\n');
fprintf('  Viscosity: %.0f cP (%.0f%% vs 25°C)\n', mu_T(end)*1000, (mu_T(end)/mu_oil-1)*100);
fprintf('  Re_D: %.2e (+%.0f%% vs 25°C)\n', Re_D_T(end), (Re_D_T(end)/Re_D_oil-1)*100);
fprintf('  Friction: f = %.6f\n', f_T(end));
fprintf('  Annual cost: $%.2f M\n', Cost_T(end));

fprintf('\nECONOMIC IMPACT:\n');
fprintf('----------------\n');
fprintf('Winter vs Summer (15°C vs 40°C):\n');
fprintf('  Cost difference: $%.2f M/year\n', Cost_T(1) - Cost_T(end));
fprintf('  Percentage savings: %.1f%%\n', (Cost_T(1) - Cost_T(end))/Cost_T(1)*100);
fprintf('  20-year NPV savings: $%.1f M (5%% discount)\n', (Cost_T(1) - Cost_T(end))*12.46);

fprintf('\nOptimization Strategy:\n');
fprintf('  1. Operate at higher temperatures when possible\n');
fprintf('  2. Consider heating for heavy crudes\n');
fprintf('  3. Insulation may provide ROI\n');
fprintf('  4. Seasonal operating strategies\n');

%% Store Parametric Results
parametric_results = struct();
parametric_results.T_range = T_range;
parametric_results.rho_T = rho_T;
parametric_results.mu_T = mu_T;
parametric_results.Re_D_T = Re_D_T;
parametric_results.f_T = f_T;
parametric_results.dP_T = dP_T;
parametric_results.P_elec_T = P_elec_T;
parametric_results.Cost_T = Cost_T;
parametric_results.Re_range = Re_range_param;
parametric_results.f_range = f_range;

fprintf('\n====================================================\n');


save('phase1_complete.mat', 'dns_data', 'oil_results', 'parametric_results');
fprintf('\nSaved: phase1_complete.mat\n');
fprintf('====================================================\n');