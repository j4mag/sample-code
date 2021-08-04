% PURPOSE:  Processes an input signal into ascii
%           16-QAM, HRRC pulse
%
% INPUTS:
%   r:   received signal, 16-QAM HRRC pulse
%
% OUTPUTS:
%   output: the estimated signal in ascii, a char array
%   sym:    the estimated signal data as passed to ESE471lab5b

function [output, sym] = ESE471lab6(r)
    %% processing
    %r(nT) = s
    
    %Demodulation
    t = 0:length(r)-1;
    M = 16;
    T_CARRIER = 4; %4 samples / cycle
    r_dm(1,:) = r.*sqrt(2).*cos(t*2*pi/T_CARRIER);
    r_dm(2,:) =-r.*sqrt(2).*sin(t*2*pi/T_CARRIER);
    
    %matched filter
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
    
    h = p(end:-1:1);
    x2(1,:) = conv(h,r_dm(1,:));
    x2(2,:) = conv(h,r_dm(2,:));
    
    %time synch
    SYNCH_DELAY=(2*Lp-1)*N+7; %was 11
    x2 = x2(:,SYNCH_DELAY+1:end-SYNCH_DELAY);
    
    figure(4)
    subplot(2,1,1)
    plot_eye_diagram(x2(1,:), N, 1);
    title('In Phase')
    subplot(2,1,2)
    plot_eye_diagram(x2(2,:), N, 1);
    title('Quadrature')

    %downsample
    r_hat(1,:) = x2(1,SAMPLE_RATE+1:SAMPLE_RATE:end);
    r_hat(2,:) = x2(2,SAMPLE_RATE+1:SAMPLE_RATE:end);
    
    
    %bit decisions
    a_hat   = round((r_hat/A+sqrt(M)-1)/2);
    sym     = b2gray(a_hat(1,:))*4 + b2gray(3-a_hat(2,:));
    sym_bin = de2bi(sym,log2(M),'left-msb')'; % express it as a binary vector
    
    %postprocessing
    try
        output = binvector2str(sym_bin(:)');
    catch e
        warning(e.message)
        output = '';
    end
    %% plotting
    
    figure(2)
    clf;
    subplot(3,2,1)
    plot(r)
    hold on
    title('r(nT)','Interpreter','Latex')
    ylabel('Volts')
    xlabel('Time (s)')
    
    subplot(3,2,2)
    plot(p)
    title('p(t)','Interpreter','Latex')
    ylabel('Volts')
    xlabel('Time (s)')
    
    subplot(3,2,3)
    plot(x2(1,:))
    hold on
    plot(x2(2,:))
    t = (1+SAMPLE_RATE):SAMPLE_RATE:length(x2);
    plot(t,r_hat(1,:),'o')
    plot(t,r_hat(2,:),'o')

    title('x(nT) vs x(kTs) (downsampled)','Interpreter','Latex')
    ylabel('Watts')
    xlabel('Time (s)')
    legend("x_0(nT)","x_1(nT)","x_0(kTs)","x_1(kTs)")
    
    subplot(3,2,4)
    plot(r_hat(1,:),r_hat(2,:),'o')
    xlim([min(r_hat(1,:))-1,max(r_hat(1,:))+1])
    ylim([min(r_hat(2,:))-1,max(r_hat(2,:))+1])
    title('Signal Space Projections of Symbol Estimates $$\hat{r}$$','Interpreter','Latex')
    xlabel('Amplitude (times A)')
    legend('x(kTs)','location','best')
    
    subplot(3,2,5)
    plot(sym,'o-')
    title('$$\hat{sym}(kTs)$$','Interpreter','Latex')
    ylabel('A')
    xlabel('k')
    
    subplot(3,2,6)
    histogram(sym)
    title('Symbol appearances in $$\hat{sym}(kTs)$$','Interpreter','Latex')
    ylabel('Number of Appearances')
    xlabel('Symbol')
end
