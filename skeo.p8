pico-8 cartridge // http://www.pico-8.com
version 10
__lua__

printh("\n\n-------\n-poop-\n-------")

dev = true

-- constants

grav = 0.3
left = true -- these are for facing
right = false

start_cell_x = 29
start_cell_y = 16
start_x = start_cell_x * 8 -- where to draw initial cam
start_y = start_cell_y * 8
p2_strt_x = start_x + 8 * 13

starting_scroll_speed = 2
scroll_cooldown = 450 -- 15 seconds

--screen stuff
screen_height = 32 -- cells
screen2_offset = 17 -- x cells after screen 1 ends

-- sounds
snd_jmp = 0
snd_bmp = 1
snd_wif = 2
snd_hit = 3
snd_lnd = 4

-- game state
game_over = false
default_got = 30
game_over_timeout = 30
players = {} -- players in the game
actors = {} -- living players
fx = {} -- particles and splosions n stuff
starting_lives = 3

player_info = {
	{
		player = 0,
		clr = 6,
		x = start_x + 8 * 1,
		lives = starting_lives
	}, {
		player = 1,
		clr = 8,
		x = start_x + 8 * 13,
		lives = starting_lives
	}, {
		player = 2,
		clr = 12,
		x = start_x + 8 * 4,
		lives = starting_lives
	},{
		player = 3,
		clr = 3,
		x = start_x + 8 * 9,
		lives = starting_lives
	}
}

-- animations
run_anim = {
	frames = {0,2,4,6,8,10,12,14,32,34,36,38,40},
	tx = 2,
	loop = true
}

idle_anim = {
	frames = {42,44},
	tx = 30,
	loop = true
}

jmp_anim = {
	frames = {8,12,14,46},
	tx = 2,
	loop = false
}

clmb_anim = {
	frames = {132,134,136,134,132,128,130,128},
	tx = 2,
	loop = true
}

fall_bk_anim = {
	frames = {164,166},
	tx = 2,
	loop = true
}

end_fall_bk_anim = {
	frames = {168,170,172},
	tx = 2,
	loop = false
}

fall_fwd_anim = {
	frames = {138,140},
	tx = 2,
	loop = true
}

end_fall_fwd_anim = {
	frames = {142,160,162},
	tx = 2,
	loop = false
}

stand_anim = {
	frames = {174},
	tx = 2,
	loop = false
}

jab_anim = {
	frames = {194, 196, 198, 196, 194},
	tx = 2,
	loop = false,
	strike_frame = 198
}

hook_anim = {
	frames = {194, 200, 202, 204, 196},
	tx = 2,
	loop = false,
	strike_frame = 202
}
punch_anims = {jab_anim, hook_anim}

fall_anims = {fall_fwd_anim, fall_bk_anim, end_fall_fwd_anim, end_fall_bk_anim, stand_anim}
air_fall_anims = {fall_fwd_anim, fall_bk_anim}

-- actor 'class'
actor = {
	player = 0,
	clr = 7,
	x = start_x + 8,
	y = start_y + (14 * 8),
	dx = 0,
	dy = 0,
	max_dx = 4,--max x speed
	max_dy = 5,--max y speed
	max_clmb_dx=0.5,--max climb speed
	max_clmb_dy=2,--max climb speed
	acc = 0.5,--acceleration
	dcc = 0.9,--decceleration
	clmb_dcc = 0.8,--decceleration
	jmp_speed = -2.5,
	jmp_ended = false,
	jmp_ticks = 0,
	max_jmp_time = 8,--max time jump can be held
	size = 2,
	run_anim = run_anim,
	jmp_anim = jmp_anim,
	idle_anim = idle_anim,
	clmb_anim = clmb_anim,
	fall_bk_anim = fall_bk_anim,
	fall_fwd_anim = fall_fwd_anim,
	end_fall_bk_anim = end_fall_bk_anim,
	end_fall_fwd_anim = end_fall_fwd_anim,
	jab_anim = jab_anim,
	hook_anim = hook_anim,
	stand_anim = stand_anim,
	cur_anim = idle_anim,
	cur_anim_tx = idle_anim.tx,
	frame = idle_anim.frames[1],
	airtime = 0,
	anim_loops = 0,
	anim_index = 1,
	anim_tx = idle_anim.tx,
	grounded = false,
	on_ladder = false,
	climbing = false,
	downed = false,
	fall_threshold = 4,
	mass = 1, -- for caclulating force
	nap_cur = 0, -- time spent downed after collision
	nap_max = 60,
	facing = right,
	collision_offset = 4,
	punch_y_offset = 4, -- your fist is in front of you
	punch_force = 1,
}
function actor.new(settings)
	local dude = setmetatable((settings or {}), { __index = actor }) 
	return dude
end

function actor:draw()
	pal(7, self.clr)
	local h_px = (self.size * 8) / 2
	spr(self.frame,
		self.x - h_px,
		self.y - h_px,
		self.size,self.size,
		self.facing,
		false)
	pal()
end

function actor:update()
	if not self.downed then
		if not self:check_punch_button() then
			self:check_run_buttons()
			self:check_clmb_buttons()
			self:check_jmp_button()
		end
	else
		self:update_nap()
	end

	self:move()
	self:collide()

	self:pick_animation()
	self:update_punch()

	self:screen_wrap()
	self:die_maybe()
end

function actor:check_punch_button()
	if(self.climbing or not self.grounded) return false
	self.punching = self.punching or btn(5, self.player) 
	return self.punching
end

function actor:check_run_buttons()
	local bl=btn(0, self.player) --left
	local br=btn(1, self.player) --right

	if(bl and br) return
	if bl then
		self.facing = left
		self.dx -= self.acc
	elseif br then
		self.facing = right
		self.dx += self.acc
	end
end

function actor:check_clmb_buttons()
	if not self.on_ladder then
		self.climbing = false
		return 
	end

	local bu=btn(2, self.player) -- up
	local bd=btn(3, self.player) -- down

	if bu or bd then
		self.climbing = true
	elseif self.climbing then
		-- not pressing any buttons, but we are in climb mode: hold still
		self.dy = 0
	end
	if(bu and bd) return
	if bu then
		self.facing = left -- todo: do we need these facings?
		self.dy -= self.acc
	elseif bd then
		self.facing = right
		self.dy += self.acc
	end
end

