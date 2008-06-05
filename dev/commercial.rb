$:.unshift("../lib")
require 'date'
require 'chronos/datetime'
weeks = 0
year  = 2000
days  = 0
def nweeks(days)
	days.div(7) + (days%7==6 ? 1 : 0)
end
File.open("commercial.txt", "w") { |fh|
	2000.upto(2400) { |year|
		fh.printf "%4d %4d %8d %4d %4d %d\n", year, weeks, days, nweeks(days), weeks-nweeks(days), days%7

		date  = Date.civil(year, 12, 31)
		w = date.strftime("%V")
		weeks += w == "01" ? 52 : w.to_i
		days  += ((year%4 == 0 && year%100 != 0) || (year%400 == 0)) ? 366 : 365
	}
}