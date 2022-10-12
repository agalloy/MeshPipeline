%% This is a function created to clean up images eliminating floating points
% Created on 6/29/2021 by Hannah Borges
% image is a binary mask 
% conn specifies the pixel connectivity 
% new_image is the output containing the cleaned up image

function new_image = cleanSegmentation(image, conn)

new_image = zeros(size(image));
CC = bwconncomp(image, conn);
numPixels = cellfun(@numel,CC.PixelIdxList);
[biggest, idx] = max(numPixels); 
new_image(CC.PixelIdxList{idx}) = 1;
new_image = new_image | imclearborder(~new_image); % Removing holes from image

% Dilation and erosion process
SE = strel('cube', 3);
new_image = imdilate(new_image, SE);

new_image = imerode(new_image, SE);
new_image = imerode(new_image, SE);

new_image = imdilate(new_image, SE);

end
