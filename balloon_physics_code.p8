pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
--physics engine
--by alex mcculloch

--game loop

--[[
the game loop contains
all the primary script 
functions that are needed 
for the game to function
-]]

function _init()
--inits the worlds gravity
 set_grav(0.2)
 
--inits player acceleration
 set_player_accel(.1)

--creates all in game characters
 create_characters()
 
 --starts the game by initializing character positions
 start_game()
end

function _update()
--updates the physics engine
 update_physics()
 --handles game logic
 game_logic()
 --applies wind forces to gameobjects
 wind()
end

function _draw()
--clears the sceen if true
	clear_screen(true)
	
--draws all gameobjects in scene
	render_game_objects()
end

-->8
--physics

--[[
the physics script contains
all the neccessary physics
calculations to simulate
semi-realistic collisions
and handling those collisions.
inputs from the character 
controller are feeded into 
this script.
--]]


--move(c1,t)
--[[

--called when
move(c1,t) is called in the game loops update function

--importance
move is important for updating sprites or nodes positions after a sprites
rigid body's velocities are updated. 

--collisions
Since collision detection reasigns velocity. 
Move most be called after collision detection.
This will allow collisions to visually behave properly.  
If forgotten the position of the sprite that collided will have
undesirable results.

--user input


--]]
function move(c1,t)
	local g = 0
	 c1.pos.x = c1.pos.x + c1.lin_vel.x
	 c1.pos.y = c1.pos.y + c1.lin_vel.y
	 c1.lin_vel.x = c1.lin_vel.x * c1.fric
	 c1.lin_vel.y = c1.lin_vel.y * c1.fric
	 c1.lin_vel.y = c1.lin_vel.y + grav
end

--updates the game physics engine
function update_physics()
--updates player physics
 player_update_physics()
--updates all box and circle colliders physics
 chars_update_physics()
--updates all cloth nodes physics
 cloths_update_physics()
end

--updates the player's physics
function player_update_physics()
 player_update()
 player_coll()
end

--updates main player 
function player_update()
	move_player(player)
	move(player,"ball")
end

--handles player collisions
function player_coll()
	coll(player,ball1,"cc")
	coll(player,rect1,"cr")
	coll(ball1,rect1,"cr")
end
   

--updates all character physics
function chars_update_physics()
 chars_update()
end

--updates characters
function chars_update()
	move(ball1,"ball")
	
	ball1.lin_vel.x = ball1.lin_vel.x +  rnd(.2)-.1
	ball1.lin_vel.y = ball1.lin_vel.y +  rnd(.2)-.1
	move(rect1,nil)
	ball1.a_grav = col_rect_vs_circ(s_grav,ball1)
	b_bounce_walls(ball1)
	rect1.lin_vel.x = rect1.lin_vel.x + rnd(.2)-.1 -.1
	rect1.lin_vel.y = rect1.lin_vel.y + rnd(.2)-.1
   
end

--updates all cloths
function cloths_update_physics()
 cloth_update(cloth1,player)
 cloth_update(cloth2,ball1)
 
end

--update cloths
function cloth_update(cloths,fix)
 cloths[1].pos.x = fix.pos.x
 cloths[1].pos.y = fix.pos.y 
 cloths[1].lin_vel.x = fix.lin_vel.x 
 cloths[1].lin_vel.y = fix.lin_vel.y + fix.rad+1
 move(cloths[1],"cloth")
 for i =2, #cloths, 1 do
  cloths[i].pos.x = (cloths[i-1].pos.x + cloths[i].pos.x) *.5
  cloths[i].pos.y = (cloths[i-1].pos.y + cloths[i].pos.y) *.5 +1
 end
end

--inits the worlds gravity
function set_grav(g)
 grav = g
end

--inits the players acceleration
function set_player_accel(a)
 acel = a
end

function coll(g1,g2,t)
 if t == "cc" then
  if col_circ(g1,g2) then
  	handle_coll(g1,g2,t)
  	sfx(0)
 	end
 elseif t == "cr" then
	 if col_rect_vs_circ(g2,g1) then
	  handle_coll(g1,g2,t)
	  sfx(1)
	 end
 end
 
end




