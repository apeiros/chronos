extern VALUE rb_color_cmyk__allocate(VALUE class);

typedef struct _cDatetime {
	unsigned long long day_number;
	unsigned long long ns_number;
} cDatetime;
