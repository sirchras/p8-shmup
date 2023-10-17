sin,pi=math.sin,math.pi

function psin(x,d)
  for i=0,x do
    local q=i/d
    print(q.." "..sin(-2*pi*q))
    if q>=1 then break end
  end
end

psin(arg[1],arg[2])
