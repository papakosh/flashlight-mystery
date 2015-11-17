require 'ostruct'

# Node class updated
class Node < OpenStruct
 DEFAULTS = { :root => { :open => true, :can_take => false, :can_open => false, :can_see => "none", :locked => false }, # initialize hash obj to hold defaults of different node types
	      :room => { :open => true, :can_take => false, :can_open => false, :can_see => "none", :locked => false },
	      :item => { :open => false,:can_take => true, :can_open => true, :can_see => "none", :locked => false },
 	      :player => { :open => true,:can_take => false,:can_open => false, :can_see => "all", :locked => false }
	    }    

def init_with(c)
    c.map.keys.each do|k|
      instance_variable_set("@#{k}", c.map[k])
    end

    @table.keys.each do|k|
      new_ostruct_member(k)
    end
  end

  

def self.save(node, file='save.yaml')
    File.open(file, 'w+') do|f|
      f.puts node.to_yaml
    end
  end

  

def self.load(file='save.yaml')
    YAML::load_file(file)
  end


  

 def puts(*s)
    
	STDOUT.puts( s.join(' ').word_wrap)
  
 end




 def initialize(parent=nil, tag=nil, defaults={}, &block) # called by Node.new
  super()
  defaults.each {|k,v| send("#{k}=", v)} # loop through hash parms, storing key-value pairs (usually one or none)
  self.parent = parent # set parent of current node
  self.parent.children << self unless parent.nil? # when parent is not null, add current node to parent's children array
  self.tag = tag # set tag of current node
  self.children = [] # initialize array for children of current node
  instance_eval(&block) unless block.nil? # call block code using current instance of node
 end
 
 def room(tag, name, partial_name, &block) # called to create Node of type 'room'
  r = Node.new(self, tag, DEFAULTS[:room], &block)
  r.name = name
  r.partial_name = partial_name
 end

 def item(tag, name, partial_name, *words, &block) # called to create Node of type 'item'
  i = Node.new(self, tag, DEFAULTS[:item])
  i.name = name
  i.words = words
  i.partial_name = partial_name
  i.instance_eval(&block) if block_given?
 end
 
 def player(&block) # called to create Node of type 'player'
  Player.new(self, :player, DEFAULTS[:player], &block)
 end

 def self.root(&block) # called to create root node
  Node.new(nil, :root, &block)
 end 

 def get_room # called to return node of type 'room' based on who the caller is
  if parent.tag == :root  # if parent of caller is root, return caller 
   return self
  else #otherwise call get_room recursively on parent until finding the node whose parent is root 
   return parent.get_room
  end
 end

 def get_root # called to find root node
  if tag == :root || parent.nil? # if tag is root, return caller
   return self
  else # otherwise call get_root recursively on parent until finding the root node
   return parent.get_root
  end
 end

 def hidden? # called to find out if caller is hidden
  if tag == :root || parent.tag == :root # if tag or parent tag is root then not hidden (false)
    return false 
  elsif parent.open == false # else if parent open status is false, then hidden (true)
   return true
  else
   return parent.hidden?  # otherwise call hidden? recursively on parent until finding root or open status of false
  end
 end

 def script(key, *args) # called to execute script for a given node
  if respond_to?("script_#{key}") # if script exists then execute script of given node
   return eval(self.send("script_#{key}"))
  else
   return true 
  end
 end

 def move(thing, to, check=true) # called to move a node from one spot to another
  item = find(thing) # find the node to move
  dest = find(to) # find where the node is moving
  return if item.nil? # if node to move is null, print out error
  if check && item.hidden? # if checking for hidden and item is hidden, print out error
    puts "You can't get to the #{thing} right now."
    return
  end
  return puts "Can't find the #{to}" if dest.nil? # if dest is null, print out error
  if check && (dest.hidden? || dest.open == false) # if checking for hidden and dest is hidden, print out error 
    puts "You can't put the #{thing} in the #{to}"
    return
  end
  if dest.ancestors.include?(item) # if the item being moved is the parent of the destination then print error 
   puts "Are you trying to destroy the universe?"
   return
  end
  item.parent.children.delete(item) # if successfully can move, then delete item from parent's children array
  dest.children << item  # and add item to children array of dest
  item.parent = dest # and finally, make item's parent the dest
 end

 def find(thing) # called to find a node given input 'thing'
  case thing
    
    when Symbol
 # if 'thing' is a symbol (ie :living_room), call find by tag
     find_by_tag(thing)
    
    when String
  # if 'thing' is a string (ie a description), call find by string 
     find_by_string(thing)

    when Array
     find_by_string(thing.join(' '))
    when Node
  # if 'thing' is a node, just return 'thing' - used by move
     return thing

    else
     return nil   
  end
  
 end

  

 def find_by_tag(tag)
 # called to find a node given a tag (i.e. :living_room)
   return self if self.tag == tag # if tag is callers, return caller

    
   children.each do|c|
      # else, loop through the caller's children, 				    
			    # calling find by tag on each until found or no more
    res = c.find_by_tag(tag)
      
    return res unless res.nil?
    
   end

      
    return nil	# if no matching tag, return nil
  
 end

 def find_by_string(words) # called to find nodes given a string of words
  #puts "find by string WORDS = #{words}"
  #words = words.split unless words.is_a?(Array) # split words into an array of strings if not already
  nodes = find_by_name(words) # find nodes by matching on the names
  nodes = find_by_partial_name(words) unless nodes.any?
  if nodes.empty? # if nodes empty then print message
   #puts "No matches for #{words} found."
   return nil
  end
  
  if nodes.length == 1 # if only one node left, return the first
   return nodes.first
  else
    nodes.each do |i| # otherwise, loop through the nodes and score the nodes on number of matching adjectives 
     i.search_score = (words & i.words).length
    end
    nodes.sort! do |a,b| 
