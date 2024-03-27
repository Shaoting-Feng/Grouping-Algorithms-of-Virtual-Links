function [BAG,MTU] = Find_Feasible_BAG_MTU(F)
    N_step = []; 
    for i = 1:size(F.period,2)
        frag = ceil(F.payload(i) / ceil(F.payload(i) / F.period(i)));
        frag = 1:frag;
        N_step = union(unique(ceil(F.payload(i) ./ frag)),N_step);
    end
    N_step = sort(N_step);
    BAG = [];
    MTU = [];
    i = 1;
    for k = 0:7
        while i <= numel(N_step) && sum(ceil(F.payload ./ N_step(i)) ./ F.period) > 1 / 2^k
            i = i + 1;
        end
        if i <= numel(N_step)
            BAG = [BAG 2^k];
            MTU = [MTU N_step(i)];
        end
    end
end