require 'csv'

CANIDATE_NAME = 1
EVENT_ATTENDED = 2
NETWORKING = 3
RESUME = 5
CASE = 6
BAD_ROW = 7
BAD_SCORE = -1

@fails = []
@csv = nil

@output_csv = [] # canidate name, average networking score, average resume score, average case score, recomennded score, actual score
@key = {} # canidate_name -> [canidate csv index, networking_scores_averaged, resume_scores_averaged, case_scores_averaged]

csv_path = "/Users/TheOwner/Downloads/AH\ Canidates.csv"

def run
  @path = "/Users/TheOwner/Downloads/AH\ Canidates.csv"
  read_csv!
  init_result_csv!
  parse_applications!
  translate_results!
  create_reccomended_score!
  sort_results!
  add_headers!
  write_results!
end

def add_headers!
  @output_csv.unshift(['Canidate Name', 'Average Networking Score', 'Average Resume Score', 'Average Case Score', 'Reccomended Score', 'Actual score'])
end

def write_results!
  CSV.open("/Users/TheOwner/Desktop/applicants_parsed#{Time.now}.csv", "wb") do |csv|
    @output_csv.each do |row|
      csv << row
    end
  end
end

def translate_results!
  @output_csv.each do |row|
    row[1] = ((row[1].to_f / 6) * 10).round(2)
    row[2] = ((row[2].to_f / 7) * 10).round(2)
    row[3] = ((row[3].to_f / 8) * 10).round(2)
  end
end

def create_reccomended_score!
  @row
  @output_csv.each do |row|
    @row = row
    row[4] = ((row[1] + row[2] + row[3]).to_f / num_scores(row)).round(2)
  end
end

def sort_results!
  @output_csv.sort! do |a,b|
    difference = a[4] - b[4]
    if difference > 0
      -1
    elsif difference < 0
      1
    else
      0
    end
  end
end

def num_scores(row)
  num = 0
  num += 1 if row[1] != 0
  num += 1 if row[2] != 0
  num += 1 if row[3] != 0
  num
end

def read_csv!
  @csv = CSV.parse(File.read(@path))
  @csv.shift #remove leading headers
end

def init_result_csv!
  @output_csv = []
end

def normalized(event)
  case event
  when NETWORKING
    1
  when RESUME
    2
  when CASE
    3
  else
    raise 'shit fuck'
  end
end

def average_in_score(applicant, event, score, row)
  event = normalized(event)
  num_averaged = @key[applicant][event]
  old_average = row[event]
  new_average = ((old_average * num_averaged + score).to_f / (num_averaged + 1)).round(2)

  row[event] = new_average
  @key[applicant][event] = num_averaged + 1
end

def output_index_or_add(name)
  @key[name] = [@output_csv.length, 0 ,0, 0] if !@key[name]
  @key[name][0]
end

def index_is_new?(index)
  index == @output_csv.length
end

def canidate_name(row)
  row[CANIDATE_NAME]
end

def which_event(row)
  case row[EVENT_ATTENDED]
  when 'Monday: Intro Night'
    NETWORKING
  when 'Tuesday: Meet the Brothers'
    NETWORKING
  when 'Wednesday: Alumni Night'
    NETWORKING
  when 'Thursday: Resume Workshop'
    RESUME
  when 'Friday: Sports Day'
    NETWORKING
  when 'Saturday: Case Workshop'
    CASE
  else
    default_to_scores_given(row)
  end
end

def default_to_scores_given(row)
  if row[NETWORKING]
    NETWORKING
  elsif row[RESUME]
    RESUME
  elsif row[CASE]
    CASE
  else
    @fails << row
    BAD_ROW
  end
end

def score(row, event)
  result_string = row[event]
  if result_string.nil?
    @fails << row
    BAD_SCORE
  else
    result_string.split('?').length
  end
end

def parse_applications!
  @csv.each do |row|
    @current_row = row
    current_applicant = canidate_name(row)
    current_event = which_event(row)

    if current_event != BAD_ROW
      current_score = score(row, current_event)
      if current_score != BAD_SCORE
        index = output_index_or_add(current_applicant)

        if index_is_new?(index)
          @output_csv << row = [current_applicant, 0, 0, 0, 0]
        else
          row = @output_csv[index]
        end
        average_in_score(current_applicant, current_event, current_score, row)
      end
    end
  end
  1
end




