function output=cf_search(method,cfg,scenario,options)
%CF_SEARCH GA, PSO, GA+PSO, PSO+GA, or PGSAO under one evaluation budget.
if nargin<4 || isempty(options), options=cfg.search; end
method=upper(strrep(char(method),' ','')); rng(cfg.seedSearch,'twister');
tracker=initializeTracker(options.maxEvaluations,cfg.search.dimension);
N=min(options.populationSize,options.maxEvaluations); initialX=rand(N,cfg.search.dimension);
switch method
    case 'GA'
        [X,scores,tracker]=gaPhase(cfg,scenario,options,tracker,initialX,[],options.maxEvaluations);
    case 'PSO'
        [X,scores,~,~,tracker]=psoPhase(cfg,scenario,options,tracker,initialX,[],[],options.maxEvaluations);
    case 'GA+PSO'
        firstBudget=hybridFirstBudget(options,N);
        [X,scores,tracker]=gaPhase(cfg,scenario,options,tracker,initialX,[],firstBudget);
        [X,scores,~,~,tracker]=psoPhase(cfg,scenario,options,tracker,X,scores,zeros(size(X)),options.maxEvaluations);
    case 'PSO+GA'
        firstBudget=hybridFirstBudget(options,N);
        [~,~,pbestX,pbestScore,tracker]=psoPhase(cfg,scenario,options,tracker,initialX,[],[],firstBudget);
        [X,scores,tracker]=gaPhase(cfg,scenario,options,tracker,pbestX,pbestScore,options.maxEvaluations);
    case 'PGSAO'
        [X,scores,tracker]=pgsaoSearch(cfg,scenario,options,tracker,initialX);
    otherwise
        error('Unknown method: %s',method);
end
count=tracker.evaluationCount;
output.Method=method; output.BestX=tracker.bestX;
output.BestCandidate=cf_decode_candidate(tracker.bestX,cfg);
output.BestResult=tracker.bestResult; output.BestScore=tracker.bestScore; output.Evaluations=count;
output.History=table((1:count)',tracker.traceScore(1:count),tracker.traceBest(1:count), ...
    'VariableNames',{'Evaluation','Score','BestScore'});
output.EvaluationX=tracker.archiveX(1:count,:); output.EvaluationScore=tracker.traceScore(1:count);
output.FinalPopulation=X; output.FinalScores=scores;
end

function budget=hybridFirstBudget(options,N)
raw=floor(options.hybridFirstFraction*options.maxEvaluations);
budget=floor(raw/N)*N; budget=max(N,budget); budget=min(budget,options.maxEvaluations-N);
if budget<N, budget=min(N,options.maxEvaluations); end
end

function t=initializeTracker(maxEval,D)
t.maxEvaluations=maxEval; t.evaluationCount=0; t.bestScore=-inf;
t.bestX=nan(1,D); t.bestResult=[]; t.traceScore=nan(maxEval,1);
t.traceBest=nan(maxEval,1); t.archiveX=nan(maxEval,D);
end

function [score,result,t]=evaluateTracked(x,cfg,scenario,options,t)
x=clip01(x); candidate=cf_decode_candidate(x,cfg);
try
    result=cf_evaluate_candidate(cfg,scenario,candidate,true); score=result.Score;
    if ~isfinite(score), score=-realmax; end
catch ME
    warning('cf_search:CandidateFailed','Candidate failed: %s',ME.message);
    result=[]; score=-realmax;
end
t.evaluationCount=t.evaluationCount+1; k=t.evaluationCount;
t.traceScore(k)=score; t.archiveX(k,:)=x;
if score>t.bestScore, t.bestScore=score; t.bestX=x; t.bestResult=result; end
t.traceBest(k)=t.bestScore;
if options.verbose
    fprintf('search eval %3d/%3d: score=%10.4f, best=%10.4f\n',k,t.maxEvaluations,score,t.bestScore);
end
end

function [X,scores,t]=gaPhase(cfg,scenario,o,t,X,initialScores,phaseEnd)
N=size(X,1);
if isempty(initialScores), scores=-inf(N,1);
else, scores=initialScores(:); X=makeNextGeneration(X,scores,o); scores=-inf(N,1); end
while t.evaluationCount<phaseEnd && t.evaluationCount<t.maxEvaluations
    completed=true;
    for i=1:N
        if t.evaluationCount>=phaseEnd || t.evaluationCount>=t.maxEvaluations
            completed=false; break;
        end
        [scores(i),~,t]=evaluateTracked(X(i,:),cfg,scenario,o,t);
    end
    if ~completed || t.evaluationCount>=phaseEnd || t.evaluationCount>=t.maxEvaluations, break; end
    X=makeNextGeneration(X,scores,o); scores=-inf(N,1);
end
end

function nextX=makeNextGeneration(X,scores,o)
[N,D]=size(X); [~,order]=sort(scores,'descend'); elite=min(o.eliteCount,N);
nextX=zeros(N,D); nextX(1:elite,:)=X(order(1:elite),:); index=elite+1;
while index<=N
    p1=tournamentIndex(scores,o.tournamentSize); p2=tournamentIndex(scores,o.tournamentSize);
    [c1,c2]=gaCrossover(X(p1,:),X(p2,:),o.crossoverRate);
    c1=mutateVector(c1,o.mutationRate,o.mutationSigma);
    c2=mutateVector(c2,o.mutationRate,o.mutationSigma);
    nextX(index,:)=c1; if index+1<=N, nextX(index+1,:)=c2; end
    index=index+2;
