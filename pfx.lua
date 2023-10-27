-- this is a mess...

-- effects={}
pfx={}

-- classes --
--
--util class to avoid repetition
class={}
function class:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  return o
end

--particle class
ptc=class:new{
  x=0, --x
  y=0, --y
  r=0, --ptc radius
  c=7, --default color
  -- dx=0, --x velocity
  -- dy=0, --y velocity
  -- dr=0, --change in radius
  t=0, --ptc age
  mt=30, --ptc max age
  -- typ="expl" --ptc type
}
function ptc:update()
  --update ptc age
  self.t+=1
  --if ptc too old, expire ptc
  if self.t>self.mt then
    self:expire()
  end
end
function ptc:draw()
  if self.r<1 then
    pset(self.x,self.y,self.c)
  else
    circfill(self.x,self.y,
      self.r,self.c)
  end
end
function ptc:expire()
  del(pfx,self)
end

--spark ptc
sprk=ptc:new{
  dx=0, --x velocity
  dy=0, --y velocity
}
function sprk:update()
  --update position
  self.x+=self.dx
  self.y+=self.dy
  --deccelerate ptc
  self.dx*=0.85
  self.dy*=0.85
  --call parent update
  ptc.update(self)
end

--explosion ptc
expl=sprk:new{
  explc="red"
}
function expl:expire()
  --if ptc too old, shrink/fade
  self.r-=0.5
  if (self.r<0) del(pfx,self)
end
do
  local lt={
    "red": {10,9,8,2,5},
    "blue": {13,12,1,2,5}
  }
  function expl:draw()
    local ct=lt[self.explc]
    local c,age=self.c,self.t/self.mt
    if (age>0.2) c=ct[1]
    if (age>0.3) c=ct[2]
    if (age>0.5) c=ct[3]
    if (age>0.6) c=ct[4]
    if (age>0.8) c=ct[5]
    ptc.draw(self)
  end
end

--wave ptc
wave=ptc:new{
  c=6, --default color
  dr=0, --change in radius
}
function wave:update()
  --incr/dcrm radius
  self.r+=self.dr
  --call parent update
  ptc.update(self)
end
function wave:draw()
  circ(self.x,self.y,
    self.r,self.c)
end

-- do
--   local lt={
--     --explosion ptc
--     expl={
--       update=function(self)
--         --update position
--         self.x+=self.dx
--         self.y+=self.dy
--         --deccelerate ptc
--         self.dx*=0.85
--         self.dy*=0.85
--         --if ptc too old, shrink/fade
--         if self.t>self.mt then
--           self.r-=0.5
--           if (self.r<0) del(pfx,self)
--         end
--       end,
--       draw=function(self)
--         --todo: other colors? green,purple?
--         local red=(self.explc=="red")
--         local c,age=self.c,self.t/self.mt
--         --change color based on ptc age
--         if (age>0.2) c=red and 10 or 13
--         if (age>0.3) c=red and 9 or 12
--         if (age>0.5) c=red and 8 or 1
--         if (age>0.6) c=2
--         if (age>0.8) c=5
--         circfill(self.x,self.y,
--           self.r,c)
--       end
--     },
--     --shockwave ptc
--     wave={
--       update=function(self)
--         --incr/dcrm radius
--         self.r+=self.dr
--         --if ptc too old, delete
--         if self.t>self.mt then
--           del(pfx,self)
--         end
--       end,
--       draw=function(self)
--         circ(self.x,self.y,
--           self.r,self.c)
--       end
--     },
--     --spark ptc
--     sprk={
--       update=function(self)
--         --update position
--         self.x+=self.dx
--         self.y+=self.dy
--         --deccelerate ptc
--         self.dx*=0.85
--         self.dy*=0.85
--         --if ptc too old, delete
--         if self.t>self.mt then
--           del(pfx,self)
--         end
--       end,
--       draw=function(self)
--         if self.r<1 then
--           pset(self.x,self.y,self.c)
--         else
--           circfill(self.x,self.y,
--             self.r,self.c)
--         end
--       end
--     }
--   }

-- end

-- helper functions --
--
--spawn explosion pfx
function spawnexplosion(x,y,ec)
	local ec=ec or "red"
	--central flash ptc
	add(pfx,expl:new{
		x=x,
		y=y,
		r=8,
		mt=0,
		explc=ec
	})
	--emanating ptc
	for i=1,30 do
		add(pfx,expl:new{
			x=x,
			y=y,
			r=1+rnd(4), -- 1<=r<5
			dx=rnd(6)-3, -- -3<=dx<3
			dy=rnd(6)-3, -- -3<=dy<3
			mt=10+rnd(10), -- 10<=mt<20
			explc=c
		})
	end
	--shockwave
	add(pfx,wave:new{
		x=x,
		y=y,
		r=9,
		c=6,
		dr=2,
		mt=6,
	})
	--sparks
	for i=1,20 do
		add(pfx,sprk:new{
			x=x,
			y=y,
			dx=rnd(10)-5, -- -5<=dx<5
			dy=rnd(10)-5, -- -5<=dy<5
			mt=10+rnd(10), -- 10<=mt<20
		})
	end
end

function spawnimpact(x,y)
	--shockwave
	add(pfx,wave:new{
		x=x,
		y=y,
		r=3,
		c=6,
		dr=1,
		mt=3,
	})
	--sparks
	for i=1,ceil(rnd(2)) do
		add(pfx,sprk:new{
			x=x,
			y=y,
			r=flr(rnd(2)), -- r=0,1
			dx=rnd(10)-5, -- -5<=dx<5
			dy=rnd(5)-5, -- -5<=dy<0
			mt=10+rnd(10), -- 10<=mt<20
		})
	end
end
