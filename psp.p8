-- pico space program
-- by nothke

doground = true
groundy = 120

cam = {}
crafts = {}
focuscraft = {}
engineparticles = {}

lines_pod = {
 {x=-4, y=-4}, {x= 0, y= 4},
 {x= 0, y= 4}, {x= 4, y=-4},
 {x= 4, y=-4}, {x=-4, y=-4},
}

lines_tank = {
 {x=-4, y=-4}, {x=-4, y= 4},
 {x=-4, y= 4}, {x= 4, y= 4},
 {x= 4, y= 4}, {x= 4, y=-4},
 {x= 4, y=-4}, {x=-4, y=-4},
}

lines_bell = {
 {x=-3, y=-4}, {x= 4, y= 4},
 {x= 4, y= 4}, {x=-4, y= 4},
 {x=-4, y= 4}, {x= 3, y=-4},
 {x= 3, y=-4}, {x=-3, y=-4},
}

dt = 1/30
gravity = 0.1

particlespeedmult = 5

function _init()
 poke(0x5f2d, 1)

 craft = initcraft()

 part = initpart()
 part.lines = lines_bell
 part.isthruster = true
 addpart(craft, part, {x = 0, y = -12})

 part = initpart()
 part.lines = lines_tank
 addpart(craft, part, {x = 0, y = -4})

  part = initpart()
 part.lines = lines_tank
 addpart(craft, part, {x = 0, y = 4})

 part = initpart()
 part.lines = lines_pod
 addpart(craft, part, {x = 0, y = 12})

 focuscraft = craft
end

function initcraft()
 _forward = {}
 _forward.x = sin(0.125)
 _forward.y = cos(0.125)

 _right = {}
 _right.x = sin(0.375)
 _right.y = cos(0.375)

 craft = {
 x = 64, -- position x
 y = 118, -- position y
 v = {x = 0, y = 0}, -- velocity
 f = _forward, -- forward vector
 r = _right, -- right vector
 a = 0.375, -- angle
 av = 0, -- angular velocity
 parts = {},
 com = {x = 0, y = 0} } -- center of mass

 add(crafts, craft)
 return craft
end

function addpart(craft, part, lpos)
 add(craft.parts, part)
 part.x = lpos.x
 part.y = lpos.y
end

function initpart()
 _forward = {x = sin(0.125), y = cos(0.125)}
 _right = {x = sin(0.375), y = cos(0.375)}

 part = { 
  lines = lines_tank,
  x = 0, -- position x
  y = 0, -- position y
  f = _forward, -- forward vector
  r = _right, -- right vector
  a = 0.375, -- angle
  com = {x = 0, y = 0}, -- center of mass
  isthruster = false}
 return part
end

-- inputs
in_thrt = 0
in_rot = 0
in_x = false

function _update()
 -- inputs
 if (btn(0)) then in_rot = -1
 elseif (btn(1)) then in_rot = 1
 else in_rot = 0 end

 if btn(2) then 
  in_thrt = 1 
  else in_thrt = 0
 end

 in_x = btn(4)

 -- physics

 -- temporary, just to make controlling easier
 propoangulardrag = 1

 for i=1,#crafts,1 do
  craft = crafts[i]

  craft.av += in_rot * 0.003
  a = craft.a
  
  craft.f.x = sin(a + 0.125)
  craft.f.y = cos(a + 0.125)
  
  craft.r.x = sin(a + 0.375)
  craft.r.y = cos(a + 0.375) 

  -- add gravity
  craft.v.y += gravity

  -- step velocity
  craft.x += craft.v.x
  craft.y += craft.v.y

  craft.v.x += craft.f.x * in_thrt * 0.2
  craft.v.y += craft.f.y * in_thrt * 0.2

  -- step angular velocity
  craft.a += craft.av
  craft.av *= propoangulardrag

  collided = craft.y > groundy - 2
  boomvelocity = craft.v.y > 3

  -- ground collision
  if doground and collided then
   if boomvelocity then
    del(crafts, craft)
    boom(pos)
    goto outaloop
   end

   craft.v.y = 0
   craft.v.y = -gravity
   craft.v.x *= 0.9 -- friction

   craft.y = groundy - 2
  end

  -- particles
  for i=1,#craft.parts,1 do
   part = craft.parts[i]

   if part.isthruster then
    if in_thrt > 0 then
     ppos = localtoworldpartpos(craft, part, {x = 0, y = 0})
     pvel = {
     x = craft.v.x - craft.f.x * particlespeedmult, 
     y = craft.v.y - craft.f.y * particlespeedmult}
     addparticle(engineparticles, 4, ppos, pvel, 1, 10, 20)
    end
   end
  end

  ::outaloop::
 end

 updateparticlesystem(engineparticles)

 cam.x = focuscraft.x - 64
 cam.y = focuscraft.y - 64
 cam.v = { x = focuscraft.v.x, y = focuscraft.v.y }

 --cam.x = 0
 --cam.y = 0
