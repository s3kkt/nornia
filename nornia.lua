local src = { 
  [1] = { ["name"] = _path.dust .. "code/nornia/audio/p1.wav" } , 
  [2] = { ["name"] = _path.dust .. "code/nornia/audio/p2.wav" } , 
  }

local set_val = {
  [1] = { ["loop_start"] = math.random(0,10), ["loop_end"] = math.random(30,50), ["cuf"] = 100, ["hp"] = 1.0, ["q"] = 1 },
  [2] = { ["loop_start"] = math.random(0,5), ["loop_end"] = math.random(10,30), ["cuf"] = 100, ["hp"] = 1.0, ["q"] = 1 },
  [3] = { ["loop_start"] = math.random(0,5), ["loop_end"] = math.random(10,30), ["cuf"] = 100, ["hp"] = 1.0, ["q"] = 1 },
}

local voice_col = {
  [1] = { ["name"] = "vo 1" , ["x"] = 34 , ["y"] = 5 },
  [2] = { ["name"] = "vo 2" , ["x"] = 68 , ["y"] = 5 },
  [3] = { ["name"] = "in 1" , ["x"] = 106 , ["y"] = 5 },
}

local filter = {
  [1] = { ["name"] = "cuf" , ["x"] = 15 , ["y"] = 15 , ["active"] = 1 },
  [2] = { ["name"] = "q" , ["x"] = 15 , ["y"] = 25 , ["active"] = 0 },
  [3] = { ["name"] = "hp" , ["x"] = 15 , ["y"] = 35 , ["active"] = 0 },
}

local positions = {0,0,0,0}

audio.level_dac(2)
audio.rev_on()
voices = 2
fade_time = 0.01
metro_time = 10.0 
phase = 0.5
page = 1
active = 1
screens = 3
settings = 3
rate = 1.0
rec = 1.0
pre = 0.0

m = metro.init()
m.time = metro_time
m.event = function()
  for i=1,4 do
    softcut.position(i,1+math.random(8)*0.25)
  end
end

function update_positions(i,pos)
  positions[i] = pos - 1
  redraw()
end

function init()
  softcut.buffer_clear()
  for voice = 1,3 do
    if voice ~= 3 then
      file = src[voice].name
      softcut.buffer_read_mono(file,0,1,-1,1,1) --FIXME: ch is 0-indexed
      softcut.loop_start(voice,set_val[voice].loop_start)
      softcut.loop_end(voice,set_val[voice].loop_end)
      softcut.fade_time(voice,fade_time)
      softcut.phase_quant(voice,phase)
--    print_info(file)
    elseif voice == 3 then
      audio.level_adc_cut(voice)
      softcut.level_input_cut(1,voice,1.0)
      softcut.level_input_cut(2,voice,1.0)
      softcut.rec_level(voice,rec)
      softcut.pre_level(voice,pre)
      softcut.rec(voice,1)
    randomize_all()  
  end
    set_common_settings(voice)
    set_filter_settings(voice)
    softcut.event_phase(update_positions)
    softcut.poll_start_phase()
  end
  m:start()
end

function set_common_settings(voice)
      softcut.enable(voice,1)
      softcut.buffer(voice,1)
      softcut.level(voice,1.0)
      softcut.pan(voice,(voice-2.5)*0.5)
      softcut.rate(voice,voice*0.25)
      softcut.loop(voice,1)
      softcut.position(voice,1)
      softcut.play(voice,1)
end

function set_filter_settings(voice)
    softcut.post_filter_dry(voice,0.0)
    softcut.post_filter_hp(voice,set_val[voice].hp)
    softcut.post_filter_fc(voice,set_val[voice].cuf)
    softcut.post_filter_rq(voice,set_val[voice].q)
end

function randomize_all()
  for i=1,3 do
    softcut.level(i,math.random()*0.5+0.2)
    softcut.pan(i,0.5-math.random())
    softcut.rate(i,2^(math.random(10)/2-4))
    softcut.fade_time(i,0.1*math.random(0,20))
  end
