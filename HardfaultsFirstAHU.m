
clc; clear; close all;
%% User-defined Parameters
sOaMinSp = 10;
seasonalAvailability = 1; % 1 if heating is only available in the winter and cooling is only available in the summer

%% Load Data
% Read the CSV file using readtable with preserved original column names
data = readtable('canal ahu 1.csv', 'VariableNamingRule', 'preserve');

% Extract the textual date and time information for the timestamp
txt = data{:, 1}; % Assuming the first column is the date-time in text form

% Convert to MATLAB datetime using datetime (better alternative to datenum)
t = datetime(txt, 'InputFormat', 'yyyy-MM-dd HH:mm'); % Adjust format according to your actual timestamp format

% Extract numeric columns based on their position (similar to the original code)
num = data{:, 2:end}; % Exclude the first column which is date and time

% Assign the numeric data to variables as per your original code
tSa = num(:,11); % supply air temperature (degC)
tRa = num(:,9); % return air temperature (degC)
tOa = num(:,13); % outdoor air temperature (degC)
pSa = num(:,1); % supply air pressure (Pa)
sOa = num(:,3); % mixing box damper (%)
sHc = num(:,6); % heating coil valve (%)
sCc = num(:,7); % cooling coil valve (%)
sFan = num(:,2); % fan status (%)

%% mixing box model

ind = sHc == 0 & sCc == 0 & sFan > 0; % fan operating hours when heating and cooling are off
fOa = (tSa(ind) - tRa(ind))./(tOa(ind)-tRa(ind)); % outdoor air fraction
handle = sOa(ind)/100; % normalize mixing box damper [0 1]
ft = fittype('c/(1+exp(a*x+b))');
options = fitoptions(ft);
options.Robust = 'Bisquare';
options.Lower = [-20  -20 -20];
options.Upper = [20    20  20];
[mdlDmp,gofDmp] = fit(handle(fOa < 1 & fOa > 0),fOa(fOa < 1 & fOa > 0),ft,options);

% generate a plot defining the behaviour
fig = figure('units','inch','position',[0,0,2,2]);
    scatter(handle(fOa < 1 & fOa > 0),fOa(fOa < 1 & fOa > 0),12,[0 0 1],...
        'filled','o','MarkerFaceAlpha',.1,'MarkerEdgeAlpha',.1)
    hold on
    plot((0:0.01:1)',min(mdlDmp(0:0.01:1),1),'r','LineWidth',2)
    ylabel('Outdoor air fraction')
    xlabel('Mixing box damper signal')
    xlim([0 1])
    xticks(0:0.2:1)
    ylim([0 1])
    yticks(0:0.2:1)
    set(gca,'TickDir','out');
    box off
print(fig,'outdoor air fraction to damper.png','-r600','-dpng');


%% heating coil model
% fan operating hours when heating is on and cooling is off
ind = sFan > 0 & sHc > 0 & sCc == 0;
% mixed air estimate using the mixing box model
tMa = (mdlDmp(sOa(ind)./100).*tOa(ind) + (1-mdlDmp(sOa(ind)./100)).*tRa(ind));
yHtg = tSa(ind) - tMa;
xHtg = sHc(ind)/100;

ft = fittype('c/(1+exp(a*x+b))');
options = fitoptions(ft);
options.Robust = 'Bisquare';
options.Lower = [-20  -20 -20];
options.Upper = [20    20  20];
[mdlHtgCl,gofHtgCl] = fit(xHtg,yHtg,ft,options);

%% cooling coil model
% fan operating hours when heating is off and cooling is on
ind = sFan > 0 & sHc == 0 & sCc > 0;
% mixed air estimate using the mixing box model
tMa = (mdlDmp(sOa(ind)./100).*tOa(ind) + (1-mdlDmp(sOa(ind)./100)).*tRa(ind));
yClg = tSa(ind) - tMa;
xClg = sCc(ind)/100;

ft = fittype('c/(1+exp(a*x+b))');
options = fitoptions(ft);
options.Robust = 'Bisquare';
options.Lower = [-20  -20 -20];
options.Upper = [20    20  20];
[mdlClgCl,gofClgCl] = fit(xClg,yClg,ft,options);

fig = figure('units','inch','position',[0,0,3,3]);
    scatter(xHtg,yHtg,6,[1 0 0],'filled','o','MarkerFaceAlpha',.1,'MarkerEdgeAlpha',.1)
    hold on
    ha = plot((0:0.01:1)',mdlHtgCl(0:0.01:1),'r','LineWidth',2);
    scatter(xClg,yClg,6,[0 0 1],'filled','o','MarkerFaceAlpha',.1,'MarkerEdgeAlpha',.1)
    hb = plot((0:0.01:1)',mdlClgCl(0:0.01:1),'b','LineWidth',2);
    ylabel({['Temperature change (' char(176) 'C)']})
    xlabel('Coil valve fraction on')
    xlim([0 1])
    xticks(0:0.2:1)
    ylim([-20 20])
    yticks(-20:5:20)
    set(gca,'TickDir','out');
    box off   
    legend([ha hb], {'Heating coil','Cooling coil'},'NumColumns',2,'Location','northoutside')
    legend('boxoff')
print(fig,'temperature change across coil.png','-r600','-dpng');




