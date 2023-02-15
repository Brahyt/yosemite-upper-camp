require 'httparty'
require 'debug'

unless ARGV[0] && ARGV[1]
  puts 'provide a start date and end date YYYY-MM-DD YYYY-MM-DD'

  exit!
end

@start_date = ARGV[0]

@parsed_start_date = DateTime.parse('2023-03-01')
@parsed_end_date = DateTime.parse(ARGV[1])
@avail_campsites = {}

url = "https://www.recreation.gov/api/camps/availability/campground/232447/month?start_date=#{DateTime.parse(@start_date).strftime("%Y-%m")}-01T00%3A00%3A00.000Z"

destination_url = "https://www.recreation.gov/search?q=Upper%20Pines%20Campground&checkin=#{@parsed_start_date.month}%2F#{@parsed_start_date.day}%2F#{@parsed_start_date.year}"

def date_within_range(key)
  DateTime.parse(key).between?(@parsed_start_date, @parsed_end_date)
end

def check_site_reservations(campsite)
  campsite['availabilities'].each_key do |key_date|
    next unless date_within_range(key_date)

    next if ['Reserved', 'Not Reservable Management'].include? campsite['availabilities'][key_date]

    @avail_campsites[campsite['site']] = [] unless @avail_campsites[campsite['site']]
    @avail_campsites[campsite['site']] << key_date
  end
end

response = HTTParty.get(url)

unless response&.message == 'OK'
  puts "ERROR"
  puts response
  puts "ERROR"

  exit!
end

campsites = JSON.parse(response.body)['campsites']

campsites.each_key do |site_number|
  check_site_reservations(campsites[site_number])
end

if @avail_campsites.empty?
  puts 'NO CAMP SITES'
else
  print "\a"

  puts "\n"
  @avail_campsites.each_key do |key|
    puts "-- SITE: #{key} --"
    puts @avail_campsites[key]
    puts "\n"
  end

  puts destination_url
end

