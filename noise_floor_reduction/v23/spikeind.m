function spindx = spikeind(img)

[n,m] = size(img);

spindx = zeros(size(img));
vspindx = spindx;
hspindx = spindx;

% for i = 1:n
%     if img(i,1) > 0
%         hspindx(i,1) = (img(i,1)-img(i,2)) / img(i,1);
%     end
%     if img(i,m) > 0
%         hspindx(i,m) = (img(i,m)-img(i,m-1)) / img(i,m);
%     end
% end
% 
% for j = 1:m
%     if img(1,j) > 0
%         vspindx(1,j) = (img(1,j)-img(2,j)) / img(1,j);
%     end
%     if img(n,j) > 0
%         vspindx(n,j) = (img(n,j)-img(n,j-1)) / img(n,j);
%     end
% end

img = max(img,0);
for i = 2:n-1
    for j = 2:m-1
        if img(i,j) > 0
            hspindx(i,j) = max(0,(img(i,j) - (img(i,j-1) + img(i,j+1))/2)) / img(i,j);
            vspindx(i,j) = max(0,(img(i,j) - (img(i-1,j) + img(i+1,j))/2)) / img(i,j);
            spindx(i,j) = max(hspindx(i,j),vspindx(i,j));
        end
    end
end

end