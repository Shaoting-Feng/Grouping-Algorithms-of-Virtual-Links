% 对于每一条VL确定其可取的BAG和MTU组合，去除掉使得bandwidth和jitter都劣于其他某个组合的组合
function [BAG,MTU] = Find_Feasible_BAG_MTU_v2(F)
    N_step = []; % 记录每个突变点的MTU
    for i = 1:size(F.period,2)
        frag = ceil(F.payload(i) / ceil(F.payload(i) / F.period(i) / 2));
        frag = 1:frag;
        N_step = union(unique(ceil(F.payload(i) ./ frag)),N_step);
    end
    N_step = sort(N_step);
    
    BAG = [];
    MTU = [];
    
    % 遍历每个BAG寻找符合要求的最小MTU
    % 也可以遍历每个MTU寻找符合要求的最大BAG，理论上时间复杂度都是O(BAG*MTU)，就是注意考虑应该尽快剪枝
    i = 1;
    BAG_remember = 0;
    flag = false;
    for BAG_tmp = 0.5:0.5:1024
        % MTU的可选值范围已经遍历了一遍
        if i > numel(N_step)
            break;
        end
        
        while i <= numel(N_step) && sum(ceil(F.payload ./ N_step(i)) ./ F.period) > 1 / BAG_tmp
            % 针对每一个MTU只保存最大的BAG
            if i <= numel(N_step) && flag
                BAG = [BAG BAG_remember];
                MTU = [MTU N_step(i)];
                flag = false; % BAG_remember变化的flag
            end
            i = i + 1;
        end
        
        % 是一组满足第一个不等式的BAG和MTU
        BAG_remember = BAG_tmp;
        flag = true;
    end
end