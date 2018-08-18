-- pico space program
-- by nothke

-- settings:
-- - physics
doground = true
groundy = 120

gravity = 0.05
propoangulardrag = 0.1

-- - graphical
particlespeedmult = 5
drawui = false

debuglines = false

-- part graphics
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

lines_thin_tank = {
 {x=-2, y=-4}, {x=-2, y= 4},
 {x=-2, y= 4}, {x= 2, y= 4},
 {x= 2, y= 4}, {x= 2, y=-4},
 {x= 2, y=-4}, {x=-2, y=-4},
}

lines_thicc_tank = {
 {x=-8, y=-4}, {x=-8, y= 4},
 {x=-8, y= 4}, {x= 8, y= 4},
 {x= 8, y= 4}, {x= 8, y=-4},
 {x= 8, y=-4}, {x=-8, y=-4},
}

lines_thin_cone = {
 {x=-2, y=-4}, {x= 2, y= 4},
 {x= 2, y= 4}, {x= 2, y=-4},
 {x= 2, y=-4}, {x=-2, y=-4},
}

lines_bell = {
 {x=-3, y=-4}, {x= 4, y= 4},
 {x= 4, y= 4}, {x=-4, y= 4},
 {x=-4, y= 4}, {x= 3, y=-4},
 {x= 3, y=-4}, {x=-3, y=-4},
}

lines_rcs = {
 {x=-1, y=-1}, {x= 1, y= 1},
 {x= 1, y= 1}, {x=-1, y= 1},
 {x=-1, y= 1}, {x= 1, y=-1},
 {x= 1, y=-1}, {x=-1, y=-1},
}

-- part data
part_standard_tank = {
 name = "fuel tank",
 lines = lines_tank,
 fuel = 10,
}

part_thin_tank = {
 name = "thin tank",
 lines = lines_thin_tank,
 fuel = 5,
}

part_thicc_tank = {
 name = "thicc tank",
 lines = lines_thicc_tank,
 fuel = 20,
}

part_thin_cone = {
 name = "thin cone",
 lines = lines_thin_cone,
 fuel = 2,
}

part_engine = {
 name = "rocket engine",
 lines = lines_bell,
 isthruster = true,
 force = 1
}

part_pod = {
 name = "crew pod",
 lines = lines_pod
}

part_rcs = {
 name = "rcs thruster",
 lines = lines_rcs
}

partlib = {
 part_standard_tank,
 part_engine,
 part_pod,
 part_rcs,
 part_thin_cone,
 part_thin_tank,
 part_thicc_tank
}

-- dont change
dt = 1/30 -- deltatime

cam = {x=0, y=0}
crafts = {}
focuscraft = {}
engineparticles = {}

addforces = {}

-- 0 build mode
-- 1 fly mode
mode = 0

symmetry = true

mouse = {}
wmouse = {}
click = false
rclick = false

function _init()
 poke(0x5f2d, 1)


 craft = initcraft()

 part = newpart(part_pod)
 addpart(craft, part, {x = 0, y = 12})

--[[
 part = newpart(part_engine)
 addpart(craft, part, {x = 0, y = -12})

 part = newpart(part_standard_tank)
 addpart(craft, part, {x = 0, y = -4})

 part = newpart(part_standard_tank)
 addpart(craft, part, {x = 0, y = 4})

 part = newpart(part_standard_tank)
 addpart(craft, part, {x = 8, y = 4})

 part = newpart(part_standard_tank)
 addpart(craft, part, {x = 16, y = 4})

 part = newpart(part_standard_tank)
 addpart(craft, part, {x = 24, y = 4})

 part = newpart(part_engine)
 addpart(craft, part, {x = 24, y = -4})
]]


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
 com = {x = 0, y = 0}, -- center of mass

 numthrusters = 0,
 numtanks = 0
 } 

 add(crafts, craft)
 return craft
end

