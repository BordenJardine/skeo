pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
--crowd
--by tad and stepus

numplayers=2
numbots=8
numdeaths=0
numgames=0
gamestowin=10

continue=false
rand = {}

for j=0,2000 do
 rand[j]=flr(rnd(5))
end

names={"pl1","pl2","pl3","pl4"}
chars={"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","0","1","2","3","4","5","6","7","8","9"}
if(peek(0x5e0c)==5)then
 names[1]=chars[peek(0x5e00)]..chars[peek(0x5e01)]..chars[peek(0x5e02)]
 names[2]=chars[peek(0x5e03)]..chars[peek(0x5e04)]..chars[peek(0x5e05)]
 names[3]=chars[peek(0x5e06)]..chars[peek(0x5e07)]..chars[peek(0x5e08)]
 names[4]=chars[peek(0x5e09)]..chars[peek(0x5e0a)]..chars[peek(0x5e0b)]
end

gwins={0,0,0,0}
gcoins={0,0,0,0}
gkills={0,0,0,0}
gbotkills={0,0,0,0}
gdeaths={0,0,0,0}
colorl={7,9,6,7,13,14,8,11,12,5,6,10}
colord={9,4,13,6,1,8,2,3,1,0,5,9}

--hitboxy xoffset, yoffset, w, h
ph={3,10,12,15}
ch={1,1,6,6}
lsh={-128,10,0,15}
rsh={15,10,128,15}

debug=false

function _init()
 scr={}
 t=0
 
 end_kill=3
 end_kill_pl=true
 end_kill_bot=true
 end_coins=5
 play_ready={false,false,false,false}
 namestate={0,0,0,0}
 wins={0,0,0,0}
 deaths={0,0,0,0}
 wincause={{},{},{},{}}
 
 if(peek(0x5e0e)==5)then
  numplayers=peek(0x5e0d)
  numbots=peek(0x5e0f)
  end_coins=peek(0x5e10)
  end_kill=peek(0x5e11)
  gamestowin=peek(0x5e12)
 end
 
 show_menu()
 
end

function _update60()
 scr.upd()
end

function _draw()
 scr.drw()
end

function show_menu()
 s=0
 start=false
 prepush=true
 scr.upd = update_menu
 scr.drw = draw_menu
 play_ready={false,false,false,false}
 wincause={{},{},{},{}}
 menu_state=0
 bots={}
 for i=1,(numbots+numplayers)/2 do
  temp=init_bot(i)
  temp.menu=1
 	temp.y=flr(rnd(49))+63 --position y
  add(bots,temp) 
 end
 for i=1,(numbots+numplayers)/2 do
  temp=init_bot(i)
  temp.menu=2
  temp.y=flr(rnd(50))+21 --position y

  add(bots,temp) 
 end


 music(0)
end

function check_btn()
 temp=true
 for i=0,3 do
  for j=0,6 do
   if(btn(j,i))temp=false
  end
 end
 return(temp)
end

function update_menu()
 t+=0.125
