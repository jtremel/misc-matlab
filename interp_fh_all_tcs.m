clear all;

% input file (.xls format, each row is a single event timecourse)
sInFile = 'fh_it_regions_for_interp.xls';
sInSheet = { 'face_rgns', 'house_rgns'};
sOutFile = { 'fh_output_interp_face_rgns.txt', 'fh_output_interp_house_rgns.txt' };

% number of time points
nTp = 12;
% number of points between time points to interpolate
nTp_i = 1000;
% number of time points to move when stepping through each time series
nStep = 3;
% minimum and maximum time point for signal onset (1 = first time point)
nOnsetStartMin = 1;
nOnsetStartMax = nTp;
% percentage of peak magnitude that will be considered as the onset time
fOnsetThresh = [0.10, 0.15, 0.20, 0.25];

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
% set up timing
tp = 1:nTp;
tp_i = 1/nTp_i;
nx_i = (nTp * nTp_i) - (nTp_i - 1);
t_min_onset = (nOnsetStartMin * nTp_i)-999;

% read data, get row count
for sheets = 1:length(sInSheet)
    [tc] = xlsread( sInFile, sInSheet{sheets} );
    nRows = size(tc, 1);

    % preallocate so arrays don't grow in loop
    onsetTime = zeros(nRows, size(fOnsetThresh,2));
    onsetMag = zeros(nRows, size(fOnsetThresh,2));
    peakTime = zeros(nRows,1);
    peakMag = zeros(nRows,1);
    y_i = zeros(nRows, nx_i);

    % interpolate
    x_i = 1:tp_i:nTp;
    y_i(:,:) = interp1(tc(:,:)',x_i,'linear')';

    for row = 1:nRows
        [peakMag(row), peakTime(row)] = max(tc(row,:)); % grab peak data
        for i = 1:size(fOnsetThresh, 2);
            thresh = peakMag(row) * fOnsetThresh(i);
            x_i = (peakTime(row) * nTp_i) - (nTp_i - 1);
            while x_i ~= 0 && x_i > (t_min_onset) && y_i(row,x_i) > thresh;
                x_i = x_i - nStep;
                if x_i < t_min_onset
                    x_i = t_min_onset;
                end
            end
            onsetMag(row,i)=mean(y_i(row,x_i));
            % note if nTp_i is changed, this will need to be changed:
            onsetTime(row,i)=((x_i+999)/1000); 
        end
    end 
    output = [ onsetTime, onsetMag, peakTime, peakMag];

    save (sOutFile{sheets}, 'output', '-ASCII')
    output
    sOutFile{sheets}
end