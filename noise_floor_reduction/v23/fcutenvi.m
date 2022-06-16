function [image,pout,t,refmat]=fcutenvi(fname,line,sample,height,width)
% freadenvi          	- read envi image (V. Guissard, Apr 29 2004)
%
% 				Reads an image of ENVI standard type 
%				to a [col x line x band] MATLAB array
%
% SYNTAX
%
% image=freadenvi(fname)
% [image,p]=freadenvi(fname)
% [image,p,t]=freadenvi(fname)
%
% INPUT :
%
% fname	string	giving the full pathname of the ENVI image to read.
%
% OUTPUT :
%
% image	c by l by b array containing the ENVI image values organised in
%				c : cols, l : lines and b : bands.
% p		1 by 3	vector that contains (1) the nb of cols, (2) the number.
%				of lines and (3) the number of bands of the opened image.
%
% t		string	describing the image data type string in MATLAB conventions.
%
% refmat   1 by 4 vector that contains (1)-(2) longitude and latitude of the
%               upper left corner of the image and (3)-(4) coordinate steps
%
% NOTE : 			freadenvi needs the corresponding image header file generated
%				automatically by ENVI. The ENVI header file must have the same name
%				as the ENVI image file + the '.hdf' exention.
%
%%%%%%%%%%%%%

% Parameters initialization
elements={'samples' 'lines' 'bands' 'data type' 'map info'};
d={'uint8' 'int16' 'int32' 'float32' 'float64' 'uint16' 'uint32' 'int64' 'uint64'};
si=[1 2 4 4 8 2 4 8 8];
% Check user input
if ~ischar(fname)
    error('fname should be a char string');
end


% Open ENVI header file to retreive s, l, b & d variables
rfid = fopen(strcat(fname,'.hdr'),'r');

% Check if the header file is correctely open
if rfid == -1
    error('Input header file does not exist');
end;

% Read ENVI image header file and get p(1) : nb samples,
% p(2) : nb lines, p(3) : nb bands and t : data type
while 1
    tline = fgetl(rfid);
    if ~ischar(tline), break, end
    [first,second]=strtok(tline,'=');
    
    switch strtrim(first)
        case elements(1)
            [f,s]=strtok(second);
            p(1)=str2num(s);
        case elements(2)
            [f,s]=strtok(second);
            p(2)=str2num(s);
        case elements(3)
            [f,s]=strtok(second);
            p(3)=str2num(s);
        case elements(4)
            [f,s]=strtok(second);
            t=str2num(s);
            switch t
                case 1
                    t=d(1);
                    si=si(1);
                case 2
                    t=d(2);
                    si=si(2);
                case 3
                    t=d(3);
                    si=si(3);
                case 4
                    t=d(4);
                    si=si(4);
                case 5
                    t=d(5);
                    si=si(5);
                case 12
                    t=d(6);
                    si=si(6);
                case 13
                    t=d(7);
                    si=si(7);
                case 14
                    t=d(8);
                    si=si(8);
                case 15
                    t=d(9);
                    si=si(9);
                otherwise
                    error('Unknown image data type');
            end
        case elements(5)
            [f,s]=strtok(second);
            [f,s]=strtok(s);
            [f,s]=strtok(s);
            [f,s]=strtok(s);
            refmat(1) = str2num(f);
            [f,s]=strtok(s);
            refmat(2) = str2num(f);
            [f,s]=strtok(s);
            refmat(3) = str2num(f);
            [f,s]=strtok(s);
            refmat(4) = str2num(f);
            [f,s]=strtok(s);
            refmat(5) = str2num(f);
            [f,s]=strtok(s,' }');
            % f
            refmat(6) = str2num(f);
    end
end
fclose(rfid);

t=t{1,1};
% Open the ENVI image and store it in the 'image' MATLAB array
disp([('Opening '),(num2str(p(1))),(' samples x '),(num2str(p(2))),(' lines x '),(num2str(p(3))),(' bands')]);
disp([('of type '), (t), (' image...')]);

sample = round(sample);
line = round(line);
width = round(width);
height = round(height);
pout(1) = width;
pout(2) = height;
if sample<1 || line<1 || height<1 || width <1 || sample>p(1) || line>p(2)
    error('Wrong images cut size')
end

if sample+width-1>p(1)
    warning('corrected width')
    width  = p(1)+1-sample;
end

if line+height-1>p(2)
    warning('corrected height')
    height = p(2)+1-line;
end

refmat(3) = refmat(3) + (sample - 1) * refmat(5);
refmat(4) = refmat(4) - (line - 1) * refmat(6);

fid=fopen(fname);
image = [];
cur_band = 1;
while cur_band<=p(3)
    fseek(fid, (p(1)*p(2)*(cur_band-1) + p(1)*(line-1)+(sample-1))*si, 'bof');
    image = [image; fread(fid, width*height, [num2str(width) '*' t '=>' t],(p(1)-width)*si)];
    cur_band = cur_band+1;
end
fclose(fid);
% size(image)
% width*height
image=reshape(image,[width,height,p(3)])';


