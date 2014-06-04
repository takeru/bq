require "pp"
require "json"
require "bq"
require "terminal-table"

project_id = nil
project_id ||= ENV["bq_project_id"]
raise "please set your project_id" unless project_id
token_file = ".bq_secret_token.json"

bq = Bq::InstalledApp.new(:project_id=>project_id, :token_storage=>token_file)
unless bq.authorized?
  unless bq.authorize
    raise "failed to authorize."
  end
end
q = DATA.read.strip
result = bq.query(q).to_hash

if result["error"] || result["rows"].nil?
  pp result
  exit
end

["kind","jobReference","totalRows","totalBytesProcessed","jobComplete","cacheHit"].each do |k|
  puts "%20s : %s" % [k, result[k]]
end

# pp [result["rows"], result["schema"]]
rows   = result["rows"]
fields = result["schema"]["fields"]
headings = [""] + fields.map{|f| f["name"] + "\n" + f["type"] + "\n" + f["mode"] }
table = Terminal::Table.new :headings=>headings do |t|
  rows.each_with_index do |r,i|
    t.add_row [i] + r['f'].map{|hash| hash['v'] }
  end
end
table.align_column(0, :right)
fields.each_with_index do |s,i|
  if %w(INTEGER FLOAT).include?(s["type"])
    table.align_column(i+1, :right)
  end
end
puts table

__END__
--- SELECT weight_pounds, state, year, gestation_weeks FROM publicdata:samples.natality ORDER BY weight_pounds DESC LIMIT 10;
--- SELECT word FROM publicdata:samples.shakespeare WHERE word="huzzah";
--- SELECT corpus FROM publicdata:samples.shakespeare GROUP BY corpus;
SELECT corpus, sum(word_count) AS wordcount FROM publicdata:samples.shakespeare GROUP BY corpus ORDER BY wordcount DESC;
