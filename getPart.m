function imgPart=getPart(img,luCorner,rlCorner)

luRow=luCorner(1);
luCol=luCorner(2);
rlRow=rlCorner(1);
rlCol=rlCorner(2);

if luRow<=0
    luRow=1;
end
if luCol<=0
    luCol=1;
end
if rlRow<=0
    rlRow=1;
end
if rlCol<=0
    rlCol=1;
end

imgPart=img(luRow:rlRow,luCol:rlCol,:);

end
