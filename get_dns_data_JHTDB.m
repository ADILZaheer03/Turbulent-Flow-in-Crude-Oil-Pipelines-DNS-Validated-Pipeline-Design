function [dns_data] = get_dns_data_JHTDB()
%GET_DNS_DATA_JHTDB Query JHTDB channel flow at Re_tau = 1000

fprintf('\n========== Querying JHTDB ==========\n');

authkey = 'YOUR_JHTDB_TOKEN_HERE';
dataset = 'channel';
variable = 'velocity';
temporal_method = 'none';
spatial_method = 'lag4';
spatial_operator = 'field';

Re_tau = 1000;
h = 1.0;
nu = 5e-5;
u_tau = Re_tau * nu / h;

fprintf('Re_tau=%d, h=%.1f, nu=%.2e, u_tau=%.4f\n', Re_tau, h, nu, u_tau);

y_plus_sample = [1, 3, 5, 7, 10, 12, 15, 20, 25, 30, 40, 50, 70, 100, 150, 200, 300, 500, 800, 1000]';
N_yplus = length(y_plus_sample);
y_from_wall = y_plus_sample * nu / u_tau;
y_physical = -h + y_from_wall;

x_plus = 0:48:804;
Nx = length(x_plus);
x_physical = x_plus * nu / u_tau;

z_plus = 0:24:204;
Nz = length(z_plus);
z_physical = z_plus * nu / u_tau;

fprintf('Sampling: %d y+, %dx%d plane = %d pts/plane\n', N_yplus, Nx, Nz, Nx*Nz);

time = 0.0;

U_mean = zeros(N_yplus, 1);
U_rms = zeros(N_yplus, 1);
V_rms = zeros(N_yplus, 1);
W_rms = zeros(N_yplus, 1);
UV_mean = zeros(N_yplus, 1);

fprintf('Querying... ');

for iy = 1:N_yplus
    if mod(iy, 5) == 0, fprintf('%d/%d ', iy, N_yplus); end
    
    y_j = y_physical(iy);
    n_points = Nx * Nz;
    points = zeros(n_points, 3);
    
    idx = 1;
    for ix = 1:Nx
        for iz = 1:Nz
            points(idx, :) = [x_physical(ix), y_j, z_physical(iz)];
            idx = idx + 1;
        end
    end
    
    try
        result = getData(authkey, dataset, variable, time, temporal_method, spatial_method, spatial_operator, points);
        u = result(:, 1);
        v = result(:, 2);
        w = result(:, 3);
        U_mean(iy) = mean(u);
        U_rms(iy) = std(u);
        V_rms(iy) = std(v);
        W_rms(iy) = std(w);
        UV_mean(iy) = mean(u .* v);
    catch ME
        warning('Failed y+=%.1f: %s', y_plus_sample(iy), ME.message);
        U_mean(iy) = NaN;
    end
end

fprintf('Done!\n');

U_plus = U_mean / u_tau;
k_plus = 0.5 * (U_rms.^2 + V_rms.^2 + W_rms.^2) / u_tau^2;
uv_plus = UV_mean / u_tau^2;

dns_data = struct();
dns_data.Re_tau = Re_tau;
dns_data.h = h;
dns_data.nu = nu;
dns_data.u_tau = u_tau;
dns_data.y_plus = y_plus_sample;
dns_data.U_plus = U_plus;
dns_data.k_plus = k_plus;
dns_data.uv_plus = uv_plus;
dns_data.U_rms = U_rms;
dns_data.V_rms = V_rms;
dns_data.W_rms = W_rms;
dns_data.kappa = 0.41;
dns_data.B = 5.2;

fprintf('DNS loaded: %d points\n', N_yplus);
fprintf('====================================\n');

end
