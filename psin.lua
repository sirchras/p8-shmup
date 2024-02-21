SIN,PI=math.sin,math.pi

local psin=function(x,d)
  for i=0,x do
    local q=i/d
    print(q.." "..SIN(-2*PI*q))
    if q>=1 then break end
  end
end

psin(arg[1],arg[2])
