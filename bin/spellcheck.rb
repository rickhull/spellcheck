#!/usr/bin/env ruby

require 'spellcheck'

if !ARGV[0] || ARGV[0].strip.empty?
  # No argument, prompt the user for a dictionary path
  print "Please enter the path to a dictionary file and press enter to continue\n( Default: '/usr/share/dict/words' )\n> "
  dict = $stdin.gets.chomp.strip
else
  # Argument passed, should use that as the dictionary path
  dict = ARGV[0].strip
end

# Make a trie
trieHard = Trie.new
# Make a state handler to hold each step's calculations
stateHandler = State.new
# If they didn't pass a path, use the unix default, otherwise use theirs
trieHard.build((dict.empty?) ? dict = '/usr/share/dict/words' : dict)
# Makin' Bacon
print "Loaded, ready!\n"

# Now we just spin our wheels waiting on user input
# working when needed
begin
  loop do
    # User prompt
    print "> "
    input = $stdin.gets.chomp.strip
    if !input.empty?
      # An edit distance of your maximum string length seems to be a
      # good upper limit
      puts trieHard.step(input, trieHard.maxLength, stateHandler)
    end
  end
rescue Interrupt
  # Pretty message for keyboard interrupt death
  warn "\nBye!"
end
