require 'rubygems'
require 'inline'


	inline do |builder|
		builder.c %q{
			VALUE year_and_day_of_year() {
				int day_number = FIX2INT(rb_ivar_get(self, rb_intern("@day_number")));
				int y4c = (day_number - 1) / 146097;
				int days = (day_number - 1) % 146097;
				int y1c;
				
				if (days == 0) {
					y1c = days = 0;
				} else {
					y1c = (days - 1) / 36524;
					days =  (days - 1) % 36524;
					days += 1;
				}

				int y4 = days / 1461;
				days = days % 1461;
				int y1;
				if ( y1c != 0 && y4 == 0 ) { days -= 1; }
				if ( days == 0 ) {
					y1 = days = 0; 
				} else if ( y1c != 0 && y4 == 0 ) {
						y1 = days / 365;
						days = days % 365;
				} else {
					y1 = (days - 1) / 365;
					days = (days - 1) % 365;
					if ( y1 == 0 ) { days += 1; }
				}
				int year = y4c * 400 + y1c * 100 + y4 * 4 + y1;
				int day_of_year = days + 1;
				
				rb_ivar_set(self, rb_intern("@day_of_year"), INT2FIX(day_of_year));
				rb_ivar_set(self, rb_intern("@year"), INT2FIX(year));

				return rb_ary_new3(2, INT2FIX(year), INT2FIX(day_of_year));
			}
		}
	end