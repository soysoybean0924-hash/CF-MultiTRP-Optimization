function output = m3_testbed_search(method,cfg,scenario,options)
%M3_TESTBED_SEARCH Full-9D M3 staging search with default-candidate seeding.
%
% This testbed search intentionally lives outside the production cf_search
% path. It is used for unconfirmed M3-scale experiments where every outer
% algorithm must see cfg.defaultX before trying its own update rule.
if nargin < 4 || isempty(options)
    options = cfg.search;
end

method = upper(strrep(char(method),' ',''));
rng(cfg.seedSearch,'twister');
[activeDimensions,fixedX,searchDimension] = searchSpace(options,cfg);
tracker = initializeTracker(options.maxEvaluations,searchDimension);
N = min(options.populationSize,options.maxEvaluations);
initialX = rand(N,searchDimension);
initialX(1,:) = fixedX(activeDimensions);

switch method
    case 'GA'
        [X,scores,tracker] = gaPhase(cfg,scenario,options,tracker,initialX,[],options.maxEvaluations);
    case 'PSO'
        [X,scores,~,~,tracker] = psoPhase(cfg,scenario,options,tracker,initialX,[],[],options.maxEvaluations);
    case 'GA+PSO'
        firstBudget = hybridFirstBudget(options,N);
        [X,scores,tracker] = gaPhase(cfg,scenario,options,tracker,initialX,[],firstBudget);
        [X,scores,~,~,tracker] = psoPhase(cfg,scenario,options,tracker,X,scores,zeros(size(X)),options.maxEvaluations);
    case 'PSO+GA'
        firstBudget = hybridFirstBudget(options,N);
        [~,~,pbestX,pbestScore,tracker] = psoPhase(cfg,scenario,options,tracker,initialX,[],[],firstBudget);
        [X,scores,tracker] = gaPhase(cfg,scenario,options,tracker,pbestX,pbestScore,options.maxEvaluations);
    case 'PGSAO'
        [X,scores,tracker] = pgsaoSearch(cfg,scenario,options,tracker,initialX);
    otherwise
        error('Unknown method: %s',method);
end

count = tracker.evaluationCount;
bestFullX = expandSearchVector(tracker.bestX,activeDimensions,fixedX);
output.Method = method;
output.BestReducedX = tracker.bestX;
output.ActiveDimensions = activeDimensions;
output.FixedX = fixedX;
output.BestX = bestFullX;
output.BestCandidate = cf_decode_candidate(bestFullX,cfg);
output.BestResult = tracker.bestResult;
output.BestScore = tracker.bestScore;
output.BestObjective = tracker.bestObjective;
output.ObjectiveName = 'J_true';
output.Evaluations = count;
output.History = table((1:count)',tracker.traceObjective(1:count),tracker.traceScore(1:count), ...
    tracker.traceBestObjective(1:count),tracker.traceBestScore(1:count), ...
    'VariableNames',{'Evaluation','Objective','Score','BestObjective','BestScore'});
output.EvaluationX = tracker.archiveX(1:count,:);
output.EvaluationObjective = tracker.traceObjective(1:count);
output.EvaluationScore = tracker.traceScore(1:count);
output.FinalPopulation = X;
output.FinalObjectives = scores;
output.FinalScores = [];
output.DefaultCandidateInjected = true;
output.DefaultCandidateReducedX = fixedX(activeDimensions);
end