-- if(btnp(0) or btnp(1) or btnp(5)or btnp(4))sfx(16)
-- if(btnp(2) or btnp(3))sfx(15)
 foreach(bots,update_bot) 
 for i=0,3 do
  if(menu_state==0)then
   if (btnp(4,i)and s==0)then
    menu_state=3
    play_ready={false,false,false,false}
    namestate={0,0,0,0}
    prepush=true
    s=0
   end
   if (btnp(4,i)and s==1)then
    menu_state=1
    s=0
   end
   if (btnp(4,i)and s==2)then
    menu_state=2
    temp0=flr(rnd(2))+1
    if(temp0==2)then
     temp1=flr(rnd(8))+2
    else
     temp1=flr(rnd(9))+2
    end
	    temp2=flr(rnd(9))+2

    --s=0
   end

   if (btnp(3,i))s+=1
   if (btnp(2,i))s-=1
   if (s>2)s=0
   if (s<0)s=2

  elseif(menu_state==1)then
   if ((btnp(0,i))and s==0)then
    if(numplayers>2)numplayers-=1
   end
   if ((btnp(1,i))and s==0)then
    if(numplayers<4)numplayers+=1
   end
 
   if ((btnp(0,i))and s==1)numbots-=1
   if ((btnp(1,i))and s==1)numbots+=1
    if(numbots>50)numbots=50

   if(numbots<0)numbots=0
  
   if ((btnp(0,i))and s==2)end_coins-=1
   if(end_coins>9)end_coins=9
   if ((btnp(1,i))and s==2)end_coins+=1
   if(end_coins<0)end_coins=0
   
   if ((btnp(0,i))and s==3)gamestowin-=1
   if(gamestowin>10)gamestowin=10
   if ((btnp(1,i))and s==3)gamestowin+=1
   if(gamestowin<1)gamestowin=1


   if ((btnp(0,i))and s==4)end_kill-=1
   if ((btnp(1,i))and s==4)end_kill+=1
   if (btnp(4,i)and s==5)reset_global()
   if(end_kill>3)end_kill=0
   if(end_kill<0)end_kill=3
   end_kill_pl=false
   end_kill_bot=false
   if(flr(end_kill)%2==1)end_kill_pl=true
   if(end_kill>1)end_kill_bot=true
   if (btnp(3,i))s+=1
   if (btnp(2,i))s-=1
   if (s>3)s=0
   if (s<0)s=3
   if (btnp(5,i))then
    menu_state=0
    s=0
   end
  elseif(menu_state==2)then
   if (btnp(5,i))then
    menu_state=0
    --s=0
   end
  elseif(menu_state==3)then
   if (check_btn())prepush=false
   if (s==0 and btn(4,i)and not prepush)then
    play_ready[i+1]=true
   end
   if (btnp(5,i))then
    if(play_ready[i+1])then
     play_ready[i+1]=false
    else
     play_ready[i+1]=false
     menu_state=0
     s=0
    end
   end

   ready=0
   for j=1,numplayers do
    if(play_ready[j])ready+=1
   end
   if(ready==numplayers)then start=true
   
   end
   if(start and check_btn())then
    
    sfx(25)
    menu_state=4
          
   end
   if (btnp(1,i) and not play_ready[i+1])then
    namestate[i+1]+=1
    if(namestate[i+1]>2)namestate[i+1]=0

   end
   if (btnp(0,i)and not play_ready[i+1])then
    namestate[i+1]-=1
    if(namestate[i+1]<0)namestate[i+1]=2
   end
   if (btnp(2,i)and not play_ready[i+1])then
    tmp=getcharnum(sub(names[i+1],namestate[i+1]+1,namestate[i+1]+1))
    tmp+=1
    if(tmp>#chars)tmp=1
    
    temp=chars[tmp]
    if(namestate[i+1]==0)names[i+1] = temp..sub(names[i+1],2,3)
    if(namestate[i+1]==1)names[i+1] = sub(names[i+1],1,1)..temp..sub(names[i+1],3,3)
    if(namestate[i+1]==2)names[i+1] = sub(names[i+1],1,2)..temp

    --names[i+1]=temp
   end
   if (btnp(3,i)and not play_ready[i+1])then
    tmp=getcharnum(sub(names[i+1],namestate[i+1]+1,namestate[i+1]+1))
    tmp-=1
    if(tmp<=0)tmp=#chars

    temp=chars[tmp]
    if(namestate[i+1]==0)names[i+1] = temp..sub(names[i+1],2,3)
    if(namestate[i+1]==1)names[i+1] = sub(names[i+1],1,1)..temp..sub(names[i+1],3,3)
    if(namestate[i+1]==2)names[i+1] = sub(names[i+1],1,2)..temp

   end   
  elseif(menu_state==4)then
   if (check_btn())prepush=false
   if(btnp(4,i) or btnp(5,i))then 
    gametime=flr(time())
    gametime_a=0
    start_game()
   end
   
  end 
 i+=1
 end

 poke(0x5e00,getcharnum(sub(names[1],1,1)))
 poke(0x5e01,getcharnum(sub(names[1],2,2)))
 poke(0x5e02,getcharnum(sub(names[1],3,3)))
 poke(0x5e03,getcharnum(sub(names[2],1,1)))
 poke(0x5e04,getcharnum(sub(names[2],2,2)))
 poke(0x5e05,getcharnum(sub(names[2],3,3)))
 poke(0x5e06,getcharnum(sub(names[3],1,1)))
 poke(0x5e07,getcharnum(sub(names[3],2,2)))
 poke(0x5e08,getcharnum(sub(names[3],3,3)))
 poke(0x5e09,getcharnum(sub(names[4],1,1)))
 poke(0x5e0a,getcharnum(sub(names[4],2,2)))
 poke(0x5e0b,getcharnum(sub(names[4],3,3)))
 poke(0x5e0d,numplayers)
 poke(0x5e0f,numbots)
 poke(0x5e10,end_coins)
 poke(0x5e11,end_kill)
 poke(0x5e12,gamestowin)
 
 poke(0x5e0c,5)
 poke(0x5e0e,5)

end

function getcharnum(char)
 for i=1,#chars do
  if(char==chars[i])return i
 end 
end

function reset_global()
 numgames=0
 gwins={0,0,0,0}
 gcoins={0,0,0,0}
 gkills={0,0,0,0}
 gbotkills={0,0,0,0}
 gdeaths={0,0,0,0}
end

function draw_menu()
 cls()
 pal()
 palt(0,false)
 palt(15,true)
  
 --rectfill(0,0,128,128,0)
 
  
-- rectfill(0,0,128,128,0)
 map(0,16)
 
 --for i=1,24 do
 -- rectfill(0+i*10,0,8+i*10,4,colorl[i])
 -- rectfill(0+i*10,4,8+i*10,8,colord[i])
 -- i+=1
 --end

 --rectfill(92,120,126,126)
 --print("tad 2017",94,121,7)
 if(menu_state==3)then
  print("choose\n name",24,6,5)
 else 
  print("agents\nin the",24,6,5)
 end 
 
 for y=1,70 do 
  for i=1,#bots do
   if(bots[i].menu==2 and flr(bots[i].y)==y)draw_player(bots[i])
  end
 end
 --foreach(bots,draw_player)
  
 pal(7,0)
 map(16,0,-1,19)
 map(16,0,-1,14)
 map(16,0,0,19)
 map(16,0,0,14)
 map(16,0,1,19)
 map(16,0,1,14)
 pal(7,6)
 map(16,0,0,15)
 pal(7,7)
 map(16,0,0,18)
 pal(7,7)

  
 for y=50,128 do 
  for i=1,#bots do
   if(bots[i].menu==1 and flr(bots[i].y)==y)draw_player(bots[i])
  end
 end
 
-- x=98
-- y=107+abs((t%5)-2)
-- rectfill(x-2,y-1,x+28,y+17,8)
-- print("capek's\n b-day\nedition",x,y,7)
   
  
  if(menu_state==0)then
  x1=37
  y1=80
  x2=91
  y2=111
  
  rectfill(x1,y1,x2,y2,0)
  rectfill(x1+1,y1+1,x2-1,y2-1,6)
  rectfill(x1+1,y1+1,x2-2,y2-2,7)
  rectfill(x1+2,y1+2,x2-1,y2-1,13)
  rectfill(x1+2,y1+9,x2-2,y2-2,6)
  rectfill(x2-7,y1+3,x2-3,y1+7,8)
  line(x2-6,y1+4,x2-4,y1+6,7)
  line(x2-4,y1+4,x2-6,y1+6,7)
  
  print("menu",x1+3,y1+3,7)

  
 -- rectfill(38,85,90,111,0)
 -- rectfill(39,86,89,110,6)
 -- rectfill(39,89,89,110,7)

  rectfill(40,90+6*s,88,96+6*s,(s==0) and 0 or 0)
  
  print("start",42,91,(s==0) and 7 or 13)
  print("options",42,97,(s==1) and 7 or 13)
  print("help",42,103,(s==2) and 7 or 13) 
 
 elseif(menu_state==1)then
--  rectfill(38,85,90,111,0)
--  rectfill(39,86,89,110,6)
--  rectfill(39,89,89,110,7)
  x1=37
  y1=80
  x2=91
  y2=117
  
  rectfill(x1,y1,x2,y2,0)
  rectfill(x1+1,y1+1,x2-1,y2-1,6)
  rectfill(x1+1,y1+1,x2-2,y2-2,7)
  rectfill(x1+2,y1+2,x2-1,y2-1,13)
  rectfill(x1+2,y1+9,x2-2,y2-2,6)
  rectfill(x2-7,y1+3,x2-3,y1+7,8)
  line(x2-6,y1+4,x2-4,y1+6,7)
  line(x2-4,y1+4,x2-6,y1+6,7)
  
  print("options",x1+3,y1+3,7)

  
 -- rectfill(38,85,90,111,0)
 -- rectfill(39,86,89,110,6)
 -- rectfill(39,89,89,110,7)

  rectfill(40,90+6*s,88,96+6*s,(s==0) and 0 or 0)



  --rectfill(0,17,128,59,0)
  rectfill(40,90+6*s,88,96+6*s,0)
  print("players",42,91,(s==0) and 7 or 13)
  print(numplayers,80,91,(s==0) and 7 or 13)
  print("bots",42,97,(s==1) and 7 or 13)
  print(numbots,80,97,(s==1) and 7 or 13)
  print("coins",42,103,(s==2) and 7 or 13)
  print(end_coins,80,103,(s==2) and 7 or 13)
  print("wins",42,109,(s==3) and 7 or 13)
  print(gamestowin,80,109,(s==3) and 7 or 13)

  --print("death",42,110,7)
  --temp={"off","plr","bot","all"}
  --print(temp[end_kill+1],76,110,7)
 elseif(menu_state==2)then
  
  x1=29
  y1=4
  x2=98
  y2=124
  
  rectfill(x1,y1,x2,y2,0)
  rectfill(x1+1,y1+1,x2-1,y2-1,6)
  rectfill(x1+1,y1+1,x2-2,y2-2,7)
  rectfill(x1+2,y1+2,x2-1,y2-1,13)
  rectfill(x1+2,y1+9,x2-2,y2-2,6)
  rectfill(x2-7,y1+3,x2-3,y1+7,8)
  line(x2-6,y1+4,x2-4,y1+6,7)
  line(x2-4,y1+4,x2-6,y1+6,7)
  
  --rect(x1+1,y1+1,x2-1,y2-1,0)
  
  print("help",x1+3,y1+3,7)

--  rectfill(x1+3,y1+10,x2-4,y1+117,13)
--  rectfill(x1+4,y1+11,x2-3,y1+118,7)
  
--  rectfill(28,15,99,121,0)
--  rectfill(29,16,98,120,7)

  pal(7,colorl[temp0])
 	pal(9,colord[temp0])
 	pal(14,colorl[temp1])
 	pal(8,colord[temp1])
  pal(11,colorl[temp2])
 	pal(3,colord[temp2])
 
  spr(0+flr(t%4)*2,32,17,2,2,true)
  pal()
  palt(0,false)
  palt(15,true)
 
  spr(248+(t+rand[1])%8,36,35)
  spr(116+(t+rand[6])%4,36,56)
  spr(104+(t+rand[2])%8,36,81)
  spr(100+(t+rand[3])%4,36,90)
  spr(120+(t+rand[4])%8,36,98)
  spr(198+(t+rand[5])%4,36,111)

  print("multiplayer\nvs game for\n2-4 players",50,18,13)
  print("controllers\nrecommended",50,38)
  print("—,Ž shoot",50,50)
  
  print("be in crowd\nstay hidden\nfind player\nscore point",50,58)
 
  print("kill player",50,84)
  print("get "..end_coins.. " coins",50,92)
  print("do not kill\nnormal guys",50,100)
  print("get "..gamestowin.." wins",50,114)
      
 elseif(menu_state==3)then
  for i=1,numplayers do
   rectfill(8+32*(i-1),90,22+32*(i-1),96,0)
   print((names[i]),10+32*(i-1),91,7)

   if(play_ready[i])then
    --rectfill(4+32*(i-1),98,26+32*(i-1),104,0)
    --print("ready",6+32*(i-1),99,7)
    print((names[i]),10+32*(i-1),91,9)

   else
    print(sub(names[i],namestate[i]+1,namestate[i]+1),10+32*(i-1)+4*namestate[i],91,0+((flr(t%2))*7))
   end
  
  end
 elseif(menu_state==4)then

  namestring=""

  for i=1,numplayers do
   namestring=namestring..names[i]
   if(i!=numplayers)namestring=namestring..","
  end

  x1=13
  y1=7
  x2=115
  y2=122
  
  rectfill(x1,y1,x2,y2,0)
  rectfill(x1+1,y1+1,x2-1,y2-1,6)
  rectfill(x1+1,y1+1,x2-2,y2-2,7)
  rectfill(x1+2,y1+2,x2-1,y2-1,13)
  rectfill(x1+2,y1+9,x2-2,y2-2,6)
  rectfill(x2-7,y1+3,x2-3,y1+7,8)
  line(x2-6,y1+4,x2-4,y1+6,7)
  line(x2-4,y1+4,x2-6,y1+6,7)

  print("e-mail",x1+3,y1+3,7)
  print("from:",x1+3,y1+13,13)
  print("  to:",x1+3,y1+25,13)
  
  rectfill(x1+22,y1+10,x2-4,y1+19,13)
  rectfill(x1+23,y1+11,x2-3,y1+20,7)
  rect(x1+23,y1+11,x2-4,y1+19,0)
  print("boss",x1+25,y1+13,5)
  
  rectfill(x1+22,y1+22,x2-4,y1+31,13)
  rectfill(x1+23,y1+23,x2-3,y1+32,7)
  rect(x1+23,y1+23,x2-4,y1+31,0)
  print(namestring,x1+25,y1+25,5)
  
  rectfill(x1+3,y1+34,x2-4,y2-4,13)
  rectfill(x1+4,y1+35,x2-3,y2-3,7)
  rect(x1+4,y1+35,x2-4,y2-4,0)
  print("dear agent,",x1+7,y1+38,5)
  print("you are our only hope.\nyou will be operating\nunder cover in the\ncrowd among other\nagents.\nfind and kill one of\nthem or collect coins.\nand please, please do\nnot kill civilians.",x1+7,y1+47,5)
  print("             xoxo boss",x1+7,y1+103,5)
  --print(namestring,26,48)
  --print("dear agent,\nyou are our only hope",26,60)


 end

end

function show_result()
 prepush=true
 show=0
 numgames+=1
 gametime_p=(time()-gametime)/2
 gametime_a+=gametime_p

-- gametime_p=37

 if(gametime_p>=3600)then
  gametime_s=flr(gametime_p/3600)..":"
  gametime_p=flr(gametime_p%3600)
 else
  gametime_s=" "
 end

 if(gametime_p/60<10)then
  gametime_s=gametime_s.."0"
 else
  gametime_s=gametime_s..""
 end
 gametime_s=gametime_s..flr(gametime_p/60)
 gametime_s=gametime_s..":"
 if(gametime_p%60<10)gametime_s=gametime_s.."0"
 gametime_s=gametime_s..flr(gametime_p%60)
 
 if(gametime_a>=3600)then
  gametime_sa=flr(gametime_a/3600)..":"
  gametime_a=flr(gametime_a%3600)
 else
  gametime_sa=" "
 end


 if(gametime_a/60<10)then
  gametime_sa=gametime_sa.."0"
 else
  gametime_sa=gametime_sa..""
 end
 gametime_sa=gametime_sa..flr(gametime_a/60)
 gametime_sa=gametime_sa..":"
 if(gametime_a%60<10)gametime_sa=gametime_sa.."0"
 gametime_sa=gametime_sa..flr(gametime_a%60)
 
 scr.upd = update_result
 scr.drw = draw_result
 for i=1,numplayers do
  gwins[i]+=wins[i]
  gcoins[i]+=players[i].coins
  gkills[i]+=players[i].kills
  gbotkills[i]+=players[i].botkills
  gdeaths[i]+=deaths[i]

  i+=1
 end
end

function update_result()
 t+=0.25
 if (check_btn())prepush=false
 for i=0,3 do
   if ((btn(4,i) or btn(5,i))  and not prepush)then
   if(btn(5,i))continue=true
   if(btn(4,i))continue=true
   show+=1
   prepush=true
  end
 end  
 if (show==1) then
  t=0
  scr.upd = update_postgame
  scr.drw = draw_postgame
 
 end 
 
 max_score=max(max(gwins[4],gwins[1]),max(gwins[2],gwins[3]))
 if (max_score>=gamestowin) then 
  continue=false
  
  
 end
 
 if (show==4) then
  if(continue)then
   
   if(check_btn())then
    continue=false
    start_game()
   end
  else
   gametime_a=0
   reset_global()
   show_menu()
  end
 end
 end

function draw_result()
  
 pal()
 palt(0,false)
 palt(15,true)
 
 if(show==0)then
  map(16,16)
  if (numgames<10)then
   print(numgames,67,0)
  else
   print(numgames,65,0)
  end
  foreach(coins,draw_coin)

  if (deathbot!=-1 and end_kill_bot) then
      --black guy
   bots[deathbot].c[2]=6
   bots[deathbot].c[1]=7
   
   --draw_player(bots[deathbot])
   deadbot=true
   
   if bots[deathbot].c[1]==9 and
    bots[deathbot].c[2]==4 then
    if bots[deathbot].c[3]==9 then
     bots[deathbot].c[3]=7
    end
    if bots[deathbot].c[4]==4 then
     bots[deathbot].c[4]=6
    end
    if bots[deathbot].c[5]==9 then
     bots[deathbot].c[5]=7
    end
    if bots[deathbot].c[6]==4 then
     bots[deathbot].c[6]=6
    end
   end
    
     
  end
-- drawname=true
 for y=0,128 do
  for i=1,numplayers do
   if(flr(players[i].y)==y)draw_player(players[i])
  end
  if(deadbot)then
   if(flr(bots[deathbot].y)==y)draw_player(bots[deathbot])
  end
 end
 for y=0,128 do
  for i=1,numplayers do
   if(flr(players[i].y)==y)draw_name(players[i])
  end
 end
 
 
-- foreach(players,draw_player)
-- foreach(players,draw_name)
-- drawname=false
 
 elseif(show==1 or show==2 or show==3)then 
  --rectfill(0,0,128,128,0)
  max_score=max(max(gwins[4],gwins[1]),max(gwins[2],gwins[3]))
 
  map(0,16)
  foreach(players,printresultglobal)
  if(show==2 and max_score>=gamestowin)then
   
   if(not win)sfx(25)
   win=true
   winnames=""
   for i=1,4 do
    if(winners[i])then
     if(winnames!="")winnames=winnames..","
     winnames=winnames..names[i]
    end
   end
   x1=13
   y1=25
   x2=115
   y2=122
  
   rectfill(x1,y1,x2,y2,0)
   rectfill(x1+1,y1+1,x2-1,y2-1,6)
   rectfill(x1+1,y1+1,x2-2,y2-2,7)
   rectfill(x1+2,y1+2,x2-1,y2-1,13)
   rectfill(x1+2,y1+9,x2-2,y2-2,6)
   rectfill(x2-7,y1+3,x2-3,y1+7,8)
   line(x2-6,y1+4,x2-4,y1+6,7)
   line(x2-4,y1+4,x2-6,y1+6,7) 

   print("e-mail",x1+3,y1+3,7)
   print("from:",x1+3,y1+13,13)
   print("  to:",x1+3,y1+25,13)
   
   rectfill(x1+22,y1+10,x2-4,y1+19,13)
   rectfill(x1+23,y1+11,x2-3,y1+20,7)
   rect(x1+23,y1+11,x2-4,y1+19,0)
   print("boss",x1+25,y1+13,5)
  
   rectfill(x1+22,y1+22,x2-4,y1+31,13)
   rectfill(x1+23,y1+23,x2-3,y1+32,7)
   rect(x1+23,y1+23,x2-4,y1+31,0)
   print(winnames,x1+25,y1+25,5)
   
   rectfill(x1+3,y1+34,x2-4,y2-4,13)
   rectfill(x1+4,y1+35,x2-3,y2-3,7)
   rect(x1+4,y1+35,x2-4,y2-4,0)
   print("dear agent,",x1+7,y1+38,5)
   print("you are the best!\nthank you very much!\nand about your reward.\nyou picked up some\ncoins right? you can\nkeep them.",x1+7,y1+47,5)
   print("             xoxo boss",x1+7,y1+85,5)

  else
   show=3
  end
 
  
 end
end

function printresultglobal(p)
 if max_score>=gamestowin then 
   
  for i=1,4 do
   if(gwins[i]==max_score)then
    winner=i
   end
  end
  
  print("game over",19,6,8)
  print(gametime_sa,23,12)

 else
  
  print("game",23,6,5)
  print(numgames,45,6,5)
  print(gametime_s,23,12)
 end
 
-- print(wincause[1][1],50,80)
-- print(wincause[1][2],50,90)
-- print(wincause[1][3],50,100)
-- print(#wincause[1],50,70)
 
-- print(wincause[2][1],80,80)
-- print(wincause[2][2],80,90)
-- print(wincause[2][3],80,100)
-- print(#wincause[2],80,70)

-- print(wincause[3][1],110,80)
-- print(wincause[3][2],110,90)
-- print(wincause[3][3],110,100)
-- print(#wincause[3],110,70)

 
 rectfill(2,41+16*p.i,16,47+16*p.i,0)
 --print(names[p.i],4,42+16*p.i,7+flr((wins[p.i])*t%2)*2)
 print(names[p.i],4,42+16*p.i,7+wins[p.i]*2)
 
 
 if max_score>=gamestowin then 
  if max_score==gwins[p.i]then
   print(names[p.i],4,42+16*p.i,8)
   winners[p.i]=true
  end
 end

 for i=1,gwins[p.i] do
  if(i==gwins[p.i] and wins[p.i]==1)then
   if(wincause[p.i][i]=="kill")then
    spr(136+((t+rand[i*(p.i+i)])/2)%8,30+9*i,41+16*p.i)
 		elseif(wincause[p.i][i]=="coin")then
    spr(132+((t+rand[i*(p.i+i)])/2)%4,30+9*i,41+16*p.i)
   elseif(wincause[p.i][i]=="skull")then
    spr(152+((t+rand[i*(p.i+i)])/2)%8,30+9*i,41+16*p.i)
   elseif(wincause[p.i][i]=="last")then
    if(numplayers==2)then
     spr(136+((t+rand[i*(p.i+i)])/2)%8,30+9*i,41+16*p.i)
    else
     spr(148+((t+rand[i*(p.i+i)])/2)%4,30+9*i,41+16*p.i)
    end
   else
    spr(152+((t+rand[i*(p.i+i)])/2)%8,30+9*i,41+16*p.i)
 
   end
  else
   if(wincause[p.i][i]=="kill")then
    spr(104+((t+rand[i*(p.i+i)])/2)%8,30+9*i,41+16*p.i)
 		elseif(wincause[p.i][i]=="coin")then
    spr(100+((t+rand[i*(p.i+i)])/2)%4,30+9*i,41+16*p.i)
   elseif(wincause[p.i][i]=="skull")then
    spr(120+((t+rand[i*(p.i+i)])/2)%8,30+9*i,41+16*p.i)
   elseif(wincause[p.i][i]=="last")then
    if(numplayers==2)then
     spr(104+((t+rand[i*(p.i+i)])/2)%8,30+9*i,41+16*p.i)
    else
     spr(116+((t+rand[i*(p.i+i)])/2)%4,30+9*i,41+16*p.i)
    end
   else
    spr(120+((t+rand[i*(p.i+i)])/2)%8,30+9*i,41+16*p.i)
 
   end
  
  end
 end

 xpos=20
 p.x=xpos
 if(p.s==3)then
  if(p.f)then
   p.x=xpos+3
  else
   p.x=xpos-4
  end
 end
 if(p.s==4)then
  if(p.f)then
   p.x=xpos-4
  else
   p.x=xpos+5
  end
 end
 
 p.y=33+16*p.i
 if(p.s==3)p.y-=2
 if(p.s==4)p.y-=2

 draw_player(p)

end

function start_game()
 gameover=false
 numdeaths=0
 deadbot=false
 wins={0,0,0,0}
 deaths={0,0,0,0}
 deathbot=-1
 win=false
 t=0
 winners={false,false,false,false}
 music(-1,1000)
 gametime=time()
 
 scr.upd = update_pregame
 scr.drw = draw_pregame
 players={}
 bots={}
 coins={}
 nextcoin=1
 for i=1,numplayers do
  temp=init_player(i)
  add(players,temp) 
 end 
 for i=1,numbots do
  temp=init_bot(i)
  add(bots,temp) 
 end
 c={}
 c.x=flr(rnd(122))
 c.y=flr(rnd(110))+10
 add(coins,c)
 sfx(14)
end

function update_pregame()
 t+=0.25
 if t>16 then
  camera(0,0)
  scr.upd = update_game
  scr.drw = draw_game
 end
end

function draw_pregame()
 camera(-128+t*8,0)
 
 draw_game()
 
-- rectfill(0,0,128,64-t*4,0)
-- rectfill(0,64+t*4,128,128,0)
-- rectfill(0,0,64-t*4,128,0)
-- rectfill(64+t*4,0,128,128,0)
end

function update_postgame()
 t+=0.25
 if t>16 then
  camera(0,0)
  show=2
  scr.upd = update_result
  scr.drw = draw_result
 end
end

function draw_postgame()
 camera(128-t*8,0)
 
 draw_result()
 
 --rectfill(0,0,128,t*4,0)
 --rectfill(0,128-t*4,128,128,0)
 --rectfill(0,0,t*4,128,0)
 --rectfill(128-t*4,0,128,128,0)
end

function init_bot(id)
 b={}
 b.i=id+numplayers
 b.x=flr(rnd(115))-3 --position x
	b.y=flr(rnd(109))+3 --position y
	b.mx=0
	b.my=0
	b.mt=0
 b.rndxs=3
 b.rndys=3
 b.rndxo=-1
 b.rndyo=-1
	if(flr(rnd(2))==1)then
	 b.f=true
	else
	 b.f=false --flip
	end
	b.t=flr(rnd(4)) --animation time
	b.ch=0 --character
 b.coins=0
 b.death=false
 temp0=flr(rnd(2))+1
 if(temp0==2)then
  temp1=flr(rnd(10))+2
 else
  temp1=flr(rnd(11))+2
 end
	temp2=flr(rnd(11))+2
	b.c={colorl[temp0],colord[temp0],
	colorl[temp1],colord[temp1],
	colorl[temp2],colord[temp2]}
	b.menu=0
	
 return b
end
function init_player(id)
 p={} --new player
 p.i=id --id
 p.x=flr(rnd(115))-3 --position x
	p.y=flr(rnd(109))+3 --position y
	p.vx=0.0 --velocity x
	p.vy=0.0 --velocity y
 p.my=0	
	p.f=false --flip
	if(rnd(2)>1)p.f=true
	p.t=flr(rnd(4)) --animation time
	p.s=0
	p.talk=false
	p.shoot=false
	p.preshoot=false
	p.ch=0 --character
 p.g=false
 p.coins=0
 p.death=false
	p.kills=0
	p.botkills=0
	
	temp0=flr(rnd(2))+1
 if(temp0==2)then
  temp1=flr(rnd(10))+2
 else
  temp1=flr(rnd(11))+2
 end
	temp2=flr(rnd(11))+2

	p.c={colorl[temp0],colord[temp0],
	colorl[temp1],colord[temp1],
	colorl[temp2],colord[temp2]}
	
 return p
end

function update_game()
 --gametime+=0.25
 t+=0.25
 
 if (gameover)then
  
  t=0
  
  show_result()
 end

 foreach(players,update_player)
 foreach(bots,update_bot)
 foreach(coins,collide_coin)
 foreach(players,collide_shot)
 nextcoin-=1
 if (#coins==0 and nextcoin <=0) then
  c={}
  c.x=flr(rnd(122))
  c.y=flr(rnd(110))+10
  add(coins,c)
 end
 
end

function update_bot(b)
 if not b.death then
 b.t+=0.125
 if b.mt<=0 then
  b.mt=flr(rnd(50))
  b.mx=0
  b.my=0

  if (b.walll or b.wallr) rndx=2
  if (b.wallr) rndxplus = 1
  b.mx=(flr(rnd(b.rndxs))+b.rndxo)/2
  b.my=(flr(rnd(b.rndys))+b.rndyo)/4

  b.rndxs=3
  b.rndys=3
  b.rndxo=-1
  b.rndyo=-1

  if(b.mx>0)b.f=true
  if(b.mx<0)b.f=false
  if(b.mx==0)b.mt*=2
  b.s=1
  if(b.mx==0 and b.my==0)b.s=0
 else
  b.mt-=1
  b.yl=b.y
  b.x+=b.mx
  b.y+=b.my
  --b.up
  --if(b.yl<b.y)b.up=1
 end

 --move restrictions

 if(b.menu==1)then
  if(b.x<-3)b.x=-3 b.mx=0 b.rndxs=2 b.rndxo=0 
  if(b.x>115)b.x=115 b.mx=0 b.rndxs=2 b.rndxo=-1 
  if(b.y<60)b.y=60 b.my=0 b.rndys=2 b.rndyo=0
  if(b.y>111)b.y=111 b.my=0 b.rndys=2 b.rndyo=-1
  if(b.mx==0 and b.my==0)b.s=0

 elseif(b.menu==2)then 
  if(b.x<-3)b.x=-3 b.mx=0 b.rndxs=2 b.rndxo=0 
  if(b.x>115)b.x=115 b.mx=0 b.rndxs=2 b.rndxo=-1 
  
  if(b.x<69 and b.my<0)then
   if(b.y<19)b.y=19 b.my=0 b.rndys=2 b.rndyo=0
  else
   if(b.y<3)b.y=3 b.my=0 b.rndys=2 b.rndyo=0
  end
  
  if(b.y<19)then
   if(b.x<69)b.x=69 b.mx=0 b.rndxs=2 b.rndxo=0
  else
   if(b.x<-3)b.x=-3 b.mx=0 b.rndxs=2 b.rndxo=0
  end
  
  if(b.y>54)b.y=54 b.my=0 b.rndys=2 b.rndyo=-1
  if(b.mx==0 and b.my==0)b.s=0

 else
  if(b.x<-3)b.x=-3 b.mx=0 b.rndxs=2 b.rndxo=0 
  if(b.x>115)b.x=115 b.mx=0 b.rndxs=2 b.rndxo=-1 
  if(b.y<3)b.y=3 b.my=0 b.rndys=2 b.rndyo=0
  if(b.y>111)b.y=111 b.my=0 b.rndys=2 b.rndyo=-1
  if(b.mx==0 and b.my==0)b.s=0
  end
 end 
end

function update_player(p)
 --time
 p.t+=0.125
  
 if not p.death then
 
 --state
 p.slast=p.s
 if(p.s!=2)p.s=0
 
 --input
 
 p.l=btn(0,p.i-1)
	p.r=btn(1,p.i-1)
	p.u=btn(2,p.i-1)
	p.d=btn(3,p.i-1)
	p.a=btn(4,p.i-1)
	p.b=btn(5,p.i-1)
	--talk 
	if (false and p.a and p.s!=2) then
	 p.s=5
	 if (not p.talk) then
	  --sfx(1,p.i)
   p.talk=true
  end	
	else
	 if p.talk then
	  --sfx(-1,p.i)
	  p.talk=false
	 end
	end
	
	--walking ‹ ‘
	p.my=0
	p.mx=0
	if (p.s!=2 and p.s!=3 and 
	   p.s!=4 and p.s!=5) then
	 if(p.l and p.x>-3) then
	  p.x-=0.5
	  p.f=false
	  p.s=1
	 end
	 if(p.r and p.x<115) then
	  p.x+=0.5 
	  p.f=true
	  p.s=1
	 end
	 if(p.u and p.y>3) then
	  if(p.l or p.r)p.mx=1
	  p.my=-1
	  p.y-=0.25 
	  p.s=1
	 end
	 if(p.d and p.y<111) then
	  p.y+=0.25
	  p.s=1
	 end
	end
 
	--shoot —
	if ((p.b or p.a) and not p.preshoot) then
	 p.s=2
	 p.preshoot=true
	end
	if not p.b then 
	 p.preshoot=false
	end
	
	if(p.s==2 and p.t==2)then
	 p.shoot=true
  sfx(0)
	end
	
	if(p.s==2 and p.t==5)then
	 p.s=0
	 p.t=0
	end
	
 --state
 if p.s!=p.slast then 
  p.t=0 
 end
 
 p.slast=p.s
 
 end
end

function collide_shot(p)
 hit=false
 step=0
 if p.s==2 and flr(p.t)==2 
 and p.shoot then
  p.shoot=false
  while(not hit)do
   if(p.f)then
    h=rsh
    h[3]=step+15
   else
    h=lsh
    h[1]=-step
   end
   step+=1
   if(step==128)hit=true
  
   for i=1,numplayers do
    if (collide(p,h,players[i],ph)and not players[i].death) then
     hit=true
     players[i].death=true
     deaths[i]+=1
     p.kills+=1
     numdeaths+=1
     
     if(end_kill_pl and #wincause[p.i]<=numgames)then
      wins[p.i]=1
      add(wincause[p.i],"kill")
      gameover=true
      sfx(6)
     end
     if p.f==players[i].f then
      players[i].s=4
     else
      players[i].s=3
     end
     
    end
  
   end
   for i=1,numbots do
    if (collide(p,h,bots[i],ph)and not bots[i].death) then
     hit=true
     bots[i].death=true
     p.botkills+=1
     deathbot=i
     if(end_kill_bot)then
      
      for j=1,numplayers do
       if(p.i!=j and not players[j].death and #wincause[j]<=numgames)then
        wins[j]=1
        add(wincause[j],"skull")
       end
      end 
      gameover=true
      sfx(6)
     end
     if p.f==bots[i].f then
      bots[i].s=4
     else
      bots[i].s=3
     end
    end
   end 
  end
 end
 if(numplayers-numdeaths==1 and not gameover)then
  for i=1,numplayers do
   if(not players[i].death and #wincause[i]<=numgames)then
    gameover=true
    wins[i]=1
    add(wincause[i],"last")
    sfx(6)
   end
  end     
 end
 
end

function collide_coin(c)
 --logika pozrani mince
 for i=1,numplayers do
  if collide(players[i],ph,c,ch) then
   players[i].coins+=1
   if(players[i].coins==end_coins and #wincause[i]<=numgames)then
    wins[i]=1
    add(wincause[i],"coin")
    gameover=true
    sfx(7)
   end
   coins={}
   sfx(3)
   nextcoin=flr(rnd(10))
  end
 end
 for i=1,numbots do
  if collide(bots[i],ph,c,ch) then
   bots[i].coins+=1
   coins={}
   sfx(3)
   nextcoin=flr(rnd(10))
  end
 end
end

function collide(a,ah,b,bh)
 return 
 a.x+ah[3]>=b.x+bh[1] and
 b.x+bh[3]>=a.x+ah[1] and
 a.y+ah[4]>=b.y+bh[2] and
 b.y+bh[4]>=a.y+ah[2] 
  --return a2>=b1 and b2>=a1 
end

function draw_game()
 cls()
 pal()
 palt(0,false)
 palt(15,true)
 rectfill(0,0,128,128,0)
 map(16,16)
 map(0,16,-128,0)
 if (numgames<9)then
  print(numgames+1,67,0,7)
 else
  print(numgames+1,65,0,7)
 end
 foreach(coins,draw_coin)
 --print(time(),100,100)
 for y=0,128 do
  for i=1,numplayers do
   if(flr(players[i].y)==y)draw_player(players[i])
  end
  for i=1,numbots do
   if(flr(bots[i].y)==y)draw_player(bots[i])
  end
 end
 
 if debug then
  print("x "..players[1].x,0,0)
  print("y "..players[1].y,0,6)
  print("vx "..players[1].vx,0,12)
  print("vy "..players[1].vy,0,18)
  if (players[1].g) print("g",0,24)
  rect(0,10,122,120,8)
 end
end

function draw_player(p)
	
 --set palete
 pal(7,p.c[1])
 pal(9,p.c[2])
 pal(14,p.c[3])
 pal(8,p.c[4])
 pal(11,p.c[5])
 pal(3,p.c[6])

--states 
--1 walking
--2 shooting
--3 death from front
--4 death from back
--5 talking
--else idle

--walking
 if p.s==1 then
  up=0
  if(p.my<0 and (p.mx==0 or true))up=1
  spr((8+64*up)+flr(p.t%4)*2,p.x,p.y,2,2,p.f)
--shooting 
 elseif p.s==2 then
  spr((36+64*p.ch)+flr(p.t%6)*2,p.x,p.y,2,2,p.f)
--death drom front  
 elseif p.s==3 then
  yoff=2
  if(p.f)then
   xoff=3
  else
   xoff=-3
  end
  if(p.t<2)then
   spr((64+64*p.ch)+flr(p.t%2)*2,p.x-xoff,p.y+yoff,2,2,p.f)
  else
   spr((66),p.x-xoff,p.y+yoff,2,2,p.f)
  end
--death drom back  
 elseif p.s==4 then
  yoff=2
  if(p.f)then
   xoff=-3
  else
   xoff=3
  end
  if(p.t<2)then
   spr((68+64*p.ch)+flr(p.t%2)*2,p.x-xoff,p.y+yoff,2,2,p.f)
  else
   spr((70),p.x-xoff,p.y+yoff,2,2,p.f)
  end
--speak
 elseif p.s==5 then
   spr((32+64*p.ch)+flr(p.t%2)*2,p.x,p.y,2,2,p.f)
 
--idle
 else
  spr((0+64*p.ch)+flr(p.t%4)*2,p.x,p.y,2,2,p.f)
 end

 pal()
 palt(0,false)
 palt(15,true)

 if debug then
  rect(p.x+ph[1], p.y+ph[2], p.x+ph[3], p.y+ph[4],5)
  rect(p.x+lsh[1], p.y+lsh[2], p.x+lsh[3], p.y+lsh[4],4)
  rect(p.x+rsh[1], p.y+rsh[2], p.x+rsh[3], p.y+rsh[4],4)
  
  --rect(p.x+3, p.y+1, p.x+12, p.y+15,5)
  line(p.x+5,p.y+16,p.x+10,p.y+16,3)
  line(p.x,p.y,p.x,p.y,7)
  print(p.coins,p.x+6,p.y-4,7)
  print(p.s,p.x+10,p.y-4,7)
  print(p.deaths,p.x+2,p.y-4,7)
 end
end

function draw_name(p)
  xo=0
  yo=0
  if(p.s==3)then
   if(p.f)then
    xo=-3
   else
    xo=4
   end 
   yo=7
  end 
  if(p.s==4)then
   if(p.f)then
    xo=4
   else
    xo=-3
   end 
   yo=7
   
  end 
  --if(p.y<20)yo=24
  rectfill(p.x+xo,p.y-7+yo,p.x+14+xo,p.y-1+yo,0)
  max_score=max(max(gwins[4],gwins[1]),max(gwins[2],gwins[3]))
  if (max_score>=gamestowin and max_score==gwins[p.i]) then 
   print(names[p.i],p.x+xo+2,p.y-6+yo,7+wins[p.i])
  else
   print(names[p.i],p.x+xo+2,p.y-6+yo,7+wins[p.i]*2)
  end
  color(7)
end


function draw_coin(c)
 spr(132+(t/2%4),c.x,c.y)
 if debug then
  rect(c.x+ch[1], c.y+ch[2], c.x+ch[3], c.y+ch[4],5)
  rect(c.x+1, c.y+1, c.x+6, c.y+6,5)
  line(c.x,c.y,c.x,c.y,7)
 end
end

__gfx__
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffff00000000ffffffffffffffffffffffffffffffffffffffff00000000ffffffffffffffffffffffff00000000ffffffffffffffffffffffff00000000ffff
ffff07777990ffffffff00000000ffffffff00000000ffffffff07777990ffffffff00000000ffffffff07777990ffffffff00000000ffffffff07777990ffff
ffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffff
ffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffff
ffff09799990ffffffff07777990ffffffff07777990ffffffff09799990ffffffff07777990ffffffff09799990ffffffff07777990ffffffff09799990ffff
ffff07797990ffffffff09799990ffffffff09799990ffffffff07797990ffffffff09799990ffffffff07797990ffffffff09799990ffffffff07797990ffff
ffff07997990ffffffff07797990ffffffff07797990ffffffff07997990ffffffff07797990ffffffff07997990ffffffff07797990ffffffff07997990ffff
ffff07777990ffffffff07997990ffffffff07997990ffffffff07777990ffffffff07997990ffffffff07777990ffffffff07997990ffffffff07777990ffff
fffff0888e880fffffff077779980fffffff07777990fffffffff0888e880fffffff07777990fffffffff0888e880fffffff07777990fffffffff0888e880fff
fffff0eeee880ffffffff0888e880ffffffff0888e880ffffffff0eeee880ffffffff0888e880ffffffff0eeee880fffffff00888e8800fffffff0eeee880fff
ffff07eeee8790ffffff07eeee8790fffffff0eeee880ffffffff0eeee880ffffffff0eeee790fffffff07eeee8790fffff079eeee88790fffff07eeee8790ff
ffff07bbbb3790ffffff07bbbb3790ffffff07eeee8790ffffff07bbbb3790fffffff0eeee790fffffff07bbbb3790fffff079eeee88790fffff07bbbb3790ff
fffff03303300ffffffff03303300fffffff07bbbb3790ffffff0733033790ffffff03bbbb330ffffffff03303300fffffff00bbb33300fffffff03303300fff
fffff0b30b30fffffffff0b30b30fffffffff03303300ffffffff0b30b300fffffff0b3000b30ffffffff0b30b30ffffffffff00b300fffffffff0b30b30ffff
fffff0000000fffffffff0000000fffffffff0000000fffffffff0000000ffffffff000fff000ffffffff0000000ffffffffff00000ffffffffff0000000ffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffff00000000ffffffff00000000ffffffff00000000ffffffff00000000ffffffff00000000ffffffff00000000ffffffff00000000ffffffff00000000ffff
ffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffff
ffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffff
ffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffffffff07777990ffff
ffff09799990ffffffff09799990ffffffff09799990ffffffff09799990ffffffff09799990ffffffff09799990ffffffff09799990ffffffff09799990ffff
ffff07797990ffffffff07797990ffffffff07797990ffffffff07797990ffffffff07797990ffffffff07797990ffffffff07797990ffffffff07797990ffff
ffff07997990ffffffff07997990ffffffff07997990ffffffff07997990ffffffff07997990ffffffff07997990ffffffff07997990ffffffff07997990ffff
ffff07007990ffffffff07007990ffffffff07777990ffff000007777990fffff00007777990ffff000007777990ffffffff07777990ffffffff07777990ffff
ffff077779880fffffff070079880ffffffff0888e880fff066660888e880ffff06660888e880fff066660888e880ffffffff0888e880ffffffff0888e880fff
fffff0888e880ffffffff0778e880ffffffff0eeee880ffff00790eeee880fffff0070eeee880ffff00790eeee880ffffffff0eeee880ffffffff0eeee880fff
ffff07eeee8790ffffff0788ee8790ffffff00eeee8790fffff0d0eeee8790ffffff00eeee8790fffff0d0eeee8790ffffff00eeee8790ffffff07eeee8790ff
ffff07bbbb3790ffffff07bbbb3790fffff070bbbb3790ffffff00bbbb3790fffffff0bbbb3790ffffff00bbbb3790fffff070bbbb3790ffffff07bbbb3790ff
fffff03303300ffffffff03303300fffff06003303300ffffffff03303300ffffffff03303300ffffffff03303300fffff06003303300ffffffff03303300fff
fffff0b30b30fffffffff0b30b30fffffff0f0b30b30fffffffff0b30b30fffffffff0b30b30fffffffff0b30b30fffffff0f0b30b30fffffffff0b30b30ffff
fffff0000000fffffffff0000000fffffffff0000000fffffffff0000000fffffffff0000000fffffffff0000000fffffffff0000000fffffffff0000000ffff
ff00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ff07777990fffffffffffffffffffffffffff00000000fffffffffffffffffffffffffffffffffffffff00000000ffffffffffffffffffffffff00000000ffff
ff07777990fffffffffffffffffffffffffff07777990fffffffffffffffffffffff00000000ffffffff07799990ffffffff00000000ffffffff07799990ffff
ff07777990fffffffffffffffffffffffffff07777990fffffffffffffffffffffff07799990ffffffff07799990ffffffff07799990ffffffff07799990ffff
ff09799990fffffffffffffffffffffffffff07777990fffffffffffffffffffffff07799990ffffffff07799990ffffffff07799990ffffffff07799990ffff
ff07797990fffffffffffffffffffffffffff09799990fffffffffffffffffffffff07799990ffffffff07799990ffffffff07799990ffffffff07799990ffff
ff07997990ffffffffff00ff00000000fffff07797990fffffffffffffffffffffff07799990ffffffff07799990ffffffff07799990ffffffff07799990ffff
ff07777990fffffff000770077797770fffff07997990fffffffffff0000ffffffff07799990ffffffff07799990ffffffff07799990ffffffff07799990ffff
fff0888e880ffffff0b3beee79777770fffff07777990fff00000000eeeb000fffff07799990ffffffff07799990ffffffff07799990ffffffff07799990ffff
fff0eeee880ffffff033beee79997770ffffff0888e880ff07777777eeeb3b0fffff07799990fffffffff0ee88880fffffff07799990fffffffff0ee88880fff
ff07eeee8790fffff000beee77797770ffffff0eeee880ff07777777eeeb330fffff00ee88880ffffffff0ee88880fffffff00ee88880ffffffff0ee88880fff
ff0b30b33790fffff0b3beee99999990fffff07eee79800f07777777eeeb000ffff079ee888890ffffff079e88880ffffffff07988880fffffff079e88880fff
ff0b30b3000ffffff033388899999990fffff07bbb79330f0777777788833b0ffff079ee888890ffffff079b33330ffffffff07988880fffffff079b33330fff
ff0000000ffffffff000778800000000ffffff000000000f099999998877330fffff00bb33330ffffffff0330330ffffffff03bb33330ffffffff0330330ffff
fffffffffffffffffff09900ffffffffffffffffffffffff099999990099000fffffff00b300fffffffff0b30b30ffffffff0b3000b30ffffffff0b30b30ffff
ffffffffffffffffffff00ffffffffffffffffffffffffff00000000ff00ffffffffff00000ffffffffff0000000ffffffff000fff000ffffffff0000000ffff
00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
07777660ffffffffffff00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
077776d0ffffffffffff07777660fffff000000ff000000ff000000fff0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
077776d0ffffffffffff07777660fffff079940ff097790ff049970fff0440fff000000f0000000f000000ffff000ffff000000ff0000000ff000000fff000ff
06766660ffffffffffff077776d0fffff074940ff094490ff049470fff0440fff076660f0677660f066670ffff060ffff076660ff0677660ff066670fff060ff
07767660ffffffffffff067666d0fffff094940ff094490ff049490fff0440ffff000990f000f490f000440fff060fff044000ff094f000ff099000ffff090ff
07667660ffffffffffff07767660fffff099940ff099990ff049990fff0440ffffff0990ffff0490fff0440fff040fff0440ffff0940fffff0990ffffff090ff
07777660ffffffffffff07667660fffff000000ff000000ff000000fff0000fffffff000fffff000ffff000fff000fff000fffff000ffffff000fffffff000ff
f0888e880fffffffffff07777660ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f0eeee880ffffffffffff0888e880fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
07eeee8760fffffffffff0eeee880ffff00f000f000f000f000f00ffff000ffff000000ff000000ff000000ff000000ff000000ff000000ff000000ff000000f
07bbbb3760ffffffffff07eeee8760fff070e80f0e707e0f08e070ffff080ffff077770ff077770ff077770ff077770ff077770ff077770ff077770ff077770f
f03303300fffffffffff07bbbb3760fff07ee80f0eeeee0f08ee70ffff080ffff007070ff007700ff070700ff077700ff077770ff077770ff077770ff007770f
f0b30b30fffffffffffff03303300ffff0eee80ff0eee0ff08eee0ffff080ffff076770ff076670ff077670ff077770ff077770ff077770ff077770ff077770f
f0000000fffffffffffff0b30b30ffffff0e80ffff0e0ffff08e0fffff080ffff07770fff077770fff07770fff00070fff00670fff0660fff07600fff07000ff
fffffffffffffffffffff0000000fffffff00ffffff0ffffff00ffffff000ffff0000fffff0000fffff0000ffffff00fffff000fff0000fff000fffff00fffff
55555555000000005555555555555555ffffffffffffffffffffffffff0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
55555555666d76665555555555555555f000000ffffffffff000000fff0440ffffffffffffffffffffffffffff000ffffffffffffffffffffffffffffff000ff
00000000666d66667777777755555555f079940ff000000ff049970fff0440fff000000fffffffff000000ffff060ffff000000fffffffffff000000fff060ff
666d7666666d66667777777755555555f074940ff097790ff049470fff0440fff076660f0000000f066670ffff060ffff076660ff0000000ff066670fff090ff
666d6666000000007777777755555555f094940ff094490ff049490fff0440ffff0009900677660ff000440fff040fff044000fff0677660f099000ffff090ff
666d6666ddd0dddd7777777755555555f099940ff094490ff049990fff0000ffffff0990f000f490fff0440fff000fff0440ffff094f000ff0990ffffff000ff
666d6666ddd0dddd5555555555555555f000000ff099990ff000000ffffffffffffff000ffff0490ffff000fffffffff000fffff0940fffff000ffffffffffff
00000000000000005555555555555555fffffffff000000ffffffffffffffffffffffffffffff000ffffffffffffffffffffffff000fffffffffffffffffffff
fffffffffffffffffffffffff000000fffffffffffffffffffffffffff000ffffffffffffffffffffffffffff000000ffffffffffffffffffffffffff000000f
00000000ffffffff00000000f066660ff00f000fffffffff000f00ffff080ffff000000ffffffffff000000ff077770ff000000ffffffffff000000ff077770f
077776600000000006677770f055550ff070e80f000f000f08e070ffff080ffff077770ff000000ff077770ff077700ff077770ff000000ff077770ff007770f
066665500777777005566660f066660ff07ee80f0e707e0f08ee70ffff080ffff007070ff077770ff070700ff077770ff077770ff077770ff077770ff077770f
077776600666666006677770f066660ff0eee80f0eeeee0f08eee0ffff080ffff076770ff007700ff077670fff00070ff077770ff077770ff077770ff07000ff
077776600777777006677770f000000fff0e80fff0eee0fff08e0fffff000ffff07770fff076670fff07770ffffff00fff00670ff077770ff07600fff00fffff
000000000777777000000000fffffffffff00fffff0e0fffff00fffffffffffff0000ffff077770ffff0000fffffffffffff000fff0660fff000ffffffffffff
ffffffff00000000fffffffffffffffffffffffffff0ffffffffffffffffffffffffffffff0000ffffffffffffffffffffffffffff0000ffffffffffffffffff
555555555555555566666666055555550ddddddd05555555dddddddd555555550ddddddd55555555ff0000ff6666666066666666666666600666666606666666
555555555555555566666666d7ddddddd76666665ddddddddddddddd555555550000000077777777f0ee880f6666666066666666666666600666666606666666
777777775555555566666666d66dddddd66666665ddddddddddddddd5555555566666666000000000e8e88e06666666066666666666d66600666666606666666
777777775555555566666666d666ddddd66666665ddddddddddddddd0000000066666666666666660e8e88e06666666066666666666666d00666666606666666
7777777755555555666666660dddd5550ddddddd05555555dddddddd666666660000000066666666f0ee880f66666660666666666d66ddd00666666606666666
777777775555555566666666d76666ddd76666665ddddddddddddddd66666666dddddddd66666666f0ee880f666666606666666666ddddd00666666606666666
555555555555555566666666d666666dd66666665ddddddddddddddd66666666dddddddd666666660eee888066666660666666666dddddd00666666606666666
555555555555555566666666d6666666d66666665ddddddddddddddd000000000000000000000000f000000f6666666000000000000000000000000006666666
7ddd7dd79aaa9aa9007770060ddddddd88888888877776606666666000000000000000000000000000000000555555556d66dd66666666666666666666d66666
7dd777779a9a99a900070006d76666558888888887777660333336600999999044444440999999909999999055555555666dddd666d6666666dd66d66666ddd6
777dd7779aaa999900707006d6666d558888888887767660333333600999999044444440444444404444444055555555666dddd6d66666d66dddd6d6666ddddd
7d7777d799999aa900070006d666d5558888888887667660333333600000000044444440999999909999779005555555666dddd6d66dd6666dddd666666ddddd
777776779aaa99a9007070060ddd5555888888888666666033333360000000004444666044444440444466405500550066d6dd6666dddd666dddd6666666dddd
666666669999999900070006d7666666888888888666666033333360000000004444666044444440444466400000005566d6dd666dddddd666dd6d6666d6dddd
666666666666666600707006d6666666666666666666666033333360000000004444444046644440444444405000000566666d66ddddddd6666d6d6666d6d6d6
666666666666666600000006d666666666666666666666603333366000000000000000004664444000000000550000550000000000000000666d6666666666d6
777777777777777777777777777777777777777677777777fffffffffffffffffffffffffffffffffff000fffffffffffffffffffff000fffff000ffffffffff
777777777777777777777777777777777777777777777777ffffffffffffffffffffffffffffffffff077700ffffffffffffffffff0000000000000fffffffff
777777777777777777777777777777777777777777777777ffff0fffffff0fffffff0fffffff0ffff0766777fffffffffffffffff00660000000a000ffffffff
777777777777777777777777677777777777777777777777ff00a00fff00a00fff00a00fff00a00ff076d767fffffffffffffffff006d060a00c0800ffffffff
777777777777777777777776667777777777777777777777f08a8880f088a880f0888a80f0a888a00777766dffffffff0fffffff0000066d0660b00d0fffffff
777777777777777777777766777777777777776677777777f0898880f0889880f0888980f0988890077777d7ffffffff0fffffff000000d006d0000d0fffffff
777777777776777777777666777777777777777777777777ff09990fff09990fff09990fff09990f07777777ffffffff0fffffff000000000000000d0fffffff
777777777676677777776666777777777777777777777777ff00000fff00000fff00000fff00000f07777666ffffffff0fffffff00000dddddd000dd0fffffff
7777777777777777777777777ffffffffffffff7ffffffff777777777ffffff7777777777777777707776600000666660fff07770000dd00000ddddd06dd0fff
777777777777777ff777777777ffffffffffff77fffffffff777777f77ffff777777777777777777066600fffff006660fff06dd0ddd00fffff00ddd06d0ffff
77777777777777ffff777777777ffffffffff777ffffffffff7777ff777ff7777777777777777777f000fffffffff000fffff0977000fffffffff000f00d0fff
7777777777777ffffff777777777ffffffff7777fffffffffff77fff777777777777777777777777ffff0799994760ffffff0799994760ffffff076666d760ff
777777777777ffffffff777777777ffffff77777fff77fffffffffff77777777777ff77777777777ffff0799994760ffffff0799994760ffffff0799994760ff
77777777777ffffffffff777777777ffff777777ff7777ffffffffff7777777777ffff7777777777fffff04404400ffffffff09999440ffffffff04404400fff
7777777777ffffffffffff777777777ff7777777f777777fffffffff777777777ffffff777777777fffff0940940fffffffff0760760fffffffff0940940ffff
777777777ffffffffffffff7777777777777777777777777ffffffff77777777ffffffff77777777fffff0000000fffffffff0000000fffffffff0000000ffff
6666666666666666666666666ffffffffffffff6fff000fffff000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
666666666666666ff666666666ffffffffffff66ff0777000007770fffffffffffff000000000fffffff000000000fffffff000000000fffffff000000000fff
66666666666666ffff666666666ffffffffff666f07667777777a770ffffffffffff099999440fffffff099999440fffffff099999440fffffff099999440fff
6666666666666ffffff666666666ffffffff6666f076d767a77c7870ffffffffffff077999440fffffff077999440fffffff077999440fffffff077999440fff
666666666666ffffffff666666666ffffff666660777766d7667b7760fffffffffff077779440fffffff077779440fffffff077779440fffffff077779440fff
66666666666ffffffffff666666666ffff666666077777d776d777760fffffffffff097999440fffffff097999440fffffff097999440fffffff097999440fff
6666666666ffffffffffff666666666ff666666607777777777777760fffffffffff077979440fffffff077979440fffffff077979440fffffff077979440fff
666666666ffffffffffffff6666666666666666607777666666777660fffffffffff079979440fffffff079979440fffffff079979440fffffff079979440fff
ffffffffffffffffffffffffffffffffffffffff07776600000666660fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffff066600fffff006660fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffff000fffffffff000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000f000000fff0000fff000000f00000000ffffffffffffffffffffffff00000000f000000fff0000fff000000f00000000f000000fff0000fff000000f
06566660f056660fff0560fff055550f05555550ffffffffffffffffffffffff06566660f0d6560fff0d60fff0dddd0f0dddddd0f0dddd0fff06d0fff0666d0f
05556650f055650fff0560fff055550f05555550ffffffffffffffffffffffff05556680f0d5550fff0d60fff0dddd0f0dddddd0f0dddd0fff06d0fff0668d0f
06566560f056560fff0560fff055550f05555550ffffffffffffffffffffffff06566860f0d6560fff0d60fff0dddd0f0dddddd0f0dddd0fff06d0fff0686d0f
00000000f000000fff0000fff000000f00000000ffffffffffffffffffffffff00000000f000000fff0000fff000000f00000000f000000fff0000fff000000f
__label__
666666667ddd7dd79aaa9aa900777006666666669aaa9aa97ddd7dd700777006888778888777766000000000055555550ddddddd066666667ddd7dd79aaa9aa9
666666667dd777779a9a99a900070006666666669a9a99a97dd77777000700068888788887777660999999905dddddddd7666666066666667dd777779a9a99a9
66666666777dd7779aaa999900707006666666669aaa9999777dd777007070068888788887767660444444405dddddddd666666606666666777dd7779aaa9999
666666667d7777d799999aa9000700066666666699999aa97d7777d7000700068888788887667660999999905dddddddd6666666066666667d7777d799999aa9
66666666777776779aaa99a900707006666666669aaa99a97777767700707006888777888666666044444440055555550ddddddd06666666777776779aaa99a9
66666666666666669999999900070006666666669999999966666666000700068888888886666660444444405dddddddd7666666066666666666666699999999
66666666666666666666666600707006666666666666666666666666007070066666666666666660466444405dddddddd6666666066666666666666666666666
66666666666666666666666600000006666666666666666666666666000000066666666666666660466444405dddddddd6666666066666666666666666666666
666666666d66dd66666666666666666666666666666666666666666666666666666666666666666000000000000000000000000006666666666666666d66dd66
66666666666dddd66666666666666666666666666666666666d666666666666666666666666666604444444099999990999999900666666666666666666dddd6
66666666666dddd666666666666666666666666666666666d66666d66666666666666666666d66604444444044444440444444400666666666666666666dddd6
66666666666dddd666666666666666666666666666666666d66dd6666666666666666666666666d04444444099997790999977900666666666666666666dddd6
6666666666d6dd666666666666666666666666666666666666dddd6666666666666666666d66ddd0444466604444664044446640066666666666666666d6dd66
6666666666d6dd66666666666666666666666666666666666dddddd6666666666666666666ddddd0444466604444664044446640066666666666666666d6dd66
6666666666666d6666666666666666666666666666666666ddddddd666666666666666666dddddd0444444404444444044444440066666666666666666666d66
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0555555505555555055555550555555505555555055555550555555505555555055555550555555505555555055555550ddddddd055555550555555505555555
5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5dddddddd7666666d7dddddd5ddddddd5ddddddd
5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5dddddddd6666666d66ddddd5ddddddd5ddddddd
5ddddddd5dd00000000ddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5dddddddd6666666d666dddd5ddddddd5ddddddd
0555555505509977770555550555555505555555055555550555555505555555055555550555555505555555055555550ddddddd0dddd5550555555505555555
5ddddddd5dd09977770ddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5dddddddd7666666d76666dd5ddddddd5ddddddd
5ddddddd5dd09977770ddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5dddddddd6666666d666666d5ddddddd5ddddddd
5ddddddd5dd09999790ddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5dddddddd6666666d66666665ddddddd5ddddddd
0555555505509979770555550555555505555555055555550555555505555555055555550555555505555555055555550ddddddd0ddddddd0555555505555555
5ddddddd5dd09979970ddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5dddddddd7666666d7666666d7dddddd5ddddddd
5ddddddd5d099977770ddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5dddddddd6666666d6666666d66ddddd5ddddddd
5ddddddd5d099a9990dddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5dddddddd6666666d6666666d666dddd5ddddddd
0555555500979aaaa70555550555555505555555055555550555555505555555055555550555555505555555055555550ddddddd0ddddddd0dddd55505555555
5ddddddd50978eeee70ddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5dddddddd7666666d7666666d76666dd5ddddddd
5ddddddd5d00880880dddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5dddddddd6666666d6666666d666666d5ddddddd
5ddddddd5dd08e08e0dddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5ddddddd5dddddddd6666666d6666666d66666665ddddddd
0ddddddd0dd0000000dddddd0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd0d00000000dddddd0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd
d7666666d7666666d7666666d7666666d7666666d7666666d7666666d7666655d709977770666666d7666666d7666666d7666666d7666666d7666666d7666666
d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666d55d609977770666666d6666666d6666666d6666666d6666666d6666666d6666666
d6666666d6666666d6666666d6666666d6666666d6666666d6666666d666d555d609977770666666d6666666d6666666d6666666d6666666d6666666d6666666
0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd0ddd55550d09999790dddddd0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd
d7666666d7666666d7666666d7666666d7666666d7666666d7666666d7666666d709979770666666d7666666d7666666d7666666d7666666d7666666d7666666
d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d609979970666666d6666666d6666666d6666666d6666666d6666666d6666666
d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d609977770666666d6666666d6666666d6666666d6666666d6666666d6666666
0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd004494440ddddddd0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd
d7666655d7666666d7666666d7666666d7666666d7666666d7666666d7666666d044999907666666d7666666d7666655d7666666d7666666d7666666d7666666
d6666d55d6666666d6666666d6666666d666600000000666d6666666d66666660974999970666666d6666666d6666d55d666666600000000d6666666d6666666
d666d555d6666666d6666666d6666666d666604499990666d6666666d66666660979aaa000000006d6666666d666d555d666666609977770d6666666d6666666
0ddd55550ddddddd0ddddddd0ddddddd0dddd04499990ddd0ddddddd0ddddddd000990907777990d0ddddddd0ddd55550ddddddd099777700ddddddd0ddddddd
d7666666d7666666d7666666d7666666d766604499990666d7666666d7666666d709a09077779906d7666666d7666666d766666609977770d7666666d7666666
d6666666d6666666d6666666d6666666d666604444940666d6666666d6666666d600000077779906d6666666d6666666d666666609999790d6666666d6666666
d6666666d6666666d6666666d6666666d666604494990666d6666666d6666666d666666097999906d6666666d6666666d666666609979770d6666666d6666666
0ddddddd0ddddddd0ddddddd0ddddddd0dddd04494490ddd0ddddddd0ddddddd0dddddd07797990d0ddddddd0ddddddd0ddddddd099799700ddddddd0ddddddd
00000000000000000000000000000000000001449999000000000000000000000000000079979900000000000000000000000000099777700000000000000000
666666666666666666666666666666666666011d1110666666666666666666666666666077779906666666666666666666666660449444066666666666666666
666666666666666666666666666666666660491dddd9066666666666666666666666666604449440666666666666666666666660979999066666666666666666
00000000000000000000000000000000000049499999000000000000000000000000000009999440000000000000000000000000979999000000000000000000
dddddddddddddddddddddddddddddddddddd00440440dddddddddddddddddddddddddddd09999440ddddddddddddddddddddddd022888820dddddddddddddddd
ddddddddddddddddddddddddddddddddddddd0490490ddddddddddddddddddddddddddd076666d790dddddddddddddddddddddd028000280dddddddddddddddd
0000000000000000000000000000000000000000000000000000000000000000000000007dd0dd79000000000000000000000000000000000000000000000000
55555555555555555555555555555555555555555555555555555555555555555555555506d06d00555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555500000005555555555555555555555555555555555555555555555555
55555555555555555555555555555555777777777777777777777777555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555777777777777777777777777555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555777777777777777777777777555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555777777777777777777777777555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555000000005555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555077779905555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555077779905555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555077779907777777777777777777555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555097999907777777777700000077555555550555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555077979907777777777709779077555555555500550055555555555555555555555555555555555555555555555555555555
55555555555555555555555555555079979907777777777709449077555555550000005555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555077779905555555555509449055555555555000000555555555555555555555555555555555555555555555555555555555
5555555555555555555555555555550333b330555555555509999055555555555500005555555555555555555555555555555555555555555555555555555555
5555555555555555555555555555550bbbb330555555555500000055555555555555555555555555555555555555555555555555555555555555555555555555
5555555555555555555555555555507bbbb379055555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5555555555555555555555555555507dddd179077777777777777777555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555501101100777777777777777777555555555555555555555555555555555555555555555555555555555555555555555555
5555555555555555555555555555550d10d107777777777777777777555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555500000007777777777777777777555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
77777777777777775555555555555555777777777777777777777777555555555555555577777777777777777777777777777777555555555555555577777777
77777777777777775555555555555555777777777777777777777777555555555555555577777777777777777777777777777777555555555555555577777777
77777777777777775555555555555555777777777777777777777777555555555555555577777777777777777777777777777777555555555555555577777777
77777777777777775555555555555555777777777777777777777777555555555555555577777777777777777777777777777777555555555555555577777777
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555777777777777777777777777555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555777777777777777777777777555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555777777777777777777777777555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555777777777777777777777777555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555000000005555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555077779905555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555077779905555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555077779905555555555555555555555555555555
55555555555555555555555555555555777777777777777777777777555555555555555555555555555555555097999905555555555555555555555555555555
55555555555555555555555555555555777777777777777777777777555555555555555555555555555555555077979905555555555555555555555505555555
55555555555555555555555555555555777777777777777777777777555555555555555555555555555555555079979905555555555555555555555555005500
55555555555555555555555555555555777777777777777777777777555555555555555555555555555555555077779905555555555555555555555500000055
5555555555555555555555555555550000000055555555555555555555555555555555555555555555555555550999a990555555555555555555555550000005
5555555555555555555555555555550449999055555555555555555555555555555555555555555555555555550aaaa990555555555555555555555555000055
5555555555555555555555555555550449999055555555555555555555555555555555555555555555555555550aaaa990555555555555555555555555555555
5555555555555555555555555555550449999055555555555555555555555555000000005555555555555555507dddd179055555555555555555555555555555
55555555555555555555555555555504444940777777777777777777555555550777799055555555555555555071101179055555555555555555555555555555
5555555555555555555555555555550449499077777777777777777755555555077779905555555555555555550d10d100555555555555555555555555555555
55555555555555555555555555555504494490777777777777777777555555550777799055555555555555555500000005555555555555555555555555555555
55555555555555555555555555555504499990777777777777777777555555550979999055500000000555555555555555555555555555555555555555555555
555555555555555555555555555550dd6ddd05555555555555555555555555550779799055509999440555555555555555555555555555555555555555555555
555555555555555555555555555550dd666605555555555555555555555555550799799055509999440555555555555555555555555555555555555555555555
555555555555555555555555555550dd666605555555555555555555555555550777799055509999440555555555555555555555555555555555555555555555
55555555555555555555555555550498eeee90555555555555555555555555550044494400504944440555555555555555555555555555555555555555555555
55555555555555555555555555550498808890555555555555555555555555507999994479009949440555555555555555555555555555555555555555555555
00000000000000000000000000000008e08e00000000000000000000000000007999994479009449440000000000000000000000000000000000000000000000
666666666666666666666666666666000000066666666666666666666666666600bbb33300609999440666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666600b30066660222822066666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666600000666660888822066666666666666666666666666666666666666666666
00000000000000000000000000000000000000000000000000000000000000000000000000000888822000000000000000000000000000000000000000000000
0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd0dd09cccc1940ddd0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd
d7666666d7666666d7666666d7666666d7666666d7666666d7666666d7666655d7666666d760911011940666d7666666d7666666d7666666d7666655d7666666
d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666d55d6666666d6660c10c1006666d6666666d6666666d6666666d6666d55d6666666
d6666666d6666666d6666666d6666666d6666666d6666666d6666666d666d555d6666666d666000000066666d6666666d6666666d6666666d666d555d6666666
0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd0ddd55550ddddddd0ddddddd0ddddddd0ddddddd0ddddddd0ddddddd0ddd55550ddddddd
d7666666d7666666d7666666d7666666d7666666d7666666d7666666d7666666d7666666d7666666d7666666d7666666d7666666d7666666d7666666d7666666
d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666
d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010000000000000000000000000000000000000000000000000000000000010100000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
00000000000000000000000000000000cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000cbd0d0cbd0d0cbd4d0cbd7d7cbd0d0cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000cbd0d2cbd0d2cbd0d0cbd0d0cbd0d0cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000cbd0cbcbd0cbcbd0d0cbd0d0cbd0d0cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000cbd0cbcbd0cbcbd0d0cbd0d0cbd0d0cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000cbd0d4cbd0cbcbd0d0cbd0d0cbd0d0cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000cbd0d0cbd0cbcbd0d1cbd1d2cbd0d1cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a2bec0c0c0c0c0a2abb9a5a4afb0b2b1a2b0b1b2a2b1b0b2b4b5b9a5a4afb0b1b1cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a2a2c3c0c0c0c4bfabb8baa4aebdacacacbcacacacacbdacacadb8babaaeacbcbccbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a2a2c0c1c0c0c2a2aba5a5a4a3a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a4a3a5a5a5cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
acbdacacacacacacada5a5a4a4a3a5a5a5a5a5a5a5a5a5a5a5a5a5a5a4a4a3a5a5cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a5a5a5a5a5a5a5a5a5a5a5a4a4a4a4a4a4a4a4a4a4a4a4b3a4a4a4a4a4a4a4a4a4cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a5a5a5a5a5a5a5a5a5a5a5a4b3a4a4a4b3a4a4a4a4a4a4a4a4a4a4b3a4a4a4a4a4cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a1a1a1a1838383a1a1a1a1a1a1a1a1bba1a1a1a1a0a0a0a1a1a1a1a1a1a1a1a1a1cbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
838383838383838383838383838383838383838382828283bb83838383838383830000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
83838383a1a1a183838383838383838383838383828282838383838383838383830000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8383828282828383828282828383828282828383828282838382828282838382820000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
83838383a1a1a183838383838383838383838383828282838383838383838383830000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
83838383a1a1a1838383838383838383838383838282828383838383838383bbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb838383a1a1a183838383838383838383838383828282838383838383838383830000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a4b3a4a4a4a4a4a4a4a4b3a4a4a4a4a4a4a4a4a4a4a4a4b3a4a4a4a4a4a4b3a4a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0008000022670156500f6300962005610036100f600096000560004600016000b6000a60009600086000560004600010000100000000000000000018600156000e6000a600066000000000000000000000000000
0005001f111700b1700c170081700f17007170061700d17006170101700a170091700c170061700e170181700f170111700f17006170021700a1700c17010170031700a170061700917018170081700517000000
000400002307023060230502303023010230101b3001b3001b3001b300191002300023000230702306023050230302301023010000000000023000230002300023000000002a0702a0602a0502a0302a0102a010
000800003307039070390403902039010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000d1000c1700a16007150041200e1700815009140041400212001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000977007740047300372001100091600714005130041100311000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800003007030070300703007030070300703007030070300703007030070300703007030070300703007030070300703007030070300703007030070300603006030050300503003030030300103001030000
000800003307039070330703907033070390703307039070330703907033070390703307039070390403902039010390003300039000390003900039000000000000000000000000000000000000000000000000
000800002307023060230502303023010131001b3001b3001b3001b30019100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800003307039070330703907033070390703377039770330703907033770397703377039770397403972039710390003300039000390003900039000000000000000000000000000000000000000000000000
0010000000675000003c6050060500675006053c6053c60500675000000c0000067500605006750c00000000006750000000605006050067500000006750e00000675000000c0000067500605006750067500605
001000002e6352e6052e6352e6053c6732e6052e6352e6052e6352e6052e6352e6053c673000002e635000002e635000002e635000003c6732e6002f635000002f635000002f635000003c673000000000000000
0010000008450084500845008450074500745007450074500a4500a4500a4500a45008450084500845008450000000000000000054000845008450084500845000000000000b4500b45008450084500945009450
0010000008450084500845008450074500745007450074500a4500a4500a4500a45008450084500845008450000000000000000054000845008450084500845000000000000b4000b40008450084500845008450
0004000001610026100361004610056100661007610076100761007610076100761007610076100761007610076100761008610096100a6100c6100d6100f610116101361015610186101a6101c6101f61022610
00040000223501f320325000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400002935027320325000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001e35514430144101e35514430144101e355144301a35514430144101a35514430144101a355144301535514430144101535514430144101535514430144101441014410144301e355144301e35514430
001000001a0501d05022050220501d05022050220502205020300183002b3002b3002b30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001a3501d35022350223501d35022350223502235020300183002b3002b3002b30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a00001a3501d3001a3001a3501a3001a35021350213502135021350213501a3502135021350213502134021330213202131000000000000000000000000000000000000000000000000000000000000000000
001000000365501600000000000024655246000000000000036550000000000000002465500000000000000003655000000000000000246550000000000000000365500000000000000024655256000000000000
00100000070520705206052060520d0520d0520c0520c0520d3020d3020d3020d3020b3020b3020b3020b302070520705206052060520a0520a05209052090520200201002053020530205302053020530205302
000600002835028330283102835028330283100030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000400002135021330213102535025330253102135021330213102535025330253100030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000400002935029340293302930029350293402933029300293000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
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
00 0a4b0d51
00 0a4b0c51
00 0a0b0d51
00 0a0b0c51
01 0a0b0d11
00 0a0b0c11
00 0a4b0d11
00 0a4b0c11
00 0a0b0d11
00 0a0b0c11
00 0a0b4d11
00 0a0b4c11
00 0a0b0d11
00 0a0b0c11
00 0a0b0d51
02 0a0b0c51
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

