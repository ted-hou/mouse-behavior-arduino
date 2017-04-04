numchannels = 1;
numcolumns = numchannels + 1;

% Find the total length of data points:
FileID = fopen('C:\Users\DollahDollahBillz\Dropbox (MIT)\1 ASSAD LAB\Fiber Photometry Debug\fake.bin', 'r');
data = fread(FileID, 'double');
numrows = length(data)/numcolumns;

data = reshape(data, [numrows, numcolumns]);

fclose(FileID);

% % Then put in the right shape:
% FileID2 = fopen('C:\Users\DollahDollahBillz\Dropbox (MIT)\1 ASSAD LAB\Fiber Photometry Debug\fake.bin', 'r');
% data2 = fread(FileID, [numrows,numcolumns], 'double');
