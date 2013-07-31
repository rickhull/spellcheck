#!/usr/bin/env ruby

default_dict = '/usr/share/dict/words'
DICT = File.exists?(default_dict) && default_dict

unless DICT
  warn "Note: could not find default dict #{default_dict}"
  warn "Try installing `wamerican` on Debian based systems"
end

def prompt_dict
  msg = "Dictionary path required:"
  msg << " (#{DICT})" if DICT
  $stderr.print "#{msg}\n> "
  dict = $stdin.gets.chomp
  if dict.empty?
    return DICT if DICT
    warn "Dictionary path required"
    exit 1
  end
  dict
end


# embed a tiny, completely different program for generating words
#
if ARGV[0].to_s.downcase == 'generate'
  ARGV.shift
  $stdout.sync = true

  require 'spellbreaker'

  begin
    dict = ARGV.shift || prompt_dict
    spell = Misspell.new
    spell.build dict
    puts dict # Feed dictionary path to spellchecker

    loop { puts spell.wrong(spell.dictionary.sample) }
  rescue Interrupt
    warn "\nBye!"
    exit
  end
end

# ok, we're not generating words.  Let's spellcheck them!
#
require 'spellcheck'

begin
  dict = ARGV.shift || prompt_dict

  # Make a trie
  trieHard = Trie.new
  stateHandler = State.new

  # Makin' Bacon
  trieHard.build dict
  puts "Loaded, ready!"

  # Now we just spin our wheels waiting on user input
  # working when needed
  loop do
    # User prompt
    print "> "
    input = $stdin.gets.chomp
    unless input.empty?
      # An edit distance of your maximum string length seems to be a
      # good upper limit
      puts trieHard.step(input, trieHard.maxLength, stateHandler)
    end
  end
rescue Interrupt
  # Pretty message for keyboard interrupt death
  warn "\nBye!"
end