function addpart(craft, part, lpos)
 add(craft.parts, part)
 part.x = lpos.x
 part.y = lpos.y

 if (part.isthruster) craft.numthrusters += 1
 if (part.fuel ~= nil) craft.numtanks += 1
end

function removepart(craft, part)
 if (part.isthruster) craft.numthrusters -= 1
 if (part.fuel ~= nil) craft.numtanks -= 1

 del(craft.parts, part)
end

function newpart(pt)
 part = initpart()

 part.lines = pt.lines
 if (pt.isthruster ~= nil) part.isthruster = pt.isthruster
 if (pt.fuel ~= nil ) part.fuel = pt.fuel
 return part
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

 -- mouse
 mouse = {x = stat(32), y = stat(33)}
 wmouse = {x = cam.x + mouse.x, y = cam.y + mouse.y}
 click = stat(34) == 1
 rclick = stat(34) == 2

 -- physics
 if mode ~= 0 then
  for i=1,#crafts,1 do
   craft = crafts[i]
 
   craft.av += in_rot * 0.003
   a = craft.a

   updatecraftvectors(craft) 
 
   -- add gravity
   craft.v.y += gravity
 
   -- step velocity
   craft.x += craft.v.x
   craft.y += craft.v.y
 
   -- process thrusters
   if in_thrt > 0 then
    for p=1,#craft.parts do
     if craft.parts[p].isthruster then
      local part = craft.parts[p]
      local ppos = local2worldpartpos(craft, part)
      local f = {x=craft.f.x*0.001,y=craft.f.y*0.001} -- temp
      addforce(craft, ppos, f)
     end
    end
   end
 
   --craft.v.x += craft.f.x * in_thrt * 0.2
   --craft.v.y += craft.f.y * in_thrt * 0.2
 
   -- step angular velocity
   craft.a += craft.av
   craft.av *= 1 - propoangulardrag
 
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
      ppos = local2worldpartpos(craft, part)
      pvel = {
      x = craft.v.x - craft.f.x * particlespeedmult, 
      y = craft.v.y - craft.f.y * particlespeedmult}

      local numparticles = 10 / craft.numthrusters
      if (numparticles < 1) numparticles = 1
      addparticle(engineparticles, numparticles, ppos, pvel, 3, 10, 20)
     end
    end
   end
 
   ::outaloop::
  end
 
  updateparticlesystem(engineparticles)
 
  cam.x = focuscraft.x - 64
  cam.y = focuscraft.y - 64
  cam.v = { x = focuscraft.v.x, y = focuscraft.v.y }
 else -- mode == 0 build mode
  resetcraft(focuscraft)
 end

 --cam.x = 0
 --cam.y = 0
end

function resetcraft(craft)
  craft.x = 64
  craft.y = 64
  craft.a = 0.375
  craft.v.x = 0
  craft.v.y = 0
  craft.av = 0
  updatecraftvectors(craft)
end

function local2worldpartposoffset(craft, part, lpos)
 l = { x = part.x + lpos.x, y = part.y + lpos.y }
 return local2worldpos(craft, l)
end

function local2worldpartpos(craft, part)
 l = { x = part.x, y = part.y }
 return local2worldpos(craft, l)
end

function local2worldpos(transform, lpos)
 lpos = {
  x = transform.x + transform.r.x * lpos.x + transform.f.x * lpos.y,
  y = transform.y + transform.r.y * lpos.x + transform.f.y * lpos.y
 }

 return lpos
end

function world2localpos(transform, pos)
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
 if debuglines then
 add(addforces, {
  pos = pos, 
  dirf = fdir,
  diff = diff
  })
 end
end

function boom(pos)
 v = { x =0, y = -3 }
 addparticle(engineparticles, 100, pos, v, 6, 10, 20)
end

lastclicked = false
lclickstartpos = {}
prevmouse = {}
selected = 0

