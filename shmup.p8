pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--main
do
	--state transition vars
	local state,target_state
	local tt=0 --time til trans
	--true if state transition
	isstatetrans=function()
		return not not target_state
	end

	function _init()
		--load start screen
		startscrn()
--		setbtnpdelay()
		--debug
--		frame=0
	end

	function _update()
		local update={
			start=update_start,
			game=update_game,
			over=update_over
		}
		--transition states
		if target_state then
			tt-=1
			if tt<=0 then
				--set state to target state
				state,target_state=target_state,nil
			end
		end
		update[state]()
		--debug
--		frame+=1
	end

	function _draw()
		local draw={
			start=draw_start,
			game=draw_game,
			over=draw_over,
		}
		draw[state]()
		--debug layout/ui
--		line(0,0,0,127,5)
--		line(64,0,64,127,5)
--		line(127,0,127,127,5)
--		print("❎",0,0,2) --7x5 px
--		print("ww",0,6,2) --7x5 px
--		print("♥",0,12,2) --7x5 px
		--debug time
		print(flr(time()),0,120,7)
		print(flr(time()*30),16,120,7)
		--debug game objs and fx
		if (bullets) print(#bullets,0,112,8)
		if (enemies) print(#enemies,0,104,11)
		if (pfx) print(#pfx,0,96,9)
		--debug waves
--		if (wvt) print(wvt,120,104,11)
		--debug state/transitions
--		print(state,0,80,12)
--		print(target_state,0,88,12)
--		if (target_state) print(tt,20,88,12)
		--debug music playing
--		print(stat(57),30,120,13)
	end

	function setstate(target,delay)
		--block if state is trans
		if (target_state) return
		local delay=delay or 0
		--if no delay,set state
		if delay==0 then
			state=target
			return
		end
		tt=delay
		target_state=target
	end
end

--update init btnp delay to val
-- or disables if none provided
function setbtnpdelay(delay)
	--default init btnp delay: 15
	--default rep btnp delay: 4
	local delay=delay or 255
	poke(0x5f5c,delay)
end

--return fn that alternates
-- between two color values
function blink(c1,c2)
	local c1,c2=c1,c2
	return function()
		local n=ceil(sin(time()))
		return n==1 and c1 or c2
	end
end
-->8
--start state
function startscrn()
	--set state, play music
	setstate("start")
	music(7)
end

function update_start()
	if btnp(❎) then
		--start game
		startgame()
	end
end

do
	local blnk=blink(6,7)
	function draw_start()
		cls(1)
		print("shmup game v0.5",34,40,
			12)
		print("press ❎ to start",30,
			80,blnk())
	end
end
-->8
--game state
function startgame()
	--state
	setstate("game")
	--set init btnp delay
	setbtnpdelay(4)
	--play music
	music(0)
	--set score,wave
	score=0
	waves=init_waves()
	wave=1
	wvt=60 --wave timer
	--player
	p=player:new{x=60,y=60}
	--bullets
	bullets={}
	m_flsh=0
	--enemies
	enemies={}
	atkfreq=waves[wave].atkfreq
	--fx
--	effects={} --sprite effects
	pfx={} --particles
	--background
	bg=bgrnd()
end

function update_game()
	--spawn new wave
	if wvt>0 then
		wvt-=1
		if (wvt==0) spawnwave(wave)
	end
	--check if wave defeated
	if #enemies==0 and wvt==0 then
		nextwave()
	end
	--move player
	if (p.♥>0) p:update()
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
		if e.y>128 or
		   e.x<-8 or e.x>128 then
			if (e.act==e.atk) del(enemies,e)
		end
	end
	--select enemy to attack
	local fr=ceil(time()*30) --idk why ceil works here but flr doesn't
	if #enemies>0 and fr%atkfreq==0 then
		local e=selectenemy()
		if e and e.act==e.hold then
			e.wait=30
			e.shke=30
			e.act=e.atk
			--debug
--			e.frame=fr
		end
	end
	--anim fx
	for ptc in all(pfx) do
		ptc:update()
	end
	--anim background
	bg.update()
	--check if game over
	if p.♥<=0 and
	   not isstatetrans() then
		gameover()
	end
end

function draw_game()
	cls(0)
	--background
	bg.draw()
	--player
	if (p.♥>0) p:draw()
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
	--ui: score,health
	print("score: "..score,40,0,12)
	for i=1,p.m♥ do
		sp=p.♥>=i and 11 or 12
		spr(sp,(i-1)*8,1)
	end
	--ui: wave
	if wvt>0 then
		displaywavetxt()
	end
end

--next wave
function nextwave()
	--do nothing if state trans
	if (isstatetrans()) return
	--get next wave if more waves
	if wave<#waves then
		--inc wave count
		wave+=1
		--update enemy atkfreq
		atkfreq=waves[wave].atkfreq
		wvt=60
		--play wave music
		music(3)
		return
	end
	--if no more waves, gameover
	gameover(true)
end

--spawn wave
function spawnwave(wave)
	local y=-8
	local wave=waves[wave]
	for i=1,#wave do
		local row=wave[i]
		spawnenemies(row,#wave-i)
	end
end

--incoming wave text
do
	local blnk=blink(8,6)
	function displaywavetxt()
		print("warning",51,32,blnk())
		print("wave incoming",39,40,
			blnk())
		print("wave "..wave,53,90,6)
	end
end

--spawn a row of enemies
-- this is a math nightmare
-- and prob should be fixed
function spawnenemies(row,i)
	local x,y=6,-10*(i+1)
	local etyp={green,spinner,
		jelly,red,bb}
	for i=1,#row do
		local et,e,x0=etyp[row[i]]
		if (not et) goto nxt
		x0=64+24*(i-(#row/2)-0.5)
		e=spawnenemy(et,x0,y)
		--perhaps vectors?
		e.tx,e.ty=x,y+56
		--this could use trig if i felt extra
--		e.wait=i*3
		e.wait=abs(i-(#row/2)-0.5)*3
--		e.wait=(5-abs(i-(#row/2)-0.5))*3
		::nxt::
		x+=(e and e.spx*8 or 8)+4
	end
end

function spawnenemy(typ,x,y)
	local e=typ:new{
		x=x or rnd(120),
		y=y or -8,
	}
	add(enemies,e)
	return e
end

--select available enemy to atk
-- bias towards front
--fn might be doing too much...
function selectenemy()
--	local e=rnd(enemies)
	local r=#enemies%10
	local n=r==0 and 10 or r
	local i=#enemies-n+1
	--get vanguard of formation
	local tbl={
		unpack(enemies,i,#enemies)
	}
	--filter out busy enemies
	for e in all(tbl) do
		if (e.act!=e.hold) del(tbl,e)
	end
	if (#tbl>0) return rnd(tbl)
	--select from behind vanguard
	i-=1+flr(rnd(10))
	if i>0 then
		local e=enemies[i]
		if (e.act==e.hold) return e
	end
	return nil
end

--spawn explosion pfx
function spawnexplosion(x,y,c)
	local c=c or "red"
	--central flash ptc
	add(pfx,expl:new{
		x=x,
		y=y,
		r=8,
		mt=0,
		explc=c
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
	add(pfx,skwv:new{
		x=x,
		y=y,
		r=9,
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

--spawn bullet impact pfx
function spawnimpact(x,y)
	--shockwave
	add(pfx,skwv:new{
		x=x,
		y=y,
		r=3,
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
do
	local drawtxt,drawwin,drawlose
	function gameover(win)
		--set state
		setstate("over",30)
		drawtxt=win and drawwin
			or drawlose
--		setstate("over")
		--play music
		music(win and 0 or 6)
		--set btnp delay
		setbtnpdelay()
	end

	function update_over()
		--anim any remaining ptc
		for ptc in all(pfx) do
			ptc:update()
		end
		if btnp(❎) then
			--start game
	--		startgame()
			startscrn()
		end
	end

	local blnk=blink(6,7)
	function draw_over()
		draw_game() --draw game in bg
		drawtxt()
		print("press ❎ to restart",
			25,80,blnk())
	end

	--drawtxt
	drawwin=function()
		print("congratulations",35,
			40,12)
	end
	drawlose=function()
		print("game over",47,40,8)
	end
end
-->8
--classes: gmobj & particles

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
--should this be on this class?
function gmobj:move(dx,dy)
	--todo
	local dx=dx or 0
	local dy=dy or 0
	self.x+=dx
	self.y+=dy
end
--collisions (square)
function gmobj:col(obj)
	local sw,sh=(8*self.spx)-1,(8*self.spy)-1
	local ow,oh=(8*obj.spx)-1,(8*obj.spy)-1
	local sx1,ox1=self.x,obj.x
	local sx2,ox2=sx1+sw,ox1+ow
	local sy1,oy1=self.y,obj.y
	local sy2,oy2=sy1+sh,oy1+oh
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

--particle class
ptc=class:new{
	x=0, --x
	y=0, --y
	r=0, --ptc radius
	c=7, --default color
	t=0, --ptc age
	mt=30, --ptc max age
}
function ptc:update()
	--update ptc age
	self.t+=1
	--if ptc too old, delete
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
	dy=0 --y velocity
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
do
	local lt={
		red={10,9,8,2,5},
		blue={13,12,1,2,5},
		green={13,11,3,2,5},
		purple={14,13,14,2,5},
	}
	function expl:draw()
		local ct=lt[self.explc]
		local age=self.t/self.mt
		if (age>0.2) self.c=ct[1]
		if (age>0.3) self.c=ct[2]
		if (age>0.5) self.c=ct[3]
		if (age>0.6) self.c=ct[4]
		if (age>0.8) self.c=ct[5]
		--call parent draw
		ptc.draw(self)
	end
end
function expl:expire()
	--if ptc too old, shrink/fade
	self.r-=0.5
	if (self.r<0) del(pfx,self)
end

--shockwave ptc
skwv=ptc:new{
	c=6, --default color
	dr=1, --change in radius
}
function skwv:update()
	--incr/dcrm radius
	self.r+=self.dr
	--call parent update
	ptc.update(self)
end
function skwv:draw()
	circ(self.x,self.y,
		self.r,self.c)
end
-->8
--classes: player,projectiles

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
	local s=self.s
	local dx,dy=0,0
	--btn input
	--⬆️⬇️⬅️➡️❎
	if btn(⬅️) then
		dx,sp=-self.s,1
	end
	if btn(➡️) then
		dx,sp=self.s,3
	end
	if (btn(⬆️)) dy=-self.s
	if (btn(⬇️)) dy=self.s
--	if btn(❎) and self.fc<=0 then
	if btnp(❎) then
		--spawn new bullet
		add(bullets,bullet:new{
			x=self.x,
			y=self.y-6,
			dy=-2
		})
		--reset fire cooldown
		self.fc=self.fr
		--set muzzle flash
		self.mflsh=4
		--play firing sfx
		sfx(0)
	end
	--move/update player
	self:move(dx,dy)
	self.x=mid(0,self.x,120)
	self.y=mid(0,self.y,120)
	self.sp=sp
	--decrm iframes
	if (self.invul>0) self.invul-=1
	--decrm fire cooldown
	if (self.fc>0) self.fc-=1
	--anim muzzle flash
	if (self.mflsh>0) self.mflsh-=1
	--anim flame
	self.fsp+=1
	if (self.fsp>9)	self.fsp=5
end
function player:draw()
	local x,y=self.x,self.y
	--blinking
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
	self:move(self.dx,self.dy)
	for i=#enemies,1,-1 do
		local e=enemies[i]
		if self:col(e) then
			--todo: enemy bullets
			e.♥-=1
			e.flsh=4
			spawnimpact(self.x+4,
				self.y+4)
			sfx(3)
			del(bullets,self)
			if e.♥<=0 then
				--create explosion fx
				spawnexplosion(e.x+4,e.y+4,
					"green")
				--delete the dead enemy
				deli(enemies,i)
				--score,sfx feedback
				sfx(2)
				score+=10
				--spawn new enemy
--				spawnenemy()
			end
		end
	end
end
-->8
--classes: enemies

--enemy class
enemy=gmobj:new{
	sp=32, --enemy sprite
	♥=3, --enemy health
	flsh=0,--dmg flash
	act=nil, --current action: adv,hold,atk
	tx=0, --target x position
	ty=0, --target y position
	wait=0, --wait before active
	shke=0, --shake
	s=1, --default speed
}
function enemy:update()
	if (self.shke>0) self.shke-=1
	if self.wait>0 then
		self.wait-=1
		return
	end
	if (not self.act) self.act=self.adv
	self:act()
--	self.y+=1
	--check enemy/player collision
	if self:col(p) and
	   p.invul==0 then
		--spawn explosion fx,sfx
		spawnexplosion(p.x+4,p.y+4)
		sfx(1)
		--todo: this seems a little dodgy
		p.♥-=1
		p.invul=60
	end
	--dcrm dmg flash
	if (self.flsh>0) self.flsh-=1
	--anim
	self:anim()
end
function enemy:draw()
	--manipulate palette to flash
	-- when taking damage
	if (self.flsh>0) self:flash()
	--cpy to prevent mutation
	local obj={
		x=self.x,
		y=self.y,
		sp=self.sp,
		spx=self.spx,
		spy=self.spy
	}
	if (self.shke>0) then
		obj.x+=sin(time()*30/3)
	end
	--call parent draw fn
	gmobj.draw(obj)
	pal() --reset palette
	--debug
--	print(self.y,self.x,self.y+8,8)
--	if (self.wait) print(self.wait,self.x,self.y+8,8)
--	local atk=(self.act==self.atk)
--	local adv=(self.act==self.adv)
--	local hold=(self.act==self.hold)
--	print(hold and "y" or "n",self.x,self.y+8,8)
--	if (self.frame) print(self.frame,self.x,self.y+8,8)
--	if (self.act==self.atk) print(self.dx,self.x,self.y+8,8)
end
function enemy:flash()
	--flash white on dmg
	for i=1,15 do
		pal(i,7)
	end
end
--update the enemy sprite
function enemy:anim()
	self.sp+=0.4
	if (self.sp>=36) self.sp=32
end
--enemy behavior: advance
function enemy:adv()
	local dx=(self.tx-self.x)/8
	local dy=(self.ty-self.y)/8
	if abs(self.y-self.ty)<0.5 then
		self.y=self.ty
		self.x=self.tx
		self.act=self.hold
	end
	self:move(dx,dy)
end
function enemy:hold()
	--do something?
end
function enemy:atk()
	--attack
	self:move(0,self.s)
end

--default green enemy
green=enemy:new{
	typ="green",
}
--function green:flash()
--	--kinda color invert
--	pal(1,8) --d blue to brwn
--	pal(3,2) --d grn to purple
--	pal(7,0) --white to blck
--	pal(11,14) --l grn to pink
--end
function green:atk()
	local d,dx=p.x-self.x,0
	if self.y<p.y then
		dx=sgn(d)*min(abs(d),20)/30
	end
	dx+=sin(time()*30/20)
	local dy=1
	self:move(dx,dy)
	self.x=mid(0,self.x,120)
end

--spinner enemy
spinner=enemy:new{
	typ="spinner",
	sp=120, --120-123
	dx=0,
--	♥=5,
}
function spinner:anim()
	self.sp+=0.4
	if (self.sp>=124) self.sp=120
end
function spinner:atk()
	local dy=0
	if self.dx==0 then
		if p.y<=self.y then
			--mv horizontally
			self.dx=sgn(p.x-self.x)*2
		else
			--continue vertically
			dy=1
		end
	end
	self:move(self.dx,dy)
end

--jellyfish enemy
jelly=enemy:new{
	typ="jelly",
	sp=101, --101-104
	♥=2,
}
function jelly:anim()
	self.sp+=0.4
	if (self.sp>=105) self.sp=101
end

--red
red=enemy:new{
	typ="red",
	sp=84, --84-85
	♥=2,
}
function red:anim()
	self.sp+=0.2
	if (self.sp>=86) self.sp=84
end
function red:atk()
	local dx=sin(time()*30/20)
	local dy=2.5
	self:move(dx,dy)
	self.x=mid(0,self.x,120)
end

--todo: change name
--golden bug?
bb=enemy:new{
	sp=144, --144,146
	♥=10,
	spx=2, --sprite width
	spy=2, --sprite height
	s=0.5,
}
do
	local i=1
	local fr={144,146}
	function bb:anim()
		i+=0.2
		if (flr(i)>#fr) i=1
		self.sp=fr[flr(i)]
	end
end
-->8
--waves
function init_waves()
	return {
		{
			--wave 1
			{1,1,1,1,1,1,1,1,1,1},
			{1,1,1,1,1,1,1,1,1,1},
			{1,1,1,1,1,1,1,1,1,1},
			{1,1,1,1,1,1,1,1,1,1},
			atkfreq=60
		},
		{
			--wave 2
			{0,0,1,0,1,1,0,1,0,0},
			{2,1,0,1,4,4,1,0,1,3},
			{3,1,0,1,4,4,1,0,1,2},
			{0,0,1,0,1,1,0,1,0,0},
			atkfreq=50
		},
		{
			--wave 3
			{1,1,1,1,1,1,1,1,1,1},
			{1,1,1,1,1,1,1,1,1,1},
			{1,1,1,1,1,1,1,1,1,1},
			{1,1,1,1,1,1,1,1,1,1},
			atkfreq=40
		},
		{
			--wave 4
			{0,0,0,0,0,0,0,0,0,0},
			{0,0,0,0,5,0,0,0,0,0},
			{0,0,0,0,0,0,0,0,0,0},
			{0,0,0,0,0,0,0,0,0,0},
			atkfreq=30
		},
	}
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
00000000000000000000000000070000020000200200002002000020020000205555555555555555555555555555555502222220022222200222222002222220
000bb000000bb0000007700000077000022ff220022ff220022ff220022ff2200578875005788750d562465d0578875022e66e2222e66e2222e66e2222e66e22
0066660000666600606666066066660602ffff2002ffff2002ffff2002ffff2005624650d562465d05177150d562465d27761772277617722776177227716772
0566665065666656b566665bb566665b0077d7000077d700007d77000077d700d517715d051771500566865005177150261aa172216aa162261aa612261aa162
65637656b563765b056376500563765008577580085775800857758008577580056686500566865005d24d50056686502ee99ee22ee99ee22ee99ee22ee99ee2
b063360b006336000063360000633600080550800805508008055080080550805d5245d505d24d500505505005d24d5022299222229999222229922222299222
006336000063360000633600006336000c0000c007c007c007c00c7007c007c05005500505055050050000500505505020999902020000202099990202999920
0006600000066000000660000006600000c7c7000007c0000077cc000007c000dd0000dd0dd00dd005dddd500dd00dd022000022022002202200002202200220
00ff880000ff88000000000000000000200000020200002000000000000000003350053303500530000000000000000000000000000000000000000000000000
0888888008888880000000000000000022000022220000220000000000000000330dd033030dd030005005000350053000000000000000000000000000000000
06555560076665500000000000000000222222222222222200000000000000003b8dd8b3338dd833030dd030030dd03003e33e300e33e330033e333003e333e0
6566665576555565000000000000000028222282282222820000000000000000032dd2300b2dd2b0038dd830338dd833e33e33e333e33e333e33e333e33e333e
57655576555776550000000000000000288888822888888200000000000000003b3553b33b3553b3033dd3300b2dd2b033300333333003333330033333300333
0655766005765550000000000000000028788782287887820000000000000000333dd333333dd33303b55b303b3553b3e3e3333bbe33333ebe3e333be3e3333b
0057650000655700000000000000000028888882080000800000000000000000330550330305503003bddb30333dd3334bbbbeb44bbbebb44bbbbeb44bbbebe4
00065000000570000000000000000000080000800000000000000000000000000000000000000000003553000305503004444440044444400444444004444440
0066600000666000006660000068600000888000002222000022220000222200002222000cccccc00c0000c00000000000000000000000000000000000000000
055556000555560005585600058886000882880002eeee2002eeee2002eeee2002eeee20c0c0c0ccc000000c0000000000000000000000000000000000000000
55555560555855605588856058828860882228802ee77ee22ee77ee22eeeeee22ee77ee2c022220ccc2c2c0cc022220c00222200000000000000000000000000
55555550558885505882885088222880822222802ee77ee22ee77ee22ee77ee22ee77ee2cc2cac0cc02aa20cc0cac2ccc02aa20c000000000000000000000000
15555550155855501588855018828850882228802eeeeee22eeeeee22eeeeee22eeeeee2c02aa20cc0cac2ccc02aa20ccc2cac0c000000000000000000000000
01555500015555000158550001888500088288002222222222222222222222222222222200222200c022220ccc2c2c0cc022220c000000000000000000000000
0011100000111000001110000018100000888000202020200202020220202020020202020000000000000000c000000cc0c0c0cc000000000000000000000000
00000000000000000000000000000000000000002000200002000200002000200002000200000000000000000c0000c00cccccc0000000000000000000000000
000880000009900000089000000890000000000001111110011111100000000000d89d0000189100001891000019810000005500000050000005000000550000
706666050766665000676600006656000000000001cccc1001cccc10000000000d5115d000d515000011110000515d0000055000000550000005500000055000
1661c6610161661000666600001666000000000001cccc1001cccc1000000000d51aa15d0151a11000155100011a151005555550055555500555555005555550
7066660507666650006766000066560000000000017cc710017cc71000000000d51aa15d0d51a15000d55d00051a15d022222222222222222222222222222222
0076650000766500007665000076650000000000017cc710017cc710000000006d5005d6065005d0006dd6000d50056026060602260606022666666226060602
000750000007500000075000000750000000000001111110011111100000000066d00d60006d0d600066660006d0d60020000002206060622222222020606062
00075000000750000007500000075000000000001100001101100110000000000760067000660600000660000060660020606062222222200000000022222220
00060000000600000006000000060000000000001100001101100110000000000070070000070700000770000070700022222220000000000000000000000000
0007033000700000007d330003330333000000000022220000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d3300000d33000028833003bb3bb3000000000888882000000000000000000000000000000000000000000000000000000000000000000000000000000000
0778827000288330071ffd1000884200002882000888882000288200000000000000000000000000000000000000000000000000000000000000000000000000
071ffd10077ffd700778827008ee8e800333e33308ee8e80088ee883000000000000000000000000000000000000000000000000000000000000000000000000
00288200071882100028820008ee8e8003bb4bb308ee8e8008eeee83000000000000000000000000000000000000000000000000000000000000000000000000
07d882d00028820007d882d00888882008eeee800088420008eeee80000000000000000000000000000000000000000000000000000000000000000000000000
0028820007d882d000dffd0008888820088ee88003bb3bb3088ee880000000000000000000000000000000000000000000000000000000000000000000000000
00dffd0000dffd000000000000222200002882000333033300288200000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000149aa94100000000012222100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00019777aa921000000029aaaa920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d09a77a949920d00d0497777aa920d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0619aaa9422441600619a77944294160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07149a922249417006149a9442244160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07d249aaa9942d7006d249aa99442d60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
067d22444422d760077d22244222d770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d666224422666d00d776249942677d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
066d51499415d66001d1529749251d10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0041519749151400066151944a151660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00a001944a100a0000400149a4100400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000049a400090000a0000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000034050310502d05027050220501d05019050130500f0500c0500b050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000000000296502b6502c6402c6402c6302963027630236201e62016620106100c61009610086000760006600076000560005600000000000000000000000000000000000000000000000000000000000000
00010000326500e6502965031640156400c6300763005620036200364000620006000060000620006200060000650006000065000600006500060001650006000060000600006000060000600006000060000600
00010000156202c64028600146003a600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
00060000010501605019050160501905001050160501905016050190601b0611b0611b061290001d000170002600001050160501905016050190500105016050190501b0611b0611b0501b0501b0401b0301b025
00060000205401d540205401d540205401d540205401d54022540225502255022550225500000000000000000000025534225302553022530255301d530255302253019531275322753027530275322753027530
000600001972020720227201b730207301973020740227401b74020740227402274022740000000000000000000001672020720257201b730257301973025740227401b740277402274027740277402774027740
001000001f5501f5501b5501d5501d550205501f5501f5501b5501a5501b5501d5501f5501f5501b5501d5501d550205501f5501b5501a5501b5501d5501f5502755027550255502355023550225502055020550
001000000f5500f5500a5500f5501b530165501b5501b550165500f5500f5500a5500f5500f5500a550055500a5500e5500f5500f550165501b5501b550165501755017550125500f5500f550125501055010550
001000001e5501c5501c550175501e5501b550205501d550225501e55023550205501c55026550265500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000017550145501455010550175500b550195500d5501b5500f5501c550105500455016550165500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
080d00001b0301b0001b0201d0201e0302003020040200401b7001d700227001a7001b7001b700227001b7001b7001d7001b7001b7001b7001d700227001a7001b7001b700167001b7001b7001b7001c7001c700
040d00001f5301f0001f52021520225302453024530245301e7001e70020700237002070022700227001670000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d000022030220002203024030250302703027030270301b0001b0001b0001d0001e00020000200002000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4c1000002b0202b0202b0202b0202b0202b0202b0202b0202b020290202b0202c0202b0202b0202b0202602026020260202702027020270202b0202b0202b0202a0302a0302a0302703027030270302003020030
4c1000002003028030280302c0302a0302a0302a0302703027030270302c0302a030290302e0302e0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f00001e050000001e0501d0501b0501a0601a0621a062000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
040f00001b540070001b5401a54018540175501755217562075000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000
010c0000290502c0002a00029055290552a000270502900024000290002705024000240002400027050240002a05024000240002a0552a055240002905024000240002400029050240002a000290002405026200
510c00001431519315203251432519315203151432519325203151431519325203251431519315203251432519315203151432519325203151431519325203251431519315203251432519315203151432518325
010c00000175001750017500175001750017500175001750017500175001750017500175001750017500175001750017500175001750017500175001750017500175001750017500175001750017500175001750
010c0000195502c5002a50019555195552a500185502950024500295001855024500245002450018550245001b55024500245001b5551b555245001955024500245002450019550245002a500295001855026500
010c0000290502c0002a00029055290552a000270502900024000290002000024000240352504527050240002a050240002f0052d0552c0552400029050240002400024000240002400024030250422905026200
010c0000195502c5002a50019555195552a500185502950024500295002050024500145351654518550245001b550245002f5051e5551d5552450019550245002450024500245002450014530165401955026500
010c00002c05024000240002a05529055240002e050240002400029000270502400024000240002e050240003005024000240002e0552d05524000300502400024000290002905024000270002a0002900028000
510c0000143151931520325143251931520315163251932516315183151932516325183151931516325183251b3151e315183251b3251e315183151b3251e325183151b3151d325183251b3151d315183251b325
010c00000175001750017500175001750017500175001750037500375003750037500375003750037500375006750067500675006750067500675006750067500575005750057500575005750057500575005750
010c00001d55024500245001b55519555245001e550245002450029500165502450024500245001e550245001e55024500245001d5551b555245001d5502450024500295001855024500275002a5002950028500
__music__
04 04050644
00 07084749
04 090a484a
04 0b0c0d44
00 0e084344
04 0f0a4344
04 10114e44
01 12131415
00 16131417
02 18191a1b

