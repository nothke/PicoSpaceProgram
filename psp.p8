-- pico space program
-- by nothke

-- settings:
-- - physics
doground = false
groundy = 120 -- y position of ground

gravity = 1
propoangulardrag = 0

gbody = {x=64, y=150, r=150}
gbodysqrc = ((gbody.r)*0.01)*((gbody.r)*0.01)

-- - graphical
particlespeedmult = 200
drawui = false

debuglines = true

tooltipx = 24
tooltipy = 3

trajectorypoints = 20
trajectory = {}

-- part graphics
lines_pod = {
 -- outline
 {x=-4, y=-4}, {x= 0, y= 4},
 {x= 0, y= 4}, {x= 4, y=-4},
 {x= 4, y=-4}, {x= 0, y=-5},
 {x= 0, y=-5}, {x=-4, y=-4},
 -- central line
 {x= 0, y=-1}, {x= 1, y=-1}
}

lines_cone = {
 -- outline
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
 name = "standard tank",
 lines = lines_tank,
 mass = 1,
 fuel = 10,
}

part_thin_tank = {
 name = "thin tank",
 lines = lines_thin_tank,
 mass = 0.5,
 fuel = 5,
}

part_thicc_tank = {
 name = "thicc tank",
 lines = lines_thicc_tank,
 mass = 5,
 fuel = 20,
}

part_cone = {
 name = "cone",
 lines = lines_cone,
  mass = 0.4,
}

part_thin_cone = {
 name = "thin cone",
 lines = lines_thin_cone,
 mass = 0.2,
 fuel = 2,

}

part_engine = {
 name = "rocket engine",
 lines = lines_bell,
 mass = 2,
 isthruster = true,
 force = 0.3
}

part_pod = {
 name = "crew pod",
 lines = lines_pod,
 mass = 2,
 control = true
}

part_rcs = {
 name = "rcs thruster",
 lines = lines_rcs,
 mass = 0.1,
}

partlib = {
 part_standard_tank,
 part_engine,
 part_cone,
 part_pod,
 part_rcs,
 part_thin_cone,
 part_thin_tank,
 part_thicc_tank
}

-- dont change
dt = 1/30 -- deltatime
dt100 = 3.3333 -- dt * 100

cam = {x=0, y=0}
crafts = {}
focuscraft = {}
buildparts={}
engineparticles = {}

addforces = {}

-- 0 build mode
-- 1 fly mode
mode = 0

symmetry = true
rotate = 0
gridsnap = false
deletemode = false

mouse = {}
wmouse = {}
click = false
rclick = false
onbutton = false
frameonbutton = false

debuglog={}

function _init()
 poke(0x5f2d, 1) -- enable mouse

 craft = initcraft()
 focuscraft = craft

 build()

 -- add initial parts here
 part = newpart(part_pod)
 addpart(craft, part, {x = 0, y = 0})
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
 inertia = 0, -- moment of inertia (angular)
 mass = 0, -- mass

 numthrusters = 0,
 numtanks = 0,
 controllable = false,
 } 

 add(crafts, craft)
 return craft
end

function clearcraft(craft)
 craft.parts={}
 craft.inertia = 0
 craft.mass = 0
 craft.com={x=0,y=0}

 craft.numthrusters = 0
 craft.numtanks = 0
 craft.controllable = false
end

function addpart(craft, part, lpos)
 add(craft.parts, part)
 part.x = lpos.x
 part.y = lpos.y
 part.ox = lpos.x
 part.oy = lpos.y

 if (part.isthruster) craft.numthrusters += 1
 if (part.fuel ~= nil) craft.numtanks += 1
 if (part.control) craft.controllable = true

 craft.inertia += 1000
 craft.mass += part.mass

 updatecom(craft)
end

function removepart(craft, part)
 if (part.isthruster) craft.numthrusters -= 1
 if (part.fuel ~= nil) craft.numtanks -= 1

 craft.inertia -= 1000
 craft.mass -= part.mass

 del(craft.parts, part)
 updatecom(craft)
end

function newpart(pt)
 part = initpart()

 part.lines = pt.lines
 part.mass = pt.mass
 if pt.isthruster ~= nil then 
  part.isthruster = pt.isthruster
  part.force = pt.force
 end
 if (pt.fuel ~= nil) part.fuel = pt.fuel
 if (pt.control ~= nil) part.control = pt.control
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