end

function localtoworldpartpos(craft, part, lpos)
 l = { 
  x = part.x + lpos.x,
  y = part.y + lpos.y }

 return localtoworldpos(craft, l)
end

function localtoworldpos(transform, lpos)
 lpos = {
  x = transform.x + transform.r.x * lpos.x + transform.f.x * lpos.y,
  y = transform.y + transform.r.y * lpos.x + transform.f.y * lpos.y
 }

 return lpos
end

function worldtolocalpos(transform, pos)
 local diff = { x = transform.x - pos.x, y = transform.y - pos.y }
 local _x = -dot(diff, transform.r)
 local _y = -dot(diff, transform.f)
 return {x = _x, y = _y}
end

-- adds force at position calculating torque
function addforce(craft, pos, fdir)
 diff = { x = craft.x - pos.x, y = craft.y - pos.y }
 r = length(diff)
 ndiff = normalize(diff)

 directforce = dot(ndiff, fdir)
 radialforce = dot(right(ndiff), fdir) * 0.5
 
 -- t = f * r 
 craft.av += radialforce * r
 craft.v.x += directforce * ndiff.x * 100
 craft.v.y += directforce * ndiff.y * 100

 -- debug
 vray(pos, fdir, 10000, 9)
 vray(pos, diff, 1, 3)
end

function boom(pos)
 v = { x =0, y = -3 }
 addparticle(engineparticles, 100, pos, v, 6, 10, 20)
end

lastclicked = false
lclickstartpos = {}
prevmouse = {}

function _draw()
 cls()

 camera(cam.x,cam.y)

 drawparticlesline(engineparticles, 5)
 drawparticlescolor(engineparticles, 6)

 for i=1,#crafts,1 do
  drawcraft(crafts[i])
   --print(parts[i].v.y, 10, 10, 10)
 end

 -- ground
 if doground then
  line(cam.x -1000, groundy, cam.x + 10000, groundy, 1)
 end

 vray({x = focuscraft.x, y = focuscraft.y}, focuscraft.v, 5, 10)

 -- temp

 -- mouse
 mouse = {x = stat(32), y = stat(33)}
 wmouse = {x = cam.x + mouse.x, y = cam.y + mouse.y}
 click = stat(34) == 1

 spr(0,wmouse.x - 4,wmouse.y - 4)
 --pset(mousex, mousey, 10)

 if click then
  if not lastclicked then
   lclickstartpos = worldtolocalpos(focuscraft, wmouse)
  end

  --fpos = { x = focuspart.x + 7, y = focuspart.y }
  fpos = { x = 7, y = 3 }
  --fpos = localtoworldpos(focuspart, fpos)
  fpos = localtoworldpos(focuscraft, lclickstartpos)

  --fdir = { x = 0.001, y = -0.002 }
  fdir = {
   x = -(fpos.x - wmouse.x) * 0.0001, 
   y = -(fpos.y - wmouse.y) * 0.0001 }

  addforce(focuscraft, fpos, fdir)
 end

 prevmouse = {x = wmouse.x, y = wmouse.y}
 lastclicked = click

 -- ui
 h = flr(-(focuscraft.y - groundy))
 hstr = ""..h
 txtx = 64+15-#hstr*4
 rectfill(cam.x+64-14,cam.y,cam.x+64+14,cam.y+10,6)
 print(h, cam.x+txtx, cam.y+1, 5)
end

function drawcraft(craft)
 for i=1,#craft.parts,1 do
  part = craft.parts[i]

  col = 7

  for i=1,#part.lines,2 do
   l0 = {x = part.x + part.lines[i].x,   y = part.y + part.lines[i].y}
   l1 = {x = part.x + part.lines[i+1].x, y = part.y + part.lines[i+1].y}

   v0 = localtoworldpos(craft, l0)
   v1 = localtoworldpos(craft, l1)

   vline(v0, v1, col)
  end
 end
end

function drawpart(part)

 col = 7

 for i=1,#part.lines,2 do
  v0 = localtoworldpos(part, part.lines[i])
  v1 = localtoworldpos(part, part.lines[i+1])

  vline(v0, v1, col)
 end

 --[[
 pos = { x = part.x, y = part.y }
 _forward = { 
  x = part.x + part.f.x * 10, 
  y = part.y + part.f.y * 10 }
 _right = { 
  x = part.x + part.r.x * 10, 
  y = part.y + part.r.y * 10 }
 vline(pos, _forward, 12)
 vline(pos, _right, 8)
 ]]
end

-- particles

