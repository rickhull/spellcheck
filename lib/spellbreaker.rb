# this is pretty awful, it's just built to get the job done

module Misspell
  VOWELS = %w{a e i o u}

  def self.vowels(word)
    word.length.times { |i|
      word[i] = VOWELS.sample if VOWELS.include?(word[i])
    }
    word
  end

  def self.repeat(word)
    (rand(3) + 1).times {
      random = rand word.length
      char = word[random]
      word.insert(random, char) if char != '\''
    }
    word
  end

  def self.caps(word)
    start = rand(word.length - 1) # can't be the last char
    finish = start + 1
    remaining = word.length - 1 - start
    finish += rand(remaining) if remaining >= 1
    word[start..finish] = word[start..finish].upcase
    word
  end

  def self.wrong(word)
    case rand(3)
    when 0
      word = self.caps(word)
    when 1
      word = self.repeat(word)
    when 2
      word = self.vowels(word)
    end
    rand(2).zero? ? word : self.wrong(word)
  end

  # iterate over the input file, generating a wrong output word
  # with random-sized input skips
  #
  def self.process(dict)
    if File.exists?(dict)
      test = false
      count = 0
      target = rand(500)
      IO.foreach(dict) { |word|
        # skip a random amount of words
        count += 1
        next if count < target

        word = word.chomp.strip
        next if word.empty?

        # output, update random count state
        puts self.wrong(word)
        count = 0
        target = rand(500)
      }
    else
      raise "Invalid dictionary: #{dict}"
    end
  end
end
