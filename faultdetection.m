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
tSa = num(:, 11); % Supply air temperature (degC)
tRa = num(:, 9); % Return air temperature (degC)
tOa = num(:, 13); % Outdoor air temperature (degC)
pSa = num(:, 1);  % Supply air pressure (Pa)
sOa = num(:, 3);  % Outdoor Air Damper (%)
sHc = num(:, 6);  % Heating Coil State (%)
sCc = num(:, 7);  % Cooling Coil State (%)
sFan = num(:, 2); % Fan VFD state

if seasonalAvailability == 1
    sCc = (month(t) > 4 & month(t) < 10).*sCc;
    sHc = (month(t) < 5 | month(t) > 9).*sHc;
 
end



%% state of operation

indOperating = (weekday(t) > 1 & weekday(t) < 7) & (hour(t) > 7 & hour(t) < 17) & sFan > 10;
indHtg = indOperating & sHc > 0 & tOa < tSa & sOa > sOaMinSp - 5 & sOa < sOaMinSp + 5 & sCc < 5;
indEcon = indOperating & sHc < 5 & tOa < tSa & sOa > sOaMinSp & sCc == 0;
indEconClg = indOperating & sHc < 5 & tOa > tSa & tRa > tOa & sOa > 90 & sCc > 0;
indClg = indOperating & sHc < 5 & tOa > tSa & tRa > tSa & sOa > sOaMinSp - 5 & sOa < sOaMinSp + 5 & sCc > 0;
indNormal = indHtg | indEcon | indEconClg | indClg;
indFault = setdiff(find(indOperating),find(indNormal));

fig = figure('units','inch','position',[0,0,6,10]);    
      subplot(3,1,1)
          scatter(tOa(indHtg),sOa(indHtg),12,[1 0 0],...
          'filled','o','MarkerFaceAlpha',.3,'MarkerEdgeAlpha',.3);
          hold on
          scatter(tOa(indEcon),sOa(indEcon),12,[0 1 0],...
          'filled','o','MarkerFaceAlpha',.3,'MarkerEdgeAlpha',.3);
          scatter(tOa(indEconClg),sOa(indEconClg),12,[0 1 0],...
          'filled','o','MarkerFaceAlpha',.3,'MarkerEdgeAlpha',.3);
          scatter(tOa(indClg),sOa(indClg),12,[0 0 1],...
          'filled','o','MarkerFaceAlpha',.3,'MarkerEdgeAlpha',.3);
          scatter(tOa(indFault),sOa(indFault),12,[0 0 0],...
          'filled','o','MarkerFaceAlpha',.8,'MarkerEdgeAlpha',.8); 
          text(-25,100,strcat('Total normal =', num2str(sum(indNormal)),'h'));
          text(-25,90,strcat('Heating state =', num2str(sum(indHtg)),'h'));
          text(-25,80,strcat('Economizer state =', num2str(sum(indEcon)),'h'));
          text(-25,70,strcat('Economizer with cooling state =', num2str(sum(indEconClg)),'h'));
          text(-25,60,strcat('Cooling state =', num2str(sum(indClg)),'h'));
          text(-25,50,strcat('Fault state =', num2str(length(indFault)),'h'));
          xlim([-30 30])
          xticks(-30:10:30)
          ylim([0 100])
          yticks(0:10:100)
          ylabel('Mixing box damper position (%)')
          xlabel('Outdoor air temperature (^{o}C)')
          set(gca,'TickDir','out');
          box off
      subplot(3,1,2)
          scatter(tOa(indHtg),sHc(indHtg),12,[1 0 0],...
          'filled','o','MarkerFaceAlpha',.3,'MarkerEdgeAlpha',.3);
          hold on
          scatter(tOa(indEcon),sHc(indEcon),12,[0 1 0],...
          'filled','o','MarkerFaceAlpha',.3,'MarkerEdgeAlpha',.3);
          scatter(tOa(indEconClg),sHc(indEconClg),12,[0 1 0],...
          'filled','o','MarkerFaceAlpha',.3,'MarkerEdgeAlpha',.3);
          scatter(tOa(indClg),sHc(indClg),12,[0 0 1],...
          'filled','o','MarkerFaceAlpha',.3,'MarkerEdgeAlpha',.3);
          scatter(tOa(indFault),sHc(indFault),12,[0 0 0],...
          'filled','o','MarkerFaceAlpha',.8,'MarkerEdgeAlpha',.8); 
          xlim([-30 30])
          xticks(-30:10:30)
          ylim([0 100])
          yticks(0:10:100)
          ylabel('Heating coil (%)')
          xlabel('Outdoor air temperature (^{o}C)')
          set(gca,'TickDir','out');
          box off
      subplot(3,1,3)
          scatter(tOa(indHtg),sCc(indHtg),12,[1 0 0],...
          'filled','o','MarkerFaceAlpha',.3,'MarkerEdgeAlpha',.3);
          hold on
          scatter(tOa(indEcon),sCc(indEcon),12,[0 1 0],...
          'filled','o','MarkerFaceAlpha',.3,'MarkerEdgeAlpha',.3);
          scatter(tOa(indEconClg),sCc(indEconClg),12,[0 1 0],...
          'filled','o','MarkerFaceAlpha',.3,'MarkerEdgeAlpha',.3);
          scatter(tOa(indClg),sCc(indClg),12,[0 0 1],...
          'filled','o','MarkerFaceAlpha',.3,'MarkerEdgeAlpha',.3);
          scatter(tOa(indFault),sCc(indFault),12,[0 0 0],...
          'filled','o','MarkerFaceAlpha',.8,'MarkerEdgeAlpha',.8); 
          xlim([-30 30])
          xticks(-30:10:30)
          ylim([0 100])
          yticks(0:10:100)
          ylabel('Cooling coil (%)')
          xlabel('Outdoor air temperature (^{o}C)')
          set(gca,'TickDir','out');
          box off
