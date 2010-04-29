class Taxonomy
  
  stuff = []
  
  f = File.open("#{RAILS_ROOT}/data/taxonomy.txt")
  while (line = f.gets)
    next if line =~ /^#/
    #T01001(2000)	hsa	H.sapiens	Homo sapiens (human)
    garbage, tlc, abbrspecies, fullspecies = line.chomp.split("\t")
    species = fullspecies.split(" (").first
    h = {:tlc => tlc, :species => species}
    stuff.push h
  	
    #puts "<option value=\"#{tlc}\">#{species}</option>"
  end
  
  stuff.sort! do |a,b|
    a[:species] <=> b[:species]
  end
  
  for thing in stuff
    puts "<option value=\"#{thing[:tlc]}\">#{thing[:species]}</option>"
  end
  
end