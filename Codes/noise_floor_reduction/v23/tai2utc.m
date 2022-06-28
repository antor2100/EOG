function dateutc = tai2utc(tai,datetai)

taicorr = 0;

if isempty(tai)
    dateutc = datetai;
else
    ntai = length(tai);
    for i = 1:ntai-1
%         taidatefrom = tai(i).date
%         taidateto = tai(i+1).date
%         datetai
	
        taifrom = datenum(tai(i).date,'yyyy mmm dd');
        taito = datenum(tai(i+1).date,'yyyy mmm dd');
        if datetai >= taifrom && datetai < taito
%             disp(['TAI_UTC interval found ' datestr(taifrom) ' to ' datestr(taito)])
            taicorr = tai(i).tai_utc;
        end
    end
    if datetai >= taito
%         disp(['TAI_UTC latest time stamp used ' datestr(taito)])
        taicorr = tai(ntai).tai_utc;
    end
    dateutc = datetai - taicorr/60/60/24;
%     dateinfo = datestr(dateutc)
end


