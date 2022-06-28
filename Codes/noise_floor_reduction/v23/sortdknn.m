function [knndx,ix] = sortdknn(x,k)
% tic
% toc
knndx = [];
ix = [];
N = length(x);
if N < 2*k + 1
    warning(['Tail length ' num2str(N) ' is less than double number of neighbors ' num2str(k)])
else
    [sx,ix] = sort(x);
    knndx = zeros(size(x));
    for i=1:N
        dx = abs(sx - sx(i));
        if i-k < 1
            dxwin = 1:2*k+1;
        elseif i+k > N
            dxwin = max(1,N-2*k-1):N;
        else
            dxwin = i-k:i+k;
        end
%         i
%         k
%         N
%         dxwin
        sdx = sort(dx(dxwin));
        knndx(i) = mean(sdx(2:k+1));
    end
end