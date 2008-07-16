class Integer
	# whether the given number is a leap year in gregorian calendar system
	def leap_year?(year)
		((self%4).zero? && !(self%100).zero?) || (self%400).zero?
	end
end
