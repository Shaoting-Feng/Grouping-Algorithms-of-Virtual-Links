% 输入：一个port的消息信息（消息周期、消息大小、端口的B）
% 输出：此port的初始化分组方案，目前的VL数量
function [F,N] = Initialization_forCp(messages)
    n = length(messages.period); % 此port发送的消息的类别数

    % 把消息预分组都放在一个VL中
    F = struct; % 指定发送端口的消息记录
    F.period = [];
    F.payload = [];
    F.index = [];
    for i = 1:n
        F.period = [F.period messages.period(i)];
        F.payload = [F.payload messages.payload(i)];
        F.index = [F.index i - 1]; % 消息的编号，从0开始
    end

    F.L_P = F.payload ./ F.period; % 为消息添加一个属性，payload除以period的商
    [F.L_P,idx] = sort(F.L_P,'descend'); % 把消息按照l除以p的商降序排序
    F.period = F.period(idx);
    F.payload = F.payload(idx);
    F.index = F.index(idx);
    
    % 检查方案是否可行
    while true
        N = length(F); % 目前的VL数量
        [bestB,~,~,~,VLidx] = Find_Minimum_Bandwidth_Configuration_forCp(F,N,messages.B);
    	if bestB ~= Inf
            break;
        end
        if VLidx == 0
            f = {F.index};
            lens = zeros(1,length(F));
            for i = 1:length(F)
                lens(i) = length(f{i});
            end
            [~,VLidx] = max(lens);
        end
        numInVL = length(F(VLidx).period); % 编号最小的没有可行BAG和MTU数组的VL（设为VL_x）中的消息数量
        
        % 如果把VL_x中原L_P最大的消息单独放在一个新的VL中
        if VLidx == N
            F(VLidx+1).period = [];
            F(VLidx+1).payload = [];
            F(VLidx+1).L_P = [];
            F(VLidx+1).index = [];
        end
        
        % 把VL_x中原L_P最大的消息改编至其他VL
        F(VLidx+1).period = [F(VLidx+1).period F(VLidx).period(1)];
        F(VLidx+1).payload = [F(VLidx+1).payload F(VLidx).payload(1)];
        F(VLidx+1).L_P = [F(VLidx+1).L_P F(VLidx).L_P(1)];
        F(VLidx+1).index = [F(VLidx+1).index F(VLidx).index(1)];
        
        % 删除VL_x中L_P最大的消息
        F(VLidx).period = F(VLidx).period(2:numInVL);
        F(VLidx).payload = F(VLidx).payload(2:numInVL);
        F(VLidx).L_P = F(VLidx).L_P(2:numInVL);
        F(VLidx).index = F(VLidx).index(2:numInVL);
    end
end
    