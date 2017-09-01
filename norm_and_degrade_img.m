%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
% process_image_set.m
%+
%+ This routine will normalize a set of input images to have identical
%+ luminance and spatial frequency. Optionally, images can be noise-
%+ degraded via linear interpolation between a clear vs noisy image.
%+
%+ July 30, 2015
%+
%+ (input file names should read as three digits, e.g., 001.jpg, 002.jpg)
%+ (see line 47 to change for different file names)
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%

% ~~~~~ Input Options ~~~~~ %
% Number of images
nImages = 56;
% Input directory (accessed from current working directory)
inFileDir = 'loc';
% Input file format (e.g., 'jpg', 'png')
inFileFormat = 'png';
% Input file width
inFileW = 1200;
% Input file height
inFileH = 800;

% ~~~~~ Output Options ~~~~~ %
% Output directory
outFileDir = 'loc_normed';
% Output file format (e.g., 'png', 'jpg')
outFileFormat = 'png';
% Output filename suffix (e.g., '_degraded')
outFileSuffix = '';

% ~~~~~ Misc Options ~~~~~ %
% Set to 1 to pad images to nearest power of 2 for FT computations
bNearest2 = 0;
% Set to 1 if you want to degrade images
bDegrade = 0;
% If degrading, set percentage of phase noise to introduce
noisePercent = 0.99; 

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%

% ~~~~~ Compute FT-derived spectra ~~~~~ %
for i = 1:nImages
    rawImg{i} = imread( sprintf( '%s/%03i.%s', inFileDir, i, ...
        inFileFormat) );                            % Read image
    
    if bNearest2
        ftW = pow2( nextpow2( inFileW ) );          % Resize to nearest
        ftH = pow2( nextpow2( inFileH ) );          %+ power of 2.
    else
        ftW = inFileW;                              % Keep input
        ftH = inFileH;                              %+ dimensions
    end
    
    % FT components
    ft{i} = fft2( double( rawImg{i} ), ftH, ftW );	% Forward DFT
    ft_amp{i} = abs( ft{i} );                       % Amplitude spectrum
    ft_phase{i} = angle( ft{i} );                   % Phase angle spectrum
    %ft_power{i} = ft{i} .* conj(ft{i});            % Power spectrum
end

clear ft
%clear rawImg

% ~~~~~ Compute mean amplitude spectrum ~~~~~ %
ft_amp_mean = zeros(ftH, ftW, 3);
for i = 1:nImages
    % Sum all amplitudes across image set
    ft_amp_mean = ft_amp_mean + ft_amp{i};
end
% Take average
ft_amp_mean = ft_amp_mean ./ nImages;

clear ft_amp

% ~~~~~ Recombine signal into new image ~~~~~ %
for i = 1:nImages
    if bDegrade
        % randomize the original image to generate noise with
        %+ same RGB values of original image
        rand_img = rawImg{i};
        rand_img(randperm(numel(rand_img))) = rand_img;
        
        % create matrix of random phases from the random image
        rand_phase = zeros( ftH, ftW, 3 );
        rand_phase = angle( fft2( rand_img ) );
        %rand_phase(:,:,1) = angle( fft2( rand( ftH, ftW ) ) );
        %rand_phase(:,:,2) = angle( fft2( rand( ftH, ftW ) ) );
        %rand_phase(:,:,3) = angle( fft2( rand( ftH, ftW ) ) );
        
        % recombine with average amplitude
        noise_ft = ft_amp_mean .* exp( 1i * rand_phase );
        % invert to new image
        noise_img = uint8( real( ifft2( noise_ft ) ) );
    end

    % Recombine mean amplitude and image phase into new DFT
    new_ft = ft_amp_mean .* exp( 1i * ft_phase{i});
    % Invert DFT
    new_img = ifft2( new_ft );
    % Fix imaginary round-off
    new_img = real( new_img );
    % Convert to image friendly data type
    new_img = uint8( new_img );
    
    if bDegrade
        new_img = ( noisePercent * noise_img ) + ...
            ( ( 1.0 - noisePercent ) * new_img );
    end
    
    % Trim down to proper size
    new_img = new_img(1:inFileH, 1:inFileW, 1:3);
    % Write image file to disk
    disp( sprintf('Saving %s/%03i%s.%s...', outFileDir, i, ...
        outFileSuffix, outFileFormat ) );
    imwrite( new_img, sprintf( '%s/%03i%s.%s', outFileDir, i, ...
        outFileSuffix, outFileFormat ), outFileFormat );
end