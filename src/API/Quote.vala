public class Tuba.API.Quote : API.Status {
	public bool tuba_has_quote {
		get { return this.state == "accepted"; }
	}

	public string state { get; set; default = "accepted"; }
	public API.Status? quoted_status {
		set {
			if (value == null) {
				this.state = "pending";
			} else {
				//  if (value.quote != null) value.tuba_had_quote = true; // TODO: preparation for 2-level nesting
				value.quote = null;
				this.patch (value);
			}
		}
	}
}
