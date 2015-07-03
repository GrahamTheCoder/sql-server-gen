# sql-server-gen

The goal of this package is to generate arbitrary SQL Server databases (in the form of create statements).  Current goal is just to produce full table definitions.  Currently supported objects types are tables (partial) and sequences (full).

Contributers more than welcome (especially if you know enough Haskell to help me simplify the code!).

# Build instructions

## Linux

Download all the stuff you need. (GHC 7.10.1 from https://www.haskell.org/ghc/download_ghc_7_10_1 and cabal-install from https://www.haskell.org/cabal/download.html).  Clone this project and open up a command prompt in the root directory of the cloned project.  Running the following series of commands ought to get you somewhere close to working.

    cabal update
    cabal sandbox init
    cabal install --dependencies-only
    cabal repl

## Windows

Building Haskell on Windows is a minor pain in the bottom.  You'll need to install MinGW (http://sourceforge.net/projects/mingw/?source=typ_redirect) and install the packages (make sure gcc is selected).  Once you've done this, find the install directory and run  `msys.bat`.  Do all of this in the command prompt that pops up.

    cabal update
    cabal sandbox init
    cabal install happy
    cabal install --dependencies-only
    cabal repl

This'll create a sandbox environment, download and install all the dependencies and then open up a REPL with the code loaded.  From here you should be able to experiment with the code, for example:

    x <- sample' (arbitrary :: Gen DatabaseDefinition)
    
# Usage

There's a command line interface then

    cabal build cli
    ./cli --help    

Should produce the documentation.  
