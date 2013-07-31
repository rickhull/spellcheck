#!/usr/bin/env ruby

$stdout.sync = true

default_dict = '/usr/share/dict/words'
DICT = File.exists?(default_dict) ? default_dict : nil

unless DICT
  $stderr.puts "Note: could not find default dict #{default_dict}"
  $stderr.puts "Try installing `wamerican` on Debian based systems"
  $stderr.puts
end

def prompt_dict
  msg = "Dictionary path required:"
  msg << " (#{DICT})" if DICT
  print "#{msg}\n> "
  $stdin.gets.chomp
end


# embed a tiny, completely different program for generating words
#
if ARGV[0].to_s.downcase == 'generate'
  require 'spellbreaker'

  ARGV.shift
  dict = ARGV.shift || prompt_dict
  spell = Misspell.new
  spell.build((dict.empty?) ? dict = '/usr/share/dict/words' : dict)
  puts dict # Feed dictionary path to spellchecker

  begin
    loop do
      puts spell.wrong(spell.dictionary.sample)
    end
  rescue Interrupt
    warn "\nBye!"
    exit
  end
end

# ok, we're not generating words.  Let's spellcheck them!
#
require 'spellcheck'

dict = ARGV.shift || prompt_dict

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
