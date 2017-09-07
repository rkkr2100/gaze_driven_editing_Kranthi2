clc
clear all
close all

%% Cut Detection and Path Optimization
load AllData

outwidth_all = [400 350 350 570 496 572 350 0 350];

idx_video = 9;
fps = AllData{idx_video}.fps;
Data = AllData{idx_video}.Data;
resolution = AllData{idx_video}.resolution;

AR = 4/3;  % Required Aspect Ratio

l = min([length(Data{1}(:,1)) length(Data{2}(:,1)) length(Data{3}(:,1))]);
st = 1;
ed = l;
AData = [(Data{1}(st:ed,1)) (Data{2}(st:ed,1)) (Data{3}(st:ed,1))];

l = length(AData);
data = median(AData');
data = data';

%load 4e_R_data.mat
%data = data_c*1366/320;

% nearest neighbour approx
% nn = 0;
% for i=1:length(data)
%     if data(i) >=0
%         nn = data(i);
%     else
%         data(i) = nn;
%     end
% end


out_width = AllData{idx_video}.resolution(2);
out_width = round(outwidth_all(idx_video)*AR);
length1 = outwidth_all(idx_video);


size_data = size(data,1);
bool = ones(size_data,4); % all have equal weights

%% Finding cuts in gaze data

cut_dist = round(0.7*(out_width)); %was 150

N = size(data,1);
s_skip = 3;      % s-skip distance
fixtime = 24;    % Fixation time
k=24 ;      % no more than 1 cut in k frames

cuts_cvx = cut_detect_cvx(data,cut_dist,s_skip,fixtime,k);

figure,
%subplot(211)
plot(data,'.b')
hold on;
scatter(cuts_cvx,data(cuts_cvx),20,'*r')
% plot(abs(D1*data))
% plot(1:3600,ones(3600,1)*l2,'-k');
% plot(n3+1:N-n3,abs(D4*data.*(x(n3+1:N-n3))),'-m');
% plot(n3+1:N-n3,abs(D4*data),'-g');
% plot(n3+1:N-n3,abs(D4*data).*(x(n3+1:N-n3)) + (1-x(n3+1:N-n3))*(l2)-l2,'-g')
axis([0 l 0 1366])


%% DP

tic

[cuts_dp,dp_output,img,c1,cuts21] = cut_detect_DP(data,out_width,k,30,100,cut_dist,AData,1);
[cuts_dp_2,dp_output_2,img_2,c2,cuts22] = cut_detect_DP(data,out_width,k,30,100,cut_dist,AData,0);

toc



scatter(cuts_dp,dp_output(cuts_dp),20,'ok');
scatter(cuts21,dp_output(cuts21),20,'+r');
scatter(c1,dp_output(c1),20,'*r');

scatter(cuts_dp_2,dp_output_2(cuts_dp_2),20,'or');
scatter(cuts22,dp_output_2(cuts22),20,'+k');
scatter(c2,dp_output_2(c2),20,'*b');

plot(dp_output,'-k');
plot(dp_output_2,'-g');

% pause
% plot(temp(:,1),'-g')
% plot(temp(:,2),'-m');
% plot(temp(:,3),'-k');

img2 = img(size(img,1):-1:1,:);
figure,imshow(img2,[])

%% Zoom detection 

per_frameVar = var(AData');

mini = min(per_frameVar);
per_frameVar = per_frameVar-mini;
maxi = max(per_frameVar);

per_frameVar = 1 - ((1-(per_frameVar/maxi))*0.3)' ;

%% Path Optimization

% load original cuts
A = importdata(['./original_cut_detection/' AllData{idx_video}.filename(1:end-4) '_shots.txt'], ' ');
cuts_org = A(:,1);
cuts = c1;
bool = ones(N,4);

% generate bool variables
% for original cuts

% [dp_output_smooth,L2_cuts]= smooth_DP(cuts21,c1,dp_output,out_width,bool) ; 


bool(cuts_org(1):cuts_org(1)+s_skip,1) = 0;
for i=2:length(cuts_org)
        bool(cuts_org(i):cuts_org(i)+s_skip,1) = 0;
        bool(cuts_org(i):cuts_org(i),2) = 0;
        bool(cuts_org(i)-1:cuts_org(i),3) = 0;
        bool(cuts_org(i)-2:cuts_org(i),4) = 0;
end

% for detected cuts
for i=2:length(cuts)
        bool(cuts(i):cuts(i)+s_skip,1) = 0;
        bool(cuts(i):cuts(i),2) = 0;
        bool(cuts(i)-1:cuts(i),3) = 0;
        bool(cuts(i)-2:cuts(i),4) = 0;
end
%bool(1:10,1) = 0;
bool(l-3:l,[0 2 3]+1) = 0;
bool(l-3:l,1) = 1;
bool = bool(1:l,:);


lambda0 = 0.005;
lambda1 = 50;
lambda2 = 5;
lambda3 = 30;
vc1 = 3;
vc2 = 3;

thresh = out_width*0.2;

[opt_data,temp1, temp2,zoom]=path_optimization_cvx(data,bool,lambda0,lambda1,lambda2,lambda3,vc1,vc2,thresh,per_frameVar);
[opt_data_dp,temp1_dp, temp2_dp,zoom_dp]=path_optimization_cvx(dp_output,bool,lambda0,lambda1,lambda2,lambda3,vc1,vc2,thresh,per_frameVar);




figure,
%subplot(211)
plot(data,'.b')
hold on;
plot(dp_output,'-k')
%axis([0 l 0 1366])

plot(opt_data,'-g')
plot(opt_data_dp,'-r')
legend('Gaze Data', 'Track')

% subplot(212);
% plot(temp1,'-b')
% hold on
% plot(temp2,'-r')
% 
% plot(temp1_dp,'.k')
% hold on
% plot(temp2_dp,'.m')
% 
% axis([0 l 0 6])

out_width
length1

one= [];
si = size(opt_data_dp,1);
for i =1:si
   
   out_width = round( (length1*zoom_dp(i)*AR) - mod(round((length1*zoom_dp(i)*AR)),2)) ;
   h  =  round(length1*zoom_dp(i)) - mod(round((length1*zoom_dp(i))),2)  ;
   
   t_y = round(opt_data_dp(i,1)-out_width/2) ;   
   if(t_y <= 0)
    t_y = 1;
   end
   if(t_y+out_width>=1366)
   t_y=1366-out_width;
   end
   
   top = round( length1/2 - h/2 );
   
   
   one = vertcat(one,[t_y,top,out_width,h]);
   
end
close all
dlmwrite([AllData{idx_video}.filename(1:end-4),'_optzoom.txt'],one);


% fileID = fopen([AllData{idx_video}.filename(1:end-4) '_optpath.txt'],'w');
% fprintf(fileID,'%f \n',opt_data');
% fclose(fileID);
% 
% fileID = fopen([AllData{idx_video}.filename(1:end-4) '_optpath_dp.txt'],'w');
% fprintf(fileID,'%f \n',opt_data_dp');
% fclose(fileID);