# Sort the nodes highest to lowest using the scores
      b.search_score <=> a.search_score                             
    end  
    nodes.delete_if do |i| # deletes node if current node's score is less than first node's score
      i.search_score < nodes.first.search_score 
    end
    if nodes.length == 1
      return nodes.first
    else
      puts "You were looking for #{words}. Which item did you mean?" # otherwise return back multiple, asking which one was meant
      nodes.each do |i|
        puts " * #{i.name} (#{i.words.join(', ')})"
      end
    end
  return nil
  end

  
 end

 def find_by_name(words,nodes=[]) # called to find node by name
  #words = word.split unless words.is_a?(Array) # split words into an array of strings if not already
  #puts "find by name WORDS = #{words}"
  nodes << self if name != null && words.include?(name) # if words include caller's name, then add caller to node array
  children.each do |c|  # call find_by_name recursively on children nodes looking for matches
   #puts "tag of child is = #{c.tag}"
   c.find_by_name(words,nodes)
  end  
  return nodes
 end

 def find_by_partial_name(words,nodes=[]) # called to find node by name
  #words = word.split unless words.is_a?(Array) # split words into an array of strings if not already
  nodes << self if partial_name != null && words.include?(partial_name) # if words include caller's name, then add caller to node array
  
  children.each do |c|  # call find_by_name recursively on children nodes looking for matches
   c.find_by_partial_name(words,nodes)
  end  
  return nodes
 end


 def to_s (level='mansion', verbose=false, indent='') # called to print out nodes based on their relation to the root in a formatted display (tree)
     bullet = if parent && parent.tag == :root then '#'  # if parent is root, then pound sign displays next to node
     elsif tag == :player then '@'			 # if node type is player, then at sign displays next to node
     elsif tag == :root then '>' 			 # if node is root, then greater than sign 
     elsif open == true then 'O' 			 # if node status is open, then 'O' displays next to node
     elsif locked == true then '$'		 	 # if node status is locked, then '$' displays next to node
     else '*'						 # otherwise * displays next to node (item nodes - closed)  
     end

    if (level == 'mansion')
      if (tag == :player)
        str = "#{indent}#{bullet} #{tag}\n"
      elsif (parent && parent.tag == :root && can_see == "all" )
        str = "#{indent}#{bullet} #{name}\n"     # formatted line to display
       elsif (parent && parent.tag == :root && can_see == "partial" )
        str = "#{indent}#{bullet} #{partial_name}\n"         
       else
        str = ""
      end
     else
       if (tag == :player)
        str = "#{indent}#{bullet} #{tag}\n"
       elsif (tag != :root && can_see == "all" ) || verbose
       	str = "#{indent}#{bullet} #{name}\n"		 # formatted line to display
       elsif (tag != :root && can_see == "partial" )
        str = "#{indent}#{bullet} #{partial_name}\n"
       else
  	     str = "" 
       end
      end
       if verbose # if verbose, show full details
     	  self.table.each do|k,v| # no idea what is table or how it works
		    if k == :children
			   str << "#{indent+'  '}#{k}=#{v.map(&:tag)}\n"	
		    elsif v.is_a?(Node)
			   str << "#{indent+ '  '}#{k}=#{v.tag}\n"
		    else
			   str << "#{indent+ '  '}#{k}=#{v}\n"
		    end 
     	end
     end
     
     children.each do |c|
        if (c.parent.tag != :player && c.hidden? == false)
		      str << c.to_s(level,verbose,indent + '  ')
	      end
     end
     #unless c.hidden?

     return str
  end

  def ancestors(list=[]) # called to compile a parentage list of the caller (parent, grandparent, great grandparent, etc.)
   if parent.nil?
    return list
   else
    list << parent
    return parent.ancestors(list)
   end
  end

  def described?
   if respond_to?(:described)
    return self.described
   else
    return false
   end
  end

  def describe2(light)
   if light && respond_to?(:desc_with_light)
      if self.parent.tag == :root
        status = ""
      elsif self.open
          status = "it appears to be open."
      elsif self.locked
          status = "it appears to be locked."
      else
          status = "it appears to be closed."
      end
      puts "using the flashlight, you see#{desc_with_light}#{status}" if self.parent.tag != :player
      print "\n#{desc_with_light}" if self.parent.tag == :player
   elsif respond_to?(:desc_without_light) 
      if self.parent.tag == :root
        status = ""
      elsif self.open
          status = "it appears to be open."
      elsif self.locked
          status = "it appears to be locked."
      else
          status = "it appears to be closed."
      end
    puts "you feel around the room in the dark and discover#{desc_without_light}#{status}" if self.parent.tag != :player
    puts "you examine in the dark #{desc_without_light} #{status}" if self.parent.tag == :player
   else
     puts 'Nothing of interest'
   end
  end


  def describe
   base = if !described? && respond_to?(:desc)
    self.described = true
    desc
   elsif respond_to?(:short_desc)
    short_desc
   else
    "You are in #{tag}"
   end
   if open #append presence of children nodes
    children.each do |c|
     base << (c.presence || ' ')
    end
   end
   puts base 
  end

  def short_description
   if respond_to?(:short_desc)
    return short_desc
   else
    return tag.to_s
   end
  end

