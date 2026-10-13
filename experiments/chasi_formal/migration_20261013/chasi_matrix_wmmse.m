function out = chasi_matrix_wmmse(resources, cfg, initialV)
%CHASI_MATRIX_WMMSE Complex coherent-JT WMMSE with centralized V=Z ADMM.
% resources(g): H [K,L,Nr,Nt], C [K,L,Nr,Nr], serve [L,K],
%   rb_count, tx_rb_count. All inputs are supplied; no scene is generated.
% V{g} [L,K,Nt,d], U{g} [K,Nr,d], W{g} [K,d,d].
% The local use of this function does not make its ADMM TRP distributed.
if nargin < 3, initialV = []; end
cfg = defaults(cfg);
G = numel(resources); L = size(resources(1).H,2);
if isempty(initialV)
    V = cell(1,G);
    for g=1:G
        r=resources(g); [K,~,~,Nt]=size(r.H);
        V{g}=complex(zeros(L,K,Nt,cfg.rank));
        for k=1:K
            for l=find(r.serve(:,k)).'
                h=reshape(r.H(k,l,:,:),size(r.H,3),Nt);
                [~,~,vv]=svd(h,'econ');
                V{g}(l,k,:,:)=reshape(vv(:,1:cfg.rank),1,1,Nt,cfg.rank);
            end
        end
    end
    V=project(resources,V,cfg.budget);
else
    V=initialV;
    if numel(V)~=G, error('Resource count mismatch'); end
    for g=1:G
        r=resources(g); expected=[L,size(r.H,1),size(r.H,4),cfg.rank];
        if ~isequal(size4(V{g}),expected), error('V shape mismatch'); end
        masked=V{g}.*reshape(~r.serve,L,[],1,1);
        if sqrt(sum(abs(masked).^2,'all'))>1e-8
            error('V violates service mask');
        end
    end
    if max(chasi_power(resources,V))>cfg.budget+1e-7, error('V over budget'); end
end
hist=struct([]); U=cell(1,G); W=cell(1,G); rate=cell(1,G);
lastObj=-inf; lastChange=inf; lastADMM=false; admmHist=[];
for outer=0:cfg.outer_iterations
    for g=1:G
        [U{g},W{g},rate{g}]=state(resources(g).H,resources(g).C,V{g});
    end
    obj=0;
    for g=1:G
        obj=obj+rbweight(resources(g))*sum(rate{g});
    end
    if outer==0, rel=NaN; else, rel=abs(obj-lastObj)/max(1,abs(lastObj)); end
    hist(outer+1).outer=outer; hist(outer+1).objective=obj;
    hist(outer+1).relative_objective_change=rel;
    hist(outer+1).max_power=max(chasi_power(resources,V));
    hist(outer+1).previous_v_change=lastChange;
    hist(outer+1).previous_admm_converged=lastADMM;
    if outer>0 && rel<=cfg.outer_rel_tol && lastChange<=cfg.outer_v_tol && lastADMM
        reason='relative_objective_precoder_and_admm_tolerance'; break
    end
    if outer==cfg.outer_iterations, reason='max_outer_iterations'; break
    end
    parts=cell(1,G);
    for g=1:G
        parts{g}=quadratic(resources(g).H,resources(g).C,U{g},W{g});
    end
    [nextV,admmHist,lastADMM]=v_admm(resources,parts,V,cfg);
    lastChange=cellnorm(cellminus(nextV,V))/max(cellnorm(V),eps);
    lastObj=obj; V=nextV;
    hist(outer+1).v_change=lastChange;
    hist(outer+1).admm_converged=lastADMM;
    hist(outer+1).admm_last=admmHist(end);
end
out.V=V; out.U=U; out.W=W; out.rate=rate; out.trajectory=hist;
out.reason=reason; out.power=chasi_power(resources,V);
out.last_admm_history=admmHist;
end

function cfg=defaults(cfg)
d=struct('rank',1,'budget',20,'outer_iterations',10,'outer_rel_tol',1e-4,...
    'outer_v_tol',5e-3,'admm_iterations',100,'cg_iterations',100,...
    'eps_abs',1e-4,'eps_rel',1e-3,'rho',.05);
