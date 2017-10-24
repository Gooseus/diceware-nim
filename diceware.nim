#[ 
  # Diceware CLI
  
  a self-learning example of Nim language and work in progress toward useful command-line privacy/security-enhancement tool
  
  ## Long term goals
  
  * modularization - break things up into some proper modules
  * proper documentation - look up nim documentation generator and available styles, probably something cool, maybe even some kind of documentation DSL
  * unit testing - tests to run so we know it's not gonna fuck up for random inputs
  * more options/flags - some more cool options for piping in rolls or word lists, or maybe even a stream of both?
  * my very own DSL - figure out how to express this code using some macros and templates such that it can be re-compiled with different default parameters
  * cool examples - lots of cool examples of different ways to make passwords, encrypt them, share them, etc
  * companion scripts - scripts to build word lists, help encrypt/share them (keybase?)
 ]#
# import modules
# TODO - should only import the functions we want
import strutils
import random
import sequtils
import re
import math
import times
import algorithm
import terminal
import os

type
  Params = tuple[words: int,
                list: seq[string],
                rolls: seq[string], 
                separator: string,
                wordCount: bool, 
                listPath: bool, 
                diceRolls: bool,
                force: bool, 
                pipe: bool, 
                entropyAnalysis: bool, 
                help: bool, 
                show: bool, 
                randomize: bool]

# returns a procedure that will check a word for a max and min length
proc makeWordLengthFilter(min: int=0, max: int=9) : (proc(w:string):bool) = 
  return proc(w:string) : bool =
    return min<w.len and w.len<max

# Declare variables
# TODO - optionally shuffle word_list, cut to 7776
const 
  recommended = (words: 6, list: 7776)
  defaults : Params = (words: recommended.words, 
                      list: "./words/default".staticRead().split("\n").filter(makeWordLengthFilter(2,7))[0..recommended.list-1],
                      rolls: @[],
                      separator: " ",
                      wordCount: false,
                      listPath: false,
                      diceRolls: false,
                      force: false,
                      pipe: false,
                      entropyAnalysis: false,
                      help: false,
                      show: false,
                      randomize: false)

# check and apply command line params
# need a function to consume commandLineParams and return a set of flags and variables
# should take a set of defaults?
proc getArgOpts(commandLine: seq[TaintedString], opts: Params) : Params = 
  result = opts
  if paramCount()>0:
    var last : string
    # echo commandLine
    for param in commandLine:
      if param[0] == '-':
        last = param
        if param[1] == '-':
          case param[2..^1]
          of "help":
            result.help = true
            break
          of "force":
            result.force = true
          of "word-count":
            result.wordCount = true
          of "list-path":
            result.listPath = true
          of "dice-rolls":
            result.diceRolls = true
          of "pipe-output":
            result.pipe = true
            result.force = true
          of "entropy-analysis":
            result.entropyAnalysis = true
          of "show-passphrase":
            result.show = true
          of "randomize-list":
            result.randomize = true
          else: discard
        else:
          case param[1]
          of 'h':
            result.help = true
            break
          of 'W':
            result.wordCount = true
          of 'L':
            result.listPath = true
          of 'D':
            result.diceRolls = true
          of 'f':
            result.force = true
          of 'p':
            result.pipe = true
            result.force = true
          of 'e':
            result.entropyAnalysis = true
          of 's':
            result.show = true
          of 'r':
            result.randomize = true
          else: discard
      else:
        case last
        of "-W", "--word-count":
          result.words = parseInt(param)
        of "-L", "--list-path":
          result.list = param.readFile().split("\n")
        of "-D", "--dice-rolls":
          result.rolls = param.split({ '|', ',', '!', '/', '\\', '-', '_' })
        of "-S", "--separator":
          result.separator = ""&param[0]
        else: # Param without a previous flag indicator
          result.listPath = true
          result.list = param.readFile().split("\n")

var opts = getArgOpts(commandLineParams(), defaults)

proc randomizeSeq(list: var seq[string]) : seq[string] = 
  var 
    i = 0
    swap : string
    idx : int
  
  if not opts.force: echo "Randomizing word list..."
  randomize(int(epochTime() + cpuTime()) + random(2^32))
  for word in list:
    idx = random(list.len)
    swap = list[idx]
    list[idx] = word
    list[i] = swap
    inc i
  return list

# Create a -- prefix operator that decrements before returning value
proc `--`(x: var int) : int = (dec x; return x)
# Take a string integer representation of base and converts it to the base10 integer value
proc rollsToIdx(rolls : seq[char], base : int): int = 
  var i = rolls.len;
  foldl(rolls, a + (int(b)-int('0')-1) * base^(--i), 0)
  # procedural/imperative implementation of rollsToIdx
  # for c in rolls:
  #   result += (int(c)-int('0')-1) * base^(--i)

# another operator I made which acts like a (predicate ? string : empty) operator for building strings
proc `?=`(flag:bool,truth:string) : string =
  if flag:
    return truth
  return ""