function updatecom(craft)
 local mx, my, tm = 0,0,0
 for i=1,#craft.parts do
  part = craft.parts[i]
  mx += part.mass * part.x
  my += part.mass * part.y
  tm += part.mass
 end

 craft.com.x = mx/tm
 craft.com.y = my/tm
end

function centercrafttocom(craft)
 local wcom = local2worldpos(craft, focuscraft.com)
 craft.x += wcom.x - craft.x
 craft.y += wcom.y - craft.y

 for part in all(focuscraft.parts) do
  part.x -= focuscraft.com.x
  part.y -= focuscraft.com.y
 end

 updatecom(craft)
end

-- inputs
in_thrt = 0
in_rot = 0
in_x = false

hascontrol = true

function _update()
 -- inputs
 if mode ~= 0 and focuscraft.controllable then
  if (btn(0)) then in_rot = -1
  elseif (btn(1)) then in_rot = 1
  else in_rot = 0 end
 
  if btn(2) then 
   in_thrt = 1 
   else in_thrt = 0
  end
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
 
   craft.av += in_rot / craft.inertia * 3
   a = craft.a

   updatecraftvectors(craft) 
 
   -- add gravity
   local bdiff = { x=(craft.x-gbody.x)*0.01, y=(craft.y-gbody.y)*0.01 }
   local bdiffn = normalize(bdiff)
   local sqrmag = sqrlength(bdiff)
   local gf = 5 / sqrmag
   local gravx = -bdiffn.x *gf
   local gravy = -bdiffn.y *gf

   craft.v.y += gravy * 0.5
   craft.v.x += gravx * 0.5
 
   -- step velocity
   craft.x += craft.v.x * dt
   craft.y += craft.v.y * dt
 
   -- process thrusters
   if in_thrt > 0 then
    for p=1,#craft.parts do
     if craft.parts[p].isthruster then
      local part = craft.parts[p]
      local ppos = local2worldpartpos(craft, part)
      local f = {
       x = craft.f.x * part.force,
       y = craft.f.y * part.force}
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
   boomvelocity = craft.v.y > 30
 
   -- ground collision
   --[[
   if doground and collided then
    --if boomvelocity then
    -- del(crafts, craft)
    -- boom(pos)
    -- goto outaloop
    --end

    craft.v.y = 0
    craft.v.y = -gravity
    craft.v.x *= 0.9 -- friction
 
    craft.y = groundy - 2
   end -- collision
   ]]

   --[[
   for part in all(craft.parts) do
    local colpos = local2worldpartpos(craft, part)
    colpos.y += 5
    if colpos.y > groundy then
     local coldir = {x=0,y=-1}

     if boomvelocity then
      removepart(craft, part)
      centercrafttocom(craft)
      boom(colpos)
      coldir.y = -3
      addforce(craft, colpos, coldir)
     else
      addforce(craft, colpos, coldir)
      craft.v.y = -gravity
      craft.v.x *= 0.9 -- friction
      local diff = groundy - colpos.y
      craft.y += diff
     end
    end
   end]]

   boomvelocity = length(craft.v) > 100

   -- circular body collision
   for part in all(craft.parts) do
    local colpos = local2worldpartpos(craft, part)
    local diff = vdiff(colpos,gbody)
    local d = length(diff) --sqrdist100(colpos, gbody)
    local c = gbody.r+3

    local sqrd = sqrdist100(colpos,gbody)
    local sqrc = ((gbody.r+3)*0.01)*((gbody.r+3)*0.01)

    --debug(sqrd..sqrc)

    if sqrd < sqrc then
     local coldir = normalize(diff)

     if boomvelocity then
      removepart(craft, part)
      centercrafttocom(craft)
      boom(colpos)
      --coldir.y = -3
      response = {x=coldir.x*10, y=coldir.y*10}
      addforce(craft, colpos, response)
     else
      --addforce(craft, colpos, coldir)


      --craft.v.y = -gravity
      --craft.v.x *= 0.9 -- friction
      --local diff = groundy - colpos.y
      --craft.y += diff

      -- friction
      tangent = right(coldir)
      craft.v = project(craft.v, tangent)
      --craft.v.x-=tangent.x*tdot*0.01
      --craft.v.y-=tangent.y*tdot*0.01

      

      local penetration = (sqrt(sqrc)-sqrt(sqrd))*100 --c-d
      craft.x += coldir.x*penetration
      craft.y += coldir.y*penetration

     end
    end
   end

   applyforces(craft)
 
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
      addparticle(engineparticles, numparticles, ppos, pvel, 70, 10, 20)
     end
    end
   end
 
   ::outaloop::
  end

  if #focuscraft.parts ~= 0 then
   cam.x = lerp(cam.x, focuscraft.x - 64, 0.15)
   cam.y = lerp(cam.y, focuscraft.y - 64, 0.15)
   cam.v = { x = focuscraft.v.x, y = focuscraft.v.y }
  end
 else -- mode == 0 build mode
  --resetcraft(focuscraft)
 end

 if (cam.v == nil) cam.v = {x=0,y=0} -- temp solution to prevent error
 cursor(cam.x,cam.y)

 updateparticlesystem(engineparticles)

 --cam.x = 0
 --cam.y = 0