function handle_cc_coll(c1,c2,tx,ty)
 while(col_circ(c1,c2)) do
		c1.pos.x = c1.pos.x - tx
		c1.pos.y = c1.pos.y - ty
	end
end

function handle_cr_coll(g1,c1,r1,tx,ty)
 while(col_rect_vs_circ(r1,c1)) do
		g1.pos.x = g1.pos.x - tx
		g1.pos.y = g1.pos.y - ty
	end
end

function handle_coll(c1,c2,t)
 temp_x = 0
 temp_y = 0

 if c1.pos.x < c2.pos.x then
  temp_x = 1
 else 
  temp_x = -1
 end
 
 if c1.pos.y < c2.pos.y then
  temp_y = 1
 else
  temp_y = -1
 end
 
	if t == "cc" then
 	handle_cc_coll(c1,c2,temp_x,temp_y)
 elseif t == "cr" then
  handle_cr_coll(c1,c1,c2,temp_x,temp_y)
	end

 local c2_x = c1.lin_vel.x / c2.mass  + temp_x * c1.b * abs(c2.lin_vel.x)
	local c2_y = c1.lin_vel.y / c2.mass  + temp_y * c1.b * abs(c2.lin_vel.y)
	local c1_x = c2.lin_vel.x / c1.mass  - temp_x * c2.b * abs(c1.lin_vel.x)
	local c1_y = c2.lin_vel.y / c1.mass  - temp_y * c2.b * abs(c1.lin_vel.y)

	c1_x = c1_x + c1.lin_vel.x  
	c1_y = c1_y + c1.lin_vel.y
	c2_x = c2_x + c2.lin_vel.x
	c2_y = c2_y + c2.lin_vel.y
 c1.lin_vel.x = c1_x
 c1.lin_vel.y = c1_y 
 c2.lin_vel.x = c2_x 
 c2.lin_vel.y = c2_y 
 c1.lin_vel.x = c1.lin_vel.x * (c1.fric-.3)
 c1.lin_vel.y = c1.lin_vel.y * (c1.fric-.3)
 c2.lin_vel.x = c2.lin_vel.x * (c2.fric-.3)
 c2.lin_vel.y = c2.lin_vel.y * (c2.fric-.3)
end



function clamp_on_rect(p1,r1)

 local  center = p1.cent(p1)
 clamp = 
 {
 	x = mid(r1.pos.x,center.x,r1.pos.x+r1.s.x),
 	y = mid(r1.pos.y,center.y,r1.pos.y+r1.s.y)
 }
 
 return clamp
 
end

--hanldes collision for rect and circ 
function col_rect_vs_circ(r,c)
 
 clamped = clamp_on_rect(c ,r) 
 return col_circ_vs_point(c,clamped)
end

--handles 2 colliding circles
function col_circ(c1,c2)
 local rad = c1.rad + c2.rad
 
 dist = {}
 
 dist.x = c1.pos.x - c2.pos.x
 dist.y = c1.pos.y - c2.pos.y 	
 
 return length(dist) <= rad
end

function col_circ_vs_point(c1,p1)
 dist = sub_vec(c1.cent(c1),p1)
 return length(dist) <= c1.rad
end

function b_bounce_walls(p1)
  if p1.pos.x > 127 - p1.rad then
  p1.lin_vel.x = -1
 elseif p1.pos.y > 127 - p1.rad then
  p1.lin_vel.y = -1

 elseif p1.pos.x < 0 + p1.rad then
  p1.lin_vel.x = 1
 end
end

function bounce_all_walls(p1)
 if p1.pos.x > 127 - 20then
  p1.lin_vel.x = -1
 elseif p1.pos.y > 127  then
  p1.lin_vel.y = -1
 elseif p1.pos.y < 0 + 20 then
  p1.lin_vel.y = 1
 elseif p1.pos.x < 0  then
  p1.lin_vel.x = 1
 end
end
-->8
--character controller

--[[
the character controller
contains all the scripts
for handling character inputs
--]]

next_anim = 1