function _draw()
 cls()

 camera(cam.x,cam.y)

  -- ground
 if doground then
  line(cam.x -1000, groundy, cam.x + 10000, groundy, 1)
 end

 -- build mode
 if mode == 0 then
  cls(0)

  cam.x = 0
  cam.y = 0

  camera(0,0)

  -- draw build ui
  local w = 20
  local sy = 8
  local oy = 16
  local th = 16
  rectfill(0,0,w,127,1)

  hovered = -1

  if mouse.x < w then
   hovered = flr(mouse.y / th) 
   if hovered >= #partlib then hovered = -1 end
  else
   hovered = -1
  end

  tcol = 13
  if (click) tcol = 12
  rectfill(2,hovered * th + 1,w - 2,(hovered + 1) * th - 1,tcol)

  if click and not lastclicked then
   if selected > 0 and mouse.x > w then
    -- attach | confirm | add to craft
    part = newpart(partlib[selected])
    local pos = {x = flr(mouse.x) - focuscraft.x, y = -flr(mouse.y) + focuscraft.y}
    addpart(craft, part, pos) -- attach

    if symmetry then
     part = newpart(partlib[selected])
     part.mirror = true
     pos.x = flr(128-mouse.x) - focuscraft.x
     addpart(craft, part, pos)
    end
   end

   selected = hovered + 1
  end

  if selected > 0 then
   --prints("sel: "..partlib[selected].name, 8)
   print(partlib[selected].name, w + 4, 3, 9)

   drawlinesoffset(partlib[selected].lines, mouse, 9, true)
   if symmetry then
    mouseinv = { x= 128 - mouse.x, y = mouse.y }
    drawlinesoffset(partlib[selected].lines, mouseinv, 9, true, true)
   end
  elseif hovered > -1 then
   print(partlib[hovered+1].name, w + 4, 3, 6)
  end

  if rclick and not lastclicked then selected = 0 end

  -- remove part
  closestpart = getoverlappingpart()
  if closestpart then
   p = local2worldpartpos(craft, closestpart)
   line(p.x-5,p.y-5,p.x+5,p.y+5,8)
   line(p.x-5,p.y+5,p.x+5,p.y-5,8)
   tooltip("rmb to remove")
   if rclick and not lastclicked then
    removepart(craft, closestpart)
   end
  end

  rect(0,0,w,127,6)

  local offset = { x = w/2, y = sy }
  for i=1,#partlib do
   drawlinesoffset(partlib[i].lines, offset, 7, true)
   offset.y += oy
  end

  toolx = 25
  tooly = 128-15
  if (uibutton(toolx, tooly, 10, 10, "symmetry")) symmetry = not symmetry
  spr(3,toolx+2,tooly+2)

  if (uibutton(128-11, 0, 10, 10, "fly")) mode = 1
  spr(4,128-11+2,0+2)

  
 end

 drawparticlesline(engineparticles, 5)
 drawparticlescolor(engineparticles, 6)

 for i=1,#crafts,1 do
  drawcraft(crafts[i])
   --print(parts[i].v.y, 10, 10, 10)
 end



 -- velocity ray
 if debuglines then
  vray({x = focuscraft.x, y = focuscraft.y}, focuscraft.v, 5, 10)
 end

 -- temp



 spr(0,wmouse.x - 4,wmouse.y - 4)
 --pset(mousex, mousey, 10)

 if click then
  if not lastclicked then
   lclickstartpos = world2localpos(focuscraft, wmouse)
  end

  --fpos = { x = focuspart.x + 7, y = focuspart.y }
  fpos = { x = 7, y = 3 }
  --fpos = local2worldpos(focuspart, fpos)
  fpos = local2worldpos(focuscraft, lclickstartpos)

  --fdir = { x = 0.001, y = -0.002 }
  fdir = {
   x = -(fpos.x - wmouse.x) * 0.0001, 
   y = -(fpos.y - wmouse.y) * 0.0001 }

  addforce(focuscraft, fpos, fdir)
 end

 prevmouse = {x = wmouse.x, y = wmouse.y}
 lastclicked = click

 -- debug forces
 for k in pairs(addforces) do
  af = addforces[k]
  vray(af.pos, af.dirf, -100000, 9)
  vray(af.pos, af.diff, 1, 3)
  addforces[k] = nil -- remove
 end

 -- ui
 if drawui then
  h = flr(-(focuscraft.y - groundy))
  hstr = ""..h
  txtx = 64+15-#hstr*4
  rectfill(cam.x+64-14,cam.y,cam.x+64+14,cam.y+10,6)
  print(h, cam.x+txtx, cam.y+1, 5)
 end
