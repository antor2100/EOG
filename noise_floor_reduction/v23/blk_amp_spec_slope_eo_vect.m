
function [res] = blk_amp_spec_slope_eo_vect(blk)

persistent N;
persistent wnd;
persistent r;
persistent bind;
persistent nbins;

if (nargin == 0)
    N = [];
    wnd = [];
    return;
end

if (nargin == 2 || isempty(N))
    N = size(blk, 1);
    wnd = hanning(N);
    wnd = wnd * wnd';
    
    rbins = [0:N/2];
    nbins = numel(rbins);
    [x, y] = meshgrid([-N/2:N/2-1],[-N/2:N/2-1]);
    r = sqrt(x.^2+y.^2);
    bind = bindex(r,rbins);
end

if (~isa(blk, 'double'))
    blk = double(blk);
end
blk_wnd_prod = blk .* wnd;
fftu = fft2(blk_wnd_prod);
asfftu = fftshift(abs(fftu));

sumz=sparse(bind(:),1,asfftu(:),nbins,1);
n = sparse(bind(:),1,1,nbins,1);
ab = sumz./n;
fb = linspace(0,0.5,nbins+1);

% pb = polyfit(log(fb(2:end-1)), log(ab(1:end-1))', 1);
% res(1) = -pb(1);
% res(2) = pb(2);

pdiv =  [ones(length(fb(2:end-1)),1) log(fb(2:end-1))'] \ log(ab(1:end-1));
res(1) = -pdiv(2);
res(2) = pdiv(1);

% fig2 = figure();
% hold on
% plot(log(fs),log(as),'*b')
% plot(log(fs),res(2) - res(1) * log(fs),'-r','LineWidth',3)
% xlim([-4, 0]);
% hold off
% title(['Alpha = ' num2str(res(1))]);
%
% pause(1);
%
% close(fig2);

end