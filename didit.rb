#!/usr/bin/env ruby

require 'highline/import' # https://github.com/JEG2/highline for ask()
require 'net/http'
require 'json'

# constants and globals
CONFIG_FILE = File.expand_path('~/.didit.rb')
API_VERSION = '0.0'

API_ROOT = "https://idonethis.com/api/v#{API_VERSION}/"
$endpoints = {} # to be discovered by discover_urls

### configuration logic ###

def delete_configuration()
    File.delete(CONFIG_FILE) if File.exist? CONFIG_FILE
end

def load_configuration()
    begin
        load CONFIG_FILE
    rescue Exception
    end
end

def config_works()
    if not defined? $did_config
        return false
    end
    if not $did_config[:API_TOKEN] or not $did_config[:TEAM_URL]
        return false
    end
    team = read_team()
    return (team != nil and team['done_count'] != nil)
end

def recreate_configuration()
    if File.exist? CONFIG_FILE
        delete_configuration()
        f = File.new(CONFIG_FILE, "w")
        f.close()
    end

    api_token = ""
    while api_token.length != 40 do
        api_token = ask("Please enter your iDoneThis API token: ")
    end

    team_url = ""
    while api_token and not team_url.start_with? API_ROOT do
        # get list of teams
        url = URI.parse($endpoints[:TEAMS_ENDPOINT])
        client = Net::HTTP.new(url.host, url.port)
        client.use_ssl = true
        req = Net::HTTP::Get.new(url)
        req['Content-Type'] = 'application/json'
        req['Authorization'] = 'Token ' + api_token
        res = client.start { |http| http.request(req) }
        if res.code != '200'
            puts "Something went wrong finding your teams, HTTP status code was #{res.code}. API token '#{api_token}' correct? "
            Kernel.abort()
        end

        teams = JSON.parse(res.body)['results']
        puts "You can post to the following teams:"
        teams.each_with_index do |team, index|
            puts (index+1).to_s + ": " + team['name'] + " (" + team['done_count'].to_s + " dones)"
        end

        team_selection = 0
        while team_selection < 1 or team_selection > teams.length do
            team_selection = ask("Which team do you want to send your dones to? ").to_i
        end
        team_selection -= 1
        team_url = teams[team_selection]['url']
    end

    File.open(CONFIG_FILE, "w") do |f|
        f << "$did_config = { :API_TOKEN => \"#{api_token}\", :TEAM_URL => \"#{team_url}\"}"
    end
end

### API interaction ###

def discover_urls()
    url = URI.parse(API_ROOT)
    client = Net::HTTP.new(url.host, url.port)
    client.use_ssl = true
    req = Net::HTTP::Get.new(url)
    req['Content-Type'] = 'application/json'
    res = client.start { |http| http.request(req) }
    if res.code != '200'
        return false
    end
    endpoints = JSON.parse(res.body)
    if not endpoints['teams'] or not endpoints['dones']
        return false
    end
    $endpoints[:TEAMS_ENDPOINT] = endpoints['teams']
    $endpoints[:DONES_ENDPOINT] = endpoints['dones']
    return true
end

def read_team()
    url = URI.parse($did_config[:TEAM_URL])
    client = Net::HTTP.new(url.host, url.port)
    client.use_ssl = true
    req = Net::HTTP::Get.new(url)
    req['Authorization'] = 'Token ' + $did_config[:API_TOKEN]
    req['Content-Type'] = 'application/json'
    res = client.start { |http| http.request(req) }
    if res.code != '200'
        return false
    end
    team = JSON.parse(res.body)
    return team
end

def enter_done()
    done_text = ask("What did you get done? ")
    if done_text.length < 1
        puts "Seems you're done, quitting! "
        Kernel.abort()
    end
    post_done(done_text)
end

def post_done(done_text)
    url = URI.parse($endpoints[:DONES_ENDPOINT])
    client = Net::HTTP.new(url.host, url.port)
    client.use_ssl = true
    req = Net::HTTP::Post.new(url)
    req.body = {:raw_text => done_text, :team => $did_config[:TEAM_URL], :done_date => Time.new().strftime("%Y-%m-%d")}.to_json
    req['Content-Type'] = 'application/json'
    req['Authorization'] = 'Token ' + $did_config[:API_TOKEN]
    res = client.start { |http| http.request(req) }
    if res.code != '201'
        puts "Something went wrong posting your done, HTTP status code was #{res.code}. API token '#{$did_config[:API_TOKEN]}' correct? "
        Kernel.abort()
    else
        puts "Posted your done! "
    end
end

### main application ###

if __FILE__ == $PROGRAM_NAME
    if ARGV[0] and ARGV[0] == '--reset'
        puts "Deleting configuration ..."
        delete_configuration()
    end

    # try to load the configuration file
    load_configuration()
    if not discover_urls()
        puts "Couldn't discover URLs! "
        Kernel.abort()
    end

    # if the configuration doesn't work, delete it and create it again
    if not config_works()
        recreate_configuration()
        load_configuration()
        # fail if it still doesn't work
        if not config_works()
            puts "Configuration doesn't work, giving up."
            Kernel.abort()
        end
    end

    # we should be able to post dones to our favorite team now!
    # if a string was provided as an arg, just post it.
    # otherwise, accept inputs in a loop (old behavior)
    if ARGV[0] and ARGV[0] != '--reset'
        post_done(ARGV[0])
    else
        while true do
            enter_done()
        end
    end
end


