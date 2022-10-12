

function maxTheta = maxTriSurfAngle(NodeArray, ElementArray)

TR = triangulation(ElementArray, NodeArray);
near = neighbors(TR);
normalVect = faceNormal(TR);

maxTheta = nan(length(ElementArray),1);
for i = 1:length(ElementArray)
    normalVect_near = normalVect(near(i,:),:);
    theta = acosd(normalVect_near*normalVect(i,:)');
    
    maxTheta(i) = max(theta);
end

end