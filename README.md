- - -

## Trie based State-aware Recursive Levenshtein-ish Spelling Corrector

Requires: Ruby 1.9.3

For [Twitch's](http://twitch.tv) [spellcheck problem](http://www.twitch.tv/problems/spellcheck)

This is the first application I've written in ruby, nice learning experience.
I'm not up to date on Ruby coding conventions yet, so it will probably make you wince to read.

- - -

#### "Install"

```
git clone [paste from github]
cd spellcheck
export RUBYLIB="`pwd`/lib"
export PATH="$PATH:`pwd`/bin"
```

#### Usage and Examples

It accepts an optional single argument, the path to the dictionary file to load

```
$ spellcheck.rb /usr/share/dict/words
Loaded, ready!
> cunsperricy
conspiracy
```

If you do not pass it a path, it will ask for it on startup

```
$ spellcheck.rb
Please enter the path to a dictionary file and press enter to continue
( Default: '/usr/share/dict/words' )
> /usr/share/dict/words
Loaded, ready!
> supermayun
superman
```

As you can see, you simply feed it a word and it will attempt to correct it to a word in your dictionary

To exit simply break out of the application ( standard control+c ) or force kill it if you're feeling empowered

Credits and such: too many people and papers to list, but the most obvious one would have to be [Steve Hanov](http://stevehanov.ca)

- - -

## Spellbreaker Misspeller

Requires: Ruby 1.9.3

This is a really simple script to misspell words based on the criteria in the Twitch problem, then feed them into the spellchecker

- - -

#### Usage and Examples

Same as the spellcheck, it accepts an optional dictionary path.

```
$ spellcheck.rb generate
Please enter the path to a dictionary file and press enter to continue
( Default: '/usr/share/dict/words' )
>
/usr/share/dict/words
muayNARd's
waDDLes
mmmultipliceety's
tiargusas
fuNNGUSSS's
```
As you can see, it first outputs the dictionary path, then randomly chooses a word from the dictionary to misspell

Passing it to the spellchecker with a path, the dictionary path is fed automatically:

```
$ spellcheck.rb generate /usr/share/dict/words | spellcheck.rb
Please enter the path to a dictionary file and press enter to continue
( Default: '/usr/share/dict/words' )
> Loaded, ready!
> magi
> imperiousness
> rivals
> regretful
> grampians
> relegate
> sampling
```
