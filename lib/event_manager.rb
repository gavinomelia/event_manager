require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phone_number)
  phone_number = phone_number.to_s.gsub(/\D/, '')
  if phone_number.length == 10
    phone_number
  elsif phone_number.length == 11 && phone_number[0] == '1'
    phone_number[1..10]
  else
    'Invalid phone number'
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def get_peak_hours(hour_counts)
  # Using the registration date and time we want to find out what the peak registration hours are.
  
puts "Peak registration hours:"
hour_counts.sort_by { |hour, count| -count }.each do |hour, count|
  puts "#{hour}:00 - #{count} registrations"
end
end

def get_peak_days(day_counts)
  # Using the registration date and time we want to find out what the peak registration days are.
  
puts "Peak registration days:"
day_counts.sort_by { |day, count| -count }.each do |day, count|
  puts "#{Date::DAYNAMES.at(day)}: #{count} registrations"
end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hour_counts = Hash.new(0)
day_counts = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  reg_date = row[:regdate]
  time = Time.strptime(reg_date, "%m/%d/%y %H:%M")
  hour_counts[time.hour] += 1
  day_counts[time.wday] += 1
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end

get_peak_hours(hour_counts)
get_peak_days(day_counts)