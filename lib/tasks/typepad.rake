require 'open-uri'

namespace :typepad do
  
  desc "Imports a Typepad feed into local database"
  task :import => :environment do
    config = ActiveRecord::Base.configurations[RAILS_ENV || 'development']
    raise RuntimeError, "I only work with mysql." unless config['adapter'] == 'mysql'
    
    begin
      # if typepad config file exists
      @typepad_config = YAML.load(File.open('config/typepad.yml'))['typepad']
      feed = @typepad_config['feed']
    rescue
      # else, ask the rake user for a feed url
      puts "What Typepad feed would you like to import?"
      feed = $stdin.gets.chomp
    end
    
    # define base of the Typepad blog
    @base = feed.slice(0..feed.index("weblog") + 5)
    
    read_feed(feed)
  end
  
  ## task methods
  def read_feed(feed)
    begin
        @content = Hash.from_xml open(feed)
        raise "feed error" if (@content["rss"]["channel"]["title"].blank?)
    rescue OpenURI::HTTPError => the_error
        puts "There was an error opening data, check to make sure open-uri is installed and the feed is valid!"
    rescue RuntimeError
        puts "There was an error retrieving the feed!"
    else
        parse_feed
    end
  end

  # parse's the item nodes in the feed
  def parse_feed
    remove_previous_entries
    @items = @content["rss"]["channel"]["item"]
    puts @items[0].inspect
    if !@items.nil?
      for item in @items do
          item["pubDate"] ||= ""
          item["creator"] ||= ""
          item["guid"] ||= ""
          item["title"] ||= ""
          item["description"] ||= ""
          item["encoded"] ||= ""
          item["link"] ||= ""
          params = { 
            :pubdate => item["pubDate"], 
            :creator => item["creator"], 
            :guid => relative_link(item["guid"]), 
            :title => item["title"], 
            :description => item["description"], 
            :content => correct_image_paths(item["encoded"]), 
            :link => relative_link(item["link"])
          }
          insert_entry(params)
      end
    end
  end
  
  # removes all previous Entry records and resets the auto_increment for persistence
  def remove_previous_entries
    Entry.delete_all
    Entry.connection.execute('ALTER TABLE entries AUTO_INCREMENT = 0')
  end

  # makes links relative by stripping out the base typepad URL
  def relative_link(link)
    link.gsub!(@base, "")
  end
  
  def correct_image_paths(content)
    # need to look for any image sources in the content
    # pull them down into local /images directory
    # then rewrite the src attribute inline
    content
  end
  
  # add entry to database
  def insert_entry(params)
    Entry.create(params)
  end
  
end

