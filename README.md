# DidIt CLI Client

A simple iDoneThis command line client that can post dones for you. To configure, you need [your API token](https://idonethis.com/api/token/).

## Requirements:

Requires Ruby 2.0.0 or later. 

`sudo gem install highline` - OR - `bundle install`

## Usage:

Call as `./didit.rb` from didit folder - OR - set `path` variable:

1. Add the didit directory to your `path`:
   1. `vim ~/.bash_profile`
   2. Add this line to the bottom: `export PATH=$PATH:/Your/Code/Location/didit-cli-client`
2. Chmod the files to be executable 
   1. `cd /Your/Code/Location/didit-cli-client`
   2. `chmod 700 didit.rb`
   3. Restart your terminal program
3. Run the script! > `didit.rb`

The client will continue asking you for done entries until you simply hit enter.

Alternatively, a done entry may be passed as a commandline argument, e.g.:

  `./didit.rb I made some great pasta sauce.`

Should you ever need to reset your configuration file, simply do:

  `./didit.rb --reset`

This client is written in Ruby and serves as a quick example on how one could use the iDoneThis API.
