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
		over=update_over
	}
	update[state]()
end

function _draw()
	local draw={
		start=draw_start,
		game=draw_game,
		over=draw_over
	}
	draw[state]()
	player:draw()
	--debug time
	print(flr(time()),0,120,7)
	if (bullets) print(#bullets,0,112,8)
	if (enemies) print(#enemies,0,104,11)
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
	p_s=2
	f_s=5
	x,y=60,60
	spd=2
	health=1
	lives=3
	--bullets
	bullets={}
	m_flsh=0
	--enemies
	enemies={}
	add(enemies,enemy:new{x=40,y=40})
	add(enemies,enemy:new{x=80,y=20})
	--background
	bg_update,bg_draw=bgrnd()
end

function update_game()
	--⬆️⬇️⬅️➡️
	p_s=2
	dx,dy=0,0
	--btn input
	if btn(⬅️) then
		dx,p_s=-spd,1
	end
	if btn(➡️) then
		dx,p_s=spd,3
	end
	if btn(⬆️) then dy=-spd end
	if btn(⬇️) then dy=spd end
	if btnp(❎) then
		--spawn new bullet
		b=bullet:new{x=x,y=y-6,dy=-2}
		add(bullets,b)
		m_flsh=4
		sfx(0)
	end
	--move player
	x=mid(0,x+dx,120)
	y=mid(0,y+dy,120)
	--move bullets
	for i=#bullets,1,-1 do
		local b=bullets[i]
		b:update()
		if b.y>128 or b.y<-8 then
			deli(bullets,i)
		end
	end
	--move enemies
	for e in all(enemies) do
		e:update()
		if (e.y>128) del(enemies,e)
	end
	--anim firing effect
	if m_flsh>0 then m_flsh-=1 end
	--anim flame
	f_s+=1
	if f_s>9 then f_s=5 end
	--anim background
	bg_update()
end

function draw_game()
	cls(0)
	--background
	bg_draw()
	--player
	spr(p_s,x,y)
	spr(f_s,x,y+8)
	--enemies
	for _,e in ipairs(enemies) do
		e:draw()
	end
	--bullets
	for _,b in ipairs(bullets) do
		b:draw()
	end
	if m_flsh>0 then
		circfill(x+4,y,m_flsh,7)
	end
	--ui
	print("score: "..score,40,0,12)
	for i=1,lives do
		heart=health>=i and 11 or 12
		spr(heart,(i-1)*8,1)
	end
end

--base game obj class
gmobj={x=0,y=0,sp=0}
function gmobj:new(o)
	o=o or {}
	setmetatable(o,self)
	self.__index=self
	return o
end
function gmobj:draw()
	spr(self.sp,self.x,self.y)
end

--player class
player=gmobj:new{sp=2,fsp=5}
function player:draw()
	--call parent draw
	gmobj.draw(self)
	--flame spr
	spr(self.fsp,self.x,self.y+8)
end
function player:update()
end

--bullet class
bullet=gmobj:new{sp=35,dx=0,dy=0}
function bullet:update()
	self.x+=self.dx
	self.y+=self.dy
end

--enemy class
enemy=gmobj:new{sp=37}
function enemy:update()
	self.y+=1
	--anim
	self.sp+=0.4
	if (self.sp>=41) self.sp=37
end

--starfield
function bgrnd()
	local _update,_draw
	--init
	local stars={}
	for i=1,100 do
		stars[i]={
			flr(rnd(128)), --x
			flr(rnd(128)), --y
			1+flr(rnd(3)) --spd
		}
	end
	_update=function()
		for i=1,#stars do
			local y,v=unpack(stars[i],2)
			y=(y+v)%128
			stars[i][2]=y
		end
	end
	_draw=function()
		for i=1,#stars do
			local x,y,v=unpack(stars[i])
			local c=7
			if v==1 then c=1 end
			if v==2 then c=13 end
			pset(x,y,c)
		end
	end
	return _update,_draw
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
00000000000220000002200000022000000000000000000000000000000000000000000000000000000000000880880008808800088008800880088000000000
0000000000288200002882000028820000000000000aa000000aa000000aa00000a77a00000aa000000000008888888080080080888888888008800800000000
007007000028820000288200002882000000000000a77a000007700000a77a0009aaaa9000a77a00000000008888888080000080888888888000000800000000
0007700002888e2002e88e2002e8882000000000009aa900000aa000009aa90000999900009aa900000000000888880008000800888888888000000800000000
00077000027c8e202e87c8e202e8c7200000000000099000000aa000000990000000000000099000000000000088800000808000088888800800008000000000
00700700021188202881188202881120000000000000000000099000000000000000000000000000000000000008000000080000008888000080080000000000
00000000025d820028d55d820028d520000000000000000000000000000000000000000000000000000000000000000000000000000880000008800000000000
00000000029d200002d99d200002d920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000077000000770000007700000c77c0000077000000000000000000000000000000000000000000000000000
00099000000dd00000022000000330000001100000c77c000007700000c77c000cccccc000c77c00000000000000000000000000000000000000000000000000
0097a90000d7cd00002782000037b3000017c10000cccc00000cc00000cccc0000cccc0000cccc00000000000000000000000000000000000000000000000000
009aa90000dccd0000288200003bb300001cc100000cc000000cc000000cc00000000000000cc000000000000000000000000000000000000000000000000000
00099000000dd00000022000000330000001100000000000000cc000000000000000000000000000000000000000000000000000000000000000000000000000
00090000000d00000002000000030000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999900000000000000000000000000000000000330033003300330033003300330033000000000033003300000000000000000000000000000000000000000
09aaaa900099990000999000000000000000000033b33b3333b33b3333b33b3333b33b330000000033b33b330000000000000000000000000000000000000000
9aa77aa909aaaa9009aaa90000099000000000003bbbbbb33bbbbbb33bbbbbb33bbbbbb3000000003bbbbbb30000000000000000000000000000000000000000
9a7777a909a77a9009a7a900009a7900000000003b7717b33b7717b33b7717b33b7717b3000000003bb33bb30000000000000000000000000000000000000000
9a7777a909a77a9009aaa900009aa900000000000b7117b00b7117b00b7117b00b7117b0000000000b2222b00000000000000000000000000000000000000000
9aa77aa909aaaa900099900000099000000000000037730000377300003773000037730000000000003223000000000000000000000000000000000000000000
09aaaa90009999000099000000000000000000000303303003033030030330300303303000000000030330300000000000000000000000000000000000000000
00999900000000000009000000000000000000000300003030000003030000300030030000000000030000300000000000000000000000000000000000000000
00777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000070007777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000007070000700007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000007070000700070070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000007070000700070070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000007070000700007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000070007777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000034050310502d05027050220501d05019050130500f0500c0500b050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