function actor:check_jmp_button()
	self.jmp_pressed = btn(4, self.player)
	if not self.jmp_pressed then
		self.jmp_ended = true
		if self.grounded then -- kind of a hakk to keep you from re-jumping
			self.jmp_ticks = 0
			self.jmp_ended = false
		end
		return
	end

	if(self.jmp_ended) return

	if(self.jmp_ticks == 0) sfx(sfx_jmp)
	self.jmp_ticks += 1
	if(self.jmp_ticks < self.max_jmp_time) self.dy=self.jmp_speed -- keep going up while held
end

function actor:move()
	if self.climbing then
		--decel
			self.dx *= self.clmb_dcc
		-- speed limit
		self.dx *= self.dcc
		self.dy = mid(-self.max_clmb_dy,self.dy,self.max_clmb_dy)
		self.dx = mid(-self.max_clmb_dx,self.dx,self.max_clmb_dx)
	else
		--decel
		self.dx *= self.dcc
		-- apply gravity
		self.dy += grav
		-- speed limit
		self.dx = mid(-self.max_dx,self.dx,self.max_dx)
		self.dy = mid(-self.max_dy,self.dy,self.max_dy)
	end

	-- move
	self.x += self.dx
	self.y += self.dy
end

function actor:collide()
	self:collide_ladder()
	self:collide_floor()
	self:collide_player()
end

-- speed x + speed y
-- force negative if moving left
function actor:force()
	local f = (abs(self.dx) + abs(self.dy)) * self.mass
	f = (self.dx < 0) and -f or f
	return f
end

function actor:collide_ladder()
	self.on_ladder = false

	local x = self.x
	local y = self.y
	local point = {self.x, self.y - self.size * 4}

	local tile=scroller:map_get(point[1]/8, point[2]/8)
	if fget(tile, 2) then
		self.on_ladder = true
		return true;
	end
end

function actor:collide_floor()
	local old_grounded = self.grounded
	self.grounded = false
	if(self.dy<0) return false
	local landed=false
	--check for collision at multiple points along the bottom
	--of the sprite: left, center, and right.
	local sizep = self.size * 8
	for i=-2,2,2 do
		local tile=scroller:map_get((self.x+i)/8,(self.y+(sizep/2))/8)
		if fget(tile,0) or (fget(tile,1) and self.dy>=0) then
			self.dy=0
			self.y=(flr((self.y+(sizep/2))/8)*8)-(sizep/2)
			self.grounded=true
			self.airtime=0
			if(not old_grounded) sfx(snd_lnd)
			return true
		end
	end
	return false
end

function actor:collide_player()
	for other in all(actors) do
		collide_actors(self, other) 
	end
end

function actor:apply_force(force, bonus)
	bonus = bonus or 0
	local f = abs(force - self:force()) + bonus
	if (f < self.fall_threshold) then return false end
	-- innertia
	local m = (force < 0) and -self.mass or self.mass
	self.dx += force + m
	self.downed = true
	self.climbing = false
	self.nap_cur = self.nap_max
	return true
end

function actor:update_punch()
	if(not self.punching) return
	if self.cur_anim.strike_frame != nil and self.frame == self.cur_anim.strike_frame then
		self:punch_players()
	end
	self.punching = self.anim_index < #self.cur_anim.frames
end

function actor:punch_players()
	local hit = false
	for other in all(actors) do
		if(self:punch(other)) hit = true
	end
	if hit then
		sfx(snd_hit)
	else
		sfx(snd_wif)
	end
end

function actor:punch(other)
	-- dont punch yourself, and dont punch anyone too far away
	if other == self or
		 distance(self, other) > self.size * 8 or
		 other.downed then
		return false
	end
	local offset = actor.collision_offset
	local act_size = other.size * 8
	local px = self.x + (self.facing == left and 0 or act_size)
	local py = self.y + self.punch_y_offset
	local ox = other.x -- + offset (trying to make punching for forgiving and useful)
	local oy = other.y
	local ow = act_size -- - offset
	local oh = act_size
	if intersects_point_box(px,py,ox,oy,ow,oh) then
		local force = self.punch_force * (self.facing == left and -1 or 1)
		other:apply_force(force, 4)
		return true
	end
end

-- actor is downed. wait to get up
function actor:update_nap()
	if(not self.grounded) return

	self.nap_cur -= 1
	if self.nap_cur < 1 then
		self.nap_cur = 0
		self.downed = false
	end
end

function actor:die_maybe()
	-- if off screen, remove from game
	if(self.y < cam.y + 136) return
	del(actors, self)
	sfx(snd_bmp)
	p_info = player_info[self.player + 1]
	p_info.lives -= 1
	self:explode()
	cam:shake(15,4)
end

function actor:explode()
	add(fx, explosion.new(self.x + self.size / 2, self.y, self.clr))
end

function actor:pick_animation()
	-- falling todo: wtf is all of this holy shit
	if self.downed then
		if not includes(fall_anims, self.cur_anim) then
			local anim = self:falling_fwd() and self.fall_fwd_anim or self.fall_bk_anim
			self:start_anim(anim)
		else
			if self.grounded then
				if self.anim_loops > 0 then
					local anim = self:falling_fwd() and self.end_fall_fwd_anim or self.end_fall_bk_anim
					self:start_anim(anim)
				elseif self.cur_anim != self.stand_anim and (self.nap_cur < self.nap_max / 6) then
					self:start_anim(self.stand_anim)
				end
			elseif not includes(air_fall_anims, self.cur_anim) then
				local anim = self:falling_fwd() and self.fall_fwd_anim or self.fall_bk_anim
				self:start_anim(anim)
			end
		end
		return
	end

	-- punching
	if self.punching then
		if not includes(punch_anims, self.cur_anim) then
			self:start_anim(select(punch_anims))
		end
		return
	end

	-- climbing
	if self.climbing then
		if self.cur_anim != self.clmb_anim then
			self:start_anim(self.clmb_anim)
		end
		local speed = max(abs(self.dy), abs(self.dx))
		self:set_anim_rate(speed, self.max_dx)
		return
	end

	-- jumping
	if not (self.grounded or self.falling or self.cur_anim == self.jmp_anim) then
		self:start_anim(self.jmp_anim)
		return
	end

	-- running
	if self.grounded then
		local speed_x = abs(self.dx)
		local idle_speed = 0.1
		if self.cur_anim != self.run_anim and speed_x > idle_speed then
			self:start_anim(self.run_anim)
		elseif self.cur_anim != self.idle_anim and speed_x < idle_speed then
			-- idle
			self:start_anim(self.idle_anim)
			return
		end
		if self.cur_anim == self.run_anim then
			self:set_anim_rate(speed_x, self.max_dx)
			return
		end
	end
