% 输入：一个port的消息信息（消息周期、消息大小、端口的B），此port的初始化分组方案，目前的VL数量
% 输出：此port最小的bandwidth，最小的bandwidth对应的jitter，分组情况（VL情况），每条VL的BAG，每条VL的MTU
% 相较于Split_v2.m主要是把50%分组率改为超出平均的分组率
function [B,J,F,BAG,MTU] = Split_v3(messages,F,N)
    flag = 1; % 上一次发生更改的VL的编号
    x = 1; % 先拆分VL_1
    doContinue = true;
    count = 0;
    while flag ~= x || doContinue % 在遍历一轮后停止
        count = count + 1;
        numInVL = length(F(x).period); % 正在拆分的VL（设为VL_x）中的消息数量
        
        % 排序
        [F(x).L_P,idx] = sort(F(x).L_P,'descend'); % 把消息按照l除以p的商降序排序
        F(x).period = F(x).period(idx);
        F(x).payload = F(x).payload(idx);
        F(x).index = F(x).index(idx);
        
        % 寻找第一条L_P在均值以下的消息
        % 不一定是均值，可以调参实验
        avgL_P = mean(F(x).L_P); 
%         avgL_P = (F(x).L_P(1) + F(x).L_P(end)) / 2;
%         avgL_P = F(x).L_P(1) / 10;

        i = 1;
        while 1 
            if i > numInVL
                numSplit = ceil(numInVL / 2);
                break
            end
            if F(x).L_P(i) < avgL_P
                numSplit = i - 1;
                break
            end
            i = i + 1;
        end
        
        if numInVL == 1 % VL_x只剩一条消息考虑的是合并
            % 把这条消息分别放在每一个VL中进行比较选择最优情况
            tmpF = cell(1,N); % 每一种情况
            bestB = zeros(1,N); % 每一种情况对应的B
            bestJ = zeros(1,N); % 每一种情况对应的J
            MTU = cell(1,N);
            BAG = cell(1,N);
            
            % 第一种情况：保留在VL_x中
            tmpF{1} = F;
            [bestB(1),bestJ(1),MTU{1},BAG{1},~] = Find_Minimum_Bandwidth_Configuration_v4(tmpF{1},length(tmpF{1}),messages.B);
            
            % 其他情况
            for i = 2:N
                tmpF{i} = F;
                
                % 把VL_x中这条消息改编至其他VL
                if i - 1 == x
                    j = N;
                else
                    j = i - 1;
                end
                tmpF{i}(j).period = [tmpF{i}(j).period F(x).period];
                tmpF{i}(j).payload = [tmpF{i}(j).payload F(x).payload];
                tmpF{i}(j).L_P = [tmpF{i}(j).L_P F(x).L_P];
                tmpF{i}(j).index = [tmpF{i}(j).index F(x).index];
                
                % 删除VL_x
                tmpF{i}(x) = tmpF{i}(N);
                tmpF{i}(N) = [];

                [bestB(i),bestJ(i),MTU{i},BAG{i},~] = Find_Minimum_Bandwidth_Configuration_v4(tmpF{i},length(tmpF{i}),messages.B);
            end
        else % VL_x不只剩一条消息考虑的是拆分
            % 把VL_x中lp比大的消息分别放在每一个VL（包含自己占用一个VL）中进行比较选择最优情况
            tmpF = cell(1,N+1); % 每一种情况
            bestB = zeros(1,N+1); % 每一种情况对应的B
            bestJ = zeros(1,N+1); % 每一种情况对应的J
            MTU = cell(1,N+1);
            BAG = cell(1,N+1);

            % 第一种情况：保留在VL_x中
            tmpF{1} = F;
            [bestB(1),bestJ(1),MTU{1},BAG{1},~] = Find_Minimum_Bandwidth_Configuration_v4(tmpF{1},length(tmpF{1}),messages.B);

            % 其他情况
            % 第N+1种情况：单独放在一个新的VL中
            tmpF{x+1} = F;
            tmpF{x+1}(N+1).period = [];
            tmpF{x+1}(N+1).payload = [];
            tmpF{x+1}(N+1).L_P = [];
            tmpF{x+1}(N+1).index = [];
            
            for i = 2:N+1
                % 删除VL_x中lp比最大的消息
                if i ~= x+1
                    tmpF{i} = F;
                    j = i - 1;
                else
                    j = N + 1;
                end
                tmpF{i}(x).period = F(x).period(numSplit+1:numInVL);
                tmpF{i}(x).payload = F(x).payload(numSplit+1:numInVL);
                tmpF{i}(x).L_P = F(x).L_P(numSplit+1:numInVL);
                tmpF{i}(x).index = F(x).index(numSplit+1:numInVL);

                % 把VL_x中原L_P最大的消息改编至其他VL
                tmpF{i}(j).period = [tmpF{i}(j).period F(x).period(1:numSplit)];
                tmpF{i}(j).payload = [tmpF{i}(j).payload F(x).payload(1:numSplit)];
                tmpF{i}(j).L_P = [tmpF{i}(j).L_P F(x).L_P(1:numSplit)];
                tmpF{i}(j).index = [tmpF{i}(j).index F(x).index(1:numSplit)];

                [bestB(i),bestJ(i),MTU{i},BAG{i},~] = Find_Minimum_Bandwidth_Configuration_v4(tmpF{i},length(tmpF{i}),messages.B);
            end
        end

        [B,idx] = min(bestB); % 比较各种情况的最优解
        F = tmpF{idx};
        J = bestJ(idx);
        MTU = MTU{idx};
        BAG = BAG{idx};
        N = length(F); % 目前的VL数量

        if idx ~= 1 % 循环在非VL_x为最优解时更改flag
            if x > N
                x = mod(x,N);
            end
            flag = x;
            doContinue = true;
        else
            doContinue = false;
            x = x + 1;
            if x > N
                x = mod(x,N);
            end
            if x == 0
                break;
            end
        end
    end
end