public class Tuba.API.AnnualReports : Entity {
	public class Report : Entity {
		public class Data : Entity {
			public class Countable : Entity {
				public int64 count { get; set; }
			}

			public class RebloggedAccount : Countable {
				public string account_id { get; set; }
			}

			public class NamedCountable : Countable {
				public string name { get; set; }
			}

			public class Percentiles : Entity {
				public float statuses { get; set; }
			}

			public class TimeSeries : Entity {
				public int32 month { get; set; }
				public int64 statuses { get; set; }
				public int64 followers { get; set; }
				public int64 following { get; set; }
			}

			public class TopStatuses : Entity {
				public string? by_reblogs { get; set; default = null; }
				public string? by_replies { get; set; default = null; }
				public string? by_favourites { get; set; default = null; }
			}

			public Gee.ArrayList<TimeSeries> time_series { get; set; }
			public Percentiles percentiles { get; set; }
			public TopStatuses top_statuses { get; set; }
			public Gee.ArrayList<NamedCountable> top_hashtags { get; set; }
			public Gee.ArrayList<NamedCountable> most_used_apps { get; set; }
			public Gee.ArrayList<RebloggedAccount> most_reblogged_accounts { get; set; }
			public Gee.ArrayList<RebloggedAccount> commonly_interacted_with_accounts { get; set; }

			public override Type deserialize_array_type (string prop) {
				switch (prop) {
					case "time-series":
						return typeof (TimeSeries);
					case "most-used-apps":
					case "top-hashtags":
						return typeof (NamedCountable);
					case "most-reblogged-accounts":
					case "commonly-interacted-with-accounts":
						return typeof (RebloggedAccount);
				}

				return base.deserialize_array_type (prop);
			}
		}

		public int32 year { get; set; }
		public Data data { get; set; }
	}

	public Gee.ArrayList<Report> annual_reports { get; set; }
	public Gee.ArrayList<API.Status> statuses { get; set; }
	public Gee.ArrayList<API.Account> accounts { get; set; }

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "accounts":
				return typeof (API.Account);
			case "statuses":
				return typeof (API.Status);
			case "annual-reports":
				return typeof (Report);
		}

		return base.deserialize_array_type (prop);
	}

	public static AnnualReports from (Json.Node node) throws Error {
		return Entity.from_json (typeof (AnnualReports), node) as AnnualReports;
	}

	public void open (int year = 0) {
		if (annual_reports.size == 0) return;

		new Dialogs.AnnualReport (this, year).present (app.main_window);
	}
}
