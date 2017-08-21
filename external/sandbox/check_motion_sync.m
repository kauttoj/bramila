clear all
close all


addpath('/proj/braindata/eglerean/bramila/');
addpath('/proj/braindata/eglerean/bramila/stats/')

addpath('/scratch/braindata/shared/toolboxes/export_fig/')
addpath('/scratch/braindata/shared/toolboxes/cbrewer/')
%%% TTT

pardata=[
{'/triton/becs/scratch/braindata/lnummen/StoryISC/001/ep_MCF.nii.par'}
{'/triton/becs/scratch/braindata/lnummen/StoryISC/002/ep_MCF.nii.par'}
{'/triton/becs/scratch/braindata/lnummen/StoryISC/003/ep_MCF.nii.par'}
{'/triton/becs/scratch/braindata/lnummen/StoryISC/004/ep_MCF.nii.par'}
{'/triton/becs/scratch/braindata/lnummen/StoryISC/005/ep_MCF.nii.par'}
{'/triton/becs/scratch/braindata/lnummen/StoryISC/006/ep_MCF.nii.par'}
{'/triton/becs/scratch/braindata/lnummen/StoryISC/007/ep_MCF.nii.par'}
{'/triton/becs/scratch/braindata/lnummen/StoryISC/009/ep_MCF.nii.par'}
{'/triton/becs/scratch/braindata/lnummen/StoryISC/013/ep_MCF.nii.par'}
{'/triton/becs/scratch/braindata/lnummen/StoryISC/015/ep_MCF.nii.par'}
{'/triton/becs/scratch/braindata/lnummen/StoryISC/018/ep_MCF.nii.par'}
{'/triton/becs/scratch/braindata/lnummen/StoryISC/019/ep_MCF.nii.par'}
{'/triton/becs/scratch/braindata/lnummen/StoryISC/020/ep_MCF.nii.par'}
{'/triton/becs/scratch/braindata/lnummen/StoryISC/022/ep_MCF.nii.par'}
{'/triton/becs/scratch/braindata/lnummen/StoryISC/023/ep_MCF.nii.par'}
{'/triton/becs/scratch/braindata/lnummen/StoryISC/024/ep_MCF.nii.par'}
{'/triton/becs/scratch/braindata/lnummen/StoryISC/025/ep_MCF.nii.par'}
{'/triton/becs/scratch/braindata/lnummen/StoryISC/028/ep_MCF.nii.par'}
{'/triton/becs/scratch/braindata/lnummen/StoryISC/030/ep_MCF.nii.par'}
{'/triton/becs/scratch/braindata/lnummen/StoryISC/032/ep_MCF.nii.par'}
];


load ../funpsy/model.mat % model time series

toi=1:1094;

Nsubj=length(pardata);
for s=1:Nsubj
    disp(num2str(s));
    parfile=pardata{s};
    ts=load(parfile);
	%ts(482:end,:)=[];	% remove after 481
    fwd=bramila_framewiseDisplacement(ts);
    allMts(:,s,:)=ts;
    allFwd(:,s)=fwd;
	T=size(allMts,1);
end

for mp1=1:6
    disp(num2str(mp1))
    % comparing motion param 
    data=zscore(squeeze(allMts(:,:,mp1)));

    [pvals cc]=test_isc(data(toi,:),100000,'Pearson');
    isc(mp1,1)=cc;
    isc(mp1,2:3)=pvals
    
    [pvals cc]=test_ntime(model(toi,:),data(toi,:),100000,'Pearson',0);

    chi_r=-2*log(pvals(:,:,1));
    chi_l=-2*log(pvals(:,:,2));
    chi_r=sum(chi_r,1);
    chi_l=sum(chi_l,1);
    glm(mp1,:,1)=1-chi2cdf(chi_r,2*Nsubj) % val aro
    glm(mp1,:,2)=1-chi2cdf(chi_l,2*Nsubj); % val aro

    
    
end

    [pvals cc]=test_isc(allFwd(toi,:),100000,'Pearson');
    fwd_isc(1)=cc;
    fwd_isc(2:3)=pvals;


  
    [pvals cc]=test_ntime(model(toi,:),allFwd(toi,:),100000,'Pearson',0)
    chi_r=-2*log(pvals(:,:,1));
    chi_l=-2*log(pvals(:,:,2));
    chi_r=sum(chi_r,1);
    chi_l=sum(chi_l,1);
    fwd_glm(1,:,1)=1-chi2cdf(chi_r,2*Nsubj); % val aro
    fwd_glm(1,:,2)=1-chi2cdf(chi_l,2*Nsubj); % val aro



        
