public class Tuba.API.Quote : API.Status {
	public bool tuba_has_quote {
		get {
			return this.state == "accepted"
				|| this.state == "blocked_account"
				|| this.state == "blocked_domain"
				|| this.state == "muted_account";
		}
	}

	public string state { get; set; default = "accepted"; }
	//  public string? quoted_status_id { get; set; default = null; }
	public API.Status? quoted_status {
		set {
			this.tuba_had_quote = false;
			if (value == null) {
				if (this.state == "accepted") this.state = "pending";
			} else {
				if (value.quote != null) this.tuba_had_quote = true;
				value.quote = null;
				this.patch (value);
			}
		}
	}
}
