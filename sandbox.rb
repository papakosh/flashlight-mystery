require 'yaml'
require_relative 'node'

# define new gameplay and test
# define command help - 

def single_item(tag, name, partial_name, desc, desc2)
  return item(tag, name, partial_name) do

    self.open = false
    self.can_take = true
    self.can_see = "none" 
    self.desc_with_light = <<-DESC
    #{desc}
    DESC
    self.desc_without_light = <<-DESC
    #{desc2}
    DESC
  end
end

def aspirin
  return item(:aspirin, 'aspirin', 'bottle') do

    self.open = false
    self.can_take = true
    self.can_see = "none" 
    self.desc_with_light = <<-DESC
    an aspirin bottle.
    DESC
    self.desc_without_light = <<-DESC
    a bottle.
    DESC
    item(:bronze_key, 'bronze key', 'key')
  end
end

def note
  return item(:note, 'note', 'paper') do

    self.open = false
    self.can_take = true
    self.can_see = "none" 
    self.desc_with_light = <<-DESC
    Your second clue is . . . For Classical Greeks, what was the paradisical 
    land of plenty called?
    DESC
    self.desc_without_light = <<-DESC
    a piece of paper.
    DESC
    self.script_search = <<-SCRIPT
      Player.add_clue("For Classical Greeks, what was the paradisical land of plenty called?", 1)
    SCRIPT
  end
end

def tissue_paper
  return item(:tissue_paper, 'tissue paper', 'sticky paper') do

    self.open = false
    self.can_take = true
    self.can_see = "none" 
    self.desc_with_light = <<-DESC
    tissue paper with green snot.
    DESC
    self.desc_without_light = <<-DESC
    soft paper with something sticky on it.
    DESC
  end
end

def can_see_now(node)
   node.can_see = "all" if node.parent.open
   node.children.each do |c|
     can_see_now(c)
   end
end

def flashlight
  return item(:flashlight, 'flashlight', 'light') do

    self.open = false
    self.can_take = true
    self.can_see = "all" 
    self.desc_with_light = <<-DESC
  	a flashlight.
    DESC
    self.desc_without_light = <<-DESC
  	a flashlight.
    DESC
    batteries
    self.script_use = <<-SCRIPT

     if !find(:new_batteries)
     
	     puts "The flashlight doesn't seem to work"
       return false
        
     end
     if args[0] == 'room'


	     get_room.describe2(true)
	     can_see_now(get_room)

	     get_room.find(:player).do_map('room')
     else
        args[0].describe2(true)
        can_see_now(args[0])
        if args[0].open && args[0].children.size > 0
          print "\nUpon looking, you see . . . "
          args[0].children.each do |c|
              print "\n * " + c.tag.to_s
          end
          print "\n"
        end

     end


     # decrease flashlight battery charge by 1     
     batteries = get_room.find(:player).find(:new_batteries)
     batteries.charge = batteries.charge - 1
     if (batteries.charge == 0)
        batteries.tag = :dead_batteries
        batteries.name = "dead"
     end
     return true
    SCRIPT
  end
  
end

def batteries
 return item(:new_batteries, 'new batteries', 'batteries') do
    self.open = false
    self.can_take = true
    self.charge = 10
    self.can_open = false
  end
 
end

def towel(tag, name, partial_name)
 return item(tag, name, partial_name) do
    self.open = false
    self.can_take = true  
 end      
end

def letter(tag, name, partial_name)
 return item(tag, name, partial_name) do
    self.open = false
    self.can_take = true
    self.can_see = "partial"
    self.desc_with_light = <<-DESC
    To Whom This May Concern: 

    You've been kidnapped. Now before you start freaking out, 
    I'm not going to hurt you. But, I'm also not going to let you go 
    so easily. Let's skip all the who, what, where, and why and get 
    down to business.
    You want out, and I want you to play my little game.
    
    As you have undoubtely noticed it is dark. Just the same, you have
    a flashlight. You'll need that flashlight to navigate your way through
    my mansion and find the clues to your escape. Each clue leads you closer
    to a special gold key, which is needed to open the door out of this place.
    But be careful, your flashlight has limited charges, so use it sparingly
    and keep an eye out for more batteries.

    Without further adieu, let's get started. 

    Your first clue is . . . what’s good for a headache?
    DESC
    self.desc_without_light = <<-DESC
    a piece of paper.
    DESC
    self.script_search = <<-SCRIPT
      Player.add_clue("what's good for a headache?", 0)
    SCRIPT
 end      
end
  
