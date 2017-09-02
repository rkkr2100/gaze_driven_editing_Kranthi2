function [final_cuts_dp,a, img,c,cuts2] = cut_detect_DP(data,out_width,k,sigma,duration,cut_dist,Adata,flag)

N = size(data,1);
e = ones(N,1);


[a,b,c,d,img,cuts2]=DP_findcut2(data,1366,out_width,sigma,duration,Adata,flag);

De1 = spdiags([e  -e], 0:1, N, N);
temp = De1*a;    % to find the position of cuts


[cuts_dp,~]= find(abs(temp)>0.75*out_width); % no need for this c has it 
 
nonver_curve2 = a;

% figure,plot(data);
% hold on;
% plot(nonver_curve2)

cuts_in = cuts_dp;

support = zeros(size(cuts_in,1),4) ;

for i=1:size(cuts_in,1)
    iter = cuts_in(i)+6 ;
    in_ah = cuts_in(i)+6 ;
    count = 0;
    while iter <= size(data,1)-1
        if(abs(nonver_curve2(iter)-nonver_curve2(iter+1))<=5)
            iter=iter+1;
            count=count+1;
        else
            break;
        end
    end
    
    support(i,1) = count;
    
    if(in_ah+k <= N)
        support(i,3) = mean(nonver_curve2(in_ah:in_ah+k));                %nonver_curve(iter-1);
    else
        support(i,3) = mean(nonver_curve2(in_ah:end));
    end
    
    iter = cuts_in(i)-1;
    in_ah = cuts_in(i)-1;
       
    count =0;
    
    while iter >= 2
        if(abs(nonver_curve2(iter)-nonver_curve2(iter-1))<=5)
            iter=iter-1;
            count=count+1;
        else
            break;
        end
    end
    
    support(i,2) = count;
     if(in_ah-k > 0)
        support(i,4) = mean(nonver_curve2(in_ah-k:in_ah));%nonver_curve(iter-1);
     else
        support(i,4) = mean(nonver_curve2(1:in_ah));
     end
    
end

error_cuts = zeros(size(support,1),1);

support_dist = cut_dist;

for i =1:size(support,1)
    if(abs(support(i,3)-support(i,4)) < support_dist )
        error_cuts(i)=1;
    end
end

index = find(error_cuts==1);

final_cuts_dp = cuts_dp;
for i=length(index):-1:1
    final_cuts_dp(index(i)) = [];
end
