# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'pry-byebug'
require 'time'

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(number)
  # remove anything that isnt a number
  clean_number = number.gsub(/[^0123456789]/, '')

  begin
    case true
    when clean_number.length == 11 && clean_number.chr == '1'
      clean_number[1..]

    when clean_number.length == 10
      clean_number
    else
      'invalid phone number!'
    end
  rescue StandardError
    'error!'
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by entering an zipcode'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initalized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

hours = []

days = []

contents.each_with_index do |row, idx|
  id = row[0]

  name = row[:first_name]

  # phone_number = clean_phone_number(row[:homephone])

  regdate = row[:regdate]

  clean_regdate = Time.strptime(regdate, '%m/%d/%y %H:%M')

  hours[idx] = clean_regdate.hour

  days[idx] = clean_regdate.wday

  # zipcode = clean_zipcode(row[:zipcode])

  # legislators = legislators_by_zipcode(zipcode)

  # form_letter = erb_template.result(binding)

  # save_thank_you_letter(id, form_letter)
end

def count_frequency(arr)
  arr.max_by { |a| arr.count(a) }
end

# deprecated because frequency and average are not the same

# def find_average(arr)
# total = arr.reduce(0) { |total, curr_hour| total + curr_hour }
# average = total / arr.length
# end

def to_normal_hours(hour)
  if hour > 12
    norm_hour = hour - 12
    norm_hour.to_s + ' p.m.'
  else
    hour.to_s + ' a.m.'
  end
end

def peak_days(days)
  day = count_frequency(days)
  day_to_s = Date::DAYNAMES[day]
  "The peak day is #{day_to_s}"
end

def peak_hours(hours)
  peak_hour = to_normal_hours(count_frequency(hours))
  "The peak hour is #{peak_hour}"
end

# peak_hours(hours)
# peak_days(days)

p peak_days(days)
p peak_hours(hours)
