namespace :typepad do
  desc "Imports a Typepad feed into local database"
  task :import => :environment do
    puts "Using " << RAILS_ENV << " database"
    puts "What Typepad feed would you like to import?"
    feed = $stdin.gets.chomp
    puts "Importing: " << feed
    
    ## try and read feed
    
  end
end