--handles user input for player
function move_player(p1)
 if btn(1) then
  
  p1.lin_vel.x = p1.lin_vel.x + acel
 elseif btn(0) then
		p1.lin_vel.x = p1.lin_vel.x + -acel
 end
 
 if btn(2) then
  p1.lin_vel.y = p1.lin_vel.y + -acel
 elseif btn(3) then
 	p1.lin_vel.y =  p1.lin_vel.y + acel
 end
 
  p1.lin_vel.y = p1.lin_vel.y + grav
 
 input_balloon()
 
 if p1.pos.x > 127 - p1.rad then
  p1.lin_vel.x = -1
 elseif p1.pos.y > 127 - p1.rad then
  p1.lin_vel.y = -1
 elseif p1.pos.y < 0 + p1.rad then
  p1.lin_vel.y = 1
 elseif p1.pos.x < 0 + p1.rad then
  p1.lin_vel.x = 1
 end
end


function input_balloon()
 local vx = player.lin_vel.x
 local vy = player.lin_vel.y
 local speed = sqrt(vx^2+vy^2)
 next_anim = next_anim - .6*speed 
 local random = rnd(5)

 if next_anim < 0 then
	 if vy < 0then
	  plr_anim = plr_anim -2
	  next_anim = 2
	 elseif  vy > 0 then
	  plr_anim = plr_anim + 2
	  next_anim = 2
	 end
	 
 end
 
 if plr_anim < 1 then 
 	plr_anim = 13 
 elseif plr_anim > 13then
  plr_anim = 1
 end 
 

  
end



-->8
--gameobjects

--[[
the gameobjects script
is for gameobject creation
and templates
--]]

--creates all characters in scene
function create_characters()
 player = create_ball(10,40,5,.98,3,2.2)
	ball1 = create_ball(20,90,4,.99,1,1.2)
 rect1 = create_rect(10,32,26,36,.92,5,1.9)
 s_grav = create_rect(10,20,30,40,0.97,5,1.9)
 create_cloths()

end

function create_cloths()
 cloth1 = create_cloth(14)
 cloth2 = create_cloth(14)

end

--creates nodes for cloth
function create_cloth(n,c)
 local cloth = {}

 for i=1, n, 1 do
  cloth[i] = create_node(i,40,.91)
 end
 
 return cloth
end

--creates an invisible node
function create_node(x1,y1,f)
 n ={}
 n.lin_vel = 
	{
		x = 0,
		y = 0
	}
	
	n.pos = 
	{
		x = x1,
		y = y1
	}
	
	n.fric = f
	
	return n
end

--creates a ball if called
function create_ball(x1,y1,r,f,m,bounce)
 local c = {}
 
 c.grav = -.03
 c.a_grav = false
 c.mass = m
 c.b = bounce
	c.ang_vel = 
	{
		x = 0,
		y = 0
	}
	c.lin_vel = 
	{
		x = 0,
		y = 0
	}
	
	c.pos = 
	{
		x = x1,
		y = y1
	}
	
	c.rad = r
	c.fric = f
	
	c.cent = function(self)
		local center = 
		{
			x = self.pos.x,
			y = self.pos.y			
		}
		
		return center
	end
	
	
	
	return c
end

function create_rect(x1,y1,sx,sy,f,m,bounce)
 local r = {}

 r.mass = m
	r.b = bounce
	r.ang_vel = 
	{
		x = 0,
		y = 0
	}
	r.lin_vel = 
	{
		x = 0,
		y = 0
	}
	
	r.pos = 
	{
		x = x1,
		y = y1
	}
	
	r.s =
	{
	 x = abs(sx-x1),
	 y = abs(sy-y1)
	}
	
	r.fric = f
	
	return r
end






-->8
--renderer

--[[
the renderer script handles
the drawing of the scene
--]]

plr_anim = 1



--renders all gameobjects
function render_game_objects()
 rectfill(0,0,127,16,bottom_banner_swap())
 rectfill(0,119,127,127,bottom_banner_swap())
 circfill(20,20,20,sun_swap())
 player_draw()
 chars_draw()
 cloth_draw(cloth1)
 cloth_draw(cloth2)
 draw_gui()
end
--draws main player in scene
function player_draw()

 



 circfill(player.pos.x,player.pos.y,player.rad,grav_color(ball1))
 spr(plr_anim,player.pos.x-8,player.pos.y-8,2,2)
 
end

