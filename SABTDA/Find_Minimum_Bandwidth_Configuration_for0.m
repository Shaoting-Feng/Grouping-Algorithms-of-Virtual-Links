% 输入：目前的VL情况、目前分成的VL数量、当前port的B
% 输出：此分组最小的bandwidth，最小的bandwidth对应的jitter（满足约束3），最小的bandwidth对应的MTU取值，最小的bandwidth对应的BAG取值，没有符合要求的BAG和MTU的最大的VL的编号
% 为算法0设计，与论文一模一样。
function [B_min,J,S_MTU,S_BAG,idx] = Find_Minimum_Bandwidth_Configuration_for0(F,N,portB)
    BB = portB * 1000000 * 8; % port的B
    VL = struct; % 记录每个VL的BAG和MTU信息
    B = zeros(1,N); % 记录每个VL的最小bandwidth
    J = zeros(1,N); % 记录每个VL的最小jitter
    % 注：最小bandwidth和最小jitter不一定能够同时满足
    for i = 1:N
        [VL(i).BAG,VL(i).MTU] = Find_Feasible_BAG_MTU(F(i)); 
%         if isempty(VL(i).BAG)
%             B_min = Inf;
%             J = -1;
%             S_MTU = [];
%             S_BAG = [];
%             idx = -i;
%             return
%         end
        VL(i).tmpB = (VL(i).MTU + 67) ./ VL(i).BAG; % 间接记录每个VL的bandwidth
        
        B(i) = min(VL(i).tmpB); % 记录每个VL的最小bandwidth
        J(i) = min(VL(i).MTU + 67); % 记录每个VL的最小jitter
    end
    B_0 = sum(B); % 记录整体的最小bandwidth（不一定能达到）
    J_0 = sum(J); % 记录整体的最小jitter（不一定能达到）
    
%     % 如果不存在满足约束3的BAG和MTU对
%     if J_0 > 460 * BB / 8000000
%         B_min = Inf;
%         J = -1;
%         S_MTU = [];
%         S_BAG = [];
%         idx = 0;
%         return
%     end
       
    % 使用数组+min代替了优先级队列
    % 记录：目前已经确定BAG和MTU的VL数量（按照顺序）、目前的B（未确定的VL取最小bandwidth）、目前的J（未确定的VL取最小jitter）、
    %       目前已经确定的VL的MTU取值、目前已经确定的VL的BAG取值
    queue = struct('level',0,'B',B_0,'J',J_0,'S_MTU',[],'S_BAG',[]);
    
    B_N = BB / 8000; % 入队条件：约束2

    while 1
        % 选取数组中目前的B（未确定的VL取最小bandwidth）最小的组合
        [B_min,index] = min([queue.B]);
        
        if queue(index).level == N % 全部VL已确定则程序结束
            S_MTU = queue(index).S_MTU;
            S_BAG = queue(index).S_BAG;
            J = queue(index).J;
            break
        end
        
        i = queue(index).level + 1; % 确定的VL的数量加一
        for k = 1:numel(VL(i).BAG) % 遍历正在设置的VL的所有MTU和BAG组合
            B_curr = B_min - B(i) + (VL(i).MTU(k) + 67) / VL(i).BAG(k); % 用当前MTU和BAG组合的bandwidth代替最小bandwidth
            J_curr = queue(index).J - J(i) + VL(i).MTU(k) + 67; % 用当前MTU和BAG组合的jitter代替最小bandwidth
            
            if B_curr <= B_N && J_curr <= 460 * BB / 8000000 % 满足约束2和约束3则保存
                if numel(queue(index).S_MTU) ~= 0
                    S_MTU = [queue(index).S_MTU VL(i).MTU(k)];
                    S_BAG = [queue(index).S_BAG VL(i).BAG(k)];
                else 
                    S_MTU = [VL(i).MTU(k)];
                    S_BAG = [VL(i).BAG(k)];
                end
                idx = numel(queue) + 1;
                queue(idx).level = i;
                queue(idx).B = B_curr;
                queue(idx).J = J_curr;
                queue(idx).S_MTU = S_MTU;
                queue(idx).S_BAG = S_BAG;
            end
        end
        
        % 删除数组中已经处理（为下一条VL寻找BAG和MTU）过的项
        % 方法是用最后一项代替这个处理过的项
        queue(index).level = queue(numel(queue)).level;
        queue(index).B = queue(numel(queue)).B;
        queue(index).J = queue(numel(queue)).J;
        queue(index).S_MTU = queue(numel(queue)).S_MTU;
        queue(index).S_BAG = queue(numel(queue)).S_BAG;
        if numel(queue) - 1 ~= 0
            queue = queue(1:numel(queue)-1);
        end
    end
end
            
