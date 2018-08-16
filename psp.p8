-- pico space program
-- by nothke

groundy = 120

cam = {}
parts = {}
focuspart = {}
engineparticles = {}

dt = 1/30
gravity = 0.1

function _init()
 part = initpart()
 add(parts, part)

 focuspart = part
end

function initpart()
 _forward = {}
 _forward.x = sin(0.125)
 _forward.y = cos(0.125)

 _right = {}
 _right.x = sin(0.375)
 _right.y = cos(0.375)

 part = { 
  x = 64, -- position x
  y = 64, -- position y
  v = {x = 0, y = 0}, -- velocity
  f = _forward, -- forward vector
  r = _right, -- right vector
  a = 0, -- angle
  com = {x = 0, y = 0} } -- center of mass
 return part
end

-- inputs
in_thrt = 0
in_rot = 0

function _update()
 -- inputs
 if (btn(0)) then in_rot = -1
 elseif (btn(1)) then in_rot = 1
 else in_rot = 0 end

 if btn(2) then 
  in_thrt = 1 
  else in_thrt = 0
 end

 -- physics

 for i=1,#parts,1 do
  part = parts[i]

  parts[i].a += in_rot * 0.03
  a = parts[i].a
  
  parts[i].f.x = sin(a + 0.125)
  parts[i].f.y = cos(a + 0.125)
  
  parts[i].r.x = sin(a + 0.375)
  parts[i].r.y = cos(a + 0.375) 

  -- add gravity
  parts[i].v.y += gravity

  -- step velocity
  parts[i].x += parts[i].v.x
  parts[i].y += parts[i].v.y

  parts[i].v.x += parts[i].f.x * in_thrt * 0.2
  parts[i].v.y += parts[i].f.y * in_thrt * 0.2

  collided = part.y > groundy - 2
  boomvelocity = part.v.y > 3

  -- ground collision
  if collided then
   if boomvelocity then
    del(parts, part)
    boom(pos)
    goto outaloop
   end

   parts[i].v.y = 0
   parts[i].v.y = -gravity
   parts[i].v.x *= 0.9 -- friction

   parts[i].y = groundy - 2
  end

  -- particles
  particlespeedmult = 5

  if in_thrt > 0 then
   ppos = {x = part.x, y = part.y }
   pvel = {
    x = part.v.x - part.f.x * particlespeedmult, 
    y = part.v.y - part.f.y * particlespeedmult}
   addparticle(engineparticles, 4, ppos, pvel, 1, 10, 20)
  end

  ::outaloop::
 end

 updateparticlesystem(engineparticles)
end

function boom(pos)
 v = { x =0, y = -3 }
 addparticle(engineparticles, 100, pos, v, 6, 10, 20)
end

function _draw()
 cls()

 drawparticlesline(engineparticles, 5)
 drawparticlescolor(engineparticles, 6)

 for i=1,#parts,1 do
  drawpart(parts[i])
  --print(parts[i].v.y, 10, 10, 10)
 end

 cam.x = focuspart.x - 64
 cam.y = focuspart.y - 64

 -- ground
 line(cam.x -1000, groundy, cam.x + 10000, groundy, 1)

 camera(cam.x,cam.y)
end

function drawpart(part)
 carwdt = 4

 v1 = {}
 v1.x = part.x + sin(part.a) * carwdt
 v1.y = part.y + cos(part.a) * carwdt

 v2 = {}
 v2.x = part.x + sin(part.a + 0.25) * carwdt
 v2.y = part.y + cos(part.a + 0.25) * carwdt

 v3 = {}
 v3.x = part.x + sin(part.a + 0.5) * carwdt
 v3.y = part.y + cos(part.a + 0.5) * carwdt

 v4 = {}
 v4.x = part.x + sin(part.a + 0.75) * carwdt
 v4.y = part.y + cos(part.a + 0.75) * carwdt

 col = 7
 vline(v1, v2, col)
 vline(v2, v3, col)
 vline(v3, v4, col)
 vline(v4, v1, col)

 pos = { x = part.x, y = part.y }
 forward = { 
  x = part.x + part.f.x * 10, 
  y = part.y + part.f.y * 10 }
 right = { 
  x = part.x + part.r.x * 10, 
  y = part.y + part.r.y * 10 }
 vline(pos, forward, 12)
 vline(pos, right, 8)
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

    particle.pos.x += particle.velocity.x
    particle.pos.y += particle.velocity.y

    particle.lifetime-=1 * 0.5 -- temp convert to seconds or smth

    if particle.pos.y > groundy then
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
 v.x = v.x/l
 v.y = v.y/l
 return v
end

function dot(v1, v2)
 return v1.x * v2.x + v1.y * v2.y
end

function length(v)
 return sqrt(v.x*v.x + v.y*v.y)
end

function vpset(v, col)
 pset(v.x, v.y, col)
end

function vline(v0, v1, col)
 line(v0.x,v0.y,v1.x,v1.y,col)
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