end

function enc(n,d)
  if page==1 then
    if n==1 then
      phase = util.clamp(phase+d/100,0,1)
      for i=1,4 do
        softcut.phase_quant(i,phase)
      end  
    elseif n==2 then
      fade_time = util.clamp(fade_time+d/100,0,1)
      for i=1,voices+1 do
        softcut.fade_time(i,fade_time)
      end
    elseif n==3 then
      metro_time = util.clamp(metro_time+d/8,0.125,10)
      m.time = metro_time
    end
  elseif page==2 then
    if n==1 then
-- scroll rows
    elseif n==2 then
-- scroll cols
        voice = 1
--      for voice = 1,voices+1 do
        cuf = util.clamp(set_val[voice].cuf+d*100,100,10000)
        softcut.post_filter_fc(voice,cuf)
--      end
    elseif n==3 then
-- change value
    end
  elseif page==3 then -- WIP
    if n==3 then
      active = switch_setting(active)
      print(active)
    end  
--    if n==1 then
--      rate = util.clamp(rate+d/100,-4,4)
--      softcut.rate(1,rate)
--    elseif n==2 then
--      rec = util.clamp(rec+d/100,0,1)
--      softcut.rec_level(1,rec)
--    elseif n==3 then
--      pre = util.clamp(pre+d/100,0,1)
--      softcut.pre_level(1,pre)
--    end
  end
  redraw()
end

function key(n,z)
  if n==2 and z==1 then
    randomize_all()
  elseif n==3 and z==1 then
    page = switch_page(page)
  end
end

function switch_page(page)
  if page < screens then
    page = page + 1
  else
    page = 1
  end
  return page
end

function switch_setting(active)
  if active < settings then
    print(active)
    active = active + 1
  else
    active = 1
  end
  return active
end

function redraw()
  if page == 1 then
    screen.clear()
    screen.move(10,1)
    screen.level(5)
    screen.line_rel(positions[1]*8,0)
    screen.move(40,1)
    screen.level(15)
    screen.line_rel(positions[2]*8,0)
    screen.move(70,1)
    screen.level(15)
    screen.line_rel(positions[3]*8,0)
    screen.move(100,1)
    screen.level(10)
    screen.line_rel(positions[4]*8,0)
    screen.stroke()

    screen.move(10,30)
    screen.text("offset:")
    screen.move(118,30)
    screen.text_right(string.format("%.2f",phase))
    screen.move(10,40)
    screen.text("fade time:")
    screen.move(118,40)
    screen.text_right(string.format("%.2f",fade_time))
    screen.move(10,50)
    screen.text("metro time:")
    screen.move(118,50)
    screen.text_right(string.format("%.2f",metro_time))
    screen.update()
  elseif page == 2 then
    screen.clear()
-- table:
    screen.level(1) 
    screen.move(0,7)
    screen.line_rel(150,0)
    screen.move(25,1)
    screen.line_rel(0,55)
    screen.move(60,1)
    screen.line_rel(0,55)
    screen.move(95,1)
    screen.line_rel(0,55)
    screen.stroke()
-- cols: 
  for col = 1,voices+1 do
    screen.level(15) 
    screen.move(voice_col[col].x+20,voice_col[col].y)
    screen.text_right(voice_col[col].name)
    screen.update()
  end  
-- rows: 
  screen.level(15)
  for row = 1,3 do
    screen.move(filter[row].x,filter[row].y)
    screen.text_right(filter[row].name .. ":")
  end
  screen.update()
-- params

--  screen.level(2) 
  for row = 1,3 do
    for voice = 1,voices+1 do
      screen.move(voice_col[voice].x+20,filter[row].y)
      
      if filter[row].name == "cuf" then 
        screen.level(2)
        screen.text_right(string.format("%.1f",set_val[voice].cuf/1000) .. "k")
        screen.update()
        end
      if filter[row].name == "q" then
        screen.level(15)
        screen.text_right(string.format("%.0f",set_val[voice].q)) end
      if filter[row].name == "hp" then screen.text_right(string.format("%.2f",set_val[voice].hp)) end
    end  
  end
  screen.update()
  elseif page == 3 then