if opts.help:
  echo "\n" & """
  Diceware CLI

    -W, --word-count [positiver integer]
      Words in passphrase
      Defaults to 6; should be as long as necessary
    -L, --list-path [valid file path]
      Path to word list file
      Should ideally have 7776 words; built-in list has common words between 3 and 6 characters
    -D, --dice-rolls [list of five rolls 1-6]
      Delimited list of five 6-sided dice rolls
      Can use any of { | , ! _ - / \ } to separate each roll (no spaces), e.g. 54321,63241,43213,65232,46133 or 12345|32451|64562|65232|46133)
    -S, --separator [single character string]
      Separator character string for passphrase
      Can be any character, defaults to single space (' '); make sure to escape special command line characters { ` ~ }

    -r, --randomize
      Randomize the word list
      Should add even more entropy and makes rolls unreproducible
    -p, --pipe
      Pipeable output to a file or through another program
      Enables --force and --show flags, --entropy-analysis not allowed
    -f, --force
      Don't ask confirmation questions, use defaults if not defined
    -s, --show
      Show passphrase in final output
      Normally the text is formatted as hidden so it must be copy and pasted
    -e, entropy-analysis (not supported)
      *TODO* - Entropy analysis (based on passphrase length, word list length, other options; not supported with -p)
    -h, --help
      display this message

    useage:
      diceware [-W [number of words] -L [path to word list] -D [dice rolls] -S [separator] -r -f -s -e]
      diceware [-W [number of words] -L [path to word list] -D [dice rolls] -S [separator] -r -p] | <pbcopy | keybase encrypt>

    examples:
      diceware -W 8 -D [dice rolls] -r -p] >> /path/to/passphrases.txt
      diceware -f -L ~/tmp/curse-words.txt -S \~ -r -p | echo -e "$(cat -)"'\nYour New Password!\nCopy this somewhere safe and delete this message!!' | keybase chat WeakPassphrasedFriend
  """
  quit(0)

# Start the CLI
if not (opts.wordCount or opts.force):
  write stdout, "\nHow many words do you want in your passphrase? "
  # Read user input for how many words we want in our passphase
  try: # Convert to integer
    opts.words = parseInt(readLine(stdin))
  except ValueError:
    echo "Passphrase length must be a positive integer"
    quit(0)

# Check that user input is valid
if opts.words < 1:
  echo "Passphrase length must be a positive integer"
  quit(0)

# Test for passphrase length, warn if smaller than recommended
if not opts.force and opts.words in 1 .. <recommended.words:
  echo "\nYour passphrases is shorter than recommended (", opts.words ," vs ", recommended.words ," words) for current cracking technology.\n"
  write stdout, "Would you like to proceed? "
  if not readLine(stdin).match(re"[yY]([eE][sS])?"): 
    echo "\nOk, try again";
    quit(0)

if not opts.force and opts.list.len < recommended.list:
  echo "\nYour word list is shorter than the recommended (", opts.list.len ," vs ", recommended.list ," words) for current technology.\n"
  write stdout, "Would you like to proceed? "
  if not readLine(stdin).match(re"[yY]([eE][sS])?"): 
    echo "\nOk, try again";
    quit(0)

# shuffle the word list here
if opts.randomize:
  opts.list = randomizeSeq(opts.list)

# Randomize our RNG before starting algorithm
randomize(int(epochTime() + cpuTime()))
var passphrase  = ""
# TODO (?) - parametrize the rolling part to support different dice/bases and number of rolls
const rolls_per_word = 5
const sides_per_roll = 6
# Run the diceware algorithm
# let t_start = cpuTime()
for i in 0 .. opts.words-1:
  var rolls : seq[char]
  # if we're not forcing and we haven't already rolled, then we need need to roll till we have enough
  if opts.force:
    if opts.diceRolls and i < opts.rolls.len:
      rolls = toSeq opts.rolls[i].items
    else:
      # magic auto-roller
      rolls = (toSeq 0 .. rolls_per_word-1).map(proc(x:int):char=intToStr(random(sides_per_roll)+1)[0])
  else:
    if opts.diceRolls and i < opts.rolls.len:
      rolls = toSeq opts.rolls[i].items
    else:
      write stdout, "Roll ", rolls_per_word, " dice and put the numbers in (read right-to-left): "
      rolls = toSeq readLine(stdin).items
  # convert rolls to list index and modulo with list length in case they're using a list with less than 7776 words
  passphrase = passphrase & opts.list[rollsToIdx(rolls,sides_per_roll) mod opts.list.len] & (i<opts.words-1 ?= opts.separator)

# CLI output, skip for piping
if opts.pipe:
  write stdout, passphrase
else:
  write stdout, "\n<PASSPHRASE>"
  if not opts.show:
    system.addQuitProc(resetAttributes)
    setStyle({ styleHidden })
  write stdout, passphrase
  if not opts.show: resetAttributes()
  echo "</PASSPHRASE>\n"
  echo opts.words, " word passphrase created, copy between the tags\n"
  # echo round(cpuTime() - t_start, 6), " seconds to complete"

