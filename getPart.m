function imgPart=getPart(img,luCorner,rlCorner)

luRow=luCorner(1);
luCol=luCorner(2);
rlRow=rlCorner(1);
rlCol=rlCorner(2);
imgPart=img(luRow:rlRow,luCol:rlCol,:);

end
