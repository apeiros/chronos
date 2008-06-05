#include <ruby.h>
#include <math.h>
#include "datetime.h"

VALUE rb_mChronos;
VALUE rb_mGregorian;

void
Init_cchronos()
{
	rb_mChronos   = rb_define_module("Chronos");
	rb_mGregorian = rb_define_module_under("Gregorian");
	rb_cDatetime  = rb_define_class_under(rb_mChronos, "Datetime",  rb_cObject);

	rb_include_module(rb_cDatetime, rb_mGregorian);



	rb_define_alloc_func(rb_cDatetime, rb_chronos_datetime__allocate);

	rb_define_method(rb_cDatetime, "initialize",      rb_color_rgb_initialize, -1);
}
