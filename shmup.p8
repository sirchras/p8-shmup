pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--main
function _init()
	--state
	state="start"
end

function _update()
	local update={
		start=update_start,
		game=update_game,
		over=update_over,
		debug=update_start
	}
	update[state]()
end

function _draw()
	local draw={
		start=draw_start,
		game=draw_game,
		over=draw_over,
		debug=draw_debug
	}
	draw[state]()
	--debug time
	print(flr(time()),0,120,7)
	if (bullets) print(#bullets,0,112,8)
	if (enemies) print(#enemies,0,104,11)
	if (pfx) print(#pfx,0,96,9)
end

-->8
--start state
function update_start()
	if btnp(❎) then
		--start game
		init_game()
		state="game"
	end
end

function draw_start()
	cls(1)
	print("shmup game v0.2",34,40,12)
	print("press ❎ to start",30,80,7)
end
-->8
--game state
function init_game()
	score=0
	--player
	p=player:new{x=60,y=60}
	--bullets
	bullets={}
	m_flsh=0
	--enemies
	enemies={}
	spawnenemies(2)
	--fx
--	effects={} --sprite effects
	pfx={} --particles
	--background
	bg=bgrnd()
end

function update_game()
	--test, remove later
	if (btnp(🅾️)) state="over"
	--move player
	p:update()
	--move bullets
	for i=#bullets,1,-1 do
		local b=bullets[i]
		b:update()
		--rm offscreen bullets
		if b.y>128 or b.y<-8 then
			deli(bullets,i)
		end
	end
	--move enemies
	for e in all(enemies) do
		e:update()
		--rm offscreen enemies
		if e.y>128 then
			del(enemies,e)
			spawnenemy()
		end
	end
	--anim fx
	for ptc in all(pfx) do
		ptc:update()
	end
	--anim background
	bg.update()
	--check if game over
	if p.♥<=0 then
		state="over"
	end
end

function draw_game()
	cls(0)
	--background
	bg.draw()
	--player
	p:draw()
	--enemies
	for _,e in ipairs(enemies) do
		e:draw()
	end
	--bullets
	for _,b in ipairs(bullets) do
		b:draw()
	end
	--fx
	for _,ptc in ipairs(pfx) do
		ptc:draw()
	end
	--ui
	print("score: "..score,40,0,12)
	for i=1,p.m♥ do
		sp=p.♥>=i and 11 or 12
		spr(sp,(i-1)*8,1)
	end
end

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

--base game obj class
gmobj=class:new{
	x=0, --x
	y=0, --y
	sp=0, --sprite
	spx=1, --sprite width
	spy=1 --sprite height
}
function gmobj:draw()
	spr(self.sp,self.x,self.y,
		self.spx,self.spy)
end
--collisions (square)
-- assumes 8px sprites
function gmobj:col(obj)
	local sx1,ox1=self.x,obj.x
	local sx2,ox2=sx1+7,ox1+7
	local sy1,oy1=self.y,obj.y
	local sy2,oy2=sy1+7,oy1+7
	--if obj to the right, left,
	-- above, or below:
	if sx2<ox1 or ox2<sx1 or
	   sy1>oy2 or oy1>sy2 then
		--no collision
		return false
	end
	--otherwise: collision
	return true
end

--player class
player=gmobj:new{
	sp=2, --player sprite
	fsp=5, --flame sprite
	s=2, --movement speed
	fr=4, --fire rate
	fc=0, --fire cooldown
	mflsh=0, --muzzle flash
	♥=3, --current lives
	m♥=3, --max lives
	invul=0 --iframes
}
function player:update()
	local sp=2 --default sprite
	local x,y=self.x,self.y
	local dx,dy=0,0
	--btn input
	--⬆️⬇️⬅️➡️❎
	if btn(⬅️) then
		dx,sp=-self.s,1
	end
	if btn(➡️) then
		dx,sp=self.s,3
	end
	if btn(⬆️) then dy=-self.s end
	if btn(⬇️) then dy=self.s end
	if btn(❎) and self.fc<=0 then
		--spawn new bullet
		b=bullet:new{x=x,y=y-6,dy=-2}
		add(bullets,b)
		--reset fire cooldown
		self.fc=self.fr
		--set muzzle flash
		self.mflsh=4
		--play firing sfx
		sfx(0)
	end
	--move/update player
	self.x=mid(0,x+dx,120)
	self.y=mid(0,y+dy,120)
	self.sp=sp
	--decrm iframes
	if (self.invul>0) self.invul-=1
	--decrm fire cooldown
	self.fc-=1
	--anim muzzle flash
	if (self.mflsh>0) self.mflsh-=1
	--anim flame
	self.fsp+=1
	if (self.fsp>9)	self.fsp=5
end
function player:draw()
	local x,y=self.x,self.y
	--blinking invulerability
	local ifr=self.invul
	local blink=(
		ifr>0 and sin(ifr/12)<0
	)
	if not blink then
		--call parent draw
		gmobj.draw(self)
	end
	--flame spr
	spr(self.fsp,x,y+8)
	--muzzle flash
	if self.mflsh>0 then
		circfill(x+4,y,self.mflsh,7)
	end
end

--bullet class
bullet=gmobj:new{
	sp=14, --bullet sprite
	dx=0, --x velocity
	dy=0 --y velocity
}
function bullet:update()
	self.x+=self.dx
	self.y+=self.dy
	for i=#enemies,1,-1 do
		local e=enemies[i]
		if self:col(e) then
			--todo: enemy bullets
			e.♥-=1
			e.flash=4
			spawnimpact(self.x+4,self.y+4)
			sfx(3)
			del(bullets,self)
			if e.♥<=0 then
				--create explosion fx
				spawnexplosion(e.x+4,e.y+4,"blue")
				--delete the dead enemy
				deli(enemies,i)
				--score,sfx feedback
				sfx(2)
				score+=10
				--spawn new enemy
				spawnenemy()
			end
		end
	end
end

--enemy class
enemy=gmobj:new{
	sp=32, --enemy sprite
	♥=5, --enemy health
	flash=0 --dmg indicator
}
function enemy:update()
	self.y+=1
	--check enemy/player collision
	if self:col(p) and p.invul==0 then
		--spawn explosion fx,sfx
		spawnexplosion(p.x+4,p.y+4)
		sfx(1)
		--todo: this seems a little dodgy
		p.♥-=1
		p.invul=60
	end
	--dcrm dmg flash
	if (self.flash>0) self.flash-=1
	--anim
	self.sp+=0.4
	if (self.sp>=36) self.sp=32
end
function enemy:draw()
	if self.flash>0 then
		--turn red when dmg
--		pal(3,8) --d grn to d red
--		pal(11,14) --l grn to pink

		--brighten colors/darken white
--		pal(1,12) --d blue to l blue
--		pal(3,11) --d grn to l grn
--		pal(7,5) --white to d grey
--		pal(11,7) --l grn to white

		--turn white when dmg
--		for i=1,15 do
--			pal(i,7)
--		end

		--kinda color invert
		pal(1,8) --d blue to brwn
		pal(3,2) --d grn to purple
		pal(7,0) --white to blck
		pal(11,14) --l grn to pink

		--"true" color invert
--		pal(1,15) --d blue to sand
--		pal(3,14) --d grn to pink
--		pal(7,0) --white to blck
--		pal(11,2) --l grn to purple

	end
	--call parent draw fn
	gmobj.draw(self)
	pal() --reset palette
end

--particle class
ptc=class:new{
	x=0, --x
	y=0, --y
	r=0, --ptc radius
	c=7, --default color
	dx=0, --x velocity
	dy=0, --y velocity
	dr=0, --change in radius
	t=0, --ptc age
	mt=30, --ptc max age
	typ="expl" --ptc type
}
do
	local lt={
		--explosion ptc
		expl={
			update=function(self)
				--update position
				self.x+=self.dx
				self.y+=self.dy
				--deccelerate ptc
				self.dx*=0.85
				self.dy*=0.85
				--if ptc too old, shrink/fade
				if self.t>self.mt then
					self.r-=0.5
					if (self.r<0) del(pfx,self)
				end
			end,
			draw=function(self)
				--todo: other colors? green,purple?
				local red=(self.explc=="red")
				local c,age=self.c,self.t/self.mt
				--change color based on ptc age
				if (age>0.2) c=red and 10 or 13
				if (age>0.3) c=red and 9 or 12
				if (age>0.5) c=red and 8 or 1
				if (age>0.6) c=2
				if (age>0.8) c=5
				circfill(self.x,self.y,
					self.r,c)
			end
		},
		--shockwave ptc
		wave={
			update=function(self)
				--incr/dcrm radius
				self.r+=self.dr
				--if ptc too old, delete
				if self.t>self.mt then
					del(pfx,self)
				end
			end,
			draw=function(self)
				circ(self.x,self.y,
					self.r,self.c)
			end
		},
		--spark ptc
		sprk={
			update=function(self)
				--update position
				self.x+=self.dx
				self.y+=self.dy
				--deccelerate ptc
				self.dx*=0.85
				self.dy*=0.85
				--if ptc too old, delete
				if self.t>self.mt then
					del(pfx,self)
				end
			end,
			draw=function(self)
				if self.r<1 then
					pset(self.x,self.y,self.c)
				else
					circfill(self.x,self.y,
						self.r,self.c)
				end
			end
		}
	}
	function ptc:update()
		local typ=self.typ
		--general update behaviour
		--update ptc age
		self.t+=1
		--specialised
		lt[typ].update(self)
	end
	function ptc:draw()
		local typ=self.typ
		lt[typ].draw(self)
	end
end

-- helper functions --
--
--spawn enemy
function spawnenemies(n)
	for i=1,n do
		local e=enemy:new{
			x=rnd(120), --random x pos
			y=-8 --offscreen (above)
		}
		add(enemies,e)
	end
end
spawnenemy=function() spawnenemies(1) end

--spawn explosion pfx
function spawnexplosion(x,y,c)
	local c=c or "red"
	--central flash ptc
	add(pfx,ptc:new{
		x=x,
		y=y,
		r=8,
		mt=0,
		explc=c
	})
	--emanating ptc
	for i=1,30 do
		add(pfx,ptc:new{
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
	add(pfx,ptc:new{
		x=x,
		y=y,
		r=9,
		c=6,
		dr=2,
		mt=6,
		typ="wave"
	})
	--sparks
	for i=1,20 do
		add(pfx,ptc:new{
			x=x,
			y=y,
			dx=rnd(10)-5, -- -5<=dx<5
			dy=rnd(10)-5, -- -5<=dy<5
			mt=10+rnd(10), -- 10<=mt<20
			typ="sprk"
		})
	end
end

function spawnimpact(x,y)
	--shockwave
	add(pfx,ptc:new{
		x=x,
		y=y,
		r=3,
		c=6,
		dr=1,
		mt=3,
		typ="wave"
	})
	--sparks
	for i=1,ceil(rnd(2)) do
		add(pfx,ptc:new{
			x=x,
			y=y,
			r=flr(rnd(2)), -- r=0,1
			dx=rnd(10)-5, -- -5<=dx<5
			dy=rnd(5)-5, -- -5<=dy<0
			mt=10+rnd(10), -- 10<=mt<20
			typ="sprk"
		})
	end
end

--starfield
function bgrnd()
	local _upd,_drw
	--init
	local stars={}
	for i=1,100 do
		stars[i]={
			flr(rnd(128)), --x
			flr(rnd(128)), --y
			1+flr(rnd(3)) --spd
		}
	end
	_upd=function()
		for i=1,#stars do
			local y,v=unpack(stars[i],2)
			y=(y+v)%128
			stars[i][2]=y
		end
	end
	_drw=function()
		for i=1,#stars do
			local x,y,v=unpack(stars[i])
			local c=7
			if v==1 then c=1 end
			if v==2 then c=13 end
			pset(x,y,c)
		end
	end
	return {update=_upd,draw=_drw}
end
-->8
--over state
function update_over()
	if btnp(❎) then
		--start game
		init_game()
		state="game"
	end
end

function draw_over()
	cls(8)
	print("game over",48,40,1)
	print("press ❎ to restart",30,80,6+ceil(sin(time())))
end
__gfx__
00000000000220000002200000022000000000000000000000000000000000000000000000000000088088000880880008808800009999000000000000000000
0000000000288200002882000028820000000000000aa000000aa000000aa00000a77a00000aa00088880080888888808008008009aaaa900099990000000000
007007000028820000288200002882000000000000a77a000007700000a77a0009aaaa9000a77a008880008088888880800000809aa77aa909aaaa9000099000
0007700002888e2002e88e2002e8882000000000009aa900000aa000009aa90000999900009aa9000888080008888800080008009a7777a909a77a90009a7900
00077000027c8e202e87c8e202e8c7200000000000099000000aa0000009900000000000000990000080800000888000008080009a7777a909a77a90009aa900
007007000211882028811882028811200000000000000000000990000000000000000000000000000008000000080000000800009aa77aa909aaaa9000099000
00000000025d820028d55d820028d52000000000000000000000000000000000000000000000000000000000000000000000000009aaaa900099990000000000
00000000029d200002d99d200002d920000000000000000000000000000000000000000000000000000000000000000000000000009999000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000077000000770000007700000c77c0000077000000000000000000000000000000000000000000000000000
00099000000dd00000022000000330000001100000c77c000007700000c77c000cccccc000c77c00000000000000000000000000000000000000000000000000
0097a90000d7cd00002782000037b3000017c10000cccc00000cc00000cccc0000cccc0000cccc00000000000000000000000000000000000000000000000000
009aa90000dccd0000288200003bb300001cc100000cc000000cc000000cc00000000000000cc000000000000000000000000000000000000000000000000000
00099000000dd00000022000000330000001100000000000000cc000000000000000000000000000000000000000000000000000000000000000000000000000
00090000000d00000002000000030000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03300330033003300330033003300330000000000330033000000000000000000000000000000000000000500000000000000050000000000000000000000000
33b33b3333b33b3333b33b3333b33b330000000033b33b3300000000000000000000000098800000000055555550505000000555555000000000000500000000
3bbbbbb33bbbbbb33bbbbbb33bbbbbb3000000003bbbbbb300070000000070000000899999880000050055222222500000050555555550000000000555050000
3b7717b33b7717b33b7717b33b7717b3000000003bb33bb30000000007000000000899aaaa999800005022888888250000505555885255500000000550055000
0b7117b00b7117b00b7117b00b7117b0000000000b2222b00000770a779000000089aaa77aaa9800005288899998825000555222985555000000000000055000
0037730000377300003773000037730000000000003223000000077777aa00000089aa77777a988005228999aaa9825005225552222585000005500000000050
03033030030330300303303003033030000000000303303000000a7777770700009aa777777aa90000228a9a7aa9822500522522222885500005550000005550
0300003030000003030000300030030000000000030000300000a77777777700089aa7777777a900052889a777a9882500555229552888500000500000555550
0ee00ee0088008800bb00bb0022002200ee00ee000000000000097777777a00008aaa7777777aa9005289aa77aa9882000059229928285500000000500555500
ee7ee7ee88e88e88bb7bb7bb22e22e22ee2ee2ee00000000000007777777a000089aa7777777a98000289aaaaaa9885000559528855225000000005550055000
e777777e8eeeeee8b777777b2eeeeee2e222222e0000000000070977777a00000099aa77777aa9800058899a9999885000558958529985500000000550000000
e755c57e8e7717e8b755c57b2e0040e2e200f02e0000000000000077aa90070000889aaa77aaa900005588999988225005555259528825500550000000000000
075cc5700e7117e0075cc5700e0440e0020ff020000000000000700000000000000899aaaaa99800005528888222250000552525825255000555550000005550
00e55e000087780000b55b000020020000e00e000000000000000000700000000000899aa9988000000055522250550000055555555550000055555000055550
0e0ee0e0080880800b0bb0b0020220200e0ee0e00000000000000000000000000000000988000000000050555005500000005550500500000005500000005500
0e0000e0080000800b0000b0020000200e0000e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000034050310502d05027050220501d05019050130500f0500c0500b050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000000000296502b6502c6402c6402c6302963027630236201e62016620106100c61009610086000760006600076000560005600000000000000000000000000000000000000000000000000000000000000
00010000326500e6502965031640156400c6300763005620036200364000620006000060000620006200060000650006000065000600006500060001650006000060000600006000060000600006000060000600
00010000156202c64028600146003a600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
