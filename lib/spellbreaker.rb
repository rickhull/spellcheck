# this is pretty awful, it's just built to get the job done

class Misspell
  attr_reader :dictionary

  def initialize
    @dictionary = []
    @process = [
      0, # :case,
      1, # :repeat,
      2, # :vowel,
      3, # :case_repeat,
      4, # :case_vowel,
      5, # :repeat_case,
      6, # :repeat_vowel,
      7, # :vowel_case,
      8, # :vowel_repeat,
      9, # :case_repeat_vowel
    ]
    @@vowels = ['a','e','i','o','u']
  end

  def build(dict)
    if File.exists?(dict)
      IO.foreach(dict) do |word|
        @dictionary << word.strip.downcase
      end
    else
      abort("Exit: Invalid dictionary #{dict}, is the path correct?")
    end
  end

  def vowels(word)
    (0..(word.length - 1)).each do |i|
      if @@vowels.include?(word[i])
        word[i] = (rand(100) >= 50) ? @@vowels.sample : word[i]
      end
    end
    return word
  end

  def repeat(word)
    (1..rand(1..3)).each do |i|
      random = rand(0..word.length-1)
      if word[random] != '\''
        word.insert(random,word[random])
      end
    end
    return word
  end

  def caps(word)
    random = rand(0..word.length/2)
    randomr = random+(rand(0..3))
    word[random..randomr] = word[random..randomr].upcase
    return word
  end

  def wrong(word)
    case @process.sample
    when 0
      caps(word)
    when 1
      repeat(word)
    when 2
      vowels(word)
    when 3
      repeat(caps(word))
    when 4
      vowels(caps(word))
    when 5
      caps(repeat(word))
    when 6
      vowels(repeat(word))
    when 7
      caps(vowels(word))
    when 8
      repeat(vowels(word))
    when 9
      vowels(repeat(caps(word)))
    end
    return word
  end
end