end

function traj()
 local pos = {x=craft.x,y=craft.y}
 local velo = {x=craft.v.x, y=craft.v.y}
 for i=1,300 do
  local lastp = {x=pos.x,y=pos.y}
  local dv = gforce(pos)
  velo.x += dv.x* 0.5
  velo.y += dv.y* 0.5
  pos.x+=velo.x*dt
  pos.y+=velo.y*dt
  local nextp = {x=pos.x,y=pos.y}

  local sqrd = sqrdist100(nextp,gbody)
  if sqrd < gbodysqrc then 
   vpset(nextp,8)
   break end

  vline(lastp,nextp,4)
  --vpset(nextp,7)
 end
end

function gforce(pos)
 local bdiff = { x=(pos.x-gbody.x)*0.01, y=(pos.y-gbody.y)*0.01 }
 local bdiffn = normalize(bdiff)
 local sqrmag = sqrlength(bdiff)
 local gf = 5 / sqrmag
 return {x= -bdiffn.x*gf, y=-bdiffn.y*gf}
end

function applygravity(pos, velo)
   local bdiff = { x=(pos.x-gbody.x)*0.01, y=(pos.y-gbody.y)*0.01 }
   local bdiffn = normalize(bdiff)
   local sqrmag = sqrlength(bdiff)
   local gf = 5 / sqrmag
   local gravx = -bdiffn.x *gf
   local gravy = -bdiffn.y *gf
   velo.x += gravx * dt -- configurable step?
   velo.y += gravy * dt
   pos.x += velo.x *dt
   pos.y += velo.y *dt
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
 add(addforces, {
  pos = pos, 
  dirf = fdir,
  diff = diff
  })
end