function draw_gui()

 

 if flr(grav_counter) > 0 then
  grav_counter -= .1
  wind_x = 0
  wind_y = 0
    print("current level " ..level,5,120,6)  
  print("updraft inbound",48,5,6)
 else
  print("current level " ..level,5,120,7)
  print("updraft in progress",40,5,7 )
 end
 
 game_over()
end

--draws all characters in scene
function chars_draw()

 circfill(ball1.pos.x,ball1.pos.y,ball1.rad,win_color(ball1))
 spr(38,ball1.pos.x,ball1.pos.y)
 spr(spr_swap(),rect1.pos.x,rect1.pos.y-4,2,2)
 spr(34,s_grav.pos.x,s_grav.pos.y,3,3)
 rect(0,0,127,127,2)

 
end

function wind_draw()

end

function cloth_draw(cloth)
 for i =1, #cloth-1, 1 do
  line(cloth[i].pos.x, cloth[i].pos.y, cloth[i+1].pos.x,cloth[i+1].pos.y,rope_color(cloth))
 end
end

function win_color(ball)
 if grav == 0 then
  return 2
 else
  return 8
 end
 
 
end

function grav_color(ball)
 if grav == 0 then
  return 11
 else
  return 7
 end
 
 
end

function rope_color(ball)
 if grav == 0 then
  return 7
 else
  return 6
 end
 
 
end

function spr_swap()
 if grav == 0 then
  return 39
 else
  return 41
 end
end

function sun_swap()
 if grav == 0 then
  return 10
 else
  return 5
 end
end

function bottom_banner_swap()
 if grav == 0 then
  return 1
 else
  return 13
 end
end
function clear_screen(bool)
 if bool then
  if grav == 0 then
  cls(12)
 else
  cls(1)
 end
   
 end
end

function game_over()
 local r = rnd(2)
 if ball1.pos.y < - ball1.rad then
  if r <= 1 then 
   sfx(4)
  elseif r >= 1 then
   sfx(6)
  end
  level = 1
  if btn(0) or btn(1) or btn(2)
   or btn(3) or btn(4) or btn(5) or btn(6) then
   
   start_game()
   
  end
  if grav == 0 then
   print("you lost the balloon",28,64,1)
   print("any key to restart",32,72)
 	else
    print("you lost the balloon",28,64,12)
    print("any key to restart",32,72)
 	end
 	ball1.lin_vel.x = 0
 	ball1.lin_vel.y = 0
  ball1.pos.x = 64
  ball1.pos.y = 154
 end
end

-->8
--helper functions

--[[
the helper functions script
is a placeholder for
reusable math functions
--]]


function cross_prod(s,v)
	local vec = {}
	vec.x = s * v.x
	vec.y = s * v.y
	return vec
end

function length(v1)
 return sqrt(v1.x^2+v1.y^2)
end

function sub_vec(v1,v2)
 vec2 = 
 {
 	x = v1.x - v2.x,
 	y = v1.y - v2.y
 }
 return vec2
end

-->8
--game logic

level = 1
grav_counter = 0
wind_x = 0
wind_y = 0
wind_counter = 0
wind_counter = 0

function game_logic()
 if ball1.a_grav == true then
  grav = 0
  grav_counter = 6
  s_grav.lin_vel.x = s_grav.lin_vel.x + wind_x
	 s_grav.lin_vel.y = s_grav.lin_vel.y + wind_y
 s_grav.pos.x = rnd(97)+10
	 s_grav.pos.y = rnd(97)+10
	 ball1.lin_vel.x = rnd(.5) - .4 + wind_x
	 ball1.lin_vel.y = rnd(.5) - .4 + wind_y
	 ball1.a_grav = false
 elseif flr(grav_counter) <= 0 then
  grav = -.02
 end
 
 
 
 
 level_logic(1)
end

function level_logic(num)
 if num == 1  then
	 if check_win(rect1) then
	  level = level + 1
	  rect1.lin_vel.x = 0
	  rect1.lin_vel.y = 0
  rect1.pos.x = rnd(97)+10
  rect1.pos.y = rnd(97)+10
	 

	 end
 end
  
end