myroot = Node.root do
  self.open = true
  room(:bath_1, "bathroom 1", "room") do

    self.exit_south = :hallway
    self.can_see = "partial"
    
    self.desc_with_light = <<-DESC
	that you are in an large bathroom. behind you is a door and ahead is a bathtub at the far end of the room. 
	looking to your left you see a trash can, a hamper, and a towel rack. the towel rack is next to the 
	bathtub. looking to your right you see a cabinet over a sink followed by a toilet. the toilet is beside the bathtub.
    DESC
    self.desc_without_light = <<-DESC
  that you are in an large room. behind you is a door and ahead is a tub at the far end of the room. 
  To your left you remember a can, a basket, and a towel rack are there. the towel rack is next to the 
  tub. To your right you remember a cabinet over a sink followed by a toilet. the toilet is beside the bathtub.
    DESC
    item(:door, 'door', 'door') do

      # south of player
      self.open = false
      self.can_take = false
      self.locked = true
      self.desc_with_light = <<-DESC
        a wooden door with a long, bronze handle. it looks to be the way out of here.
      DESC
      self.desc_without_light = <<-DESC
        a wooden door with a long handle. it could be the way out of here.
      DESC
      self.script_open = <<-SCRIPT
        key = false
        get_room.find(:player).children.each do |c|
          if c.name == 'bronze key' 
            key = true
          end
        end

        if self.locked && key == true
          puts "Opened."
          self.open = true
          self.locked = false
        else
          puts "The door is locked and you don't have the key" if self.locked
        end 

      SCRIPT
    end
    player do
     letter(:letter, 'letter', 'letter')
    end
    flashlight
    item(:trashcan, 'trashcan', 'can') do

      # west of player
      self.open = false
      self.can_take = false      
      self.desc_with_light = <<-DESC
        a circular metallic trash can with a lid.
      DESC
      self.desc_without_light = <<-DESC
        a tall metallic can with a lid.
      DESC
      #item(:tissue_paper, 'tissue paper', 'paper')
      single_item(:tissue_paper, 'tissue paper', 'paper', 'Green snot buried in the tissue', 'soft paper with something sticky on it.')
      note
    end
  
    item(:hamper, 'hamper', 'basket') do

      # west of player
      self.open = false
      self.can_take = false
      self.desc_with_light = <<-DESC
        a tall wicker basket with a lid.
      DESC
      self.desc_without_light = <<-DESC
        a tall basket made of a rigid material with a lid.
      DESC
      single_item(:dirty_towel, 'dirty towel', 'towel', 'nothing of interest', 'nothing of interest')
      #towel(:dirty_towels,'dirty towels', 'towels')      
    end
    item(:towel_rack, 'towel rack', 'towel rack') do

      # west of player
      self.open = true
      self.can_take = false
      self.can_open = false
      self.desc_with_light = <<-DESC
  	a pair of long, tan patterned towels draped over a rack.
      DESC
      self.desc_without_light = <<-DESC
  	a pair of towels draped over a long metal bar. it feels like a towel rack.
      DESC
      single_item(:towel1, 'towel 1', 'towel 1', 'nothing of interest', 'nothing of interest')
      single_item(:towel2, 'towel 2', 'towel 2', 'nothing of interest', 'nothing of interest')
      #towel(:towel1,'towel 1', 'towel 1')
      #towel(:towel2,'towel 2', 'towel 2')  
    end

  item(:sink, 'sink', 'sink') do

      # east of player
      self.open = true
      self.can_take = false
      self.can_open = false
      self.desc_with_light = <<-DESC
  	a deep ceramic bowl at the center of a spacious counter.there is no drain stopper at the bottom.
      DESC
      self.desc_without_light = <<-DESC
  	a deep bowl at the center of a spacious counter. there is a small hole at the bottom. it feels like a sink.
      DESC
    end
  
    item(:medicine_cabinet, 'medicine cabinet', 'cabinet') do

      # east of player
      self.open = false
      self.can_take = false
      self.desc_with_light = <<-DESC 
      a medicine cabinet with a mirror.
      DESC
      self.desc_without_light = <<-DESC
    a cabinet with a smooth surface.
      DESC
      aspirin
      item(:tooth_paste, 'tooth paste', 'tube')
      item(:tooth_brush, 'tooth brush', 'brush')
      item(:vitamins, 'vitamins', 'bottle')
    end
  
    item(:toilet, 'toilet', 'toilet') do

      # east of player
      self.open = false
      self.can_take = false      
      self.desc_with_light = <<-DESC
  	a ceramic toilet with a lid.
      DESC
      self.desc_without_light = <<-DESC
  	a wide bowl with a lid. it feels like a toilet.
      DESC
      #item(:penny, 'penny', 'coin')
      single_item(:penny, 'penny', 'coin', 'small piece of metal.', 'a piece of metal.')
    end

    item(:bath_tub, 'bath tub', 'tub') do

      # north of player
      self.open = false
      self.can_take = false      
      self.desc_with_light = <<-DESC
  	a white polyester curtain with a waffle texture about a ceramic tub.
      DESC
      self.desc_without_light = <<-DESC
  	a soft material about a wide space. it feels like a tub.
      DESC
    end
  end



  room(:hallway, "hallway", "room") do
   self.exit_north = :bath_1
   self.short_desc = <<-DESC
    In a hallway.
   DESC
  end
end


loop do
  
    player = myroot.find(:player)
  
    if Player.first_time
    print "*****************************************************************************\n"
    print "**               F L A S H L I G H T    M Y S T E R Y                      **\n"
    print "*****************************************************************************\n"
    print "\nYou've just woken up somewhere. The question is where . . . " 
    print "\nWhat you do know is that it's pitch black, and despite the few moments that"
    print "\nhave passed, your world unfortunately remains dark. However, it's not long"
    print "\nbefore you notice a flashlight beside you.\n"
    Player.not_first_time
    end
    print "\nWhat now? "
    
    input = gets.chomp
  
    verb = input.split(' ').first

  
    case verb
  
     when "load"
    
      myroot = Node.load
    
       puts "Loaded"
  
     when "save"
    
      Node.save(myroot)
    
      puts "Saved"
  
     when "quit"
    
       puts "Goodbye!"
    
       exit
  
     else
    
     player.command(input)
  
     end

   end