end
end

function idx=tournamentIndex(scores,sizeT)
choices=randi(numel(scores),max(2,sizeT),1); [~,local]=max(scores(choices)); idx=choices(local);
end

function [c1,c2]=gaCrossover(p1,p2,rate)
if rand>=rate, c1=p1; c2=p2; return; end
alpha=rand(size(p1)); c1=alpha.*p1+(1-alpha).*p2; c2=alpha.*p2+(1-alpha).*p1;
mask=rand(size(p1))<0.35; c1(mask)=p2(mask); c2(mask)=p1(mask);
c1=clip01(c1); c2=clip01(c2);
end

function child=mutateVector(child,rate,sigma)
mask=rand(size(child))<rate; child(mask)=child(mask)+sigma*randn(1,sum(mask));
reset=rand(size(child))<0.03; child(reset)=rand(1,sum(reset)); child=clip01(child);
end

function [X,currentScores,pbestX,pbestScore,t]=psoPhase(cfg,scenario,o,t,X,initialScores,V,phaseEnd)
[N,D]=size(X); if isempty(V), V=0.1*(2*rand(N,D)-1); end
if isempty(initialScores)
    pbestX=X; pbestScore=-inf(N,1); currentScores=-inf(N,1);
else
    currentScores=initialScores(:); pbestX=X; pbestScore=currentScores;
    [X,V]=moveParticles(X,V,pbestX,pbestScore,t.bestX,t.evaluationCount,o);
end
while t.evaluationCount<phaseEnd && t.evaluationCount<t.maxEvaluations
    completed=true;
    for i=1:N
        if t.evaluationCount>=phaseEnd || t.evaluationCount>=t.maxEvaluations
            completed=false; break;
        end
        [currentScores(i),~,t]=evaluateTracked(X(i,:),cfg,scenario,o,t);
        if currentScores(i)>pbestScore(i), pbestScore(i)=currentScores(i); pbestX(i,:)=X(i,:); end
    end
    if ~completed || t.evaluationCount>=phaseEnd || t.evaluationCount>=t.maxEvaluations, break; end
    progress=t.evaluationCount/max(1,t.maxEvaluations);
    inertia=o.psoInertiaStart+progress*(o.psoInertiaEnd-o.psoInertiaStart);
    V=inertia*V+o.psoCognitive*rand(N,D).*(pbestX-X)+ ...
        o.psoSocial*rand(N,D).*(repmat(t.bestX,N,1)-X);
    V=min(max(V,-o.psoVelocityLimit),o.psoVelocityLimit); X=clip01(X+V);
end
end

function [X,V]=moveParticles(X,V,pbestX,pbestScore,gbest,evalCount,o)
[N,D]=size(X);
if any(~isfinite(gbest)), [~,idx]=max(pbestScore); gbest=pbestX(idx,:); end
progress=evalCount/max(1,o.maxEvaluations);
inertia=o.psoInertiaStart+progress*(o.psoInertiaEnd-o.psoInertiaStart);
V=inertia*V+o.psoCognitive*rand(N,D).*(pbestX-X)+ ...
    o.psoSocial*rand(N,D).*(repmat(gbest,N,1)-X);
V=min(max(V,-o.psoVelocityLimit),o.psoVelocityLimit); X=clip01(X+V);
end

function [X,scores,t]=pgsaoSearch(cfg,scenario,o,t,X)
N=size(X,1); scores=-inf(N,1); pbestX=X; pbestScore=-inf(N,1);
for i=1:N
    if t.evaluationCount>=t.maxEvaluations, return; end
    [scores(i),~,t]=evaluateTracked(X(i,:),cfg,scenario,o,t);
    pbestScore(i)=scores(i); pbestX(i,:)=X(i,:);
end
particle=1;
while t.evaluationCount<t.maxEvaluations
    i=particle; peer=randi(N);
    if N>1, while peer==i, peer=randi(N); end, end
    base=X(i,:); offspring=zeros(4,size(X,2));
    offspring(1,:)=uniformCrossover(base,X(peer,:),o.pgsaoCrossoverRate);
    offspring(2,:)=uniformCrossover(base,pbestX(i,:),o.pgsaoCrossoverRate);
    offspring(3,:)=uniformCrossover(base,t.bestX,o.pgsaoCrossoverRate);
    offspring(4,:)=mutateVector(base,o.pgsaoMutationRate,o.mutationSigma);
    bestX=base; bestScore=scores(i);
    for k=1:4
        if t.evaluationCount>=t.maxEvaluations, break; end
        [newScore,~,t]=evaluateTracked(offspring(k,:),cfg,scenario,o,t);
        if newScore>bestScore, bestScore=newScore; bestX=offspring(k,:); end
    end
    X(i,:)=bestX; scores(i)=bestScore;
    if scores(i)>pbestScore(i), pbestScore(i)=scores(i); pbestX(i,:)=X(i,:); end
    particle=particle+1; if particle>N, particle=1; end
end
end

function child=uniformCrossover(base,guide,probability)
child=base; mask=rand(size(base))<probability; child(mask)=guide(mask);
blend=~mask & rand(size(base))<0.25; alpha=rand(size(base));
child(blend)=(1-alpha(blend)).*base(blend)+alpha(blend).*guide(blend);
child=clip01(child);
end
function x=clip01(x)
x=min(max(x,0),1);
end