function check_win(r)
  if r.pos.x  > 125 then
   return true
  elseif r.pos.x + 18 < 0 then
  	return true
  elseif r.pos.y + 18< 0 then
   return true
  elseif r.pos.y > 125 then
   return true
  else 
   return false
  end
end

function start_game()
 grav = 0
 grav_counter = 6
 rect1.lin_vel.x = 0
 rect1.lin_vel.y = 0
  rect1.pos.x = rnd(97)+10
  rect1.pos.y = rnd(97)+10

 	s_grav.pos.x = rnd(97)+10
	 s_grav.pos.y = rnd(97)+10
	 level = 1
	 
	 wind()
end


function wind()
 
 if wind_counter <= 0 and flr(grav_counter) < 0 then
   if rnd(100) > 90 then
    wind_counter = rnd(15)+1
    wind_x = rnd(5+level)-(4+level)
    wind_y = rnd(2+level)+level
   end
 end
 
 if wind_counter > 0 then
  	wind_counter = wind_counter - .1
  	
  player.lin_vel.x =   player.lin_vel.x  + wind_x*.05
  player.lin_vel.y =   player.lin_vel.y + wind_y
  
  ball1.lin_vel.x =   ball1.lin_vel.x + wind_x
  ball1.lin_vel.y =   ball1.lin_vel.y + wind_y
  

 
  

 end
	 
	 

