% 输入：一个port的消息信息（消息周期、消息大小、端口的B）
% 输出：此port最小的bandwidth，最小的bandwidth对应的jitter，分组情况（VL情况）
function [B,J,F] = Find_Grouping_Solution_For_Each_Port_forCp(messages)
    %% Initialization
    % 先尝试把消息都放在一个VL中，不可行则按照lp比从大到小依次分出新的VL，直至可行
%     [F,N] = Initialization_forCp(messages); % N为目前的VL数量

    %% Split
%     [B,J,F,BAG,MTU] = Split_forCp(messages,F,N);
    F = struct; % 指定发送端口的消息记录
    F.period = [];
    F.payload = [];
    F.index = [];
    for i = 1:length(messages.period)
        F.period = [F.period messages.period(i)];
        F.payload = [F.payload messages.payload(i)];
        F.index = [F.index i - 1]; % 消息的编号，从0开始
    end

    F.L_P = F.payload ./ F.period; % 为消息添加一个属性，payload除以period的商
    [B,J,F,BAG,MTU] = Split_forCp(messages,F,1);
    
    %% Output
    for i = 1:length(F)
        F(i).MTU = MTU(i);
        F(i).BAG = BAG(i);
    end
    F = rmfield(F,"L_P");
end