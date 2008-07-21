#include <math.h>
#include <ruby.h>
#include <time.h>

VALUE rb_mChronos;
VALUE rb_cDatetime;
VALUE rb_cDatetimeGregorian;
ID    id_new;

int DAYS_IN_MONTH1[]    = {0,31,28,31,30,31,30,31,31,30,31,30,31};
int DAYS_IN_MONTH2[]    = {0,31,29,31,30,31,30,31,31,30,31,30,31};
int DAYS_UNTIL_MONTH1[] = {0,31,59,90,120,151,181,212,243,273,304,334,365};
int DAYS_UNTIL_MONTH2[] = {0,31,60,91,121,152,182,213,244,274,305,335,366};

VALUE
datetime_gregorian__components(int argc, VALUE *argv, VALUE self)
{
	long cyear, cday_number; // those should/will be a 64bit int
	int cmonth, cweek, cdayofyear, cdayofmonth, cdayofweek, cdays, isleap;
	struct tm *tm_now;
	struct timeval tv_now;
	VALUE year, month, week, dayofyear, dayofmonth, dayofweek, ps_number, timezone, language;

	rb_scan_args(argc, argv, "9", &year, &month, &week, &dayofyear, &dayofmonth, &dayofweek, &ps_number, &timezone, &language);
	
	if (gettimeofday(&tv_now, 0) < 0) { // stolen from time.c (ruby18)
		rb_sys_fail("gettimeofday");
	}
  tm_now = gmtime(&(tv_now.tv_sec));


	if (!(NIL_P(year) && NIL_P(month) && NIL_P(week) && NIL_P(dayofyear) && NIL_P(dayofmonth) && NIL_P(dayofweek))) {
		cyear = NIL_P(year) ? (long)tm_now->tm_year+1900 : NUM2LONG(year);

		if (!(NIL_P(month) && NIL_P(dayofmonth))) {
			int cdoy;
			isleap = (((cyear%4==0) && !(cyear%100==0)) || (cyear%400==0));

			cmonth      = NIL_P(month) ? 1 : FIX2INT(month);
			if (1 > cmonth || cmonth > 12) {
				rb_raise(rb_eArgError, "Month out of bounds"); 
			}
			if (cdayofmonth > (isleap ? DAYS_IN_MONTH2[month] : DAYS_IN_MONTH1[month])) {
				rb_raise(rb_eArgError, "Day of month out of bounds");
			}
			cdayofmonth = NIL_P(dayofmonth) ? 1 : FIX2INT(dayofmonth);
			cdays       = cyear*365+(cyear/4)-(cyear/100)+(cyear/400)+(cyear%4!=0)+(cyear%100!=0)+(cyear%400!=0);
			cdoy        = (isleap ? DAYS_UNTIL_MONTH2[month-1] : DAYS_UNTIL_MONTH1[month-1]) + dayofmonth;
			cday_number = cdays+cdoy;
		}
	}
	return rb_funcall(rb_cDatetimeGregorian, id_new, 4, INT2NUM(cday_number), ps_number, timezone, language);
}

void
Init_chronos_core()
{
	rb_mChronos           = rb_define_module("Chronos");
	rb_cDatetime          = rb_define_class_under(rb_mChronos, "Datetime", rb_cObject);
	rb_cDatetimeGregorian = rb_define_class_under(rb_cDatetime, "Gregorian", rb_cDatetime);
	id_new                = rb_intern("new");

	rb_define_module_function(rb_cDatetimeGregorian, "components", datetime_gregorian__components, -1);
}