end


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000010000000000000100000000000000010000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000100000000000001000000000000000100000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000100000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000001000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8a898a89898a898a0000000000000077000000000000000000000000000000000000000000000000000000000000a898898a0000000000000000000000000000
98a898a8a898a898000000000007777770000000000000000000000000000000000000000000000000000000000a898aa898a0000000000008a0aa8800000000
898a898a8a898a8900077707777777777000000000000000070000000000000005000000000000000500000000a898a88a898a0008000800088a088a00000000
a898a89898a898a80077777777777777770000000000000000600000000000005570007f000000005d20005d0a898a8998a898a000000a0000890a9a00000000
a898a89898a898a8007777777777766677700000000000000000000000000005555007ff00000005ddd005df0a898a8998a898a000a0000000a08a9000000000
898a898a8a898a8900777777776777766660000000000000000000000007ffffffffffff000cfeeeeeeeeefe00a898a88a898a00008908000a8908aa00000000
98a898a8a898a89807777766666677777770000000000000000000000565ffffffffff7f0c7cefeeeeeeeeee000a898aa898a0000000000008890a8a00000000
8a898a89898a898a07767777777777777777000000000000000000005555ff555555f7ffcccceeddddddedde0000a898898a0000000000000aa0000000000000
8a890000000098a807766667777777777777700000000000000000007fffff555555ffffeeeeee5dddddeeee0000000000000000000000000000000000000000
98a8900000098a89077777777767777777777770000000000000000067fffff55555ffff55555555dddd55550000000000000000000000000000000000000000
898a89000098a89800777777777677777777777700000000000000000000000055570000000000005dd100000000000000000000000000000000000000000000
a898a890098a898a007777677776777767777770000000000000000000000000055000000000000005d000000000000000000000000000000000000000000000
a898a890098a898a0007766777777777677700000000000000000000000000000050000000000000005000000000000000000000000000000000000000000000
898a89000098a8980077767777777777677000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
98a8900000098a890777677766777766677770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8a890000000098a87777777777677667777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007777777777677777777777000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000
00000000000000000777700076677777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000776777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000007777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555566555565556555655000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555555555555555555500000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555555556566655555566000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555555555665555666550000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555555555555500000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555555555555500000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555555500000000000000
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888ffffff882222228888888888888888888888888888888888888888888888888888888888888888228228888ff88ff888222822888888822888888228888
88888f8888f882888828888888888888888888888888888888888888888888888888888888888888882288822888ffffff888222822888882282888888222888
88888ffffff882888828888888888888888888888888888888888888888888888888888888888888882288822888f8ff8f888222888888228882888888288888
88888888888882888828888888888888888888888888888888888888888888888888888888888888882288822888ffffff888888222888228882888822288888
88888f8f8f88828888288888888888888888888888888888888888888888888888888888888888888822888228888ffff8888228222888882282888222288888
888888f8f8f8822222288888888888888888888888888888888888888888888888888888888888888882282288888f88f8888228222888888822888222888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555550000000000000000000000000000000000000000000000000000000000000000005555550000000000000000000000000000000000000000005555555
5555555088888888aaaaaaaa88888888999999990000000000000000000000000000000005555550000000000011111111112222222222333333333305555555
5555555088888888aaaaaaaa88888888999999990000000000000000000000000000000005555550000000000011111111112222222222333333333305555555
5555555088888888aaaaaaaa88888888999999990000000000000000000000000000000005555550000000000011111111112222222222333333333305555555
5555555088888888aaaaaaaa88888888999999990000000000000000000000000000000005555550000000000011111111112222222222333333333305555555
5555555088888888aaaaaaaa88888888999999990000000000000000000000000000000005555550000000000011111111112222222222333333333305555555
5555555088888888aaaaaaaa88888888999999990000000000000000000000000000000005555550000000000011111111112222222222333333333305555555
5555555088888888aaaaaaaa88888888999999990000000000000000000000000000000005555550000000000011111111112222222222333333333305555555
5555555088888888aaaaaaaa88888888999999990000000000000000000000000000000005555550000000000011111111112222222222333333333305555555
555555509999999988888888aaaaaaaa888888889999999900000000000000000000000005555550000000000011111111112222222222333333333305555555
555555509999999988888888aaaaaaaa888888889999999900000000000000000000000005555550444444444455555555556666666666777777777705555555
555555509999999988888888aaaaaaaa888888889999999900000000000000000000000005555550444444444455555555556666666666777777777705555555
555555509999999988888888aaaaaaaa888888889999999900000000000000000000000005555550444444444455555555556666666666777777777705555555
555555509999999988888888aaaaaaaa888888889999999900000000000000000000000005555550444444444455555555556666666666777777777705555555
555555509999999988888888aaaaaaaa888888889999999900000000000000000000000005555550444444444455555555556666666666777777777705555555
555555509999999988888888aaaaaaaa888888889999999900000000000000000000000005555550444444444455555555556666666666777777777705555555
555555509999999988888888aaaaaaaa888888889999999900000000000000000000000005555550444444444455555555556666666666777777777705555555
55555550888888889999999988888888aaaaaaaa8888888899999999000000000000000005555550444444444455555555556666666666777777777705555555
55555550888888889999999988888888aaaaaaaa8888888899999999000000000000000005555550444444444777777777777666666666777777777705555555
55555550888888889999999988888888aaaaaaaa8888888899999999000000000000000005555550888888888700000000007aaaaaaaaabbbbbbbbbb05555555
55555550888888889999999988888888aaaaaaaa8888888899999999000000000000000005555550888888888709999999907aaaaaaaaabbbbbbbbbb05555555
55555550888888889999999988888888aaaaaaaa8888888899999999000000000000000005555550888888888709999999907aaaaaaaaabbbbbbbbbb05555555
55555550888888889999999988888888aaaaaaaa8888888899999999000000000000000005555550888888888709999999907aaaaaaaaabbbbbbbbbb05555555
55555550888888889999999988888888aaaaaaaa8888888899999999000000000000000005555550888888888709999999907aaaaaaaaabbbbbbbbbb05555555
55555550888888889999999988888888aaaaaaaa8888888899999999000000000000000005555550888888888709999999907aaaaaaaaabbbbbbbbbb05555555
55555550aaaaaaaa888888889999999988888888aaaaaaaa88888888999999990000000005555550888888888709999999907aaaaaaaaabbbbbbbbbb05555555
55555550aaaaaaaa888888889999999988888888aaaaaaaa88888888999999990000000005555550888888888709999999907aaaaaaaaabbbbbbbbbb05555555
55555550aaaaaaaa888888889999999988888888aaaaaaaa88888888999999990000000005555550888888888700000000007aaaaaaaaabbbbbbbbbb05555555
55555550aaaaaaaa888888889999999988888888aaaaaaaa88888888999999990000000005555550ccccccccc777777777777eeeeeeeeeffffffffff05555555
55555550aaaaaaaa888888889999999988888888aaaaaaaa88888888999999990000000005555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550aaaaaaaa888888889999999988888888aaaaaaaa88888888999999990000000005555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550aaaaaaaa888888889999999988888888aaaaaaaa88888888999999990000000005555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550aaaaaaaa888888889999999988888888aaaaaaaa88888888999999990000000005555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550aaaaaaaa888888889999999988888888aaaaaaaa88888888999999990000000005555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550aaaaaaaa888888889999999988888888aaaaaaaa88888888999999990000000005555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550aaaaaaaa888888889999999988888888aaaaaaaa88888888999999990000000005555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550aaaaaaaa888888889999999988888888aaaaaaaa88888888999999990000000005555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550aaaaaaaa888888889999999988888888aaaaaaaa88888888999999990000000005555550000000000000000000000000000000000000000005555555
55555550aaaaaaaa888888889999999988888888aaaaaaaa88888888999999990000000005555555555555555555555555555555555555555555555555555555
55555550aaaaaaaa888888889999999988888888aaaaaaaa88888888999999990000000005555555555555555555555555555555555555555555555555555555
55555550aaaaaaaa888888889999999988888888aaaaaaaa88888888999999990000000005555555555555555555555555555555555555555555555555555555
55555550888888889999999988888888aaaaaaaa8888888899999999000000000000000005555550000000555556667655555555555555555555555555555555
55555550888888889999999988888888aaaaaaaa8888888899999999000000000000000005555550000000555555666555555555555555555555555555555555
55555550888888889999999988888888aaaaaaaa888888889999999900000000000000000555555000000055555556dddddddddddddddddddddddd5555555555
55555550888888889999999988888888aaaaaaaa88888888999999990000000000000000055555500090005555555655555555555555555555555d5555555555
55555550888888889999999988888888aaaaaaaa8888888899999999000000000000000005555550000000555555576666666d6666666d666666655555555555
55555550888888889999999988888888aaaaaaaa8888888899999999000000000000000005555550000000555555555555555555555555555555555555555555
55555550888888889999999988888888aaaaaaaa8888888899999999000000000000000005555550000000555555555555555555555555555555555555555555
55555550888888889999999988888888aaaaaaaa8888888899999999000000000000000005555555555555555555555555555555555555555555555555555555
555555509999999988888888aaaaaaaa888888889999999900000000000000000000000005555555555555555555555555555555555555555555555555555555
555555509999999988888888aaaaaaaa888888889999999900000000000000000000000005555556665666555556667655555555555555555555555555555555
555555509999999988888888aaaaaaaa888888889999999900000000000000000000000005555556555556555555666555555555555555555555555555555555
555555509999999988888888aaaaaaaa88888888999999990000000000000000000000000555555555555555555556dddddddddddddddddddddddd5555555555
555555509999999988888888aaaaaaaa8888888899999999000000000000000000000000055555565555565555555655555555555555555555555d5555555555
555555509999999988888888aaaaaaaa888888889999999900000000000000000000000005555556665666555555576666666d6666666d666666655555555555
555555509999999988888888aaaaaaaa888888889999999900000000000000000000000005555555555555555555555555555555555555555555555555555555
555555509999999988888888aaaaaaaa888888889999999900000000000000000000000005555555555555555555555555555555555555555555555555555555
5555555088888888aaaaaaaa88888888999999990000000000000000000000000000000005555555555555555555555555555555555555555555555555555555
5555555088888888aaaaaaaa88888888999999990000000000000000000000000000000005555555555555555555555555555555555555555555555555555555
5555555088888888aaaaaaaa88888888999999990000000000000000000000000000000005555550005550005550005550005550005550005550005550005555
5555555088888888aaaaaaaa888888889999999900000000000000000000000000000000055555011d05011d05011d05011d05011d05011d05011d05011d0555
5555555088888888aaaaaaaa88888888999999990000000000000000000000000000000005555501110501110501110501110501110501110501110501110555
5555555088888888aaaaaaaa88888888999999990000000000000000000000000000000005555501110501110501110501110501110501110501110501110555
5555555088888888aaaaaaaa88888888999999990000000000000000000000000000000005555550005550005550005550005550005550005550005550005555
5555555088888888aaaaaaaa88888888999999990000000000000000000000000000000005555555555555555555555555555555555555555555555555555555
55555550000000000000000000000000000000000000000000000000000000000000000005555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555558a89000055555555555555555555555555555555555555555555555555
5555555555555555555555555d555555ddd555575757575555d5d55555555d5555555598a8900056666666666666555557777755555555555555555555555555
555555555555555555555555ddd55555ddd555555555555555d5d5d5555555d5555555898a890056ddd6d6d6ddd6555577ddd775566666555666665556666655
55555555555555555555555ddddd5555ddd555575555575555d5d5d55555555d555555a898a89056d6d6d6d6d6d6555577d7d77566dd666566ddd66566ddd665
5555555555555555555555ddddd55555ddd555555555555555ddddd555ddddddd55555a898a89056d6d6ddd6ddd6555577d7d775666d66656666d665666dd665
555555555555555555555d5ddd5555ddddddd55755555755d5ddddd55d5ddddd555555898a890056d6d666d666d6555577ddd775666d666566d666656666d665
555555555555555555555d55d55555d55555d555555555555dddddd55d55ddd555555598a8900056ddd666d666d655557777777566ddd66566ddd66566ddd665
555555555555555555555ddd555555ddddddd55757575755555ddd555d555d555555558a89000056666666666666555577777775666666656666666566666665
55555555551555555555555555555555555555555555555555555555555555555555555555555555555555555555555566666665ddddddd5ddddddd5ddddddd5
00000000017100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000017710000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000017771000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700017777100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000017711000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000001171000000000000000000000000000000000000000000000000010000000000000100000000000000010000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000100000000000001000000000000000100000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000100000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000001000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8a898a89898a898a0000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
98a898a8a898a8980000000000077777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
898a898a8a898a890007770777777777700000000000000007000000000000000500000000000000050000000000000000000000000000000000000000000000
a898a89898a898a80077777777777777770000000000000000600000000000005570007f000000005d20005d0000000000000000000000000000000000000000
a898a89898a898a8007777777777766677700000000000000000000000000005555007ff00000005ddd005df0000000000000000000000000000000000000000
898a898a8a898a8900777777776777766660000000000000000000000007ffffffffffff000cfeeeeeeeeefe0000000000000000000000000000000000000000
98a898000000000000777766666677777770000000000000000000000565ffffffffff7f0c7cefeeeeeeeeee0000000000000000000000000000000000000000
8a898a077777777770767777777777777777000000000000000000005555ff555555f7ffcccceeddddddedde0000000000000000000000000000000000000000
8a8900078a89000070766667777777777777700000000000000000007fffff555555ffffeeeeee5dddddeeee0000000000000000000000000000000000000000
98a8900798a89000707777777767777777777770000000000000000067fffff55555ffff55555555dddd55550000000000000000000000000000000000000000
898a8907898a890070777777777677777777777700000000000000000000000055570000000000005dd100000000000000000000000000000000000000000000
a898a807a898a890707777677776777767777770000000000000000000000000055000000000000005d000000000000000000000000000000000000000000000
a898a807a898a8907007766777777777677700000000000000000000000000000050000000000000005000000000000000000000000000000000000000000000
898a8907898a89007077767777777777677000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
98a8900798a890007077677766777766677770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8a8900078a8900007077777777677667777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__map__
00000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000000100752023530134402753016000006001d120000000000000000000000000000000220100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000065001650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c0000012000315005260031300a34003120067500527003150000000f3400315009060061000a3400e33011340031000d3000e3600f050091000633003200124500000011330000000f4200f5001d30000000
000e0000012000313005270031301a320031300627005240031300000019320031700906017130081700e0601633003100160300f200052000910014230032001624016320163001620016200000000000000000
000e0000012000653005570035302252003100062000e5500e50021500215200f570090001e5200a5700f56016530031001e5001e5501e500091001a530032001b5001b5501b5001620016200000000000000000
000e00000460015530066001455013520025001d1000e5500c5000460015520125500e0000b520046000a5500a50008600095501754017500175001455016550165001b5501b5001a55016200195001850017500
000e00000e5201957018530155001755015500235502250021550000001f5501f550000001e5501e5001c550000001c5500000000000285500000000000000000000000000000000000000000000000000000000
__music__
01 04424344
01 06424344
02 06424344
02 04424344