end

function drawcraft(craft)
 for i=1,#craft.parts,1 do
  part = craft.parts[i]

  col = 7

  for i=1,#part.lines,2 do
   local m = 1
   if (part.mirror) m = -1
   l0 = {x = part.x + part.lines[i].x*m  , y = part.y + part.lines[i].y}
   l1 = {x = part.x + part.lines[i+1].x*m, y = part.y + part.lines[i+1].y}

   v0 = local2worldpos(craft, l0)
   v1 = local2worldpos(craft, l1)

   vline(v0, v1, col)
  end
 end

 -- draw com
 --spr(2, craft.x - 4, craft.y - 4)
end

function drawlinesoffset(lines, offset, col, invert, mirror)
 for i=1,#lines,2 do
  if (invert) s=-1 else s=1
  if (mirror) m=-1 else m=1
  v0 = {x = m * lines[i  ].x + offset.x, y = s * lines[i  ].y + offset.y}
  v1 = {x = m * lines[i+1].x + offset.x, y = s * lines[i+1].y + offset.y}

  vline(v0, v1, col)
 end
end

function vadd(v0, v1)
 return { x = v0.x + v1.x, y = v0.y + v1.y }
end

function drawpart(part)

 col = 7

 for i=1,#part.lines,2 do
  v0 = local2worldpos(part, part.lines[i])
  v1 = local2worldpos(part, part.lines[i+1])

  vline(v0, v1, col)
 end

 pos = { x = part.x, y = part.y }
 vray(pos, part.f * 10, 12)
 vray(pos, part.r * 10, 8)
end

r2=4*4

function getoverlappingpart()
 --print(mouse.x.." "..mouse.y, 12, 12, 12)

 for part in all(focuscraft.parts) do
  local _x = focuscraft.x + part.x - mouse.x
  local _y = focuscraft.y - part.y - mouse.y
  --print(_x.." ".._y, 12, 18, 9)
  --pset(_x,_y,10)
  if r2 > _x*_x + _y*_y then
   return part
  end
 end
end

function updatecraftvectors(craft)
 a = craft.a

 craft.f.x = sin(a + 0.125)
 craft.f.y = cos(a + 0.125)
   
 craft.r.x = sin(a + 0.375)
 craft.r.y = cos(a + 0.375)
end

-- ui button
function uibutton(x, y, w, h, tooltiptext)
 rectfill(x,y,x+w,y+h,5)

 if mouse.x > x and mouse.x < x + w and
    mouse.y > y and mouse.y < y + h then
  tooltip(tooltiptext)
  rectfill(x,y,x+w,y+h,13)

  if click and not lastclicked then
   return true
  end
 end

 rect(x,y,x+w,y+h,6)

 return false
end

function tooltip(str)
 print(str, 24, 3, 6)
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

function prints(text, col)
 print(text, cam.x + 10, cam.y + 10, col)
end

-- print with shadow
function printshd(text, x, y, col)
 print(text, x+1, y+1, 0)
 print(text, x, y, col)
end

menuitem(1, "fly", function() mode = 1 end)
menuitem(2, "build", function() mode = 0 end)
menuitem(3, "toggle symmetry", function() symmetry = not symmetry end)