print(fig,'3.1.state of operation.png','-r600','-dpng');


%% mode of operation
datenums = datenum(t);
timeOfDay = hour(datenums);
dayOfWeek = weekday(datenums);

k = 1; numStateChange = []; timeOfSwitchOn = []; timeOfSwitchOff = [];
for i = floor(min(datenums))+1:floor(max(datenums))-2
  numStateChange(k,1) = sum(abs(diff(sFan(datenums >= i & datenums <= i + 1))) > 0.5);
  timeOfSwitchOn = [timeOfSwitchOn;timeOfDay(diff(sFan(datenums >= i & datenums <= i + 1)) > 0.5)];
  timeOfSwitchOff = [timeOfSwitchOff;timeOfDay(diff(sFan(datenums >= i & datenums <= i + 1)) < -0.5)];
  k = k + 1;
end


fig = figure('units','inch','position',[0,0,5,6]);
subplot(2,1,1)
    edges = [-0.5:10.5];
    h = histogram(numStateChange,edges,'Normalization','probability');
    h.FaceColor = [0 0 0];
    h.FaceAlpha = 0.1;
    h.EdgeColor = 'k';
    h.EdgeAlpha = 0.7;
    xticks(0:1:10)
    xlim([-0.49 10])
    xlabel({'Daily fan state change instances'})
    ylabel({'Fraction of days'})
    set(gca,'TickDir','out');
    box off
    
subplot(2,1,2)
    edges = [0:24];
    h = histogram(timeOfSwitchOn,edges,'Normalization','probability');
    h.FaceColor = [0 0 0];
    h.FaceAlpha = 0.1;
    h.EdgeColor = 'k';
    h.EdgeAlpha = 0.7;
    hold on
    h = histogram(timeOfSwitchOff,edges,'Normalization','probability');
    h.FaceColor = [1 0 0];
    h.FaceAlpha = 0.1;
    h.EdgeColor = 'r';
    h.EdgeAlpha = 0.7;
    xticks(0:1:24)
    ylim([0 1])
    xlabel({'Time of day (h)'})
    ylabel({'Fraction of fan state changes'})
    legend('Fan switch on','Fan switch off')
    set(gca,'TickDir','out');
    box off   
    legend boxoff  
print(fig,'3.2.Mode of operation.png','-r600','-dpng');


%% supply air temperature setpoint reset

fig = figure('units','inch','position',[0,0,3,3]);
    ind = isoutlier(tSa) == 0 & (timeOfDay > 7 & timeOfDay < 18) & (dayOfWeek > 1 & dayOfWeek < 7);
    scatter(tOa(ind),tSa(ind),'filled','o','MarkerFaceAlpha',.1,'MarkerEdgeAlpha',.1)
    hold on
    handle = -25:30;
    satResetPrmtr = [12,17,12,-12;13,20,19,-6];
    store = [];
    for i = 1:2
    tSaIdeal = (handle > satResetPrmtr(i,3)).*satResetPrmtr(i,1)...
         +(handle < satResetPrmtr(i,4)).*satResetPrmtr(i,2);
    tSaIdeal(tSaIdeal == 0) = flip(interp1([satResetPrmtr(i,4);satResetPrmtr(i,3)],[satResetPrmtr(i,1);satResetPrmtr(i,2)],(satResetPrmtr(i,4):satResetPrmtr(i,3))'));
    tSaIdeal = interp1(handle,tSaIdeal,-25:30);
    store = [store,tSaIdeal'];
    end

    plot(handle',store(:,1),'r','LineWidth',2)
    plot(handle',store(:,2),'r--','LineWidth',2)
    xlabel({['Outdoor air temperature (' char(176) 'C)']})
    ylabel({['Supply air temperature (' char(176) 'C)']})
    xlim([-25 30])
    xticks(-25:5:30)
    ylim([10 24])
    yticks(10:1:24)
    set(gca,'TickDir','out');
    box off
    s = patch([handle';flip(handle')],[store(:,1);flip(store(:,2))],'r');
    s.FaceAlpha = 0.1;
    s.EdgeColor = 'w';
    s.EdgeAlpha = 0;
    legend({'Measured','Expected low','Expected high'},'NumColumns',2,'Location','northoutside')
    legend('boxoff') 
print(fig,'3.3.supply air temperature.png','-r600','-dpng');