function addparticle(_ps, _count, _pos, _velo, randomdir, minlife, maxlife)

 for i=0,_count do
  randmult = 0.5 + rnd(100) / 100
 
  if randomdir ~= 0 then
  -- random vector
   randx = (-1 + rnd(2)) * randomdir
   randy = (-1 + rnd(2)) * randomdir
  
   velox = (_velo.x + randx) * randmult
   veloy = (_velo.y + randy) * randmult
  else
   velox = _velo.x * randmult
   veloy = _velo.y * randmult
  end
 
  randlife = flr(rnd(maxlife - minlife))
  flp = false
  if randlife % 2 == 0 then flp = true end
 
  particle = { 
   pos = {x = _pos.x, y = _pos.y }, 
   lastpos = {x = _pos.x, y = _pos.y },
   velocity = {x = velox, y = veloy},
   startlife = minlife + randlife,
   lifetime = minlife + randlife,
   flp = flp} 
 
  add(_ps, particle)
 end
end

function updateparticlesystem(ps)
 for i=#ps,1,-1 do
  particle = ps[i]

  if particle.lifetime < 1 then
   v = ps[i]
   del(ps, v)
  else
    vmult = 1 - (0.5 * dt)  -- magic

    particle.velocity.x *= vmult
    particle.velocity.y *= vmult

    particle.velocity.y += gravity

    particle.lastpos.x = particle.pos.x
    particle.lastpos.y = particle.pos.y

    particle.pos.x += particle.velocity.x - cam.v.x
    particle.pos.y += particle.velocity.y - cam.v.y

    particle.lifetime-=1 * 0.5 -- temp convert to seconds or smth

    if doground and particle.pos.y > groundy then
     randbounce = 0.2 + rnd(1)
     particle.velocity.y = -particle.velocity.y * randbounce * 0.3
     particle.pos.y = groundy
    end
  end
 end
end

function drawparticlesystem(_ps)
 --if ps ~= nil then

  for i=#_ps,1,-1 do
   particle = _ps[i]
 
   if particle.lifetime > 10 then
    --line(lastx, lasty, particle.pos.x, particle.pos.y, 9) else --vpset(particle.pos, 0)
    vpset(particle.pos, 0)
    --pset(particle.pos.x, particle.pos.y + 1, 9)
    else
    vpset(particle.pos, 4)
   end
  end
 --end
end

function drawparticlescolor(_ps, _col)
  for i=#_ps,1,-1 do
   particle = _ps[i]
   vpset(particle.pos, _col)
  end
end

function drawparticlesline(_ps, _col)
  for i=#_ps,1,-1 do
   particle = _ps[i]
   vline(particle.pos, particle.lastpos, _col)
  end
end

function drawparticlesystemsprite(ps, spritestart, spriteend)
 diff = spriteend - spritestart
 
 for i=1,#ps,1 do
 --for i=#ps,1,-1 do
  particle = ps[i]

  lifemult = particle.lifetime / particle.startlife

  spritenum = flr(spriteend - lifemult * diff)


  --sspr(spritenum, particle.pos.x - 4, particle.pos.y - 4)
  y = 56
  x = flr(diff - lifemult * diff) * 8
  sspr(x,y,8,8,particle.pos.x - 8,particle.pos.y - 8,16,16, particle.flp)
 end
end

-- vector stuff

function normalize(v)
 l = length(v)
 nv = {
  x = v.x/l,
  y = v.y/l }
 return nv
end

function dot(v1, v2)
 return v1.x * v2.x + v1.y * v2.y
end

function length(v)
 return sqrt(v.x*v.x + v.y*v.y)
end

function right(v)
 nv = { x = v.y, y=-v.x }
 return nv
end

function vpset(v, col)
 pset(v.x, v.y, col)
end

function vline(v0, v1, col)
 line(v0.x,v0.y,v1.x,v1.y,col)
end

function vray(v0, v1, scale, col)
 line(v0.x,v0.y,
  v0.x + v1.x * scale,
  v0.y + v1.y * scale,
  col)
end

-- math helpers

function lerp(tar,pos,perc)
 return (1-perc)*tar + perc*pos;
end

function clamp(min, max, value)
 if (value < min) value = min
 if (value > max) value = max

 return value
end

-- sprite rotation
function rspr(sx,sy,x,y,a,w)
 local ca,sa=cos(a),sin(a)
 local srcx,srcy,addr,pixel_pair
 local ddx0,ddy0=ca,sa
 local mask=shl(0xfff8,(w-1))
 w*=4
 ca*=w-0.5
 sa*=w-0.5
 local dx0,dy0=sa-ca+w,-ca-sa+w
 w=2*w-1
 for ix=0,w do
  srcx,srcy=dx0,dy0
  for iy=0,w do
   if band(bor(srcx,srcy),mask)==0 then
    local c=sget(sx+srcx,sy+srcy)
    sset(x+ix,y+iy,c)
   else
    sset(x+ix,y+iy,rspr_clear_col)
   end
   srcx-=ddy0
   srcy+=ddx0
  end
  dx0+=ddx0
  dy0+=ddy0
 end
end

-- print with shadow
function printshd(text, x, y, col)
 print(text, x+1, y+1, 0)
 print(text, x, y, col)
end