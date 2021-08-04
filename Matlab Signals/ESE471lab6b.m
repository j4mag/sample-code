% PURPOSE:  Generates a test signal for ESE471lab5, with diagnostic plots
%           16-QAM, HRRC pulse
%
% INPUTS:
%   data:   data vector, base 16
%
% OUTPUTS:  
%   s:      signal vector

function s = ESE471lab6b(data)
    %uses Communications Systems Toolbox (gray2bin);
    %data = [0 7 1 3 2 6 5];
    %16-QAM
    M=16;
    
    a_k_b = b2gray([fix(data/log2(M));
             mod(data,log2(M))]);
    a_k   = 2*[a_k_b(1,:);3-a_k_b(2,:)]-sqrt(M)+1;
       
    %upsample
    SAMPLE_RATE = 8; %8 samples/bit
    a_k_ex(1,:) = upsample(a_k(1,:),SAMPLE_RATE,SAMPLE_RATE-1);
    a_k_ex(2,:) = upsample(a_k(2,:),SAMPLE_RATE,SAMPLE_RATE-1);

    %modulate
    SAMPLE_RATE = 8; %Ts: 8 samples / signal  
    N = SAMPLE_RATE;
    ENERGY_PER_SYMBOL = 40;
    A = sqrt(ENERGY_PER_SYMBOL/10);
    alpha = 0.3;
    Lp = 8;
    n = -Lp*N:Lp*N;
    p = 1/sqrt(N)*(sin(pi*(1-alpha)*n/N) + 4*alpha*n/N.*cos(pi*(1+alpha)*n/N)) ...
                ./ (pi*n/N.*(1-(4*alpha*n/N).^2));    
    p(n==0) = 1/sqrt(N)*(1-alpha+4*alpha/pi);
    p(ismember(n,[-N/(4*alpha), N/(4*alpha)])) = 1/sqrt(N)*alpha/sqrt(2)*...
        ((1+2/pi)*sin(pi/4/alpha)+(1-2/pi)*cos(pi/4/alpha));
    p = A*p;
    
    signal(1,:) = conv(a_k_ex(1,:),p);
    signal(2,:) = conv(a_k_ex(2,:),p);
    
    %time_desync
    TIME_SYNCH = 0;
    signal_ex = [zeros(2,TIME_SYNCH) signal];
    t = 0:length(signal_ex)-1;
    T_CARRIER = 4; %4 samples / cycle
    signal_mod(1,:) = signal_ex(1,:).*sqrt(2).*cos(t*2*pi/T_CARRIER);
    signal_mod(2,:) =-signal_ex(2,:).*sqrt(2).*sin(t*2*pi/T_CARRIER);
    
    s = signal_mod(1,:)+signal_mod(2,:);
    
    figure(3)
    clf
    subplot(3,2,1)
    plot(data,'-o')
    legend('data(t)')
    title('$$a_k(t)$$','Interpreter','Latex')
    
    subplot(3,2,2)
    plot(n,p)
    title('p(t)','Interpreter','Latex')
    
    subplot(3,2,3)
    plot(signal_ex(1,:))
    hold on
    plot(signal_ex(2,:))
    t = (1:length(a_k))*SAMPLE_RATE+Lp*N;
    plot(t,a_k(1,:),'o')
    plot(t,a_k(2,:),'o')
    title('$$s_{unmodulated}(t)$$','Interpreter','Latex')
    legend('s_0(t)','s_1(t)','a_0(k)','a_1(k)')
    
    subplot(3,2,4)
    plot(a_k(1,:),a_k(2,:),'o')
    xlim([min(a_k(1,:))-1,max(a_k(1,:))+1])
    ylim([min(a_k(2,:))-1,max(a_k(2,:))+1])
    title('Signal Space Projections of Symbol Estimates s','Interpreter','Latex')
    xlabel('Amplitude (times A)')
    legend('x(kTs)')    
    
    subplot(3,2,5)
    plot(s)
    title('s(t)','Interpreter','Latex')
    
    subplot(3,2,6)
    histogram(data)
    title('Symbol appearances in s(kTs)','Interpreter','Latex')
    ylabel('Number of Appearances')
    xlabel('Symbol')
end