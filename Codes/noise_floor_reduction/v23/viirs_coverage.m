function covimage = viirs_coverage(latgring,longring, res, varargin)

% disp('Total number of input arguments: ' + nargin)

% formatSpec = 'Size of varargin cell array: %dx%d';
% str = compose(formatSpec,size(varargin));
% disp(str)

if length(latgring) == 12 % aggregate data
    latgring = latgring([1,2,3,5,7,8,9,11]);
    longring = longring([1,2,3,5,7,8,9,11]);
    
    % 1---2---3   
    % |       |   
    % 8       4
    % |       |
    % 7---6---5

    triangle1 = [longring([1,5,7]),latgring([1,5,7])];
    triangle2 = [longring([1,3,5]),latgring([1,3,5])];
    ntriangle = [longring([1,3,2]),latgring([1,3,2])];
    striangle = [longring([5,7,6]),latgring([5,7,6])];
    etriangle = [longring([3,5,4]),latgring([3,5,4])];
    wtriangle = [longring([7,1,8]),latgring([7,1,8])];
    
    corners1 = convertdms(triangle1,'d','r');
    corners2 = convertdms(triangle2,'d','r');
    ncorners = convertdms(ntriangle,'d','r');
    scorners = convertdms(striangle,'d','r');
    ecorners = convertdms(etriangle,'d','r');
    wcorners = convertdms(wtriangle,'d','r');
    
    [lonimage, latimage] = meshgrid(0:1/res:360-1/res, -90:1/res:90-1/res);
    positions = convertdms([lonimage(:),latimage(:)],'d','r');
    % size(positions)
    
    inflag=max(in_polysphere(positions,corners1),...
        in_polysphere(positions,corners2));
    % inflag = in_polysphere(positions,corners2);
    covimage = reshape(inflag,size(latimage));
    
    npix = convertdms([180+longring(2),-latgring(2)],'d','r');
    ncovimage = reshape(in_polysphere(positions,ncorners),size(latimage));
    if in_polysphere(npix,corners1) || in_polysphere(npix,corners2)
        %     disp('subtracting north')
        covimage = covimage - ncovimage;
    else
        %     disp('adding north')
        covimage = max(covimage,ncovimage);
    end
    
    spix = convertdms([180+longring(6),-latgring(6)],'d','r');
    scovimage = reshape(in_polysphere(positions,scorners),size(latimage));
    if in_polysphere(spix,corners1) || in_polysphere(spix,corners2)
        %     disp('subtracting south')
        covimage = covimage - scovimage;
    else
        %     disp('adding south')
        covimage = max(covimage,scovimage);
    end
    
    wpix = convertdms([180+longring(8),-latgring(8)],'d','r');
    wcovimage = reshape(in_polysphere(positions,wcorners),size(latimage));
    if in_polysphere(wpix,corners1,2) || in_polysphere(wpix,corners2,2)
        %     disp('subtracting west')
        covimage = covimage - wcovimage;
    else
        %     disp('adding west')
        covimage = max(covimage,wcovimage);
    end
    
    epix = convertdms([180+longring(4),-latgring(4)],'d','r');
    ecovimage = reshape(in_polysphere(positions,ecorners),size(latimage));
    if in_polysphere(epix,corners1,2) || in_polysphere(epix,corners2,2)
        %     disp('subtracting east')
        covimage = covimage - ecovimage;
    else
        %     disp('adding east')
        covimage = max(covimage,ecovimage);
    end
    
else % granule data

    % 1---2---3   
    % |       |   
    % |       |
    % 6---5---4

    triangle1 = [longring([1,4,6]),latgring([1,4,6])];
    triangle2 = [longring([1,3,4]),latgring([1,3,4])];
    ntriangle = [longring([1,3,2]),latgring([1,3,2])];
    striangle = [longring([4,6,5]),latgring([4,6,5])];
    
    corners1 = convertdms(triangle1,'d','r');
    corners2 = convertdms(triangle2,'d','r');
    ncorners = convertdms(ntriangle,'d','r');
    scorners = convertdms(striangle,'d','r');
    
    [lonimage, latimage] = meshgrid(0:1/res:360-1/res, -90:1/res:90-1/res);
    positions = convertdms([lonimage(:),latimage(:)],'d','r');
    % size(positions)
    
    inflag=max(in_polysphere(positions,corners1),...
        in_polysphere(positions,corners2));
    % inflag = in_polysphere(positions,corners2);
    covimage = reshape(inflag,size(latimage));
    
    npix = convertdms([180+longring(2),-latgring(2)],'d','r');
    ncovimage = reshape(in_polysphere(positions,ncorners),size(latimage));
    if in_polysphere(npix,corners1) || in_polysphere(npix,corners2)
        %     disp('subtracting north')
        covimage = covimage - ncovimage;
    else
        %     disp('adding north')
        covimage = max(covimage,ncovimage);
    end
    
    spix = convertdms([180+longring(5),-latgring(5)],'d','r');
    scovimage = reshape(in_polysphere(positions,scorners),size(latimage));
    if in_polysphere(spix,corners1) || in_polysphere(spix,corners2)
        %     disp('subtracting south')
        covimage = covimage - scovimage;
    else
        %     disp('adding south')
        covimage = max(covimage,scovimage);
    end
        
end

if length(varargin) > 0       
    obsdate = varargin{1};
    solzmax = varargin{2};
%     disp(['Nighttime coverage at date/time: ' datestr(obsdate)])

    [wAz,wEl] = SolarAzEl(obsdate,-latimage,lonimage-180,zeros(size(latimage)));
    solz = 90 - wEl;
%     max(wEl(find(covimage)))
%     min(wEl(find(covimage)))
    solzbw = wEl < 90 - solzmax;
    
    covimage = covimage & solzbw;
    
%     rasterSize = size(solz);
%     refmat = makerefmat( ...
%        'RasterSize', rasterSize, 'Latlim', [-90 90], ...
%        'Lonlim', [-180 180]);
% 
%     figure, mapshow(solzbw,refmat);
% 
%     figure, imagesc(-latimage.*covimage);    
%     colorbar;
%     
%     figure, imagesc((lonimage-180).*covimage);    
%     colorbar;
% 
%     figure, imagesc(solz);    
%     colorbar;
end
