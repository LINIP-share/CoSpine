function [ resid ] = GLMcleanup (Y, X)
% 
% Takes input 4D timeseries FMRI data and regresses out model components
% specified in X. 
%
% All regressors in X have to be demeaned and high pass filtered 
%
% by Yazhuo Kong, FMRIB, Oxford.
% 25/10/2011
%

sizeY=size(Y); % 4D, [x y z vols]
sizeX=size(X); % 4D, [ev z vols]

resid=zeros(sizeY);

if sizeY(3)==sizeX(2)

for sliceid=1:sizeY(3)
    slicedata=squeeze(Y(:,:,sliceid,:));
    idata1=reshape(slicedata,prod([sizeY(1) sizeY(2)]),sizeY(4))';  % idata1 now is 250x(128*128)

    % demean the timeseries for each voxel and for each element of the model
    Ydm = demean(idata1);
    sliceX=squeeze(X(:,sliceid,:)); sliceX=sliceX'; %sliceX is 250x(ev)
    Xdm_f = demean(sliceX);
    %Xdm_f=filter(fb,fa,Xdm);
    
    % find the mean
    Ymean = idata1 - Ydm;

    % compute parameter estimates
    B = pinv(Xdm_f)*Ydm;

    % subtract model fit from original data
    resid_slice = Ydm - Xdm_f*B;

    % add the mean back to the residuals
    resid_slice = resid_slice + Ymean;
    resid_slice=resid_slice';
    resid_slice = reshape(resid_slice,sizeY(1),sizeY(2),sizeY(4));
    resid(:,:,sliceid,:)=resid_slice;
end
else
    disp('slice number not same! quit');
    return;
end
return;