end

function actor:falling_fwd()
	return ((self.dx < 0) == self.facing)
end

function actor:set_anim_rate(speed, max_speed)
	-- running animation rate changes based on your speed
	local idle = 0.1
	if (speed >= max_speed) then
		self.cur_anim_tx = 1
	elseif (speed < max_speed / 3 and speed > idle) then
		self.cur_anim_tx = 3
	elseif (speed < idle) then
		self.cur_anim_tx = 100
	else
		self.cur_anim_tx = 2
	end
end

function actor:start_anim(anim)
	self.cur_anim = anim
	self.cur_anim_tx = anim.tx
	self.anim_tx = 0
	self.anim_index = 1
	self.anim_loops = 0
end

function actor:screen_wrap()
	local h_w = (self.size * 8) / 2
	local l_bound = cam.x - h_w
	local r_bound = cam.x + 128 + h_w
	if self.x > r_bound then
		self.x = l_bound
	elseif self.x < l_bound then
		self.x = r_bound
	end
end

function actor:advance_frame()
	self.anim_tx -= 1
	if self.anim_tx > 0 then
		-- frame is longer than one tick
		if self.anim_tx > self.cur_anim_tx then
			-- we switched to a faster animation
			self.anim_tx = self.cur_anim_tx
		end
		return
	end
	self.anim_tx = self.cur_anim_tx

	local max_frame = #self.cur_anim.frames
	self.anim_index += 1
	if self.anim_index > max_frame then
		if (self.cur_anim.loop) then
			self.anim_index = 1
			self.anim_loops += 1
		else 
			self.anim_index = max_frame
		end
	end
	self.frame = self.cur_anim.frames[self.anim_index]
end


-- fx stuff
function init_fx()
	fire.init()
	fx = {}
end

function update_fx()
	if fire_level > 0 then
		for i=1,15 do
			add(fx, fire.new(cam.x, cam.y+128))
		end
	end

	for f in all(fx) do
		f:update()
	end
end

-- fire class
-- fire_life_cycle = { '\146', '\143', '\150', '\149', '\126' }
fire_chars = {'\150', '\143', '\146'}
fire_clrs = { 7, 8, 8, 8, 8, 9, 9, 10 }
fire_level = 0
fire_life_cycle = {}
fire_speed = 1
fire = {
	x = 0,
	y = 0,
	clr = 8,
	dir = left,
	tx = 0
}
function fire.new(x, y)
	local f = setmetatable({}, { __index = fire }) 
	f.x = x - 4 + rnd(136)
	f.y = y
	f.dir = (rnd(2) > 1) and left or right
	return f
end

function fire.init()
	fire_level = 0
	fire_life_cycle = { '\126', '\149' }
end

