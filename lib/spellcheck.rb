# Requires ruby 1.9.3
# Helper class to store state for recursive functions

class State
  attr_accessor :state

  def initialize
    @state = Hash.new({})
  end

  def reset
    @state = Hash.new({})
  end
end

# A Trie is, as the pronunciation suggestions, a tree ( More accurately a root system )
# Each node contains a single letter, with branches to all possible subletters in a word set
# Words that share prefixes will follow the same path until they differ, at which point
# they branch into their respective paths
# This is faster for approximate matching as you remove re-checking in similar words,
# significantly increasing operation speed, especially with larger dictionaries

class Trie
  attr_accessor :word
  attr_reader :children
  attr_reader :maxLength

  def initialize
    @word = nil
    @children = {}
    @maxLength = 0
  end

  def insert word
    node = self
    # Turtles
    word.each_char do |letter|
      # all
      unless node.children.has_key? letter
        # the
        node.children[letter] = Trie.new
      end
      # way
      node = node.children[letter]
    end
    # down
    node.word = word
  end

  def build(dict)
    if File.exists?(dict)
      IO.foreach(dict) do |word|
        # Determine maximum word length for maximum edit distance
        if word.length > @maxLength
          @maxLength = word.length
        end
        # Format and insert every word in the dictionary into the trie
        self.insert(word.strip.downcase)
      end
    else
      # The passed dictionary doesn't exist
      abort("Exit: Invalid dictionary #{dict}, is the path correct?")
    end
  end

  def step(word, maxCost, stateHandler)
    # There's no sense in calculating further edit distance
    # once you already have a match at a lower value
    # thus, step searching
    # Made fast by keeping state between steps, so work is never done twice
    #
    # Make sure the entire word is lowercase as distance calc
    # sees cases as different letters and we don't want that
    # CUNsperrICY -> cunsperricy
    # remove duplicate consonnants if they are preceeded by duplicate vowels
    # peepple -> peeple
    # replace duplicate+ consonants with singular if they are not right after the first character in the word
    # apple -> apple
    # cunsperricy -> cunspericy
    # replace triplicate+ vowels with duplicates
    # sheeeeep -> sheep
    word = ( word.downcase
      .gsub(/([aeiou])\1{1,}([^aeiou])\2{1,}/i,'\1\1\2')
      .gsub(/(?!^).([^aeiou])\1{1,}/i,'\1')
      .gsub(/([aeiou])\1{2,}/i,'\1\1') )

    results = []
    (0..maxCost).each do |i|
      results << search(word, i, stateHandler)
      # If we have a result, return it!
      # otherwise clear the array for the next loop
      (results[0]) ? (stateHandler.reset; return results) : results.shift
    end
    # Didn't find anything, reset state and inform as much
    stateHandler.reset
    return 'NO SUGGESTION'
  end

  def search(word, maxCost, stateHandler)
    # Build the first row for Levenshtein distance calculation
    currentRow = (0..word.size).to_a
    # results format:
    # {
    #   "suggestion" => distance_calc,
    #   "suggestion" => distance_calc
    # }
    results = {}
    # Recursively search each branch of the Trie
    self.children.each_key do |key|
      search_recursive(self.children[key], key, word, currentRow, results, maxCost, stateHandler)
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
          # probably just substitution, there's a good chance this is worth more
          if (result.length == word.length)
            results[result] -= 0.1
          end
        end
      end
      # Sort the results so the "best" result is at the top, then choose it if the starting letter
      # is the same as the entered word
      # Best = lowest
      return (matching_start) ? results.sort_by{|k,v| v}[0][0] : false
    else
      # Better luck next time
      return false
    end
  end

  def search_recursive(tnode, letter, word, previousRow, results, maxCost, stateHandler)
    # Check if state-data exists from the previous step
    if stateHandler.state[maxCost-1][tnode.object_id]
      # if its not empty then we've done this already, just restore the last step's calculations
      # then we just pass them off to the next recursion like we would if we'd calculated them ourselves
      currentRow = stateHandler.state[maxCost-1][tnode.object_id]
    else
      # If no state data exists, we're a fresh run! Get busy with those calculations!
      currentRow = [previousRow[0] + 1]
      # Build one row for the letter, with a column for each letter in the
      # target word, plus one for the empty string at column 0
      (1..word.size).each do |column|
        insertCost = currentRow[column - 1] + 1
        deleteCost = previousRow[column] + 1
        replaceCost = previousRow[column - 1]
        if word[column - 1] != letter
          replaceCost += 1
          # vowels should be less valuable to replace, so if we're replacing a consonant, increase the cost
          if letter =~ /[^aeiou]/
            replaceCost += 1
          end
        end
        currentRow << [insertCost, deleteCost, replaceCost].min
      end
      # Set the state for this step on this trie, in case we have to run another step
      stateHandler.state[maxCost][tnode.object_id] = currentRow
    end
    # If the last entry in the row indicates the optimal cost is
    # not greater than the maximum cost, and there is a word in this
    # trie node, then add it to the results.
    if currentRow.last <= maxCost and tnode.word != nil
      results[tnode.word] = currentRow.last
    end
    # If any entries in the row are less than the maximum cost, then
    # recursively search each branch of the Trie.
    if currentRow.min <= maxCost
      tnode.children.each_key do |letter|
        search_recursive(tnode.children[letter], letter, word, currentRow, results, maxCost, stateHandler)
      end
    end
  end
end
