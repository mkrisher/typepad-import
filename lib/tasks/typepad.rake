=begin
  TODO remove links placed around typepad images
  TODO check differences between atom, rss1 and rss2, maybe require rss2
=end

require 'open-uri'
require 'net/http'

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
    if !@items.nil?
      for item in @items do
          item["pubDate"] ||= ""
          item["creator"] ||= ""
          item["guid"] ||= ""
          item["title"] ||= ""
          item["description"] ||= ""
          clean_content(item["encoded"] ||= "")
          item["link"] ||= ""
          params = { 
            :pubdate => item["pubDate"], 
            :creator => item["creator"], 
            :guid => relative_link(item["guid"]), 
            :title => item["title"], 
            :description => item["description"], 
            :content => @content, 
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
  
  # prepare the main content to be served locally
  def clean_content(content)
    @content = content
    unless content.nil?
      correct_image_paths
      remove_typepad_links
    end
  end
  
  # correct any embedded image paths in the content
  def correct_image_paths
    results = @content.scan(/src=\".*?\"/)
    # {|m| copy_image_locally m.gsub!("src=", "").gsub!("\"", "")}
    results.each do |result|
      copy_image_locally result.gsub!("src=", "").gsub!("\"", "")
    end
  end
  
  # pull down a copy of all images stored on typepad
  def copy_image_locally(img)
    begin
      # if an image is stored on typepad servers, copy it locally
      if img =~ /typepad/
        open("public/images/" << img.gsub(@base.gsub("weblog",""), "").gsub(".a/", "") << ".jpg","w").write(open(img).read)
        # update the link in the content
        update_image_source(img)
      end
    rescue
      puts "was not able to capture " << img << " locally"
    end
  end
  
  # update the image src path, once we have a local copy
  def update_image_source(img)
    @content.gsub!(img, "/images/" << img.gsub(@base.gsub("weblog",""), "").gsub(".a/", "") << ".jpg")
  end
  
  # remove the extra links around the typepad images
  def remove_typepad_links
    results = @content.scan(/<a href=.*?<\/a>/)

    results.each do |result|
      # if result contains an image with an image-full class
      if result =~ /image-full/
        temp = result.sub(/<a href=.*?>/, "").sub(/<\/a>/, "")
        @content.sub!(result, temp)
      end
    end
  end
  
  # add entry to database
  def insert_entry(params)
    Entry.create(params)
  end
  
end

