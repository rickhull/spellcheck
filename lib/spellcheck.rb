# Requires ruby 1.9.3

# A Trie is, as the pronunciation suggestions, a tree ( More accurately a root
# system ).  Each node contains a single letter, with branches to all possible
# subletters in a word set.
# Words that share prefixes will follow the same path until they differ, at
# which point they branch into their respective paths.
# This is faster for approximate matching as you remove re-checking in similar
# words, significantly increasing operation speed, especially with larger
# dictionaries
#
class Trie
  # Make sure the entire word is lowercase as distance calc
  # sees cases as different letters and we don't want that
  #   CUNsperrICY -> cunsperricy
  # Remove duplicate consonnants if they are preceeded by duplicate vowels
  #   peepple -> peeple
  # Replace duplicate+ consonants with singular if they are not right
  # After the first character in the word
  #   apple -> apple
  #   cunsperricy -> cunspericy
  # Replace triplicate+ vowels with duplicates
  #   sheeeeep -> sheep
  #
  def self.normalize(word)
    word.downcase
      .gsub(/([aeiou])\1{1,}([^aeiou])\2{1,}/i,'\1\1\2')
      .gsub(/(?!^).([^aeiou])\1{1,}/i,'\1')
      .gsub(/([aeiou])\1{2,}/i,'\1\1')
  end

  attr_accessor :word
  attr_reader :children
  attr_reader :max_length

  def initialize(dict = nil)
    @word = nil
    @children = {}
    @max_length = 0
    # pass a dict yet still can update attrs before build step
    yield self if block_given?
    self.build(dict) if dict
  end

  def insert word
    @max_length = word.length if word.length > @max_length
    node = self
    word.each_char do |letter|
      # register letter if it's not already present
      node.children[letter] ||= Trie.new
      # visit letter
      node = node.children[letter]
    end
    # register the word at the leaf node
    node.word = word
  end

  def build(dict)
    raise "Cannot build invalid dictionary: #{dict}" unless File.exists?(dict)
    IO.foreach(dict) { |word| self.insert(word.strip.downcase) }
    self
  end

  def suggest(word, max_cost)
    word = self.class.normalize(word)

    # Made fast by keeping state between steps, so work is never done twice
    #
    state = {}
    1.upto(max_cost).each { |i|
      suggestion = search(word, i, state)
      return suggestion if suggestion
    }
    'NO SUGGESTION'
  end

  def search(word, cost, outside_state = nil)
    word = self.class.normalize(word)
    state = outside_state || {}

    # Build the first row for Levenshtein distance calculation
    current_row = (0..word.size).to_a
    # results format:
    # {
    #   "suggestion" => distance_calc,
    #   "suggestion" => distance_calc
    # }
    results = {}
    # Recursively search each branch of the Trie
    self.children.each_key do |key|
      search_recursive(self.children[key], key, word,
                       current_row, results, cost, state)
    end
    if (!results.empty?)
      matching_start = false
      results.each_key do |result|
        # Cheaper computationally to do this than calculate edit distance
        # with floating point math in the first place
        #
        # If the initial characters match, it's a better score
        # initial character typos were not part of the possible mistakes
        if (result[0] == word[0])
          results[result] -= 0.4
          matching_start = true
          # probably just substitution, a good chance this is worth more
          if (result.length == word.length)
            results[result] -= 0.1
          end
        end
      end
      # Sort the results so the "best" result is at the top, then choose it if
      # the starting letter is the same as the entered word
      # Best = lowest
      return (matching_start) ? results.sort_by{|k,v| v}[0][0] : false
    else
      # Better luck next time
      return false
    end
  end

  def search_recursive(tnode, letter, word, previous_row, results, cost, state)
    # Check if state-data exists from the previous step
    if state[cost-1] and state[cost-1][tnode.object_id]
      # if its not empty then we've done this already, just restore the last
      # step's calculations then we just pass them off to the next recursion
      # like we would if we'd calculated them ourselves
      current_row = state[cost-1][tnode.object_id] # TODO: consider fetch
    else
      # If no state data exists, we're a fresh run!
      # Get busy with those calculations!
      current_row = [previous_row[0] + 1]
      # Build one row for the letter, with a column for each letter in the
      # target word, plus one for the empty string at column 0
      (1..word.size).each do |column|
        insertCost = current_row[column - 1] + 1
        deleteCost = previous_row[column] + 1
        replaceCost = previous_row[column - 1]
        if word[column - 1] != letter
          replaceCost += 1
          # vowels should be less valuable to replace, so if we're replacing a
          # consonant, increase the cost
          if letter =~ /[^aeiou]/
            replaceCost += 1
          end
        end
        current_row << [insertCost, deleteCost, replaceCost].min
      end
      # Set the state for this step on this trie, in case we have to run
      # another step
      state[cost] ||= {}
      state[cost][tnode.object_id] = current_row
    end
    # If the last entry in the row indicates the optimal cost is
    # not greater than the maximum cost, and there is a word in this
    # trie node, then add it to the results.
    if current_row.last <= cost and tnode.word != nil
      results[tnode.word] = current_row.last
    end
    # If any entries in the row are less than the maximum cost, then
    # recursively search each branch of the Trie.
    if current_row.min <= cost
      tnode.children.each_key do |letter|
        search_recursive(tnode.children[letter], letter, word,
                         current_row, results, cost, state)
      end
    end
  end
end
