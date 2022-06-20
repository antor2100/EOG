function write_kml_description(fid,i,verbose,dtcttype,dtstr,localdtstr,flarename,coords,waters,fishery,protected,landsea,filesav)

fprintf(fid,'<description><![CDATA[<table>\n');
fprintf(fid,'<tr><td>Type=%s </td></tr>\n',...
    dtcttype);
fprintf(fid,'<tr><td>Latitude=%f </td></tr>\n',...
    coords(i,1));
fprintf(fid,'<tr><td>Longitude=%f </td></tr>\n',...
    coords(i,2));
fprintf(fid,'<tr><td>Time UTC=%s </td></tr>\n',...
    dtstr);
fprintf(fid,'<tr><td>Local Time=%s </td></tr>\n',...
    localdtstr);
fprintf(fid,'<tr><td>DNB*1E9 Radiance=%f </td></tr>\n',...
    coords(i,3));
fprintf(fid,'<tr><td>EEZ=%s </td></tr>\n',...
    waters);
fprintf(fid,'<tr><td>FMZ=%s </td></tr>\n',...
    fishery);
fprintf(fid,'<tr><td>MPA=%s </td></tr>\n',...
    protected);

if verbose       
    fprintf(fid,'<tr><td><font size="2">&nbsp;</font></td></tr>\n');
    fprintf(fid,'<tr><td><font size="2">ID=%s </font></td></tr>\n',...
        flarename);
    fprintf(fid,'<tr><td><font size="2">QF_Detect=%d </font></td></tr>\n',...
        coords(i,4));
    fprintf(fid,'<tr><td><font size="2">QF_BitFlag=%d </font></td></tr>\n',...
        coords(i,13));    
    fprintf(fid,'<tr><td><font size="2">Land-Sea=%s </font></td></tr>\n',...
        landsea);
    if ~isempty(filesav)
        fprintf(fid,'<tr><td><font size="2">DNB_name=%s </font></td></tr>\n',...
            filesav);
    end
    fprintf(fid,'<tr><td><font size="2">Spike Median Index=%f </font></td></tr>\n',...
        coords(i,11));
    fprintf(fid,'<tr><td><font size="2">Sharpness Index=%f </font></td></tr>\n',...
        coords(i,5));
    fprintf(fid,'<tr><td><font size="2">Spike Height index=%f </font></td></tr>\n',...
        coords(i,6));
    fprintf(fid,'<tr><td><font size="2">SMI threshold=%g </font></td></tr>\n',...
        coords(i,12));
    fprintf(fid,'<tr><td><font size="2">Lunar illuminance=%g </font></td></tr>\n',...
        coords(i,14));
    fprintf(fid,'<tr><td><font size="2">DNB vs I05 correlation=%f </font></td></tr>\n',...
        coords(i,15));
end

fprintf(fid,'</table>]]></description>');