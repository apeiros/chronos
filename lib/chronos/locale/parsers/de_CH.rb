# 21. 12. 1982
# 21.12.1982
# 21. Dezember 1982
# 23:15 Uhr
# 23.15 Uhr

add(/#{day}\. ?#{month}\. ?#{year}/, :day, :month, :year)
add(/#{day}\. #{monthname} #{year}/, :day, :month, :year)
add(/#{hour}(?:[:.]#{minute}(?:[:.]#{second})?)?/, :hour, :minute, :second)
add(/gestern/) {
	d = Chronos::Datetime::Gregorian.today
	s = Chronos::Duration::Gregorian.new :days => 1
	d.to_hash(:year, :month, :day)
}
add(/heute/) {
	d = Chronos::Datetime::Gregorian.yesterday; d.to_hash(:year, :month, :day)
}
'#(gestern)#': 
  - yesterday
'#(heute)#': 
  - today
'#(morgen)#': 
  - tomorrow
'#(jetzt)#': 
  - now
'#(\d{1,2})\.(\d{1,2})\.(\d{4}|\d{2})?#': 
  - d
  - m
  - y
'#(\d{1,2})\. (\d{1,2})\. (\d{4}|\d{2}(?![.:]))?#': 
  - d
  - m
  - y
'#(\d{1,2})\. (\w{3,})\.? ?(\d{4}|\d{2})?#': 
  - d
  - T
  - y
'#(\d{1,2})\:(\d{1,2})h?#': 
  - H
  - M
'#(\d{1,2})\:(\d{1,2})(h| uhr)?#': 
  - H
  - M
'#(?:\A|[^\.\d])(\d{1,2})\.(\d{1,2})(?![\.\d])(h| uhr)?#': 
  - H
  - M
  - 0
'#(\d{1,2})(h| uhr)#': 
  - H
  - 0
