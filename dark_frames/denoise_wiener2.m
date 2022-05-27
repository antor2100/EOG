function denoise_wiener2(INFILE,INSIGMA,varargin)

INFILE ='./for_misha/SVDNB_npp_d20141122_t1229070_e1234474_b15906_c20141122183448309762_noaa_ops.rad';
INSIGMA = './for_misha/SVDNB_npp_d20141122_t1229070_e1234474_b15906_c20141122183448309762_noaa_ops.zone_var';

[OUTPUT, SCALE, PLOT, SIZE, XTRA] = ...
    process_options(varargin, '-output', '', '-scale', 1, '-plot', 1,'-size',3);

sprintf('Adaptive Wiener denoising in %d x %d window for N = %d sigmas\n',SIZE,SIZE,SCALE)

outdir = '.';
fileDNB = INFILE;
[infile_pathstr, infile_name, infile_ext] = fileparts(INFILE);
if isempty(OUTPUT)
    outdir = infile_pathstr;
    outfile = fullfile(outdir,strcat(infile_name,'.denoised'));
    warning(['Using default output file name ',outfile]);
else
    [outfile_pathstr, outfile_name, outfile_ext] = fileparts(OUTPUT);
    outdir = outfile_pathstr;
    outfile = OUTPUT;
    disp(['Output file name ',outfile]);
end

%% Noisy image
[imageDNB,p,t,refmat]=freadenvi(INFILE);
imageDNB = flipud(imageDNB);

%% Variance image
[sigmanoise,p,t,refmat]=freadenvi(INSIGMA);
sigmanoise = flipud(sigmanoise);

af3 = single(wiener2(imageDNB,[SIZE SIZE],SCALE*sigmanoise));

info=enviinfo(af3);
enviwrite(flipud(af3),info,outfile); %implicit header file is "a.dat.hdr" (if not explicitly passed)

if PLOT
    
scrsz = get(0,'ScreenSize');
giddenoise = figure('Position',[1 1 scrsz(3) scrsz(4)]);

subplot(1,2,1)
imagesc(af3)
colormap('gray')
axis image
title('Denoised image')

subplot(1,2,2)
imagesc(imageDNB-af3)
colormap('gray')
axis image
title('Residual noise')

linkaxes
zoom on

scrsz = get(0,'ScreenSize');
gidstat = figure('Position',[1 1 scrsz(3) scrsz(4)]);

dnbvar = zeros(size(imageDNB,2),1);
for i = 1:size(imageDNB,2)
    dnbvar(i) = std(af3(:,i));
end
subplot(1,2,1)
plot(dnbvar)

noisevar = zeros(size(imageDNB,2),1);
for i = 1:size(imageDNB,2)
    noisevar(i) = std(imageDNB(:,i)-af3(:,i));
end
subplot(1,2,2)
plot(noisevar)

end







