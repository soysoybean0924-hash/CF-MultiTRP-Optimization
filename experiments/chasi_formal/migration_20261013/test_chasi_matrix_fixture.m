% Deterministic two-TRP/two-resource fixture; no formal experiment is run.
here=fileparts(mfilename('fullpath'));
G=2; K=2; L=2; Nr=4; Nt=4; d=1;
resources=repmat(struct('H',[],'C',[],'serve',[],'rb_count',[],...
    'tx_rb_count',[]),1,G);
initialV=cell(1,G);
for g=1:G
    H=complex(zeros(K,L,Nr,Nt)); C=complex(zeros(K,L,Nr,Nr));
    V=complex(zeros(L,K,Nt,d));
    for k=1:K
        for l=1:L
            for r=1:Nr
                for n=1:Nt
                    H(k,l,r,n)=(.13+.025*k+.018*l+.008*r+.004*n)*...
                        exp(1i*(.17*k-.11*l+.07*r+.09*n+.03*g));
                end
                C(k,l,r,r)=.002*(1+.1*k+.2*l);
            end
            for n=1:Nt
                V(l,k,n,1)=.2*exp(1i*(.2*l+.3*k+.1*n+.04*g));
            end
        end
    end
    resources(g).H=H; resources(g).C=C;
    resources(g).serve=true(L,K);
    resources(g).rb_count=16+(g==G);resources(g).tx_rb_count=resources(g).rb_count;
    initialV{g}=V;
end
cfg=struct('rank',1,'budget',.11,'outer_iterations',2,...
    'admm_iterations',80,'cg_iterations',80,'eps_abs',1e-6,'eps_rel',1e-5);
save(fullfile(here,'matlab_fixture_input.mat'),'resources','initialV','cfg','-v7');
out=chasi_matrix_wmmse(resources,cfg,initialV);
save(fullfile(here,'matlab_fixture_output.mat'),'out','-v7');
fprintf('MATLAB objective %.12g, max power %.12g, reason %s\n',...
    out.trajectory(end).objective,max(out.power),out.reason);