function [activeDimensions,fixedX,searchDimension] = searchSpace(options,cfg)
if isfield(options,'activeDimensions') && ~isempty(options.activeDimensions)
    activeDimensions = unique(round(options.activeDimensions(:)'),'stable');
else
    activeDimensions = 1:cfg.search.dimension;
end
if any(activeDimensions < 1) || any(activeDimensions > cfg.search.dimension)
    error('activeDimensions must be in 1:%d.',cfg.search.dimension);
end
if isfield(options,'fixedX') && ~isempty(options.fixedX)
    fixedX = reshape(double(options.fixedX),1,[]);
else
    fixedX = cfg.defaultX;
end
if numel(fixedX) ~= cfg.search.dimension
    error('fixedX must contain %d normalized variables.',cfg.search.dimension);
end
fixedX = min(max(fixedX,cfg.search.lowerBound),cfg.search.upperBound);
searchDimension = numel(activeDimensions);
end

function fullX = expandSearchVector(x,activeDimensions,fixedX)
fullX = fixedX;
fullX(activeDimensions) = reshape(double(x),1,[]);
fullX = min(max(fullX,0),1);
end

function budget = hybridFirstBudget(options,N)
raw = floor(options.hybridFirstFraction*options.maxEvaluations);
budget = floor(raw/N)*N;
budget = max(N,budget);
budget = min(budget,options.maxEvaluations-N);
if budget < N
    budget = min(N,options.maxEvaluations);
end
end

function t = initializeTracker(maxEval,D)
t.maxEvaluations = maxEval;
t.evaluationCount = 0;
t.bestScore = -inf;
t.bestObjective = -inf;
t.bestX = nan(1,D);
t.bestResult = [];
t.traceObjective = nan(maxEval,1);
t.traceScore = nan(maxEval,1);
t.traceBestObjective = nan(maxEval,1);
t.traceBestScore = nan(maxEval,1);
t.archiveX = nan(maxEval,D);
end

function [objective,result,t] = evaluateTracked(x,cfg,scenario,options,t)
x = clip01(x);
[activeDimensions,fixedX,~] = searchSpace(options,cfg);
fullX = expandSearchVector(x,activeDimensions,fixedX);
candidate = cf_decode_candidate(fullX,cfg);
try
    result = cf_evaluate_candidate(cfg,scenario,candidate,true);
    score = result.Score;
    objective = result.Objective;
    if ~isfinite(objective)
        objective = -realmax;
    end
    if ~isfinite(score)
        score = -realmax;
    end
catch ME
    warning('m3_testbed_search:CandidateFailed','Candidate failed: %s',ME.message);
    result = [];
    objective = -realmax;
    score = -realmax;
end
t.evaluationCount = t.evaluationCount + 1;
k = t.evaluationCount;
t.traceObjective(k) = objective;
t.traceScore(k) = score;
t.archiveX(k,:) = x;
if isBetterCandidate(objective,score,t.bestObjective,t.bestScore)
    t.bestObjective = objective;
    t.bestScore = score;
    t.bestX = x;
    t.bestResult = result;
end
t.traceBestObjective(k) = t.bestObjective;
t.traceBestScore(k) = t.bestScore;
if options.verbose
    fprintf('testbed eval %3d/%3d: objective=%10.4f, best=%10.4f, score=%10.4f\n', ...
        k,t.maxEvaluations,objective,t.bestObjective,score);
end
end

function [X,scores,t] = gaPhase(cfg,scenario,o,t,X,initialScores,phaseEnd)
N = size(X,1);
if isempty(initialScores)
    scores = -inf(N,1);
else
    scores = initialScores(:);
    X = makeNextGeneration(X,scores,o);
    scores = -inf(N,1);
end
while t.evaluationCount < phaseEnd && t.evaluationCount < t.maxEvaluations
    completed = true;
    for i = 1:N
        if t.evaluationCount >= phaseEnd || t.evaluationCount >= t.maxEvaluations
            completed = false;
            break;
        end
        [scores(i),~,t] = evaluateTracked(X(i,:),cfg,scenario,o,t);
    end
    if ~completed || t.evaluationCount >= phaseEnd || t.evaluationCount >= t.maxEvaluations
        break;
    end
    X = makeNextGeneration(X,scores,o);
    scores = -inf(N,1);
end
end

function nextX = makeNextGeneration(X,scores,o)
[N,D] = size(X);
[~,order] = sort(scores,'descend');
elite = min(o.eliteCount,N);
nextX = zeros(N,D);
nextX(1:elite,:) = X(order(1:elite),:);
index = elite + 1;
while index <= N
    p1 = tournamentIndex(scores,o.tournamentSize);
    p2 = tournamentIndex(scores,o.tournamentSize);
    [c1,c2] = gaCrossover(X(p1,:),X(p2,:),o.crossoverRate);
    c1 = mutateVector(c1,o.mutationRate,o.mutationSigma);
    c2 = mutateVector(c2,o.mutationRate,o.mutationSigma);
    nextX(index,:) = c1;
    if index + 1 <= N
        nextX(index+1,:) = c2;
    end
    index = index + 2;
end
end

function idx = tournamentIndex(scores,sizeT)
choices = randi(numel(scores),max(2,sizeT),1);
[~,local] = max(scores(choices));
idx = choices(local);
end

function tf = isBetterCandidate(objective,score,bestObjective,bestScore)
objectiveTol = 1e-10*max(1,abs(bestObjective));
if objective > bestObjective + objectiveTol
    tf = true;
elseif abs(objective-bestObjective) <= objectiveTol && score > bestScore
    tf = true;
else
    tf = false;
end
end

function [c1,c2] = gaCrossover(p1,p2,rate)
if rand >= rate
    c1 = p1;
    c2 = p2;
    return;
end
alpha = rand(size(p1));
c1 = alpha.*p1 + (1-alpha).*p2;
c2 = alpha.*p2 + (1-alpha).*p1;
mask = rand(size(p1)) < 0.35;
c1(mask) = p2(mask);
c2(mask) = p1(mask);
c1 = clip01(c1);
c2 = clip01(c2);
end

function child = mutateVector(child,rate,sigma)
mask = rand(size(child)) < rate;
child(mask) = child(mask) + sigma*randn(1,sum(mask));
reset = rand(size(child)) < 0.03;
child(reset) = rand(1,sum(reset));
child = clip01(child);
end

function [X,currentScores,pbestX,pbestScore,t] = psoPhase(cfg,scenario,o,t,X,initialScores,V,phaseEnd)
[N,D] = size(X);
if isempty(V)
    V = 0.1*(2*rand(N,D)-1);
end
if isempty(initialScores)
    pbestX = X;
    pbestScore = -inf(N,1);
    currentScores = -inf(N,1);
else
    currentScores = initialScores(:);
    pbestX = X;
    pbestScore = currentScores;
    [X,V] = moveParticles(X,V,pbestX,pbestScore,t.bestX,t.evaluationCount,o);
end
while t.evaluationCount < phaseEnd && t.evaluationCount < t.maxEvaluations
    completed = true;
    for i = 1:N
        if t.evaluationCount >= phaseEnd || t.evaluationCount >= t.maxEvaluations
            completed = false;
            break;
        end
        [currentScores(i),~,t] = evaluateTracked(X(i,:),cfg,scenario,o,t);
        if currentScores(i) > pbestScore(i)
            pbestScore(i) = currentScores(i);
            pbestX(i,:) = X(i,:);
        end
    end
    if ~completed || t.evaluationCount >= phaseEnd || t.evaluationCount >= t.maxEvaluations
        break;
    end
    progress = t.evaluationCount/max(1,t.maxEvaluations);
    inertia = o.psoInertiaStart + progress*(o.psoInertiaEnd-o.psoInertiaStart);
    V = inertia*V + o.psoCognitive*rand(N,D).*(pbestX-X) + ...
        o.psoSocial*rand(N,D).*(repmat(t.bestX,N,1)-X);
    V = min(max(V,-o.psoVelocityLimit),o.psoVelocityLimit);
    X = clip01(X+V);
end
end

function [X,V] = moveParticles(X,V,pbestX,pbestScore,gbest,evalCount,o)
[N,~] = size(X);
if any(~isfinite(gbest))
    [~,idx] = max(pbestScore);
    gbest = pbestX(idx,:);
end
progress = evalCount/max(1,o.maxEvaluations);
inertia = o.psoInertiaStart + progress*(o.psoInertiaEnd-o.psoInertiaStart);
V = inertia*V + o.psoCognitive*rand(N,size(X,2)).*(pbestX-X) + ...
    o.psoSocial*rand(N,size(X,2)).*(repmat(gbest,N,1)-X);
V = min(max(V,-o.psoVelocityLimit),o.psoVelocityLimit);
X = clip01(X+V);
end

function [X,scores,t] = pgsaoSearch(cfg,scenario,o,t,X)
N = size(X,1);
scores = -inf(N,1);
pbestX = X;
pbestScore = -inf(N,1);
for i = 1:N
    if t.evaluationCount >= t.maxEvaluations
        return;
    end
    [scores(i),~,t] = evaluateTracked(X(i,:),cfg,scenario,o,t);
    pbestScore(i) = scores(i);
    pbestX(i,:) = X(i,:);
end
particle = 1;
while t.evaluationCount < t.maxEvaluations
    i = particle;
    peer = randi(N);
    if N > 1
        while peer == i
            peer = randi(N);
        end
    end
    base = X(i,:);
    offspring = zeros(4,size(X,2));
    offspring(1,:) = uniformCrossover(base,X(peer,:),o.pgsaoCrossoverRate);
    offspring(2,:) = uniformCrossover(base,pbestX(i,:),o.pgsaoCrossoverRate);
    offspring(3,:) = uniformCrossover(base,t.bestX,o.pgsaoCrossoverRate);
    offspring(4,:) = mutateVector(base,o.pgsaoMutationRate,o.mutationSigma);
    bestX = base;
    bestScore = scores(i);
    for k = 1:4
        if t.evaluationCount >= t.maxEvaluations
            break;
        end
        [newScore,~,t] = evaluateTracked(offspring(k,:),cfg,scenario,o,t);
        if newScore > bestScore
            bestScore = newScore;
            bestX = offspring(k,:);
        end
    end
    X(i,:) = bestX;
    scores(i) = bestScore;
    if scores(i) > pbestScore(i)
        pbestScore(i) = scores(i);
        pbestX(i,:) = X(i,:);
    end
    particle = particle + 1;
    if particle > N
        particle = 1;
    end
end
end

function child = uniformCrossover(base,guide,probability)
child = base;
mask = rand(size(base)) < probability;
child(mask) = guide(mask);
blend = ~mask & rand(size(base)) < 0.25;
alpha = rand(size(base));
child(blend) = (1-alpha(blend)).*base(blend) + alpha(blend).*guide(blend);
child = clip01(child);
end

function x = clip01(x)
x = min(max(x,0),1);
end
