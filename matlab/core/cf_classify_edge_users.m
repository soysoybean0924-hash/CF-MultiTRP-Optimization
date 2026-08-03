function edge = cf_classify_edge_users(cfg,distance)
%CF_CLASSIFY_EDGE_USERS M3-style edge/non-edge split from long-term path loss.

R = cfg.numDUs; U = cfg.numUEs;
edge = struct();
edge.Enabled = isfield(cfg,'edge') && isfield(cfg.edge,'enabled') && cfg.edge.enabled;
edge.Method = fieldOrDefault(cfg.edge,'method','m3_pathloss_delta');
edge.PathlossThresholdDb = fieldOrDefault(cfg.edge,'pathlossThresholdDb',3);
edge.MinServingDUs = fieldOrDefault(cfg.edge,'minServingDUs',2);
edge.PrimaryDU = ones(U,1);
edge.ServingMask = false(R,U);
edge.ServingDUCount = ones(U,1);
edge.EdgeUserMask = false(U,1);
edge.NonEdgeUserMask = true(U,1);
edge.RelativePathlossDb = zeros(R,U);

if ~edge.Enabled
    for u = 1:U
        [~,edge.PrimaryDU(u)] = min(distance(:,u));
        edge.ServingMask(edge.PrimaryDU(u),u) = true;
    end
    return;
end

pathlossDb = 10*cfg.pathlossExponent*log10(max(distance,cfg.minimumDistance)/cfg.referenceDistance);
for u = 1:U
    [bestLoss,bestDu] = min(pathlossDb(:,u));
    relativeLoss = pathlossDb(:,u) - bestLoss;
    servingMask = relativeLoss <= edge.PathlossThresholdDb;
    if ~any(servingMask)
        servingMask(bestDu) = true;
    end
    edge.PrimaryDU(u) = bestDu;
    edge.ServingMask(:,u) = servingMask;
    edge.ServingDUCount(u) = sum(servingMask);
    edge.EdgeUserMask(u) = edge.ServingDUCount(u) >= edge.MinServingDUs;
    edge.RelativePathlossDb(:,u) = relativeLoss;
end
edge.NonEdgeUserMask = ~edge.EdgeUserMask;
edge.NumEdgeUsers = sum(edge.EdgeUserMask);
edge.NumNonEdgeUsers = sum(edge.NonEdgeUserMask);
edge.EdgeUserRatio = edge.NumEdgeUsers/max(1,U);
end

function value = fieldOrDefault(s,name,defaultValue)
if isstruct(s) && isfield(s,name)
    value = s.(name);
else
    value = defaultValue;
end
end
