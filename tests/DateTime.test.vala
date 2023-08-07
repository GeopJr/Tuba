using GLib;

struct TestDate {
    public string iso8601;
    public string left;
    public string ago;
    public string human;
}

TestDate[] get_dates () {
    TestDate[] res = {
        {
            new DateTime.local (
                2002,
                6,
                29,
                18,
                0,
                0.0
            ).to_string (),
            "Jun 29, 2002",
            "expired on Jun 29, 2002",
            "Jun 29, 2002"
        }
    };

    var time_now = new GLib.DateTime.now_local ();

    var one_day = time_now.add_days (1);
    res += TestDate () {
        iso8601 = one_day.to_string (),
        left = "23h left",
        ago = one_day.format ("expires on %b %-e, %Y %H:%m"),
        human = one_day.format ("%b %-e, %Y %H:%m")
    };

    var m_one_day = time_now.add_days (-1);
    res += TestDate () {
        iso8601 = m_one_day.to_string (),
        left = "Yesterday",
        ago = "expired yesterday",
        human = "Yesterday"
    };

    var one_hour = time_now.add_hours (1);
    res += TestDate () {
        iso8601 = one_hour.to_string (),
        left = "59m left",
        ago = one_hour.format ("expires on %b %-e, %Y %H:%m"),
        human = one_hour.format ("%b %-e, %Y %H:%m")
    };

    var m_one_hour = time_now.add_hours (-1);
    res += TestDate () {
        iso8601 = m_one_hour.to_string (),
        left = "1h",
        ago = "expired 1h ago",
        human = "1h"
    };

    var two_minutes = time_now.add_minutes (2);
    res += TestDate () {
        iso8601 = two_minutes.to_string (),
        left = "1m left",
        ago = two_minutes.format ("expires on %b %-e, %Y %H:%m"),
        human = two_minutes.format ("%b %-e, %Y %H:%m")
    };

    var m_two_minutes = time_now.add_minutes (-2);
    res += TestDate () {
        iso8601 = m_two_minutes.to_string (),
        left = "2m",
        ago = "expired 2m ago",
        human = "2m"
    };

    var twenty_seconds = time_now.add_seconds (20);
    res += TestDate () {
        iso8601 = twenty_seconds.to_string (),
        left = "expires soon",
        ago = twenty_seconds.format ("expires on %b %-e, %Y %H:%m"),
        human = twenty_seconds.format ("%b %-e, %Y %H:%m")
    };

    var m_twenty_seconds = time_now.add_seconds (-20);
    res += TestDate () {
        iso8601 = m_twenty_seconds.to_string (),
        left = "Just now",
        ago = "expired on just now",
        human = "Just now"
    };

    return res;
}

public void test_left () {
    foreach (var test_date in get_dates ()) {
        var left_date = Tuba.DateTime.humanize_left (test_date.iso8601);

        assert_cmpstr (left_date, CompareOperator.EQ, test_date.left);
    }
}

public void test_ago () {
    foreach (var test_date in get_dates ()) {
        var ago_date = Tuba.DateTime.humanize_ago (test_date.iso8601);

        assert_cmpstr (ago_date, CompareOperator.EQ, test_date.ago);
    }
}

public void test_humanize () {
    foreach (var test_date in get_dates ()) {
        var human_date = Tuba.DateTime.humanize (test_date.iso8601);

        assert_cmpstr (human_date, CompareOperator.EQ, test_date.human);
    }
}

public int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/test_left", test_left);
    Test.add_func ("/test_ago", test_ago);
    Test.add_func ("/test_humanize", test_humanize);
    return Test.run ();
}
