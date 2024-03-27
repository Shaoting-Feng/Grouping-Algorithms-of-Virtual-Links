% 输入：一个port的消息信息（消息周期、消息大小、端口的B）
% 输出：此port最小的bandwidth，最小的bandwidth对应的jitter，分组情况（VL情况）
% Find_Grouping_Solution_For_Each_Port_v3.m在ind_Grouping_Solution_For_Each_Port_v2.m把Initialization.m改为Initialization_v2.m，
% 把Split.m改为Split_v3.m。
function [B,J,F] = Find_Grouping_Solution_For_Each_Port_v3(messages)
    %% Initialization
    % 先尝试把消息都放在一个VL中，不可行则按照lp比从大到小依次分出新的VL，直至可行
    [F,N] = Initialization_v2(messages); % N为目前的VL数量

    %% Split
    [B,J,F,BAG,MTU] = Split_v3(messages,F,N);
    
    %% Output
    for i = 1:length(F)
        F(i).MTU = MTU(i);
        F(i).BAG = BAG(i);
    end
    F = rmfield(F,"L_P");
end