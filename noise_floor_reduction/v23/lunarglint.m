function [glint] = lunarglint(senz,solz,senaz,solaz,ws)
%calculates sun glint for     
%     senz = deg2rad(90-senz);
%     solz = deg2rad(90-solz);
%     relaz = deg2rad(relaz-180);
    relaz = double(senaz)-180-double(solaz);
    senz = deg2rad(senz);
    solz = deg2rad(solz);
    relaz = deg2rad(relaz);
    omega = acos(cos(senz).*cos(solz)-sin(senz).*sin(solz).*cos(relaz))/2;
    if (omega <= 0)
        omega = 1E-7;
    end
    
    beta = acos((cos(senz)+cos(solz))./(2.*cos(omega)));
    
    if (beta <= 0)
        beta = 1E-7;
    end
    
    alpha = acos((cos(beta).*cos(solz)-cos(omega))./(sin(beta).*sin(solz)));
    
    if (sin(relaz) <= 0)
        alpha = -1*alpha;
    end
    
    sigc = 0.04964*sqrt(ws);
    sigu = 0.04964*sqrt(ws);
    chi = 0;
    alphap = alpha+chi;
    swig = sin(alphap).*tan(beta)/sigc;
    eta = cos(alphap).*tan(beta)/sigu;
    expon = -1*(swig.^2+eta.^2)/2;
    
    if (expon < -30.)
        expon = -30;
    end
    
    if (expon > 30)
        expon = 30;
    end
    
    prob = exp(expon)/(2*pi*sigu*sigc);
    rho = reflec(omega);
    glint = rho.*prob./(4*cos(senz).*cos(beta).^4);

function [phi] = reflec(theta)
    ref = 4/3;
    if (theta < 0.00001)
        phi = 0.0204078; 
    else
        thetap = asin(sin(theta)/ref);
        phi = (sin(theta-thetap)./sin(theta+thetap)).^2+(tan(theta-thetap)./tan(theta+thetap)).^2;
    %#phi = ((sin(theta-thetap)/sin(theta+thetap))^2)+((tan(theta-thetap)/tan(theta+thetap))^2);
        phi = phi/2;
    end