function fire.level_up()
	if(fire_level > #fire_chars) return
	fire_life_cycle = unshift(fire_life_cycle, fire_chars[fire_level])
	fire_level += 1
end

function fire:update()
	if self.tx == #fire_life_cycle then
		del(fx, self)
		return
	end
	self.clr = select(fire_clrs)
	if self.tx == #fire_life_cycle - 1 then
		self.clr = 5 -- smoke
	end
	if rnd(3) > 2 then
		self.dir = not self.dir
	end
	self.y -= fire_speed+rnd(2)
	self.x += (self.dir and 2 or -2)
	self.tx += 1
end

function fire:draw()
	char = fire_life_cycle[self.tx]
	print(char,self.x,self.y,self.clr)
end


-- player death explosions
explosion = {
	x = 0,
	y = 0,
	clr = 7,
	off_clr = 7,
	blink = false,
	radius = 1,
	max_radius = 16,
	thickness = 3
}
function explosion.new(x, y, clr)
	local e = setmetatable({}, { __index = explosion }) 
	e.x = x
	e.y = y
	e.off_clr = clr
	return e
end

function explosion:update()
	if self.radius > explosion.max_radius then
		self:remove()
		return
	end
	self.blink = not self.blink
	self.radius += 3
end

function explosion:draw()
	for i=0,self.thickness do
		circ(
			self.x,
			self.y,
			max(1, self.radius - i),
			self.blink and self.clr or self.off_clr
		)
	end
end

function explosion:remove()
	del(fx, self)
end


-- camera singleton
cam = {}
function cam:init()
	self.x = start_x
	self.y = start_y
	self.scrolling = dev
	self.max_scroll_tx = starting_scroll_speed
	self.scroll_tx = starting_scroll_speed
	self.cooldown = scroll_cooldown -- change scrolling speed every so often
	self.shake_remaining=0
	self.shake_force = 0
end

function cam:update()
	if(not game_over) self:update_scroll()
	self:update_shake()
end

function cam:update_scroll()
	-- check scroll speed
	self.cooldown -= 1
	if self.cooldown < 1 then
		self.cooldown = scroll_cooldown
		fire.level_up()
		if not self.scrolling then
			self.scrolling = true
		elseif not dev and self.max_scroll_tx > 1 then
			self.max_scroll_tx = max(self.max_scroll_tx / 2, 1)
		end
	end

	if(not self.scrolling) return
	
	-- scroll up
	self.scroll_tx = self.scroll_tx - 1
	if self.scroll_tx < 1 then
		self.scroll_tx = self.max_scroll_tx
		self.y -= 1
	end
end

function cam:update_shake()
	self.shake_remaining=max(0,self.shake_remaining-1)
	if self.shake_remaining > 1 then
		self.x += rnd(self.shake_force)-(self.shake_force/2)
		self.y += rnd(self.shake_force)-(self.shake_force/2)
	elseif self.shake_remaining == 1 then
		self.x = start_x
	end
end

function cam:shake(ticks,force)
	self.shake_remaining = ticks
	self.shake_force = force
end


-- scroll manager singleton
screen_height_px = screen_height * 8
scroller = {}
potential_screens = {}
current_screens = {}
screens = {}
current_top = 0
screen_draw_offset = -17 * 8
screen_width = 17
function scroller:init_screens()
	potential_screens = {
		{
			name = 'a',
			x = 0,
			y = 0,
			draw_width = start_cell_x + screen_width
		}, {
			name = 'b',
			x = screen_draw_offset,
			y = 0,
			draw_width = start_cell_x + screen_width * 2
		},{
			name = 'c',
			x = screen_draw_offset * 2,
			y = 0,
			draw_width = start_cell_x  + screen_width * 3
		},
	}

	current_top = 0
	current_screens = {}
	self:add_screen()
	self:add_screen()
end

function scroller:add_screen()
	local screen = copy(select(potential_screens))
	screen.y = current_top
	current_top -= screen_height_px
	add(current_screens, screen)
end

function scroller:map_get(x, y)
	for scrn in all(current_screens) do
		local scrn_x_cell = flr(scrn.x/8)
		local scrn_y_cell = flr(scrn.y/8)
		if mid(scrn_y_cell, y, scrn_y_cell+screen_height) == y then
			return mget(-scrn_x_cell+x, -scrn_y_cell+y)
		end
	end
end

function scroller:screen_num(cell_y)
	return flr(cell_y / 32) + 1
end

function scroller:draw_map()
	for scrn in all(current_screens) do
		if mid(scrn.y-128, cam.y, scrn.y+screen_height*8) == cam.y then
			map(0, 0, scrn.x, scrn.y, scrn.draw_width, 32) -- screen1
		elseif cam.y < scrn.y-128 then
			-- if we are above this screen, remove it and add a new one
			del(current_screens, scrn)
			self:add_screen()
		end
	end
end


-- game loop stuff

intro = 0
player_select = 1
game = 2
current_mode = player_select

function init_game()
	--init cam
	cam:init()
	scroller:init_screens()

	--init actors
	actors = {}
	for p in all(players) do
		actr = actor.new(copy(player_info[p+1]))
		add(actors, actr)
	end

	init_fx()

	game_over = false
end

function update_game()
	check_game_state()
	if game_over and game_over_timeout == 0 then
		if #actors > 0 then
			if(btn(4, actors[1].player)) init_game()
		else
			if(any_btn(4)) init_game()
		end
	else
		update_actors()
	end
	cam:update()
	update_fx()
end

function check_game_state()
	if game_over or #actors < (dev and 1 or 2) then
		if not game_over then -- game just ended
			game_over = true
			game_over_timeout = default_got
		else
			game_over_timeout = max(0, game_over_timeout - 1)
		end
	end
end

function update_actors()
	for a in all(actors) do
		a:update()
	end
end

function draw_game()
	cls()
	camera(cam.x, cam.y)
	scroller:draw_map()
	for a in all(actors) do
		a:draw()
		a:advance_frame()
	end
	for f in all(fx) do
		f:draw()
	end
	if(game_over) draw_game_over()
end

function draw_game_over()
  draw_lives_left()
	local clr = 13
	local winner = actors[1]
	if(winner) clr = winner.clr
	printc(winner and 'super' or 'no survivors',cam.x + 64, cam.y + 56,0,clr,0)
	printc(' press \151 to restart',cam.x + 56, cam.y + 64,0,clr,0)
end

function draw_lives_left()
	for p in all(players) do
		local p_info = player_info[p+1]
		local lives = p_info.lives
		if lives > 0 then
			for i=1,lives,1 do
				printc('\140', cam.x + p_info.x - start_x, cam.y + 8 + (8*i), 0, p_info.clr, 0)
			end
		end
	end
end

player_select_countdown = (dev and 1 or 5) * 30 -- 5 secods
function update_player_select()
		if player_select_countdown < 1 then
			current_mode = game
			init_game()
			return
		end
		if(#players > 1) player_select_countdown -= 1
		for i in all({0,1,2,3}) do -- TODO: normal for loop here
			if(btn(4, i) and not includes(players, i)) add(players, i)
		end
end

function draw_player_select()
	cls()
	draw_title()
	printc('press \151 to join',   64,94,0,8,0)
	if(#players == 1) printc('need at least two players',64,124,0,8,0)
	if #players > 1  then 
		printc(''..(flr(player_select_countdown/30)),64,108,0,8,0)
	end
	local i = 0
	for p in all(players) do
		printc('\140', 16+32*i,108,0,player_info[p+1].clr,0)
		i += 1
	end
end

-- title screen stuff
letter_sprites = {
	s = 224, u = 225, p = 226, e = 227, r = 228,
	k = 229, i = 230, l = 231,
	a = 232, c = 233, h = 234,
	o = 235, t = 236,
}
title = 'super kill each other '
t_x = 16 + 3
t_y = 16 + 4
function draw_title()
	local words = split(title, ' ')
	local y = 4
	for word in all(words) do
		local x = 20 
		if(word == 'kill' or word == 'each') x = x + 10 
		letters = split(word, '')
		for letter in all(letters) do
			draw_letter_o(letter, x, y)
			x += t_x
		end
		y += t_y
	end
end

function draw_letter(letter, x, y, clr)
	pal(8, clr)
	zspr(letter_sprites[letter], 1, 1, x, y, 2)
	pal()
end

function draw_letter_o(letter, x, y)
	for ix=-1,1 do for iy=-1,1 do
		draw_letter(letter, x+ix+rnd(4)-2, y+iy+rnd(4)-1, 8)
	end end
	draw_letter(letter, x, y, 0)
end

play_music = true
function toggle_music()
	play_music = not play_music
	music(play_music and 0 or -1)
end

function _init()
	-- init_game()
	music(0)

	-- fx
	-- poke(0x5f43, 1) -- lpf
	-- poke(0x5f42, 2) -- distortion
	poke(0x5f41, 12) -- reverb
	menuitem(2, "toggle music", toggle_music)
end

function _update()
	if current_mode == player_select then
		update_player_select()
	elseif current_mode == game then
		update_game()
	end
end

function _draw()
	if current_mode == player_select then
		draw_player_select()
	elseif current_mode == game then
		draw_game()
	end
end


-- helper shit
function any_btn(n)
	return btn(n, 0) or btn(n, 1) or btn(n, 2) or btn(n, 3)
end

--print string with outline.
function printo(str, startx, starty, col, col_bg)
	print(str,startx+1,starty,col_bg)
	print(str,startx-1,starty,col_bg)
	print(str,startx,starty+1,col_bg)
	print(str,startx,starty-1,col_bg)
	print(str,startx+1,starty-1,col_bg)
	print(str,startx-1,starty-1,col_bg)
	print(str,startx-1,starty+1,col_bg)
	print(str,startx+1,starty+1,col_bg)
	print(str,startx,starty,col)
end

--print string centered with 
--outline.
function printc(str, x, y, col, col_bg, special_chars)
	local len=(#str*4)+(special_chars*3)
	local startx=x-(len/2)
	local starty=y-2
	printo(str,startx,starty,col,col_bg)
end

function distance(p1, p2)
	return sqrt(sqr(p1.x - p2.x) + sqr(p1.y - p2.y))
end

function sqr(x)
	return x * x
end

function collide_actors(act1, act2)
	-- dont collide with yourself
	-- dont bother checking for collision with something far away
	-- dont bother if either of them are already downed
	if (act1 == act2) or
		 (distance(act1, act2) > act1.size * 8) or
		 act1.downed or
		 act2.downed then
		return
	end
	-- printh('d: '..distance(act1,act2)..' x1,x2: '..act1.x..','..act2.x..' y1,y2: '..act1.y..','..act2.y)
	local act_size = act1.size * 8
	-- the hitbox should be a little smaller on the x axis, because our sprite is twiggy
	local offset = act1.collision_offset
	local slim_size = act_size - (offset * 2)
	local collide = intersects_box_box(
		act1.x + offset, act1.y,
		slim_size, act_size,
		act2.x + offset, act2.y,
		slim_size, act_size
	)
	if(not collide) return false

	-- do these upfront, because apply_force mutates actors current force
	local f1 = act1:force()
	local f2 = act2:force()
	local r1 = act1:apply_force(f2)
	local r2 = act2:apply_force(f1)
	if (r1 or r2) sfx(snd_bmp)
	return true
end

function intersects_point_box(px,py,x,y,w,h)
	if flr(px)>=flr(x) and flr(px)<flr(x+w) and
				flr(py)>=flr(y) and flr(py)<flr(y+h) then
		return true
	else
		return false
	end
end

--box to box intersection
function intersects_box_box(
	x1,y1,
	w1,h1,
	x2,y2,
	w2,h2)
 
	local xd=x1-x2
	local xs=w1*0.5+w2*0.5
	if abs(xd)>=xs then return false end

	local yd=y1-y2
	local ys=h1*0.5+h2*0.5
	if abs(yd)>=ys then return false end

	return true
end

function includes(tab, val)
	for v in all(tab) do
		if(v == val) return true
	end
	return false
end

function select(t)
	return t[flr(rnd(#t))+1]
end

function copy(t) -- shallow-copy a table
	-- if type(t) ~= "table" then return t end
	-- local meta = getmetatable(t)
	local target = {}
	for k, v in pairs(t) do target[k] = v end
	-- setmetatable(target, meta)
	return target
end

function unshift(arr, val)
	local tmp = {val}
	for v in all(arr) do
		add(tmp,v)
	end
	return tmp
end

function zspr(n,w,h,dx,dy,dz)
	sx = 8 * (n % 16)
	sy = 8 * flr(n / 16)
	sw = 8 * w
	sh = 8 * h
	dw = sw * dz
	dh = sh * dz
	sspr(sx,sy,sw,sh, dx,dy,dw,dh)
end

function split(str, char)
	t = {}
	f = 1
	for i=1,#str do
		if char == '' or not char then
			add(t, sub(str,i,i))
		elseif sub(str,i,i) == char or i == #str then
			add(t, sub(str,f,i-1))
			f = i+1
		end
	end
	return t
end


__gfx__
00000000077000000000000007700000000000000770000000000000000000000000000000000000000000000770000000000000077000000000000007700000
00000000777000000000000077700000000000007770000000000000077000000000000007700000000000007770000000000000777000000000000077700000
00000000777000000000000077700000000000007770000000000000777000000000000077700000000000007770000000000000777000000000000077700000
00000007700000000000000770000000000000077000000000000000777000000000000077700000000000077000000000000007700000000000000770000000
00000777770000000000077777000700000000777700000000000007700000000000000770000000000000777700000000000077770000000000077777000000
00007707770077000000707777707000000007777770700000000077770000000000007777000000000000777700000000000777770000000000777777007000
00007007777700000000700777770000000007077777000000000077770000000000007777000000000000777700000000000077770700000000707777770000
00000707770000000000700777000000000007077700000000000777770000000000007777000000000000077777700000000077777000000000077770700000
00000077700000000000070770000000000000777000000000000077777700000000000777000000000000077000000000000007700000000000000770000000
00000077770000000000007777000000000000077700000000000007700000000000000770770000000000777000000000000077700000000000007770000000
00000770077000000000077007000000000000077770000000000077700000000000007770000000000000777700000000000077770000000000007777000000
00007000077000000077700007700000000000770770000000000007770000000000000770000000000000070700000000000007070000000000077707700000
00070000007000000700000000700000000777700770000000007077077000000000777777000000000000777000000000000077007000000000777007700000
00070000007000000700000000700000007000000700000000070770070000000000700070000000000000770000000000000700070000000077000000700000
00700000070000000000000000700000000000000700000000000000700000000000000700000000000007000000000000007000077000000070000000700000
00070000007000000000000000770000000000000770000000000000770000000000000770000000000007700000000000000700000000000000000000770000
00000000077000000000000000000000000000000000000000000000077000000000000007700000000000000000000000000000000000000000000007700000
00000000777000000000000007700000000000000770000000000000777000000000000077700000000000000770000000000000077000000000000077700000
00000000777000000000000077700000000000007770000000000000777000000000000077700000000000007770000000000000777000000000000077700700
00000007700000000000000077700000000000007770000000000007700000000000000770000000000000007770000000000000777000000000000770000700
00000077770000000000000770000000000000077000000000000007770000000000007777000000000000077000000000000077770000000000777777707000
00000777770070000000007777000000000000077700000000000007770000000000077777007700000000777700000000000777770000000007077777770000
00000707777700000000007777000000000000077700000000000007700000000000007777770000000007777700000000000777777000000070007777000000
00000077707000000000077770000000000000077000000000000007777700000000000777000000000007077770000000000707777000000007000770000000
00000077700000000000077777770000000000077770000000000077700000000000007770000000000007077070000000000707700700000000000770000000
00000077700000000000007770000000000000777077000000000077770000000000007777700000000007077007000000000007700000000000007770000000
00000077770000000000007770000000000000777000000000000077700000000000007707700000000000777700000000000077770000000070007777000000
00000770770000000000007777000000000070777000000000000007770000000000077000700000000000777700000000000077770000000707077007700000
00070700077000000007707707000000000777777000000000000777770000000000070007000000000000700700000000000070070000000000770000070700
00777000007000000000770070000000000000070000000000000707000000000000070007000000000007000700000000000700070000000000000000007000
00000000007000000000000070000000000000070000000000000070000000000000700000700000000007000700000000000700070000000000000000000000
00000000007700000000000077000000000000077000000000000077000000000000070000000000000007700770000000000770077000000000000000000000
ddddddddd000000ddddddddd00000000000000000000000000000000000000000001111111111000000111111111100000000000000000000000000111110000
00500050dd5555dddd5555dd00000000000000000000000000000000000000000010000000000100001000000000010000000000000000000001111111111110
05050505d000000dd505050d00000000000000000000000000000000000000000100100000010010010011000011001000000000000000000111111111111111
50005000500000055000500500000000000000000000000000000000000000000101110000111010010101100100101000000000000000000111111111111111
ddddddddd000000ddddddddd00000000000000000000000000000000000000000100102000010010010111100101101000000000000000000121111221111111
00000000dd5555dddd5555dd00000000000000000000000000000000000000000100001111000010010011000011001000000000000000000011111111110111
00000000d000000dd000000d00000000000000000000000000000000000000000100001001000010010000000000001000000000000000000011111111101111
00000000500000055000000500000000000000000000000000000000000000000100001011000010010010101020001000000000000000000112221111110011
ddd65dddddd65dddddddd22200000000000000000000000000000000000000000100001011000010010010000000001000000000000000000122222111111000
d5d65d5dd1d555550050002000000000000000000000000000000000000000000100001001000010010010101010001000000000000000000021112111111100
ddd65dddddd65ddd0505050200000000000000000000000000000000000000000100001111000010010010000000001000000000000000000011111111211110
d5d65d5dd5d55d2d5000500000000000000000000000000000000000000000000100100000010010010010101010001000000000000000000011111111211111
ddd65dddddd65ddddddddddd00000000000000000000000000000000000000000101110000111010010010000000001000000000000000000011111112222111
00000000055050500000000000000000000000000000000000000000000000000100100000010010010001111100001000000000000000000001111122212200
00000000005050500000000000000000000000000000000000000000000000000010000000000100001000000000010000000000000000000000001121200200
000000000000d0000000000000000000000000000000000000000000000000000001111111111000000111111111100000000000000000000000000000020000
22265ddd200000020dddddd000000000000000000000000000000000000000000001111111111000000000000000000000000000000000000000000111110000
25265d5dd252222dd050005d00000000000000000000000000000000000000000010000000000100000000000000000000000000000000000001111111111110
22d65dddd000000d0505050500000000000000000000000000000000000000000100000000000010000000000000000000000000000000000111111111111111
25d65d5d500000055000500000000000000000000000000000000000000000000100011111100010000000000000000000000000000000000111111111111111
2dd65dddd000000d0ddddddd00000000000000000000000000000000000000000100100000010010000000000000000000000000000000002121111221111111
00000000dd5252ddd000000000000000000000000000000000000000000000000100100000010010000000000000000000000000000000000211111121110111
00000000d000000d0000000000000000000000000000000000000000000000000100100010010010000000000000000000000000000000000211111111121121
00000000500000050000000000000000000000000000000000000000000000000100100001010010000000000000000000000000000000002112221111122211
00000000000000000000000000000000000000000000000000000000000000000100100001010010000000000000000000000000000000000122222111112200
00000000000000000000000000000000000000000000000000000000000000000100100010010010000000000000000000000000000000000022222111121122
00000000000000000000000000000000000000000000000000000000000000000100100000010010000000000000000000000000000000000022222111211110
00000000000000000000000000000000000000000000000000000000000000000100100220010010000000000000000000000000000000000021112111111111
00000000000000000000000000000000000000000000000000000000000000000100011111100010000000000000000000000000000000000011111111111111
00000000000000000000000000000000000000000000000000000000000000000100000000000010000000000000000000000000000000000001111111111000
00000000000000000000000000000000000000000000000000000000000000000010000000000100000000000000000000000000000000000000001111100000
00000000000000000000000000000000000000000000000000000000000000000001111111111000000000000000000000000000000000000000000000000000
00000000000000000000700000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000
00000007700000000000700077000000000000077000000000000007700000000000007700070000000000000000000000000000000000000000000000000000
00007007700000000000070777000000000000077000000000000007707000000000007770700000000000000000007700000000000000000000000000000000
00000707700000000000077777000000000007077000000000000007707000000000007777700000000000000000077700000000000000000000000000000000
00000777700000000000077777000000000007077000000000000007777000000000007777700000000000000077777700000000000000770000000000000000
00000077770000000000007770000000000007777700000000000077770000000000000777000000000000000777770000000000000007770000000000000000
00000077777000000000000777000000000007777770000000000777770000000000007777000000000000077777777000000000007777770000000000000000
00000007777000000000000777700000000000777770000000000707700000000000077770000000000777777707000700000000077777700000000000000000
00000007700000000000000770700000000000077000000000007007700000000000770770000000077777770000700000000707777700770000000000000000
00000707700000000000000770000000000000077000000000000007700000000000000770700000770077000000700077707777770700000000000007000000
00000777770000000000077777000000000000077700000000000077777000000000007777700000707770000000070070777777000700000007000000700077
00000777770000000000077777000000000000777700000000000077777000000000007777000000007000000000000000007700000000000700700000070777
00000070770000000000007077000000000000770700000000000070070000000000007007700000070000000000000000077000000000007770700000077777
00000070070000000000077007000000000000700700000000000070070000000000007000000000070000000000000000770000000000000077777007777000
00000700070000000000000007000000000000700700000000000070007000000000007000000000000000000000000000700000000000000007777777777000
00000000070000000000000000700000000000700700000000000770000000000000077000000000000000000000000000000000000000000000777777700000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000777007000000000000007700000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000777077000700000077707000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000077770077000000077777000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000007777770000000007777000070000000000000000000700000000000000000000000000000000000000000000000000
00000000000000000000000000000000007777770000000000777777700000000000000000000070000000000000000000000000000000000000000000000000
00000000000000000000000000000000000077770000000000777777000000000000000000007700000000000000000000000000000000000000000007700000
00000000000000000000000000000000000000077777700000007777000070000000007777770000000007000000000000000000000000000000077077770000
00000000000000000000000000000000000000077777070000000007777777070770777777770000000007007070000700000000000000000000707707700000
00000000000000000000000000000000000000000770077000000007777000707777777077077000077007070777707000000000000000000007777700000000
00000000000000000000000000000000000000000077000000000000077000000770770000000700777077707707770000000000000000000000777770000000
00770000000000000000000000000000000000000007000000000000007700000000077000000077077777777777000000000000000700000000777770000000
00070000000007700000000000000770000000000000770000000000000770000000000700000000000777777700000077707770007770000000777077000000
77070770077777777700077007770777000000000000000000000000000007700000000000000000000000077000000077777777777077070007077007000000
70777777777707777077777777777777000000000000000000000000000000000000000000000000000000000000000007707777777777770070707700700000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077000000000000007700000000000000077000000000000007700000000000000770000000000000077000000000000007700000000000000000000
00000000777000000000000077700000000000000777000000000000077700000000000007770000000000000777000000000000077707000000000000000000
00000000777000000000000077700000000000000777000000000000077700770000000007770000000000000777007700000000077700700000000000000000
00000077770000000000007777000000000000077770000000000007777777770000000077700000000000077770077700000077777777700000000000000000
00000777770000000000077777000000000000777777070000000077777777000000000777700000000000777777770000000777777777000000000000000000
00000777777000000000070777700000000000777777700000000770777700000000000777777000000007777777000000000707777700000000000000000000
00000707777000000000007770000000000000077770000000000077777000000000000077000000000007077770000000000070777000000000000000000000
00000707700700000000000770000000000000007700000000000000770000000000000077700000000000707700000000000000770000000000000000000000
00000007700000000000000770000000000000007700000000000000770000000000000077000000000000007700000000000000770000000000000000000000
00000077770000000000007777000000000000077770000000000007777000000000000777700000000000077770000000000007777000000000000000000000
00000077770000000000007777000000000000777770000000000077777000000000007777700000000000777770000000000077777000000000000000000000
00000070070000000000007007000000000000770077000000000077007700000000007700070000000000770077000000000077007700000000000000000000
00000700070000000000070007000000000007700070000000000770007000000000077000070000000007700007000000000770000700000000000000000000
00000700070000000000070007000000000007000700000000000700070000000000070000070000000007000000700000000700000070000000000000000000
00000770077000000000077007700000000007700770000000000770077000000000077000077000000007700000770000000770000077000000000000000000
08888880888008888888880088888888888888008880088800088000088800000088880000888800888008880088880088888888888888008888880088800888
88888888880000888800088888888888880008888800008800088000088000000880088008888880880000880888888088888888880008808888888088800088
88000008880000888800008888000008880000888800888000088000088000008800008888800888880000888880088880088008880008808800088888880088
08888800880000888800088888880000880008888888800000088000088000008800008888000000888888888800008800088000888888808800008888888088
00888888880000888888880088080000888888008888800000088000088000008888888888000000880000888800008800088000880008888800008888088888
80000088880000888800000088000008880088808800888000088000088000808800008888800888880000888880088800088000880000888800088888008888
88888880088008808800000088888888880000888800008800088000088888808800008808888880880000880888888000088000880008888888888088000888
08888800008888008880000088888888888008888880088800088000088888808880088800888800888008880088880000088000888888808888880088800888
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001040500000000000000000000000000010101000000000000000000000000000104010000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000004100000000000000000000410000000000410000000000000000000000000000000041000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000040400000004100000040400000000000410000000000410040400000004050000050515000000041000000005040500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000040500000005051504250505000005050004050424052000041414000000000000000000000000000000041000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000004100000000000000000000410000004141414100000040400000004100000000504040404050000000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000041000000000000000000000000000000000000000000624000000000004100000000515000000000410000414141414100000000000000004100000000000000000000000000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000624042505050400000000000000000000000000000000000000000000000004100000000000000000000410000414141414141000000000000004140404050000000000050404040404100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000041700000000000000000000000000000000000000000004040500000006100504050000000000000410000000000000000404000000000004100000000000000000000000000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070707070707041707070707070707000000000000000000000000000000000000000004100000000000000000000410000400000005000000000000000004100000040405000005040404000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070707070707061707070707070707000000000000000000000000000000000000000004100000000410000000000414040000000000040400000504040004100000000000000000000000000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070707070707041707070707070707000000000000000000000000000000000000050404040400000410000000000410000000000000000006240000000004140500000000000000000000050404100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040405260624040405051505040404040400000000000000000000000000000000000000000005140410000000000410000404000000000000000000000004100000000005040405000000000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070707070707070707070707070707000000000000000000000000000005040510000000040400000410000000000410000000000000000000000000000004100000000000000000000000000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000000000000000000000000000410000000000410000000050505040000000000000004100404050000000000000405000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000000000000050405000000000410000000000410000000000000000000000000000004100000000000000000000000000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404040404040000000000000000000000000000000000000000000404000000000410000000000000000000000000000004100000040405000504000000050404100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000005040510000410000404000000000000050515000000000000000504040500000004100000000000000000000504000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000000041000000410000000000000000000000000000000000000000000000000000004140500000000000000000000000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000000041000040424050000000000000000000000000000000000000000000000000004100000000404040625261000000505100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000404042526000410000000000000000000041000000604040404050000000410000004100000000000000000041000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000000041000000410000000000004100000041000000000000000000000000410000004100000040404040405042504000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000000041000000420000000000004100000041504051000000000000504050410000005000000000000000000041000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000000041000000000000000040504100000041000000620000000051000000410000000040500000000000000041000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000000041000000004100000000004100000041000000000000000000000000414050000041000050400000000041000040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000000041000000004100000000004100000041004100000040400000000000410000000041000000000000000041000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000041404062404240500000004100000041004100000000000000000000410000000041504040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000041000000004100000000004100000040404100000000000000000050404040000041000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000404042405000004100000050404240400000004140500000410000504000000000000041000000000041000000004050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000041000000004100000000004100000000004100000000410000000000000000000041000000000041000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000041000000004100000000004100000000004100504040424040404050000000004040405240405042504000000000504000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000041000000004100000000004100000040004100000000410000000000405000000000000000000041000000005040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000041000000004100000000004100000000004100000000410000000000000000000000000000000041000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000040404040405050514250404040404040404040404040404050425040404040404040404040404040405042514040406240404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00020000105741c561375000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500002467007371033510233101320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400003a6103d6003f6002360034600333003330018600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300003c65113460123600e46004450024401260004300033000230002300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000174101400053000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110002007365073650a3650c36507365073650c3650e36507365073650e3650f36507365073650f3651136507365073650a3650c36507365073650c3650e36507365073650e3650f36507365073650f36511365
0110002007455074550a4550c45507455074550c4550e45507455074550e4550f45507455074550f4551145507455074550a4550c45507455074550c4550e45507455074550e4550f45507455074550f45511455
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100020133431334305305053052765500000133431360013343000001f3032760327653000000000000000133431334305305053052765500000133531360013343000001f3032760327653000002760327653
011000043f70016600377223771500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001334313343377223771527655000001334337715133431334337722377152765300000377223771513343133433772237715276550000013343377151334313343377223771527655276453771527655
0110000013010130101301013010130101301013010130101301716027180271d0371304716057180771d0771305716057180471d0371302716017180171d0171301716017180171d01713010130101301513000
0110000013010130101301013010130101301013010130101301716027180271d0371304716057180771d0771305716057180471d0371304716057180571d0671306716077180771d0771307616076180761d076
001000001334313343377223771527655000001334337715133431334337722377152765300000377223771513343133433772237715276550000013343377151334313343377223663336643356433664336653
01100010073650a36500000073650a3650a305073650a3650730507365073650736507365073650a3650a3050a305000000000000000000000000000000000000000000000000000000000000000000000000000
011000001334313343053052765527655000001334313343000001334313343133432765527655276550000013363133630530527675276750000013363133630000013373133731337329675296752b67500000
01100000074050a40500000074050a4050a305074050a4050730507405074050740507405074050a4050a30013465224650020013465224650a2051346522465071051346513465134651346513465224650a405
0110000013465224650020013465224650a2051346522465071051346513465134651346513465224650a4051f4652e465002001f4652e4650a2051f4652e465071051f4651f4651f4651f465214652e46530465
011000001334313343053052765527655000001334313343000001334313343133432765527655276550000013363133630530527675276750000013363133630000013373133731337329675296752b6752b675
0110000013773133033f6150160513773000003f6150760313773000003f6153f60013773000003f6153f61313773133033f6150160513773000003f6153f61313773000003f6153f61313773000003f61521645
011000000000000000000000000021645000000000000000000000000000000000002164500000000000000000000000000000000000216450000000000000000000000000000000000021645000000000000000
0110000013773133033f6050160513773000003f6050760313773000003f6053f60013773000003f6053f60313773133033f6050160513773000003f6053f60313773000003f6053f60313773000003f60521655
0110002007355073550a3550c4550e455074550c35507355073550a4550c455074550a3550c355073550a45507455074550a3550c3550e355074550c45507455073550a3550c3550745511455074550c3550a355
0110000013773133033f6150160513773000003f6150760313773000003f6153f60013773000003f6153f61313773133033f6150160513773000003f6053f60313703000003f6053f60313703000003f60521605
01100008305061f5062b7262e716216451f5062b7262e71630506295062b5262e51621645295062b5262e51630506295062b5262e51621645295062b5262e51630506295062b5262e51621645295062b5262e516
011000000000000000000000000021645000000000000000000000000000000000002164500000000000000000000000000000000000216450000000000000000000000000000000000000000000000000000000
01100000132202922116205132201a2010e205132201a201132202922116205132201a2010e205132201a201132202922116205132201a2010e205132201a201132202620016205132201a2000e205132201a201
01100000132202922116205132201a2010e205132201a201132202922116205132201a2010e205132201a201132202922116205132201a2010e205132201a2011322029221162151622516235162451625516265
0110002007355073550a3550c4550e455074550c35507355073550a4550c455074550a3550c355073050a40507455074550a3550c3550e355074550c45507455073550a3550c3550745511455074550c3550a355
0110002007355073550a3550c4550e455074550c35507355073550a4550c455074550a3550c355073550a45507455074550a3550c3550e355074550c45507455073550a3550c3550745511405074050c3050a305
0110000813300262000732407430003010e2000732407430004012620013324133201a2000e2001330013324133002620013324133001a2000e200133001332413320262001332413320133000e2001332013324
0110000013773133033f6153f61513773000003f6153f61513773000003f6153f61513773000003f6153f61513773133033f6153f61513773000003f6153f61513773000003f6153f61313773000003f61521645
00100000130061f0062200624006130061f0062200624006130061f0062200624006130061f0062200624006135161f5162251624516135161f5162251624516135261f5262252624526135361f5362253624536
011000002e5262b5162e51630516226452b5162e506305062e5062b5062e50630506226451f5062250624506135061f5062250624506226451f5062250624506135061f5062250624506226451f5062250624506
001000081377313303306153f6051377300000306153f60513773000003f6153f61513773000003f6153f61513773133033f6153f61513773000003f6153f61513773000003f6153f61313773000003f61521645
001000002e5262b5162e51630516226452b5162e506305060c6000c6000c6140c620226450c6000c6140f620135061f5060f6140f630226451f5060f61410630135061f5061161411630226451f5061161414630
00100000135061f5061161411630226451f50611614146300c6000c6001461414630226450c6001461416640135061f5061662416640226451f5061762419640135061f5061963419640226451f506196341b640
001000003265028640216301c62022605376061e614176300c6000c6001661411630226050c6000d61409630135061f5060a61408620226051f5060661404620135061f5060261402610226051f5060161401615
011000003a60028600216141c63022605376061e614176200c6000c6001661411610226050c6000d61409610135061f5060a61408610226051f5060661404600135061f5060260402600226051f5060160401605
011000003a60028600216141c61022605376061e614176100c6000c6001661411620226050c6000d61409620135061f5060a61408620226051f5060661404630135061f5060260402600226051f5060160401605
011000001f1101d100221001f1101a1001a1001f1101a1001f1101d100221001f1101a1001a1001f1101a1001f1101d100221001f1101a1001a1001f1101a1001f1101d100221001f1101a1001a1001f1101a100
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000024546225461f5361353624526225261f5161351624516225161f5161351624516225161f5161351624506225061f5061350624506225061f5061350624506225061f5061350624506225061f50613506
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 0a0b0e0d
00 0a0b100f
00 0a0b0e0d
00 0a0b1112
00 13154f14
00 13164017
00 214b191a
00 215c1918
00 215d1e1c
00 1b1f1918
00 1b201918
00 1b1f1918
00 1b201918
00 1b1f2624
00 1b201924
00 1b1f2824
00 22202964
00 2d232a27
00 2d236b27
00 2d232c27
00 2d232b27
00 2d233124
00 2d237124
00 2d233124
00 2d637164
01 2d231924
02 2d231924
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 2d230524
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000

