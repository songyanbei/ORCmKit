function eta_fin = FinSchmidt(hConv, k, th, r, B, H)
% functions that compute the fin efficiency based on Schmidt's theory and geometrical data of the HEX
% source : either Wang et al. or VDI, p1273 , M1
m = sqrt(2*hConv/k/th);
phi_f = B/r;
beta_f = H/B;
R_e = r*1.27*phi_f*(beta_f-0.3)^0.5;
phi = (R_e/r - 1)*(1+0.35*log(R_e/r));
eta_fin = tanh(m*r*phi)/(m*r*phi);
end
