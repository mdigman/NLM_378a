function myspectrogram(x, fs, frameLength, hopSize, decayDb)
%% function myspectrogram(x, fs, frameLength, hopSize)
%
% A function to plot the spectrogram of input signal
% using hann window and zpf = 8
%
% x: input signal( assume a row vector)
%
% fs: sampling rate of x
%
% frameLength: frame size (in samples)
%
% hopSize (optional): time between start times of successive windows (in 
%    samples). By default, hopSize = 1/2*frameLength. 50% hopSize prevents
%    amplitude modulation using a hann window when taking the IFFT of a
%    FFT signal, thus capturing exactly 100% of the signal energy.
%
% decayDb (optional): amplitude in decibel that is the lower end of the
%    graph scale. By default, this is -60dB, meaning that everything at
%    -60dB and below will be just black.
% 
% (c) 2012, 2013 Thomas Walther

    x = x';
    if(nargin == 2)
        i = 7;
        % find closest power of two to fs/10
        while 2^i < fs/20
            i = i+1;
        end
        % now 2^i should be > fs/10.
        if abs(fs/10 - 2^(i-1)) <= abs(fs/20 - 2^i)
            frameLength = 2^(i-1);
        else
            frameLength = 2^i;
        end
    end
    if(nargin <= 3)
        hopSize = ceil(frameLength/2);
    end
    if(nargin <= 4)
        decayDb = -60;
    end

    zpf = 8;
    M = floor((length(x)-frameLength) / hopSize);
    window = hann(frameLength);
    y = zeros(frameLength*zpf / 2, M);
    for i = 0:(M-1)
        start = i*hopSize + 1;
        block = x(:, start:start + frameLength - 1)'.*window;
        X = fft(block, length(block)*zpf);
        half = (length(X)/2);
        X = X(half+1:end, 1);
        y(:,i+1) = 20*log10(abs(X));
    end
    y = y - max(max(y));
    h = imagesc([0 length(x)/fs], [fs/2 0], y, [decayDb 0]);
    ylabel('frequency in Hz');
    xlabel('time in seconds');
    set(gca,'YDir','normal');
    title(sprintf('spectrogram from -%ddB to 0dB\nframelength: %d', round(decayDb), frameLength));
    %colormap('bone');
end