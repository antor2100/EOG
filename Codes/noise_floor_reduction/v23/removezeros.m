function data2 = removezeros(data)

% Old way
% data2 = [];
% for i = 1:length(data)
%     if (data(i) ~= 0)
%         data2 = [data2 data(i)];
%     end
% end


% P = find(data ~= 0);
% data2 = data(P);


data2 = data((data~=0));