f=fieldnames(d);
for j=1:numel(f)
    if ~isfield(cfg,f{j}), cfg.(f{j})=d.(f{j}); end
end
end

function [U,W,rate]=state(H,C,V)
[K,L,Nr,Nt]=size(H); d=size(V,4);
U=complex(zeros(K,Nr,d)); W=complex(zeros(K,d,d)); rate=zeros(K,1);
p=zeros(L,1);
for l=1:L, p(l)=sum(abs(V(l,:,:,:)).^2,'all'); end
for k=1:K
    R=eye(Nr); wanted=complex(zeros(Nr,d));
    for i=1:K
        G=complex(zeros(Nr,d));
        for l=1:L
            h=reshape(H(k,l,:,:),Nr,Nt);
            v=reshape(V(l,i,:,:),Nt,d);
            G=G+h*v;
        end
        R=R+G*G';
        if i==k, wanted=G; end
    end
    for l=1:L, R=R+p(l)*reshape(C(k,l,:,:),Nr,Nr); end
    u=R\wanted;
    E=eye(d)-u'*wanted-wanted'*u+u'*R*u;
    E=(E+E')/2;
    U(k,:,:)=reshape(u,1,Nr,d);
    W(k,:,:)=reshape(E\eye(d),1,d,d);
    rate(k)=-real(log(det(E)))/log(2);
end
end

function parts=quadratic(H,C,U,W)
[K,L,Nr,Nt]=size(H); d=size(U,3);
M=complex(zeros(K,Nr,Nr)); B=complex(zeros(L,K,Nt,d)); D=zeros(L,1);
for k=1:K
    u=reshape(U(k,:,:),Nr,d); w=reshape(W(k,:,:),d,d);
    m=u*w*u'; M(k,:,:)=reshape(m,1,Nr,Nr);
    for l=1:L
        h=reshape(H(k,l,:,:),Nr,Nt);
        B(l,k,:,:)=reshape(h'*u*w,1,1,Nt,d);
        c=reshape(C(k,l,:,:),Nr,Nr);
        D(l)=D(l)+real(trace(m*c));
    end
end
parts=struct('M',M,'B',B,'D',D);
end

function y=qapply(H,parts,x,mask)
[K,L,Nr,Nt]=size(H); d=size(x,4); y=complex(zeros(size(x)));
for k=1:K
    m=reshape(parts.M(k,:,:),Nr,Nr);
    for i=1:K
        s=complex(zeros(Nr,d));
        for l=1:L
            s=s+reshape(H(k,l,:,:),Nr,Nt)*reshape(x(l,i,:,:),Nt,d);
        end
        ms=m*s;
        for l=1:L
            tmp=reshape(y(l,i,:,:),Nt,d)+reshape(H(k,l,:,:),Nr,Nt)'*ms;
            y(l,i,:,:)=reshape(tmp,1,1,Nt,d);
        end
    end
end
for l=1:L, y(l,:,:,:)=y(l,:,:,:)+parts.D(l)*x(l,:,:,:); end
y=y.*reshape(mask,L,K,1,1);
end

function [z,history,converged]=v_admm(resources,parts,initial,cfg)
G=numel(resources); z=initial; x=initial; dual=cellfun(@(v) zeros(size(v),'like',v),z,'UniformOutput',false);
n=sum(cellfun(@numel,z)); rho=cfg.rho; converged=false; history=struct([]);
for t=1:cfg.admm_iterations
    new=cell(1,G); cgmax=0;
    for g=1:G
        r=resources(g); mask=reshape(r.serve,size(r.serve,1),size(r.serve,2),1,1);
        a=rbweight(r); p=parts{g};
        apply=@(v) a*qapply(r.H,p,v,r.serve)+(rho/2)*v;
        rhs=(a*p.B+(rho/2)*(z{g}-dual{g})).*mask;
        new{g}=cg(apply,rhs,x{g},cfg.cg_iterations,1e-5).*mask;
        residual=apply(new{g})-rhs;
        cgmax=max(cgmax,sqrt(sum(abs(residual).^2,'all'))/max(sqrt(sum(abs(rhs).^2,'all')),eps));
    end
    oldz=z; z=project(resources,cellplus(new,dual),cfg.budget);
    dual=cellplus(dual,cellminus(new,z)); x=new;
    primal=cellnorm(cellminus(new,z)); dualres=rho*cellnorm(cellminus(z,oldz));
    ep=sqrt(n)*cfg.eps_abs+cfg.eps_rel*max(cellnorm(new),cellnorm(z));
    ed=sqrt(n)*cfg.eps_abs+cfg.eps_rel*rho*cellnorm(dual);
    history(t).inner=t;history(t).rho=rho;history(t).primal=primal;
    history(t).dual=dualres;history(t).eps_primal=ep;
    history(t).eps_dual=ed;history(t).cg_relative=cgmax;
    history(t).power=chasi_power(resources,z);
    if primal<=ep && dualres<=ed && cgmax<=max(1e-3,10*cfg.eps_rel)
        converged=true; break
    end
    if mod(t,10)==0 && primal>10*dualres && rho<10
        oldrho=rho;rho=2*rho;dual=cellfun(@(v) v*oldrho/rho,dual,'UniformOutput',false);
    elseif mod(t,10)==0 && dualres>10*primal && rho>1e-5
        oldrho=rho;rho=rho/2;dual=cellfun(@(v) v*oldrho/rho,dual,'UniformOutput',false);
    end
end
end

function x=cg(apply,b,x,maxiter,tol)
r=b-apply(x); p=r; rr=real(sum(conj(r).*r,'all'));
target=tol^2*max(1,real(sum(conj(b).*b,'all')));
for j=1:maxiter
    if rr<=target, break; end
    ap=apply(p); alpha=rr/max(real(sum(conj(p).*ap,'all')),1e-30);
    x=x+alpha*p; r=r-alpha*ap;
    rrnew=real(sum(conj(r).*r,'all'));
    p=r+(rrnew/max(rr,1e-30))*p; rr=rrnew;
end
end

function out=project(resources,x,budget)
out=x; G=numel(x); L=size(x{1},1);
for g=1:G
    r=resources(g); out{g}=out{g}.*reshape(r.serve,L,[],1,1);
end
p=chasi_power(resources,out);
for l=1:L
    if p(l)<=budget, continue; end
    lo=0; hi=1;
    while projectedpower(resources,out,l,hi)>budget, hi=2*hi; end
    for j=1:35
        lam=(lo+hi)/2;
        if projectedpower(resources,out,l,lam)>budget, lo=lam;
        else, hi=lam; end
    end
    for g=1:G, out{g}(l,:,:,:)=out{g}(l,:,:,:)/(1+hi*rbweight(resources(g))); end
end
end

function p=projectedpower(resources,x,l,lambda)
p=0;
for g=1:numel(x)
    a=rbweight(resources(g)); p=p+a*sum(abs(x{g}(l,:,:,:)).^2,'all')/(1+lambda*a)^2;
end
end

function p=chasi_power(resources,V)
L=size(V{1},1); p=zeros(L,1);
for g=1:numel(V)
    a=rbweight(resources(g));
    for l=1:L, p(l)=p(l)+a*sum(abs(V{g}(l,:,:,:)).^2,'all'); end
end
end

function a=rbweight(r)
if isfield(r,'tx_rb_count'), a=r.tx_rb_count/273;
else, a=r.rb_count/273; end
end

function s=size4(v)
s=[size(v,1),size(v,2),size(v,3),size(v,4)];
end

function n=cellnorm(c)
n=sqrt(sum(cellfun(@(x) real(sum(conj(x).*x,'all')),c)));
end

function c=cellplus(a,b)
c=cellfun(@plus,a,b,'UniformOutput',false);
end

function c=cellminus(a,b)
c=cellfun(@minus,a,b,'UniformOutput',false);
end
