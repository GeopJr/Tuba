struct TestUnits {
	public int64 original;
	public string result;
}

const TestUnits[] UNITS = {
	{ 0, "0" },
	{ 123, "123" },
	{ 999, "999" },
	{ 1000, "1k" },
	{ 1312, "1.3k" },
	{ 999999, "999k" },
	{ 1000000, "1M" },
	{ 9876543210, "9.8G" },
	{ 1000000000000, "♾️" },
};

public void test_shorten () {
	foreach (var test_unit in UNITS) {
		var shorten_unit = Tuba.Utils.Units.shorten (test_unit.original);
		var shorten_unit_negative = Tuba.Utils.Units.shorten (test_unit.original * -1);

		assert_cmpstr (shorten_unit, CompareOperator.EQ, test_unit.result);
		assert_cmpstr (
			shorten_unit_negative,
			CompareOperator.EQ,
			test_unit.result == "♾️" || test_unit.result == "0" ? test_unit.result : @"-$(test_unit.result)"
		);
	}
}

public int main (string[] args) {
	Test.init (ref args);

	Test.add_func ("/test_shorten", test_shorten);
	return Test.run ();
}