----------------------
    screen.clear()
-- table:
    screen.level(1) 
    screen.move(0,7)
    screen.line_rel(150,0)
    screen.move(25,1)
    screen.line_rel(0,55)
    screen.move(60,1)
    screen.line_rel(0,55)
    screen.move(95,1)
    screen.line_rel(0,55)
    screen.stroke()
-- cols: 
  for col = 1,voices+1 do
    screen.level(15) 
    screen.move(voice_col[col].x+20,voice_col[col].y)
    screen.text_right(voice_col[col].name)
    screen.update()
  end  
-- rows: 
  screen.level(15)
  for row = 1,3 do
    screen.move(filter[row].x,filter[row].y)
    screen.text_right(filter[row].name .. ":")
  end
  screen.update()

--  screen.level(2) 
--  for row = 1,3 do
--    for voice = 1,voices+1 do
--      screen.move(voice_col[voice].x+20,filter[row].y)
--      if filter[row].name == "cuf" then screen.text_right(string.format("%.1f",set_val[voice].cuf/1000) .. "k") end
--      if filter[row].name == "q" then screen.text_right(string.format("%.0f",set_val[voice].q)) end
--      if filter[row].name == "hp" then screen.text_right(string.format("%.2f",set_val[voice].hp)) end
--    end  
--  end
  if active == 1 then
    for voice = 1,voices+1 do
      screen.move(voice_col[voice].x+20,filter[active].y)
      screen.level(15)
      screen.text_right(string.format("%.1f",set_val[voice].cuf/1000) .. "k")
      screen.level(5)
      screen.text_right(string.format("%.0f",set_val[voice].q))
      screen.level(5)
      screen.text_right(string.format("%.2f",set_val[voice].hp))
      screen.stroke()
    end
  elseif active == 2 then
    for voice = 1,voices+1 do
      screen.move(voice_col[voice].x+20,filter[active].y)
      screen.level(5)
      screen.text_right(string.format("%.1f",set_val[voice].cuf/1000) .. "k")
      screen.level(15)
      screen.text_right(string.format("%.0f",set_val[voice].q))
      screen.level(5)
      screen.text_right(string.format("%.2f",set_val[voice].hp))
      screen.stroke()
    end
  elseif active == 3 then
    for voice = 1,voices+1 do
      screen.move(voice_col[voice].x+20,filter[active].y)
      screen.level(5)
      screen.text_right(string.format("%.1f",set_val[voice].cuf/1000) .. "k")
      screen.text_right(string.format("%.0f",set_val[voice].q))
      screen.level(15)
      screen.text_right(string.format("%.2f",set_val[voice].hp))
      screen.stroke()
    end
  end 
-----------------
  screen.update()
--    screen.clear()
--    screen.move(10,30)
--    screen.text("rate: ")
--    screen.move(118,30)
--    screen.text_right(string.format("%.2f",rate))
--    screen.move(10,40)
--    screen.text("rec: ")
--    screen.move(118,40)
--    screen.text_right(string.format("%.2f",rec))
--    screen.move(10,50)
--    screen.text("pre: ")
--    screen.move(118,50)
--    screen.text_right(string.format("%.2f",pre))
--    screen.update()
  end  
end

function print_info(file)
  if util.file_exists(file) == true then
    local ch, samples, samplerate = audio.file_info(file)
    local duration = samples/samplerate
    print("loading file: "..file)
    print("  channels:\t"..ch)
    print("  samples:\t"..samples)
    print("  sample rate:\t"..samplerate.."hz")
    print("  duration:\t"..duration.." sec")
  else print "read_wav(): file not found" end
end

