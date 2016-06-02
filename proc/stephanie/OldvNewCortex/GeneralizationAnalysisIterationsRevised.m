


% Isometric within 
[R2_IbyI_Gyr_Iteration] = PeriodicR2(filter,binnedData,59);

% Isometric predicted by wrist movement
[R2_IbyW_Gyr_Iteration] = PeriodicR2(filter,binnedData,59);

% Wrist Movement within
[R2_WbyW_Gyr_Iteration] = PeriodicR2(filter,binnedData,59);

% Wrist movement predicted by isometric
[R2_WbyI_Gyr_Iteration] = PeriodicR2(filter,binnedData,59);


%(across divided by within)
R2_IbyWoverIbyI_Gyr_It = R2_IbyW_Gyr_Iteration./R2_IbyI_Gyr_Iteration; %(across divided by within)
Mean_R2_IbyWoverIbyI_Gyr_It = mean(R2_IbyWoverIbyI_Gyr_It);
std_R2_IbyWoverIbyI_Gyr_It = std(R2_IbyWoverIbyI_Gyr_It);

%(across divided by within)
R2_WbyIoverWbyW_Gyr_It = R2_WbyI_Gyr_Iteration./R2_WbyW_Gyr_Iteration;
Mean_R2_WbyIoverWbyW_Gyr_It = mean(R2_WbyIoverWbyW_Gyr_It);
std_R2_WbyIoverWbyW_Gyr_It = std(R2_WbyIoverWbyW_Gyr_It);

%%%%%%%%%%%

%Isometric predicted by hybrid
[R2_IbyH_Gyr_Iteration] = PeriodicR2(filter,binnedData,59);
% Mean_R2_IbyH_Gyr_Iteration = mean(R2_IbyH_Gyr_Iteration);
% std_R2_IbyH_Gyr_Iteration = std(R2_IbyH_Gyr_Iteration);

%Wrist movement predicted by hybrid
[R2_WbyH_Gyr_Iteration] = PeriodicR2(filter,binnedData,59);
% Mean_R2_WbyH_Gyr_Iteration = mean(R2_WbyH_Gyr_Iteration);
% std_R2_WbyH_Gyr_Iteration = std(R2_WbyH_Gyr_Iteration);


% Iso predicted by hybrid over Iso predicted by Iso
R2_IbyHoverIbyI_Gyr_It = R2_IbyH_Gyr_Iteration./R2_IbyI_Gyr_Iteration;
Mean_R2_IbyHoverIbyI_Gyr_It = mean(R2_IbyHoverIbyI_Gyr_It);
std_R2_IbyHoverIbyI_Gyr_It = std(R2_IbyHoverIbyI_Gyr_It);


% WM predicted by hybrid over WM predicted by WM
R2_WbyHoverWbyW_Gyr_It = R2_WbyH_Gyr_Iteration./R2_WbyW_Gyr_Iteration;
Mean_R2_WbyHoverWbyW_Gyr_It = mean(R2_WbyHoverWbyW_Gyr_It);
std_R2_WbyHoverWbyW_Gyr_It = std(R2_WbyHoverWbyW_Gyr_It);
