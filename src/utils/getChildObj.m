function childObj = getChildObj(parentObj, childId)
%GETCHILDREN Summary of this function goes here
%   Detailed explanation goes here
childObj = '';

if isnumeric(childId) && ~mod(childId, 1)
    if childId > length(parentObj.Children)
        throw(MException('SFA:ChildNotFound', sprintf('No child with the specified index: %s', childId)));
    else
        childObj = parentObj.Children(childId);
    end
elseif isstring(childId) || ischar(childId)
    for idx=1:length(parentObj.Children)
        if strcmp(parentObj.Children(idx).Name, childId)
            childObj = parentObj.Children(idx);
        end
    end
    
    if isempty(childObj)
        throw(MException('SFA:ChildNotFound', sprintf('No child with the specified name: %s', childId)));
    end
else
    throw(MException('SFA:InvalidChildId', sprintf('Invalid childId parameter type. Expected integer, string or char.')));
end
end

