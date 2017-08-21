% new_data = SPM_high_pass_filter(data,TR,cut_off)
function new_data = SPM_high_pass_filter(data,TR,cut_off)

if nargin<3
    K.HParam = 100; % sekuntia
else
    K.HParam = cut_off; % sekuntia1
end
K.RT = TR;

if iscell(data)
    
    for k=1:length(data)
        N = size(data{k},1);
        L = size(data{k},2);
        %fprintf('data set %i: %i signals with duration %i\n',k,N,L);
        new_data{k} = zeros(size(data{k}));
        
        K.row=1:L;
        
        for kk=1:N
            y = data{k}(kk,:);
            K = spm_filter(K);
            new_data{k}(kk,:) = spm_filter(K,y');
            
        end
    end
    
else
    
    N = size(data,1);
    L = size(data,2);
    
    if N==1 || L==1
        data = data(:)';
        L=length(data);
        N=1;
    else
        fprintf('data set has %i signals with duration %i\n',N,L);
    end
        
    new_data = zeros(size(data));
    
    K.row=1:L;
    
    for k=1:N
        y = data(k,:);                
        
        K = spm_filter(K);
        new_data(k,:) = spm_filter(K,y');
        
    end
    
    % plot(t,y,t,yy);
    %
    % figure;
    %
    % NFFT = 2^nextpow2(L); % Next power of 2 from length of y
    %
    % Y = fft(y,NFFT)/L;
    %
    % YY = fft(yy,NFFT)/L;
    %
    % f = Fs/2*linspace(0,1,NFFT/2+1);
    %
    % % Plot single-sided amplitude spectrum.
    %
    % plot(f,2*abs(Y(1:NFFT/2+1)),f,2*abs(YY(1:NFFT/2+1)))
    %
    % title('Single-Sided Amplitude Spectrum of y(t)')
    %
    % xlabel('Frequency (Hz)')
    % ylabel('|Y(f)|')
    
end
end

