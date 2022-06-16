function err = fitsmile(elaxes,theta,area,handle)

a = elaxes(1);
b = elaxes(2);

A = sqrt((a^2 + b^2 + (a^2 - b^2) * cosd(2 * theta))/2);
B = sqrt((a^2 + b^2 - (a^2 - b^2) * cosd(2 * theta))/2);

S = pi * b * B;

err = norm(area - S);

end