end

class Player < Node

 @@first_time = true
 @@clues = Array.new(8) 
  
 def self.first_time
  return @@first_time
 end
 
 def self.not_first_time
  @@first_time = false
 end

 def self.add_clue(clue, index)
    @@clues[index]=clue
 end

 def command(words) # called to form send command (prefixed by do_) from words input 
  verb, *words = words.split(' ') # separate words into verb and other words 
  verb = "do_#{verb}" # create command from verb
  #puts "command is #{verb}"
  if respond_to?(verb) # if object has method, then do command
   send(verb, *words)
  else # otherwise print error
   puts "I dont know how to do that"
  end
 end

 def do_go(direction, *a) # called to go a certain direction (if exit available) - *a soaks up any extra words
  dest = get_room.send("exit_#{direction}") # get room node with exit in that direction
  if dest.nil? # if no exit, then print error
    puts "You can't go #{direction}"
  else # otherwise move to player to that room
    dest = get_root.find(dest)
    if dest.script('enter', direction)
     get_root.move(self, dest)
    end
  end
 end

 %w{ north south east west up down }.each do |dir| # not working
  define_method("do_#{dir}") do
   do_go(dir)
  end
  define_method("do_#{dir[0]}") do # not working
   do_go(dir)
  end
 end

 def do_take(*thing) # called for the player to take something from the room
  target_words = thing.join(' ')
  item = get_room.find(target_words) # find 'thing' in the room
  return puts "I dont see a #{target_words} in here." if item.nil? # return if 'thing' is null
  if item.can_see != 'none' && item.can_take && item.script('take') && item.parent.tag != :player # otherwise, if 'thing' has script defined for take action, then execute it
   puts 'Taken.' if get_root.move(item,self) # move 'thing' to caller
  else
    if item.can_see == "all"
      puts "You can't take the #{item.name}" if item.parent.tag != :player
      puts "You already have the #{item.name} in your inventory" if item.parent.tag == :player
    elsif item.can_see == "partial"
      puts "You can't take the #{item.partial_name}" if item.parent.tag != :player
      puts "You already have the #{item.partial_name} in your inventory" if item.parent.tag == :player
    else
      puts "I dont see a #{target_words} in here."
    end
  end
 end
 
 alias_method :do_get, :do_take
 
 def do_drop(*thing) # called to move 'thing' from player to room
  target_words = thing.join(' ')
  if move(target_words, get_room)
    puts "Dropped."
  else
    puts "You don't have a #{target_words}."
  end

 end 

 def open_close(thing, state) # called to open close containers
  target_words = thing.join(' ')
  container = get_room.find(target_words) # find container in room
  if container.nil? || container.can_see == 'none' # return nothing when container null
   puts "I dont see a #{target_words} in here."
   return
  end
  if container.open == state # if container already in state then print message
   puts "It's already #{state ? 'open' : 'closed'}"
  else
    if container.locked
      container.script('open')
    elsif container.can_open
   	  container.open = state # otherwise set state for container
	    if state
	     puts "Opened."
	    else
	     puts "Closed."
	    end
    else
	   puts "#{target_words} does not open/close"
    end 
  end
 end
 
 def do_open(*thing) # called to open 'things'
  open_close(thing, true)
 end

 def do_close(*thing) # called to close 'things'
  open_close(thing, false)
 end
 
 def do_look(*a) # called to find current location
   get_room.tap do |r|
    r.described = false
    r.describe
   end
 end

 def do_examine(*thing)
  item = get_room.find(thing)
  return if item.nil?
  item.described = false
  item.describe
 end

 def do_inventory(*a) # called to print out inventory of caller
  print "\n - Your Inventory - "
  if children.empty? # if nothing in inventory, print 'nothing'
   print "\n * Nothing\n"
  else
    children.each do |c| # otherwise print out each child of caller
     if c.tag != :flashlight
      print "\n * #{c.name}" if c.can_see == "all"
      print "\n * #{c.partial_name}" if c.can_see == "partial"
      
     elsif c.tag == :flashlight && c.children.empty?
      print "\n * #{c.short_description} - 0 charges"	
     elsif c.tag == :flashlight && c.children[0].tag == :new_batteries 
      print "\n * #{c.short_description} - (#{c.children[0].charge}/10 charges)"
     elsif c.tag == :flashlight && c.children[0].tag == :dead_batteries 
      print "\n * #{c.short_description} - 0 charges"
     end
    end
    print "\n"
  end
 end

 alias_method :do_inv, :do_inventory
 alias_method :do_i, :do_inventory

 def do_put(*words) # called to put something in or on something else (ie put new batteries in remote)
  prepositions = [' in ', ' on '] # setup prepositions allowed
  prep_regex = Regexp.new("(#{prepositions.join('|')})") # setup regular expression for prepositions
  item_words, _, cont_words = words.join(' ').split(prep_regex) # split phrase into item and container
  if cont_words.nil? # if no container, print error
   puts "You want to put what where?"
   return
  end
  item = get_room.find(item_words) # find item
  container = get_room.find(cont_words) # find container
  return if item.nil? || container.nil? # if item or container nil return
  if container.script('accept', item) # if container has script defined for accept then move item
   puts "Placed. " if get_room.move(item,container) # when container not null and container accepts, move item to container 
  end
 end

 def do_use(*words) # called to use an item (ie 
  prepositions = [ " in", " on", " with"]
  prepositions.map{|p| " #{p} "}
  prep_regex = Regexp.new("(#{prepositions.join('|')})")
  item1_words, _, item2_words = words.join(' ').split(prep_regex)
  
  item1 = get_room.find(item1_words)
  if item1.nil?  
   puts "Sorry, you don't seem to have a #{item1_words}"   
   return
  end
    
  if item2_words.nil? 
   if _.nil?
    puts "Sorry, how did you want to use the #{item1_words}?"
   else
    puts "Sorry, what did you want to use the #{item1_words} #{_}?"
   end
   return
  end
    
  if item2_words == 'room'
   item1.script('use', item2_words)
  else
    item2 = get_room.find(item2_words)
    #return if item1.nil? || item2.nil?
   item1.script('use', item2) unless item2.nil?
  end
 end

 def do_search (*words)
  prepositions = [" with"]
  prepositions.map{|p| " #{p} "}
  prep_regex = Regexp.new("(#{prepositions.join('|')})")
  target_words, _, item_words = words.join(' ').split(prep_regex)

  if target_words.nil?
    puts "Sorry, where did you want to search?"
   return
  end
   
  if target_words == 'room' # searching a room
     
    if item_words.nil? # doing blind search
      if room_not_covered
        size = get_room.children.length
        tag = null
        fixture = null
        index = -1
        while index == -1 do
          index = 0 + rand(size) 
          tag = get_room.children[index].tag      
          fixture = get_room.find(tag)
          if fixture.can_see != "none"
            index = -1
          end
        end
      
        fixture.can_see = "partial"
        if fixture.open
        	fixture.children.each do |c|
         	   c.can_see = "partial"
        	end
        end
        fixture.describe2(false)
      else
        get_room.describe2(false)
      end
    else # with an item
    	item = get_room.find(:player).find(item_words) 
   	  if item.nil?  
     		 puts "Sorry, you don't seem to have a #{item_words}"   
     		return   
    	end
    	item.script('use', 'room')
    end    
  else # searching an item in a room
      target_item = get_room.find(target_words) 
      if target_item.nil?  
       puts "Sorry, I dont think the #{target_words} is in here"
       return
      end
      if item_words.nil? # doing blind search	
        size = target_item.children.length
        if size == 0
          target_item.describe2(false)
          return
        end
        if target_item.open && size > 0
          print "Upon looking, you feel . . . "
          target_item.children.each do |c|
              c.can_see = "partial"
              print "\n * " + c.partial_name.to_s
          end
          print "\n"
        else
          print "The #{target_words} appears to be closed. Try opening it first.\n"
        end
      else
        item = get_room.find(:player).find(item_words) 
   	    if item.nil?  
     	    STDOUT.puts "Sorry, you don't seem to have a #{item_words}"   
     	    return   
    	   end
        target_item = get_room.find(target_words) 
        if target_item.nil?  
          puts "Sorry, I dont think the #{target_words} is in here"
          return
        end
        successful = item.script('use', target_item)               
        target_item.script('search') if successful
      end  
    end
 end
 
