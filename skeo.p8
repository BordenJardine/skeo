pico-8 cartridge // http://www.pico-8.com
version 8
__lua__

printh("\n\n-------\n-skeo-\n-------")

dev = false
disable_bg_doodads = false

-- constants

grav = 0.3
left = true -- these are for facing
right = false

start_cell_x = 29
start_cell_y = 16
start_x = start_cell_x * 8 -- where to draw initial cam
start_y = start_cell_y * 8

starting_scroll_speed = 3 -- tx between scroll pixels
scroll_speed_up_cooldown = 1800 -- 1 min
scroll_cooldown = 450 -- 15 seconds
-- scroll_cooldown = 150 -- 15 seconds

--screen stuff
screen_height = 32 -- cells
screen2_offset = 17 -- x cells after screen 1 ends

-- sounds
snd_jmp = 0
snd_bom = 1
snd_wif = 2
snd_hit = 3
snd_lnd = 4
snd_bmp = 5
snd_bet = 6
snd_al1 = 7
snd_al2 = 8

-- game state
round_over = false
default_rot = 30
round_over_timeout = 30 -- give it a sec to settle down
tag_length = 3 * 30 -- seconds after a punch a player should get credit for a kill
starting_lives = 5
players = {} -- players in the game
actors = {} -- living players
fx = {} -- particles and splosions n stuff
bg_doodads = {}
power_ups = {}


