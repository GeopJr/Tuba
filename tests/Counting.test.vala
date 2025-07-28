struct TestCount {
	public string content;
	public int count;
}

struct TestMention {
	public string content;
	public string without_mentions;
}

const TestCount[] COUNTS = {
	{"hello world", 11},
	{"γεία σου κόσμε", 14},
	{"🏳️‍⚧️👩‍👩‍👧‍👦🧔🏾🤠", 4},
	// This is correct according to https://aksharas.vipran.in/
	// Based on this discussion https://groups.google.com/g/sanskrit-programmers/c/oZSQmh6bRJU,
	// most online 'unicode counters' do not count it correctly.
	{"अद्वैत", 3}
};

const TestMention[] MENTIONS = {
	{"Can't wait for the next @GNOME@floss.social version! #GNOME", "Can't wait for the next @GNOME version! #GNOME"},
	{":dragnpats:@Tuba@floss.social", ":dragnpats:@Tuba"},
	{"@tub a@floss.social", "@tub a@floss.social"},
	{"Local user @GeopJr", "Local user @GeopJr"},
	{"Hello @gnome@floss.social @GeopJr @tuba@floss.social", "Hello @gnome @GeopJr @tuba"}
};

public void test_count () {
	foreach (var test_count in COUNTS) {
		assert_cmpint (Tuba.Utils.Counting.chars (test_count.content), CompareOperator.EQ, test_count.count);
	}
}

public void test_mention () {
	foreach (var test_mention in MENTIONS) {
		assert_cmpstr (Tuba.Utils.Counting.replace_mentions (test_mention.content), CompareOperator.EQ, test_mention.without_mentions);
	}
}

public int main (string[] args) {
	Test.init (ref args);

	Test.add_func ("/test_count", test_count);
	Test.add_func ("/test_mention", test_mention);
	return Test.run ();
}
