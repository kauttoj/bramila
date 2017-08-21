%% just a demo for dimensionality reduction with PCA or factor analysis. We could add more examples (ICA, etc)

%% demo image created from neurosynth, maps below
% fslmerge -t emos.nii.gz happy_pFgA_z_FDR_0.01.nii.gz sad_pFgA_z_FDR_0.01.nii.gz fear_pFgA_z_FDR_0.01.nii.gz disgust_pFgA_z_FDR_0.01.nii.gz surprisingly_pFgA_z_FDR_0.01.nii.gz neutral_pFgA_z_FDR_0.01.nii.gz emotion_pFgA_z_FDR_0.01.nii.gz negative\ emotional_pFgA_z_FDR_0.01.nii.gz arousal_pFgA_z_FDR_0.01.nii.gz valence_pFgA_z_FDR_0.01.nii.gz

addpath(genpath('/scratch/braindata/shared/toolboxes/bramila/bramila/'));

nii=load_nii('bramila_emos.nii');
data=double(nii.img);
NE=size(data,4);
data=reshape(data,[],NE);

ids=find(sum(data,2)>-1000);
[coeff, score, latent, tsquared, explained] = pca(data(ids,:));

[L1, T]=rotatefactors(coeff(:,1:3));
score_rot=data(ids,:)*L1;

imagesc(coeff)
figure
imagesc(L1)
colorbar
saveas(gcf,'pca_loadings.png')

for pcs=1:3
    out=zeros(91,109,91);
    out(ids)=score(:,pcs);
    filename=['pc_' num2str(pcs) '.nii']
    save_nii(make_nii(out,[2 2 2]),filename);
    niitemp=bramila_fixOriginator(filename);
    save_nii(niitemp,filename);
    
    out=zeros(91,109,91);
    out(ids)=score_rot(:,pcs);
    filename=['pc_rot_' num2str(pcs) '.nii']
    save_nii(make_nii(out,[2 2 2]),filename);
    niitemp=bramila_fixOriginator(filename);
    save_nii(niitemp,filename);
    
end


% now let's try non-negative matrix decomposition
load /scratch/braindata/shared/enricoheini/M.mat
ids=find(sum(abs(M),2)>0);
data=M;
for iter=1:10 % increase number e.g. to 100
	% we run multiple iterations and pick the best = lowest residual
	fprintf([num2str(iter) '... '])
	[Wi{iter},Hi{iter},D(iter)] = nnmf(data(ids,:),3);
end
disp('done') 

winner=find(D==min(D));
winner=winner(1);

H=Hi{winner};
W=Wi{winner};
figure
imagesc(H)
title('Loadings for NNMF');
colorbar
saveas(gcf,['nnmf_loadings.png'])

for pcs=1:3
    out=zeros(91,109,91);
    out(ids)=W(:,pcs);
    filename=['nnmf_' num2str(pcs) '.nii']
    save_nii(make_nii(out,[2 2 2]),filename);
    niitemp=bramila_fixOriginator(filename);
    save_nii(niitemp,filename);

end


