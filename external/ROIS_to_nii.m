
mask_name = 'brainnetome_MPM_rois_2mm.nii';

img = zeros(91,109,91);
for i=1:length(rois)
    fprintf('%s %i\n',rois(i).label,i);
    for j=1:size(rois(i).map,1)
        x=rois(i).map(j,1);
        y=rois(i).map(j,2);
        z=rois(i).map(j,3);
        img(x,y,z)=i;
    end
end
save_nii_oma(img,mask_name);