pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function _init()
	--player
	p_s=2
	f_s=5
	x,y=60,60
	spd=2
	b={}
	m_flsh=0
	score=0
	health=1
	lives=3
	--background
	bg_update,bg_draw=bgrnd()
end

function _update()
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
		b_x,b_y,m_flsh=x,y-6,3
		sfx(0)
	end
	--move player
	x=mid(0,x+dx,120)
	y=mid(0,y+dy,120)
	--move projectile
	if b_y then b_y-=1 end
	if m_flsh>0 then m_flsh-=1 end
	--anim flame
	f_s+=1
	if f_s>9 then f_s=5 end
	--anim background
	bg_update()
end

function _draw()
	cls(0)
	--background
	bg_draw()
	--player
	spr(p_s,x,y)
	spr(f_s,x,y+8)
	if b_y then spr(16,b_x,b_y) end
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
000000000000000000000000000000000000000000099000000990000009900000a99a00000aa000000aa000000aa00000aaaa00000000000000000000000000
00099000000dd00000022000000330000001100000a99a000009900000a99a000aaaaaa000aaaa00000aa00000aaaa0009aaaa90000000000000000000000000
0097a90000d7cd00002782000037b3000017c10000aaaa00000aa00000aaaa0000aaaa00009aa900000aa000009aa90000999900000000000000000000000000
009aa90000dccd0000288200003bb300001cc100000aa000000aa000000aa0000000000000099000000aa0000009900000000000000000000000000000000000
00099000000dd00000022000000330000001100000000000000aa000000000000000000000000000000990000000000000000000000000000000000000000000
00090000000d00000002000000030000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700007000777700000000000000000000000000000aa000000aa000000aa000009aa90000099000000990000009900000999900000000000000000000000000
7000000707000070000770000000000000000000009aa900000aa000009aa900099999900099990000099000009999000a9999a0000000000000000000000000
70000007070000700070070000000000000000000099990000099000009999000099990000a99a000009900000a99a0000aaaa00000000000000000000000000
700000070700007000700700000000000000000000099000000990000009900000000000000aa00000099000000aa00000000000000000000000000000000000
70000007070000700007700000000000000000000000000000099000000000000000000000000000000aa0000000000000000000000000000000000000000000
07000070007777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000077000000770000007700000c77c0000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000c77c000007700000c77c000cccccc000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000cccc00000cc00000cccc0000cccc0000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000cc000000cc000000cc0000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000cc000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000034050310502d05027050220501d05019050130500f0500c0500b050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
