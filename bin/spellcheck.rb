#!/usr/bin/env ruby

default_dict = '/usr/share/dict/words'
DEFAULT_DICT = File.exists?(default_dict) && default_dict

unless DEFAULT_DICT
  warn "Note: could not find default dict #{default_dict}"
  warn "Try installing `wamerican` on Debian based systems"
end

def prompt_dict
  msg = "Dictionary path required:"
  msg << " (#{DEFAULT_DICT})" if DEFAULT_DICT
  $stderr.print "#{msg}\n> "
  dict = $stdin.gets.chomp
  if dict.empty?
    return DEFAULT_DICT if DEFAULT_DICT
    warn "Dictionary path required"
    exit 1
  end
  dict
end

%w{INT TERM QUIT}.each { |sig|
  Signal.trap(sig) { warn "SIG#{sig}"; warn "Bye!"; exit }
}

# embed a tiny, completely different program for generating words
#
if ARGV[0].to_s.downcase == 'generate'
  ARGV.shift
  $stdout.sync = true

  require 'spellbreaker'

  dict = ARGV.shift || prompt_dict
  spell = Misspell.new
  spell.build dict
  puts dict # Feed dictionary path to spellchecker

  loop { puts spell.wrong(spell.dictionary.sample) }
end

# ok, we're not generating words.  Let's spellcheck them!
#
require 'spellcheck'

dict = ARGV.shift || prompt_dict

# Make a trie
trie = Trie.new

# Makin' Bacon
trie.build dict
puts "Loaded, ready!"

# Now we just spin our wheels waiting on user input
# working when needed
loop {
  # User prompt
  print "> "
  input = $stdin.gets.chomp
  unless input.empty?
    # An edit distance of your maximum string length seems to be a
    # good upper limit
    puts trie.suggest(input, trie.max_length)
  end
}