function applyforces(craft)
 local fpos = {x=0,y=0}
 local fdir = {x=0,y=0}
 local fx, fy, fdx, fdy, fm = 0,0,0
 for force in all(addforces) do
  flen = length(force.dirf)
  fpos.x += force.pos.x * flen
  fpos.y += force.pos.y * flen
  fdir.x += force.dirf.x
  fdir.y += force.dirf.y
 end

 len = length(fdir)
 fpos.x /= len
 fpos.y /= len

 --pset(mouse.x, mouse.y+5, 10)
 --print('cunt '.. #addforces, cam.x + 68, cam.y + 128 - 7, 9)
 --print('frce '.. len, cam.x + 68, cam.y + 128 - 7, 9)

 diff = { x = craft.x - fpos.x, y = craft.y - fpos.y }
 r = length(diff)
 ndiff = normalize(diff)

 directforce = dot(ndiff, fdir)
 radialforce = dot(right(ndiff), fdir)
 
 -- t = f * r 
 -- deltaangvel = (r * m * dt) / torque
 craft.av += (radialforce * dt * r) / (craft.inertia)
 mult = (directforce * 3.3333) -- dt * 100
 craft.v.x += ndiff.x * mult
 craft.v.y += ndiff.y * mult

 applyforce_pos.x = fpos.x
 applyforce_pos.y = fpos.y
end

function launch()
 mode = 1


 for i=1,#focuscraft.parts do
  buildparts[i] = focuscraft.parts[i]
 end  

 --offsetx = focuscraft.com.x
 centercrafttocom(focuscraft)

 focuscraft.com.x = 0
 focuscraft.com.y = 0
end

function build()
 mode = 0

 clearcraft(focuscraft)

 for i=1,#buildparts do
  pos={x=buildparts[i].ox,y=buildparts[i].oy}
  addpart(focuscraft, buildparts[i], pos)
 end

 resetcraft(focuscraft)
 updatecom(focuscraft)

 --focuscraft.x = 64
 focuscraft.y = 31
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

function boom(pos)
 v = { x =0, y = -150 }
 addparticle(engineparticles, 50, pos, v, 500, 10, 20)
end

lastclicked = false
lclickstartpos = {}
prevmouse = {}
selected = 0

applyforce_pos = {x=0,y=0}
applyforce_dir = {x=0,y=0}

function _draw()
 cls()

 frameonbutton = false

 camera(cam.x,cam.y)

 -- draw spacegrid
 for i=0,128,1 do
  if flr(cam.x + i) % 20 == 0 then
   line(cam.x + i, cam.y + 200, cam.x + i, cam.y - 200, 1)
  end

  if flr(cam.y + i) % 20 == 0 then
   line(cam.x - 200, cam.y + i, cam.x + 200, cam.y + i, 1)
  end
 end

 -- planet
 circfill(gbody.x, gbody.y, gbody.r,2)
 pset(gbody.x, gbody.y, 4)

  -- ground
 if doground then
  
  --rectfill(cam.x - 1000, groundy - 100, cam.x + 1000,groundy,12)
  rectfill(cam.x - 1000, groundy, cam.x + 1000,groundy + 100,5)
  line(cam.x -1000, groundy, cam.x + 10000, groundy, 6)
  --rect(0,0,100,100, 8)
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

  p = {x = mouse.x, y = mouse.y}
  if gridsnap then p = {
   x = flr((mouse.x + 4) / 8) * 8,
   y = flr((mouse.y + 4) / 8) * 8} end

  if click and not lastclicked and not onbutton then
   if selected > 0 and mouse.x > w then
    
    -- attach | confirm | add to craft
    part = newpart(partlib[selected])
    local pos = {x = flr(p.x) - focuscraft.x, y = -flr(p.y) + focuscraft.y}
    addpart(craft, part, pos) -- attach

    if symmetry then
     part = newpart(partlib[selected])
     part.mirror = true
     pos.x = flr(128-p.x) - focuscraft.x
     addpart(craft, part, pos)
    end
   end

   selected = hovered + 1

   if (selected > 0) deletemode = false
  end

  if selected > 0 then
   --prints("sel: "..partlib[selected].name, 8)
   print(partlib[selected].name, w + 4, 3, 9)

   drawlinesoffset(partlib[selected].lines, p, 9, true)
   if symmetry then
    pinv = { x= 128 - p.x, y = p.y }
    drawlinesoffset(partlib[selected].lines, pinv, 9, true, true)
   end
  elseif hovered > -1 then
   local pt = partlib[hovered+1]
   print(pt.name, tooltipx, tooltipy, 6)
   if (pt.isthruster) print('thruster', tooltipx, tooltipy + 6, 5)
   if (pt.fuel ~= nil) print('fuel: '..pt.fuel, tooltipx, tooltipy + 6, 5)
  end

  if rclick and not lastclicked then
   selected = 0 
   deletemode = false
  end

  -- remove part
  closestpart = getoverlappingpart()
  if closestpart and deletemode 
  and closestpart.control ~= true then
   p = local2worldpartpos(craft, closestpart)
   line(p.x-5,p.y-5,p.x+5,p.y+5,8)
   line(p.x-5,p.y+5,p.x+5,p.y-5,8)
   tooltip("lmb to remove")
   if click and not lastclicked then
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
  if (uibutton(toolx, tooly, 10, 10, "symmetry "..(symmetry and 'on' or 'off'))) symmetry = not symmetry
  spr(3,toolx+2,tooly+2) toolx += 10
  if  uibutton(toolx, tooly, 10, 10, "rotate") then rotate= (rotate+1)%4 end
  spr(5,toolx+2,tooly+2) toolx += 10
  if  uibutton(toolx, tooly, 10, 10, "grid snap "..(gridsnap and 'on' or 'off')) then 
   gridsnap = not gridsnap end
  spr(6,toolx+2,tooly+2) toolx += 10
  if  uibutton(toolx, tooly, 10, 10, "remove part") then deletemode = not deletemode end
  spr(7,toolx+2,tooly+2) toolx += 10

  if (uibutton(128-11, 0, 10, 10, "launch")) launch()
  spr(4,128-11+2,0+2)
 --else
  --if (uibutton(cam.x + 128-11, cam.y, 10, 10, "build")) build()
 else  --if mode ~= 0 then
  traj()

  if (uibutton(cam.x+128-11, cam.y, 10, 10, "build")) build()
  spr(9,cam.x+128-11+2,cam.y+2)
 end

 drawparticlesline(engineparticles, 5)
 drawparticlescolor(engineparticles, 6)

 for i=1,#crafts,1 do
  drawcraft(crafts[i])
   --print(parts[i].v.y, 10, 10, 10)
 end



 -- velocity ray
 if debuglines then
  lv = {x = focuscraft.v.x*0.1, y = focuscraft.v.y*0.1}
  vray({x = focuscraft.x, y = focuscraft.y}, focuscraft.v, 0.1, 10)
 end

 -- temp





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



 -- debug forces
  --print('cunt '..#addforces, cam.x + 68, cam.y + 128 - 7, 9)

 u = 0
 for k in pairs(addforces) do

  af = addforces[k]
  vray(af.pos, af.dirf, 0.1, 9)
  --vray(af.pos, af.diff, 0.1, 3)
  --if u == 0 then
  --print('frce '.. length(af.dirf), cam.x + 68, cam.y + 128 - 7, 9)
  --end
  --u+=1

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

 if #focuscraft.parts == 0 then
  -- end screen
  infox = 36
  infoy = 20
  local txtx=cam.x+64-infox+2
  local txty=cam.y+64-infoy+10
  rectfill(cam.x+64-infox, cam.y+64-infoy,   cam.x+64+infox, cam.y+64+infoy  ,1)
  rect(    cam.x+64-infox, cam.y+64-infoy,   cam.x+64+infox, cam.y+64+infoy  ,6)
  line(    cam.x+64-infox, cam.y+64-infoy+8, cam.x+64+infox, cam.y+64-infoy+8,6)
  print("flight results",  cam.x+64-4*7, cam.y+64-infoy+2,6)
  print("outcome: r.u.d",txtx,txty,6) txty+=6
  print("flight time: 0",txtx,txty,6) txty+=6
  print("max height: 0",txtx,txty,6) txty+=6

  butx = cam.x+64-infox
  buty = cam.y+64+infoy-10
  if (uibutton(butx, buty, 10, 10, "back to drawing board")) build()
  spr(9,butx+2,buty+2)
  butx+=10
  if (uibutton(butx, buty, 10, 10, "retry")) build() launch()
  spr(4,butx+2,buty+2)
 end

 -- draw mouse
 spr(0,wmouse.x - 4,wmouse.y - 4)
 --pset(mousex, mousey, 10)

 -- update cursor
 prevmouse = {x = wmouse.x, y = wmouse.y}
 lastclicked = click

 onbutton = frameonbutton

 --print('mass '..focuscraft.mass, cam.x + 68, cam.y + 128 - 20, 9)
 --print('inrt '..focuscraft.inertia, cam.x + 68, cam.y + 128 - 14, 9)
 --print('inrt '..focuscraft.av, cam.x + 68, cam.y + 128 - 7, 9)


 --print('fpos '..applyforce_pos.x, cam.x + 68, cam.y + 128 - 7, 9)
 pset(applyforce_pos.x, applyforce_pos.y, 14)

 drawdebug()
end
------------------
-- end of draw
------------------

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
 spr(2, craft.x + craft.com.x - 4, craft.y - craft.com.y - 4)
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

 if wmouse.x > x and wmouse.x < x + w and
    wmouse.y > y and wmouse.y < y + h then
  tooltip(tooltiptext)
  rectfill(x,y,x+w,y+h,13)

  frameonbutton = true

  if click and not lastclicked then
   return true
  end
 end

 rect(x,y,x+w,y+h,6)

 return false
end

function tooltip(str)
 print(str, cam.x+24, cam.y+3, 6)
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

    particle.pos.x += (particle.velocity.x - cam.v.x) * dt
    particle.pos.y += (particle.velocity.y - cam.v.y) * dt

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

function vdiff(v1,v2)
 return {x=v1.x-v2.x, y=v1.y-v2.y}
end

function sqrdist100(v1, v2)
 diffx = (v1.x-v2.x)*0.01
 diffy = (v1.y-v2.y)*0.01
 return diffx*diffx + diffy*diffy
end

function sqrlength(v)
 return v.x*v.x + v.y*v.y
end

function length(v)
 return sqrt(v.x*v.x + v.y*v.y)
end

function right(v)
 nv = { x = v.y, y=-v.x }
 return nv
end

function project(a,b)
 scale = dot(a,b)
 bn = normalize(b)
 return{x=bn.x*scale,y=bn.y*scale}
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

function debug(str)
 add(debuglog,str)
end

function drawdebug()
 cursor(cam.x,cam.y)
 for k in all(debuglog) do
  print(k)
  del(debuglog,k)
 end
end

--menuitem(1, "fly", launch())
menuitem(1, "build", build)
menuitem(2, "toggle symmetry", function() symmetry = not symmetry end)