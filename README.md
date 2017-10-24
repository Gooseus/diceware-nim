# Diceware in Nim

This was pretty much just a test of the [Nim language](https://nim-lang.org) that I just kept messing with for a weekend.

Based on the [Diceware technique](http://world.std.com/~reinhold/diceware.html) by Arnold G. Reinhold which provides a relatively easy way for a lay person to create a cryptographically secure password which is also memorable.

![Obligatory XKCD reference](https://imgs.xkcd.com/comics/password_strength.png)

*Obligatory XKCD reference - [#936](https://xkcd.com/936/)*

Here is the `diceware --help` output:

```
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
```

So lots of stuff and most of it could use a lot of work since I'm pretty naive when it comes to Nim, as well as the paradigms it allows... such as static typing.  Lots of obvious improvements, especially to the CLI and argument parsing.

In any case, the end result is a pretty neat little script that can compile and run without any dependencies since it includes a full word list in the binary, though you can substitute your own list with the `-L` switch.

Another neat thing is that you can use the `-p` and `-r` switches to pipe the output into a file, through an encryption program, or over an encrypted channel and never even see what it is.  Something I imagine could be useful for system admins or security contractors who want memorable passwords for their users.

Let me know what you think in Issues or over keybase chat [@gooseus](https://keybase.io/gooseus)