def room_not_covered
  not_covered = false
  get_room.children.each do |c|
      if c.can_see == "none"
        not_covered = true
        break
      end
  end
  return not_covered
end

 def do_map(*a)
   if a[0] == 'room'
    STDOUT.puts "\n - Room Map - "
    STDOUT.puts get_root.find(:player).get_room.to_s('room', false, '')
   else
    STDOUT.puts "\n - Map - "
    STDOUT.puts get_root
   end
 end  

 def do_debug(*a)
  system("cls")
  STDOUT.puts get_root.to_s(true)   
 end 

 def do_help
  print "\n-----HELP MENU-----"
  print "\nCommands\n"
  print "The INVENTORY command lists what you are carrying\n"
  print "The SAVE command saves the current game\n"
  print "The LOAD command restores a saved game\n"
  print "The MAP command shows what's been explored so far. Add ROOM to see room detail.\n"
  print "The INFO command gives you some idea what the game is about.\n"
  print "The CLUES command lists the clues you have gathered so far.\n"
  print "The QUIT command leaves the game.\n"
    
  print "\nMap Symbols\n"
  print "The @ symbol is you.\n"
  print "The # symbol identifies a room.\n"
  print "The * symbol identifies a fixture or item as closed. Closed objects hide their  contents.\n"
  print "The O symbol identifies a fixture or item as opened.\n"
  print "The $ symbol identifies a fixture or item as locked. Locked objects hide their  contents and require a key.\n"
 
  print "\nPlayer Actions\n"
  print "The SEARCH action allows you to learn about a room or item.\n"
  print "\tPattern: SEARCH <room or item> with or without <another item>\n"
  print "\tExample 1: SEARCH room with flashlight\n"
  print "\tExample 2: SEARCH cabinet\n"
  print "The TAKE action allows you to grab an item and store it in your inventory.\n"
  print "\tPattern: TAKE <item>\n"
  print "\tExample: TAKE flashlight\n"
  print "The PUT action allows you to place an item from inventory on/in something else.\n"
  print "\tPattern: PUT <item> on/in <another item>\n"
  print "\tExample: PUT batteries in flashlight\n"
  print "The OPEN action allows you to open an item. If locked, you will need a key.\n"
  print "\tPattern: OPEN <item>\n"
  print "\tExample: OPEN cabinet\n"
  print "The CLOSE action allows you to close an item.\n"
  print "\tPattern: CLOSE <item>\n"
  print "\tExample: CLOSE cabinet\n"
  print "The DROP action allows you to drop an item from inventory.\n"
  print "\tPattern: DROP <item>\n"
  print "\tExample: DROP batteries\n"      
 end

 def do_info
  print "You have been kidnapped and placed in a locked room. Armed with only a\n"
  print "flashlight, you must find your way through the dark and discover a way out.\n"
 end

 def do_clues
  puts "You know nothing yet" if !@@clues.any?
  index = 0
  @@clues.each do |c|
    puts "Clue #{index+1} - #{c.to_s}" if c
    index=index+1
  end
 end
end

class String

  def word_wrap(width=78)
    # Replace newlines with spaces
    
	gsub(/\n/, ' ').   
    
    # Replace more than one space with a single space
    
	gsub(/\s+/, ' ').

    # Replace spaces at the beginning of the string with nothing
    
	gsub(/^\s+/, '').

    # This one is hard to read. Replace with any amount

			     # of space after it with that punctuation and two
    
			     # spaces
	gsub(/([\.\!\?]+)(\s+)?/, '\1  ').

 # Similar to the call above, except replace commas

					   # with a comma and one space

	gsub(/\,(\s+)?/, ', ').

    # The meat of the method, replace between 1 and width
    
				  # characters followed by whitespace or the end of the
    				
				 # line with that string and a newline.  This works
    
				# because regular expression engines are greedy,
    
				# they'll take as many characters as they can.
    
	gsub(%r[(.{1,#{width}})(?:\s|\z)], "\\1\n")
#gsub(/\s+/, " ").gsub(/(.{1,#{width}})( |\Z)/, "\\1\n")

   end

end