player_info = {
	{
		player = 0,
		clrs = {5, 6, 7},
		clr = 6,
		x = start_x + 8 * 1,
		lives = starting_lives
	}, {
		player = 1,
		clrs = {2, 8, 14},
		clr = 8,
		x = start_x + 8 * 13,
		lives = starting_lives
	}, {
		player = 2,
		clrs = {1, 12, 13},
		clr = 12,
		x = start_x + 8 * 4,
		lives = starting_lives
	},{
		player = 3,
		clrs = {5, 3, 11},
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
	off_clr = false,
	x = start_x + 8,
	y = start_y + (14 * 8),
	power_level = 2,
	dx = 0, -- current speed
	dy = 0,
	dcc = 0.9,--decceleration
	clmb_dcc = 0.8,--decceleration
	jmp_ended = false,
	jmp_ticks = 0,
	max_jmp_time = 8,--max time jump can be held
	size = 2, -- 2 8*8 sprites
	size_px = 16,
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
	nap_cur = 0, -- time spent downed after collision
	nap_max = 60,
	facing = right,
	collision_offset = 4,
	punch_y_offset = 4, -- your fist is in front of you
	tag = nil
}
stats = {}

-- alpha
stats[1] = {
	max_dx = 3,--max x speed
	max_dy = 4,--max y speed
	max_clmb_dx=0.4,--max climb speed
	max_clmb_dy=1.7,--max climb speed
	acc = 0.4,--acceleration
	jmp_speed = -2.0,
	fall_threshold = 6,
	mass = 2, -- for caclulating force
	punch_force = 4,
}

-- normie
stats[2] = {
	max_dx = 4,--max x speed
	max_dy = 5,--max y speed
	max_clmb_dx=0.5,--max climb speed
	max_clmb_dy=2,--max climb speed
	acc = 0.5,--acceleration
	jmp_speed = -2.5,
	fall_threshold = 4,
	mass = 1, -- for caclulating force
	punch_force = 2.0,
}

-- beta
stats[3] = {
	max_dx = 5,--max x speed
	max_dy = 6,--max y speed
	max_clmb_dx=0.7,--max climb speed
	max_clmb_dy=3,--max climb speed
	acc = 0.7,--acceleration
	jmp_speed = -3.1,
	fall_threshold = 3,
	mass = 0.8, -- for caclulating force
	punch_force = 0.7,
}
function actor.new(settings)
	local dude = setmetatable((settings or {}), { __index = actor }) 
	return dude
end

function actor:stats()
	return stats[self.power_level]
end

function actor:change_power_level(change)
	self.power_level = mid(1, self.power_level + change, #stats)
end

function actor:draw()
	local clr = self.off_clr and self.clrs[self.power_level] or self.clr
	pal(7, clr)
	local h_px = (self.size_px) / 2
	spr(self.frame,
		self.x - h_px, -- i really shouldn't have subtracted this, but it's too late now
		self.y - h_px, -- made collision messy :(. cleanup for later meebee
		self.size,self.size,
		self.facing,
		false)
	pal()
end

function actor:update()
	if self.downed then
		self:update_nap()
	else
		if not self:check_punch_button() then
			self:check_run_buttons()
			self:check_clmb_buttons()
			self:check_jmp_button()
		end
	end
	self:move()
	self:collide()
	self:pick_animation()
	self:update_punch()
	self:screen_wrap()
	self:update_tag()
	self:die_maybe()
	self.off_clr = not self.off_clr
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
		self.dx -= self:stats().acc
	elseif br then
		self.facing = right
		self.dx += self:stats().acc
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
		self.dy -= self:stats().acc
	elseif bd then
		self.facing = right
		self.dy += self:stats().acc
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
	if(self.jmp_ticks < self.max_jmp_time) self.dy=self:stats().jmp_speed -- keep going up while held
end

function actor:move()
	if self.climbing then
		--decel
			self.dx *= self.clmb_dcc
		-- speed limit
		self.dx *= self.dcc
		self.dy = mid(-self:stats().max_clmb_dy,self.dy,self:stats().max_clmb_dy)
		self.dx = mid(-self:stats().max_clmb_dx,self.dx,self:stats().max_clmb_dx)
	else
		--decel
		self.dx *= self.dcc
		-- apply gravity
		self.dy += grav
		-- speed limit
		self.dx = mid(-self:stats().max_dx,self.dx,self:stats().max_dx)
		self.dy = mid(-self:stats().max_dy,self.dy,self:stats().max_dy)
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
	local f = (abs(self.dx) + abs(self.dy)) * self:stats().mass
	return (self.dx < 0) and -f or f
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
	local sizep = self.size_px
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
	if (f < self:stats().fall_threshold) then return false end
	-- innertia
	local m = self:stats().mass * (force < 0 and 1 or -1)
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
		 other.downed then
		return false
	end
	-- local offset = actor.collision_offset
	local act_size = other.size_px
	local px = self.x + (self.facing == left and 0 or act_size)
	local py = self.y + self.punch_y_offset
	local ox = other.x -- + offset (removing to make punching forgiving and useful)
	local oy = other.y
	local ow = act_size -- - offset
	local oh = act_size
	if intersects_point_box(px,py,ox,oy,ow,oh) then
		local force = self:stats().punch_force * (self.facing == left and -1 or 1)
		local felled = other:apply_force(force, 4)
		if felled then -- maybe we'll get a life out of this!
			other.tag = {
				actor = self,
				player_info = player_info[self.player+1],
				ttl = tag_length
			}
		end
		return felled
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

-- maybe timeout any tags this actor has received
function actor:update_tag()
	if(not self.tag) return
	self.tag.ttl -= 1
	if(self.tag.ttl < 1) self.tag = nil
end

function actor:die_maybe()
	-- if off screen, remove from game
	if(self.y < cam.y + 136) return
	del(actors, self)
	sfx(snd_bom)
	p_info = player_info[self.player + 1]
	self:explode()
	cam:shake(15,4)
	p_info.lives -= 1
	if p_info.lives < 1 then
		del(players, self.player)
	end
	local tag = self.tag
	if tag then
		congratulate(tag.actor)
		self.tag.player_info.lives += 1
	end
end

function actor:explode()
	add(fx, explosion.new(self.x, self.y, self.clr))
end

function actor:pick_animation()
	local anim_funcs = {
		'try_downed_anim',
		'try_punch_anim',
		'try_climb_anim',
		'try_jump_anim',
		'try_run_anim',
	}
	for func in all(anim_funcs) do
		if(self[func](self)) return
	end
end

function actor:try_downed_anim()
	-- todo: wtf is all of this holy shit
	if(not self.downed) return false
	if not includes(fall_anims, self.cur_anim) then -- start falling over
		local anim = self:falling_fwd() and fall_fwd_anim or fall_bk_anim
		self:start_anim(anim)
	else
		if self.grounded then
			if self.anim_loops > 0 then -- finish falling over
				local anim = self:falling_fwd() and end_fall_fwd_anim or end_fall_bk_anim
				self:start_anim(anim)
			elseif self.cur_anim != stand_anim and (self.nap_cur < self.nap_max / 6) then -- stand back up
				self:start_anim(stand_anim)
			end
		elseif not includes(air_fall_anims, self.cur_anim) then -- falling from a height
			local anim = self:falling_fwd() and fall_fwd_anim or fall_bk_anim
			self:start_anim(anim)
		end
	end
	return true
end

function actor:try_punch_anim()
	if(not self.punching) return false
	if not includes(punch_anims, self.cur_anim) then
		self:start_anim(select(punch_anims))
	end
	return true
end

function actor:try_climb_anim()
	if(not self.climbing) return false
	if self.cur_anim != clmb_anim then
		self:start_anim(clmb_anim)
	end
	local speed = max(abs(self.dy), abs(self.dx))
	self:set_anim_rate(speed, self:stats().max_dx)
	return true
end

function actor:try_jump_anim()
	if(self.grounded or self.falling or self.cur_anim == jmp_anim) return false
	self:start_anim(jmp_anim)
	return true
end

function actor:try_run_anim()
	-- running and idling
	if(not self.grounded) return false
	local speed_x = abs(self.dx)
	local idle_speed = 0.1
	if self.cur_anim != run_anim and speed_x > idle_speed then
		self:start_anim(run_anim)
	elseif self.cur_anim != idle_anim and speed_x < idle_speed then
		-- idle
		self:start_anim(idle_anim)
		return true
	end
	if self.cur_anim == run_anim then
		self:set_anim_rate(speed_x, self:stats().max_dx)
	end
	return true
end

function actor:falling_fwd()
	return self.dx < 0 == self.facing
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
	local h_w = (self.size_px) / 2
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


-- fire class
fire_chars = {'\146', '\143', '\143', '\143', '\150', '\126'}
fire_clrs = { 7, 8, 8, 8, 8, 9, 9, 10 }
fire_speed = 1
fire_started = false
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

function fire:update()
	if self.tx == #fire_chars or rnd(6) > 5 then
		del(fx, self)
		return
	end
	self.clr = select(fire_clrs)
	if rnd(3) > 2 then
		self.dir = not self.dir
	end
	self.y -= fire_speed+rnd(2)
	self.x += (self.dir and 2 or -2)
	self.tx += 1
end

function fire:draw()
	char = fire_chars[self.tx]
	print(char,self.x,self.y,self.clr)
end


-- word class
nice_words = {
	'nice!',
	'rude',
	'murderer!',
	'\135',
	'toasty!'
}
word_effect = {
	str = '',
	x = x,
	y = y,
	ttl = 2 * 30, -- 5 seconds
	clr = 6,
	clr_high = 7,
	clr_low = 1,
	bg_clr = 1,
}
function word_effect.new(settings)
	local w = setmetatable((settings or {}), { __index = word_effect })
	return w
end

function word_effect:update()
	self.ttl -= 1

	if(self.ttl % 3 == 0) self.y -= 1
	if(self.ttl < 1) del(fx, self)
end

function word_effect:draw()
	clr = ((self.ttl % 2) == 0) and self.clr_high or self.clr
	if(self.ttl < 10) clr = self.clr_low
	printc(self.str,self.x,self.y,clr,self.bg_clr,0)
end

function congratulate(actor)
	local word = select(nice_words)
	local clr = 6
	local clr_high = 7
	if word == '\135' then
		clr = 8
		clr_high = 14
	end
	add(fx, word_effect.new({
		str = word,
		clr = clr,
		clr_high = clr_high,
		x = actor.x + actor.size / 2,
		y = actor.y
	}))
end


-- bg_doodad class
bg_doodad = {
	x = 0,
	y = 0,
	timer = 0,
	timer_max = 0,
	sprite = 0
}
bg_sprites = {72, 74, 76, 104, 106, 108}
function bg_doodad.init()
	bg_doodads = {}
	bg_doodad.timer_max = 150 * cam.paralax_factor --cooldown between making doodads
	bg_doodad.timer = bg_doodad.timer_max

	bg_doodad.create_doodad(flr(rnd(144)))
end

function bg_doodad.new(x, y)
	local d = setmetatable({}, { __index = bg_doodad }) 
	d.x = x + rnd(136)
	d.y = y
	d.sprite = select(bg_sprites)
	return d
end

function bg_doodad.update_all()
	bg_doodad.timer -= 1
	if bg_doodad.timer < 1 then
		if(rnd(1) > 0.4) bg_doodad.create_doodad()
		bg_doodad.timer = bg_doodad.timer_max
	end

	for d in all(bg_doodads) do
		d:update()
	end
end

function bg_doodad.create_doodad(y_offset)
	if(disable_bg_doodads) return 
	if(y_offset == nil) y_offset = 0
	add(bg_doodads, bg_doodad.new(cam.x-16, cam.y-48+y_offset))
end

function bg_doodad:update()
	if(self.y > cam.y + 128 + 32) del(bg_doodads, self)
end

function bg_doodad:draw()
	zspr(self.sprite, 2, 2, self.x, self.y, 3)
end


-- player death explosions
explosion = {
	x = 0,
	y = 0,
	clr = 7,
	off_clr = 7,
	blink = false,
	radius = 1,
	max_radius = 32,
	thickness = 4
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
	self.radius *= 2
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

-- powerups
--power_up_timeout = 30 * 15 -- 15 seconds
power_up_timeout = 30 * 10 -- 10 seconds
power_up_counter = power_up_timeout
power_up_char = '\136'
power_up_clr_neut = 5
power_up_clrs = {
	alpha = { 2, 8, 14 },
	beta = { 1, 13, 12 }
}
power_up = {
	type = 'alpha',
	active = false,
	clr_index = 1,
	size = 8,
}
function power_up.create()
 -- pick a spot right above the camera
 -- if there isn't already something there,
 -- create a new power-up
	local tile_x = flr((cam.x + rnd(120)) / 8)
	local tile_y = flr((cam.y - 8) / 8)
	local tile = scroller:map_get(tile_x, tile_y)
	if(tile != 0) return
	add(power_ups, power_up.new(tile_x * 8, tile_y * 8))
end

function power_up.new(x, y)
	local p = setmetatable({}, { __index = power_up }) 
	p.x = x
	p.y = y
	p.type = (rnd(2) > 1) and 'alpha' or 'beta'
	return p
end

function power_up.update_all()
	power_up_counter -= 1
	if power_up_counter < 1 then
		power_up.create()
		power_up_counter = power_up_timeout
	end

	for p in all(power_ups) do
		p:update()
	end
end

function power_up:update()
	if self.y > cam.y + 136 then
		self:remove()
	end

	if self.active == false and self.y > cam.y + 64 then
		self.active = true
	end
	if(not self.active) return

	self.clr_index += 1
	if (self.clr_index > #power_up_clrs[self.type]) self.clr_index = 1

	for a in all(actors) do
		self:collide_with_actor(a)
	end
end

function power_up:collide_with_actor(actor)
	local offset = actor.collision_offset
	local act_size = actor.size_px
	local h_s = act_size / 2 -- have to subtract this cause i'm dumb and made x/y the center of the actor
	local slim_size = act_size - (offset * 2)
	local collide = intersects_box_box(
		actor.x + offset - h_s, actor.y - h_s,
		slim_size, act_size,
		self.x, self.y,
		self.size, 1
	)
	if(not collide) return false
	actor:change_power_level(self.type == 'alpha' and -1 or 1)
	self:word_effect()
	self:snd_effect()
	self:remove()
end

function power_up:snd_effect()
	if self.type == 'alpha' then
		sfx(7)
		sfx(8)
	elseif self.type == 'beta' then
		sfx(6)
	end
end

function power_up:word_effect()
	local word_clrs = power_up_clrs[self.type]
	add(fx, word_effect.new({
		str = self.type,
		clr = word_clrs[2],
		clr_high = word_clrs[3],
		x = self.x + self.size / 2,
		y = self.y
	}))
end

function power_up:draw()
	clr = self.active and power_up_clrs[self.type][self.clr_index] or power_up_clr_neut
	print(power_up_char, self.x, self.y, clr)
end

function power_up:remove()
	del(power_ups, self)
end


-- camera singleton
cam = {}

function cam:init()
	self.paralax_factor = 6 -- scrolling frames betweens moving the bg
	self.x = start_x
	self.y = start_y + 16
	self.scrolling = false
	self.max_scroll_tx = starting_scroll_speed
	self.scroll_tx = starting_scroll_speed
	self.bg_cooldown = self.paralax_factor
	self.cooldown = scroll_speed_up_cooldown -- change scrolling speed every so often
	self.shake_remaining=0
	self.shake_force = 0
end

function cam:update()
	if(not round_over) self:update_scroll()
	self:update_shake()
end

function cam:update_scroll()
	-- check scroll speed
	self.cooldown -= 1
	if self.cooldown < scroll_speed_up_cooldown - scroll_cooldown then
		if not self.scrolling then
			self.scrolling = true
			fire_started = true
		end
		if self.cooldown < 1 then
			self.cooldown = scroll_speed_up_cooldown
			self.max_scroll_tx = max(self.max_scroll_tx - 1, 1)
		end
	end

	if(not self.scrolling) return

	-- scroll up
	self.scroll_tx = self.scroll_tx - 1
	if self.scroll_tx < 1 then
		self.scroll_tx = self.max_scroll_tx
		self.y -= 1
		-- scroll bg doodads
		self.bg_cooldown -= 1
		if self.bg_cooldown < 1 then
			self.bg_cooldown = self.paralax_factor
		else
			for doodad in all(bg_doodads) do
				doodad.y -= 1
			end
		end
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
			draw_width = start_cell_x + screen_width * 3
		},{
			name = 'd',
			x = screen_draw_offset * 3,
			y = 0,
			draw_width = start_cell_x + screen_width * 4
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

-- fx stuff
function init_fx()
	bg_doodad.init()
	fire_started = true
	fx = {}
	power_ups = {}
end

update_fire = true
function update_fx()
	if fire_started then
		for i=1,10 do
			add(fx, fire.new(cam.x, cam.y+128))
		end
	end

	update_fire = not update_fire
	if update_fire then
		for f in all(fx) do
			f:update()
		end
	end

	bg_doodad.update_all()
	power_up.update_all()
end


-- game loop stuff

splash = 0
player_select = 1
game = 2
conclusion = 3
current_mode = splash

-- game mode
function init_game()
	current_mode = game
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

	round_over = false
end

function update_game()
	check_round_state()
	if round_over and round_over_timeout == 0 then
		if(check_game_over()) return
		check_new_round_input()
	else
		update_actors()
	end
	cam:update()
	update_fx()
end

function check_new_round_input()
	if #actors > 0 then
		if(btn(4, actors[1].player)) init_game()
	else
		if(any_btn(4)) init_game()
	end
end

function check_round_state()
	if round_over or #actors < (dev and 1 or 2) then
		if not round_over then -- game just ended
			round_over = true
			round_over_timeout = default_rot
		else
			round_over_timeout = max(0, round_over_timeout - 1)
		end
	end
end

function check_game_over()
	if(#players > 1) return false
	init_conclusion()
	return true
end

function update_actors()
	for a in all(actors) do
		a:update()
	end
end

function draw_game()
	cls()
	camera(cam.x, cam.y)
	for d in all(bg_doodads) do
		d:draw()
	end
	scroller:draw_map()
	for p in all(power_ups) do
		p:draw()
	end
	for a in all(actors) do
		a:draw()
		a:advance_frame()
	end
	for f in all(fx) do
		f:draw()
	end
	if(round_over and #players > 1) draw_round_over()
	if(true or dev) draw_stat()
end

function draw_round_over()
	draw_lives_left()
	local clr = 13
	local winner = actors[1]
	if(winner) clr = winner.clr
	printc(winner and 'super' or 'no survivors',cam.x + 64, cam.y + 56,0,clr,0)
	printc(' press \151 to continue',cam.x + 56, cam.y + 64,0,clr,0)
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

function draw_stat()
	print(stat(1), cam.x, cam.y, 10)
end


-- player select mode
player_select_countdown = 0
music_started = false
function init_player_select()
	if(play_music and not music_started) then
		music(0)
		music_started = true
	end
	player_select_countdown = (dev and 1 or 5) * 30 -- 5 secods
	players = {}
	-- restart the lives
	current_mode = player_select
	for p_i in all(player_info) do
		p_i.lives = starting_lives
	end
end

function update_player_select()
	if player_select_countdown < 1 then
		init_game()
		return
	end
	if(#players > 1) player_select_countdown -= 1
	for i in all({0,1,2,3}) do -- todo: normal for loop here
		if(btn(4, i) and not includes(players, i)) add(players, i)
	end
end

function draw_player_select()
	cls()
	draw_title()
	printc('press \151 to join', 64,94,0,8,0)
	if(#players == 1) printc('need at least two players',64,124,0,8,0)
	if #players > 1 then 
		printc(''..(flr(player_select_countdown/30)),64,108,0,8,0)
	end
	local i = 0
	for p in all(players) do
		printc('\140', 16+32*i,108,0,player_info[p+1].clr,0)
		i += 1
	end
end

title = 'super kill each other '
word_spacing = 16 + 4
function draw_title()
	local words = split(title, ' ')
	local y = 4
	for word in all(words) do
		local x = 20 
		if(word == 'kill' or word == 'each') x = x + 10
		draw_word(word, x, y, 0, 8) -- black on red
		y += word_spacing
	end
end

-- conclusion mode
conclusion_timeout = 0
function init_conclusion()
	current_mode = conclusion
	conclusion_timeout = 5 * 30 -- ten seconds
end

function update_conclusion()
	conclusion_timeout -= 1
	if(conclusion_timeout < 1) init_player_select()
end

function draw_conclusion()
	cls()
	camera(0,0)
	local clr = 13
	local winner = players[1]
	if winner then
		winner += 1
		clr = player_info[winner].clr
		draw_word('win', 36, 56, 7, clr)
	else
		draw_word('losers', 8, 56, 0, clr)
	end
end


-- splash screen
splash_words = {
	'music',
	'art',
	'programming',
	'design'
}
splash_word_time = 10
splash_timer = splash_word_time
splash_word_index = 1
function init_splash()
	music(63)
end

function update_splash()
	splash_timer -= 1
	if splash_timer < 1 then
		splash_word_index += 1
		splash_timer = splash_word_time
		if splash_word_index > #splash_words then
			init_player_select()
		end
	end
end

function draw_splash()
		cls()
		local clr = splash_timer % 2 == 0 and 7 or 5
		printc(splash_words[splash_word_index], 64,44,clr,0,0)
		draw_word('borden',8,56, clr, 0)
end


play_music = true
function toggle_music()
	play_music = not play_music
	music(play_music and 0 or -1)
end


function _init()
	init_splash()

	-- fx
	-- poke(0x5f43, 1) -- lpf
	-- poke(0x5f42, 2) -- distortion
	-- poke(0x5f41, 12) -- reverb
	-- poke(0x5f41, 2) -- reverb
	menuitem(2, "toggle music", toggle_music)
end

-- todo dry up this stuff
function _update()
	if current_mode == splash then
		update_splash()
	elseif current_mode == player_select then
		update_player_select()
	elseif current_mode == game then
		update_game()
	elseif current_mode == conclusion then
		update_conclusion()
	end
end

function _draw()
	if current_mode == splash then
		draw_splash()
	elseif current_mode == player_select then
		draw_player_select()
	elseif current_mode == game then
		draw_game()
	elseif current_mode == conclusion then
		draw_conclusion()
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

--crazy text
letter_sprites = {
	a = 232, b = 237, c = 233, d = 238,
	e = 227, h = 234, i = 230, k = 229,
	l = 231, n = 239, o = 235, p = 226,
	r = 228, s = 224, t = 236, u = 225,
	w = 241, y = 240,
}
letter_spacing = 16 + 3
function draw_word(word, x, y, fg_clr, bg_clr)
	letters = split(word, '')
	for letter in all(letters) do
		draw_letter_o(letter, x, y, fg_clr, bg_clr)
		x += letter_spacing
	end
end

function draw_letter_o(letter, x, y, fg_clr, bg_clr)
	for ix=-1,1 do for iy=-1,1 do
		draw_letter(letter, x+ix+rnd(4)-2, y+iy+rnd(4)-1, bg_clr)
	end end
	draw_letter(letter, x, y, fg_clr)
end

function draw_letter(letter, x, y, clr)
	pal(8, clr)
	zspr(letter_sprites[letter], 1, 1, x, y, 2)
	pal()
end

-- mathy
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
		act1.downed or
		act2.downed then
		return
	end
	local act_size = act1.size_px
	local h_s = act_size / 2 -- have to subtract this cause i'm dumb and made x/y the center of the actor
	-- the hitbox should be a little smaller on the x axis, because our sprite is twiggy
	local offset = act1.collision_offset
	local slim_size = act_size - (offset * 2)
	local collide = intersects_box_box(
		act1.x + offset - h_s, act1.y - h_s,
		slim_size, act_size,
		act2.x + offset - h_s, act2.y - h_s,
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
	-- rect(x1,y1,x1+w1,y1+h1, 8)
	-- rect(x2,y2,x2+w2,y2+h2, 11)
 
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
ddddddddd000000ddddddddd00000000000000000000000000000000000000000001111111111000000111111111100000000000000000000000055550000000
00500050dd5555dddd5555dd00000000000000000000000000000000000000000010000000000100001000000000010000000000001000000000555050000000
05050505d000000dd505050d00000000000000000000000000000000000000000100100000010010010011000011001000000000001000000000505555000000
50005000500000055000500500000000000000000000000000000000000000000101110000111010010101100100101000000000001000000000555055000550
ddddddddd000000ddddddddd00000000000000000000000000000000000000000100102000010010010111100101101000000000001000000000550005005550
00000000dd5555dddd5555dd00000000000000000000000000000000000000000100001111000010010011000011001000000000001000005500505505055550
00000000d000000dd000000d00000000000000000000000000000000000000000100001001000010010000000000001000000000001000005555555555505500
00000000500000055000000500000000000000000000000000000000000000000100001011000010010010101020001000000000001000005555555555555000
ddd65dddddd65dddddddd22200000000000000000000000000000000000000000100001011000010010010000000001000000000001000000555555555555000
d5d65d5dd1d555550050002000000000000000000000000000000000000000000100001001000010010010101010001000000000001000000005555555555500
ddd65dddddd65ddd0505050200000000000000000000000000000000000000000100001111000010010010000000001000000000101000000005555555555550
d5d65d5dd5d55d2d5000500000000000000000000000000000000000000000000100100000010010010010101010001000000000001111100000555555055555
ddd65dddddd65ddddddddddd00000000000000000000000000000000000000000101110000111010010010000000001001111111111000000000550555505555
00000000055050500000000000000000000000000000000000000000000000000100100000010010010001111100001000000000010000000000055055505555
00000000005050500000000000000000000000000000000000000000000000000010000000000100001000000000010000000000010000000000055050050500
000000000000d0000000000000000000000000000000000000000000000000000001111111111000000111111111100000000000010000000000055500000000
22265ddd200000020dddddd000000000000000000000000000000000000000000001111111111000000000111100000010010000000000000000055550000000
25265d5dd252222dd050005d00000000000000000000000000000000000000000010000000000100000011001011000001001000000000000000555050000000
22d65dddd000000d0505050500000000000000000000000000000000000000000100000000000010000100000000100000100100000000000000505555000000
25d65d5d500000055000500000000000000000000000000000000000000000000100011111100010001000011000010000010100000000000000555055000550
2dd65dddd000000d0ddddddd00000000000000000000000000000000000000000100100000010010010001100110001000010100000000000000550005005550
00000000dd5252ddd000000000000000000000000000000000000000000000000100100000010010010010050001001000010010000000005500505505055550
00000000d000000d0000000000000000000000000000000000000000000000000100100010010010100010005001000100001001000000005555555555505500
00000000500000050000000000000000000000000000000000000000000000000100100001010010110100500500100121100100100000005555555555555000
00000000000000000000000000000000000000000000000000000000000000000100100001010010100100050000101100010010010000000555555555555000
00000000000000000000000000000000000000000000000000000000000000000100100010010010100010005001000151001001001000000005555555555500
00000000000000000000000000000000000000000000000000000000000000000100100000010010010010000001001000100100100111130005555555555550
00000000000000000000000000000000000000000000000000000000000000000100100000010010010001100110001000010010010000000000555555550555
00000000000000000000000000000000000000000000000000000000000000000100011111100010001000011000010000001001001111100000555505555055
00000000000000000000000000000000000000000000000000000000000000000100000020200010000100000000100000000100100000000000505550555500
00000000000000000000000000000000000000000000000000000000000000000010000000200100000011010011000000000010100000000000550555055500
00000000000000000000000000000000000000000000000000000000000000000001111111111000000000111100000000000010100000000000550550000000
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
08888880888008888888880088888888888888008880088808888880088800000088880000888800888008880088880088888888888888008888880088800888
88888888880000888800088888888888880008888800008808088080088000000880088008888880880000880888888088888888880008808888888088800088
88000008880000888800008888000008880000888800888000088000088000008800008888800888880000888880088880088008880008808800088888880088
08888800880000888800088888880000880008888888800000088000088000008800008888000000888888888800008800088000888888808800008888888088
00888888880000888888880088080000888888008888800000088000088000008888888888000000880000888800008800088000880008888800008888088888
80000088880000888800000088000008880088808800888000088000088000808800008888800888880000888880088800088000880000888800088888008888
88888880088008808800000088888888880000888800008808088080088888808800008808888880880000880888888000088000880008888888888088000888
08888800008888008880000088888888888008888880088808888880088888808880088800888800888008880088880000088000888888808888880088800888
88800888888008880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88000088880000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88800888880880880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888880880880880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888800880880880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088000088888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088000808008080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088000880000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001040500000000000000000000000000010101000000000000000000000000000104010000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000004100000000000000000000410000000000410000000000000000000000000000000041000000000000000000000000000000004100000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000040400000004100000040400000000000410000000000410040400000004050000050515000000041000000005040500000505000000000414141000000000050504000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000040500000005051504250505000005050004050424052000041414000000000000000000000000000000041000000000000000000000000000000414141000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000004100000000000000000000410000004141414100000040400000004100000000504040404050000000004100000050005050425042505150005000000000000000000000000000000000000000000000000000000000000000000000
0000000000000041000000000000000000000000000000000000000000624000000000004100000000515000000000410000414141414100000000000000004100000000000000000000000000004140505000000000410041000000000050504000000000000000000000000000000000000000000000000000000000000000
0000000000624042505050400000000000000000000000000000000000000000000000004100000000000000000000410000414141414141000000000000004140404050000000000050404040404100000000000000410041000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000041700000000000000000000000000000000000000000004040500000006100504050000000000000410000000000000000404000000000004100000000000000000000000000004100000040500000410041000000605000000000000000000000000000000000000000000000000000000000000000000000
0070707070707041707070707070707000000000000000000000000000000000000000004100000000000000000000410000400000005000000000000000004100000040405000005040404000004100000000000000410041000000000000000000000000000000000000000000000000000000000000000000000000000000
0070707070707061707070707070707000000000000000000000000000000000000000004100000000410000000000414040000000000040400000504040004100000000000000000000000000004100000000000000410041000000000000000000000000000000000000000000000000000000000000000000000000000000
0070707070707041707070707070707000000000000000000000000000000000000050404040400000410000000000410000000000000000006240000000004140500000000000000000000050404100515000004100505050500061000050504000000000000000000000000000000000000000000000000000000000000000
4040405260624040405051505040404040400000000000000000000000000000000000000000005140410000000000410000404000000000000000000000004100000000005040405000000000004100000000004100000000000041000000000000000000000000000000000000000000000000000000000000000000000000
0070707070707070707070707070707000000000000000000000000000005040510000000040400000410000000000410000000000000000000000000000004100000000000000000000000000004100000040504250000000005042505200000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000000000000000000000000000410000000000410000000050505040000000000000004100404050000000000000405000004100005000004100000000000041000050000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000000000000050405000000000410000000000410000000000000000000000000000004100000000000000000000000000004100000000004100000000000041000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404040404040000000000000000000000000000000000000000000404000000000410000000000000000000000000000004100000040405000504000000050404100400000004100000000000041000000404000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000005040510000410000404000000000000050515000000000000000504040500000004100000000000000000000504000004100004040004100000000000041006240000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000000041000000410000000000000000000000000000000000000000000000000000004140500000000000000000000000004100000000006100000000000041000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000000041000040424050000000000000000000000000000000000000000000000000004100000000404040625261000000505100000000006050000000005050000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000404042526000410000000000000000000041000000604040404050000000410000004100000000000000000041000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000000041000000410000000000004100000041000000000000000000000000410000004100000040404040405042504000000000000000000000505050500000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000000041000000420000000000004100000041504051000000000000504050410000005000000000000000000041000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000000041000000000000000040504100000041000000620000000051000000410000000040500000000000000041000000000000004100005050000000005050000041000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000000041000000004100000000004100000041000000000000000000000000414050000041000050400000000041000040400000004100000000000000000000000041000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000000041000000004100000000004100000041004100000040400000000000410000000041000000000000000041000000000000404250510000000000000000505042505000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000041404062404240500000004100000041004100000000000000000000410000000041504040404040404040400000000000004100000000000000000000000041000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000041000000004100000000004100000040404100000000000000000050404040000041000000000000000000000000000000004100004050605050505040000041000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000404042405000004100000050404240400000004140500000410000504000000000000041000000000041000000004050000000004100000000000000000000000041000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000041000000004100000000004100000000004100000000410000000000000000000041000000000041000000000000000000404100000000000000000000000041505100000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000041000000004100000000004100000000004100504040424040404050000000004040405240405042504000000000504000004150500000000000000000405041000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000041000000004100000000004100000040004100000000410000000000405000000000000000000041000000005040000000004100004000004100000040000041000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000041000000004100000000004100000000004100000000410000000000000000000000000000000041000000000000000000004100000000004100000000000041000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000040404040405050514250404040404040404040404040404050425040404040404040404040404040405042514040406240404040404040404040504250404062404040404000000000000000000000000000000000000000000000000000000000000000
__sfx__
00020000105741c561375000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500002467007371033510233101320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400003a6103a6013f6002360034600333003330018600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300003c65113460123600e46004450024401260004300033000230002300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000174101400053000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001b371123510833103341053410a3510a201013000000000000000000000000000000000000000000293002b3002d3002f300313003130032300333000000000000000000000000000000000000000000
000300001c4601133000000294601d330000003546029340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000444000700044401870004440044400444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000300
000800000b150130000b1503f2070b1500b1500b15000000000001b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01c800002761627100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110002007365073650a3650c36507365073650c3650e36507365073650e3650f36507365073650f3651136507365073650a3650c36507365073650c3650e36507365073650e3650f36507365073650f36511365
0110002007455074550a4550c45507455074550c4550e45507455074550e4550f45507455074550f4551145507455074550a4550c45507455074550c4550e45507455074550e4550f45507455074550f45511455
0110000013343133433e725053052765500000133433e72513343000003e725276032765300000000003e72513343133433e725053052765500000133533e72513343000001f3032760327653000003e72527653
01100020133431334305305053052765500000133431360013343000001f3032760327653000000000000000133431334305305053052765500000133531360013343000001f3032760327653000002760327653
011000043f70016600377223771500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001334313343377223771527655000001334337715133431334337722377152765300000377223771513343133433772237715276550000013343377151334313343377223771527655276453771527655
0110000013010130101301013010130101301037722130101301716027180271d0371304716057180771d0771305716057180471d0371302716017377221d0171301716017180171d01713010130103772237715
0110000013010130101301013010130101301037722377151301716027180271d0371304716057180771d0771305716057180471d0371304716057180571d0671306716077180771d0771307616076180761d076
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
011000001377313303306153061513773000003061530615137730000030615306151377300000306153061513773133033061530615137730000030615306151377300000306153061513773000003061521645
011000002e5262b5162e51630516226452b5162e506305062e5062b5062e50630506226451f5062250624506135061f5062250624506226451f5062250624506135061f5062250624506226451f5062250624506
011000081377313303306153f6051377300000306153f60513773000003f6153f61513773000003f6153f61513773133033f6153f61513773000003f6153f61513773000003f6153f61313773000003f61521645
001000002e5262b5162e51630516226452b5162e506305060c6000c6000c6140c620226450c6000c6140f620135061f5060f6140f630226451f5060f61410630135061f5061161411630226451f5061161414630
00100000135061f5061161411630226051f50611614146300c6000c6001461414630226050c6001461416640135061f5061662416640226051f5061762419640135061f5061963419640226051f506196341b640
001000003463025620216101c61022605376061e614176300c6000c6001661411630226050c6000d61409630135061f5060a61408620226051f5060661404620135061f5060261402610226051f5060161401615
001000003a6002860024614216302260537606206141c6200c6000c6001961415610226050c600106140c610135061f5060a61408610226051f5060661404600135061f5060260402600226051f5060160401605
001000003a600286000a6140c610226053760610614136100c6000c6001661419620226050c6001d61420620135061f50623614266202260528606286142c620135061f5060260402600226051f5060160401605
011000001f1101d100221001f1101a1001a1001f1101a1001f1101d100221001f1101a1001a1001f1101a1001f1101d100221001f1101a1001a1001f1101a1001f1101d100221001f1101a1001a1001f1101a100
011000001f1101d100221001f1101a1001a1001f1101a1001f1101d100221001f1101a1001a1001f1101a1001f1101d100221001f1101a1001a1001f1101a1001f11016205221152211522125221252213522155
0110000024546225461f5361353622645225261f5161351624516225161f5161351622645225161f5161351624516225161f5161351622645225161f5161351624516225161f5161351622645225161f51613516
0110000000000000000a3240c43000000000000c3240e43000000000000e3240f43000000000000f3241143000000000000a3240c43000000000000c3240e43000000000000e3240f43000000000000f32411430
0110000024546225461f5361353624526225261f5161351624516225161f5161351624516225161f5161351624516225161f5161351624500225001f5001350024506225061f5061350624506225061f50613506
0110000024546225461f5361353622526225261f5161351624516225161f5161351622516225161f5161351624516225161f5161351622516225161f5161351624516225161f5161351622516225161f51613516
0110000024516225161f5161351622516225161f5161351624516225161f5161351622516225161f5161351624516225161f5161351622516225161f5161351624516225161f5161351622516225161f51613516
0110000000000000000a3240c43000000000000c3240e43000000000000e3140f42000000000000f3141142000000000000a3140c42000000000000c3140e42000000000000e3140f40000000000000f31411400
0110000007405074050a4050c40507415074150c4150e41507415074150e4150f41507425074250f4251142507425074250a4250c42507435074350c4350e43507445074450e4450f44507455074550f45511455
011000001352213522135221352213522135221352213522135221352213522135221352213522135221352213522135221352213522135221352213522135221352213522135221352213522135221352213522
0110000007455074550a4550c45507455074550c4550e45507455074550e4550f45507455074550f4551145507455074550a4550c45507455074550c4550e45507455074550e4550f45507455074550f45511455
0110000007455074550a4550c45507455074550c4550e45507455074550e4550f45507455074550f4551145507405074050a4050c40507405074050c4050e40507405074050e4050f40507405074050f40511405
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00 2220291a
00 2d632a27
00 2d236b27
00 2d232c27
00 2d232b27
00 2d233125
00 2d237125
00 2d233125
00 2d637164
00 2d231925
00 2e231925
00 2d232f25
00 2e231925
00 2d232f25
00 2e231925
00 2d302f25
00 2e301925
00 2d300d25
00 2e300c25
00 23300c32
00 23304c33
00 23344c33
00 23744c73
00 23354c73
00 230b4c73
00 230b362a
00 230b362c
00 230b366c
00 630b366c
02 6338366c
00 00000000
00 00000000
00 00000000
00 2d230524
02 2d231925
00 00000000
03 23304c33
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 07084040
00 09484040

