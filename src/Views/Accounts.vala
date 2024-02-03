public class Tuba.Views.Accounts : Views.Timeline {
	public override void on_content_changed () {
		if (accepts == typeof (API.Account) || accepts == typeof (API.Suggestion)) {
			string[] ids_to_rs = {};
			for (uint i = 0; i < model.n_items; i++) {
				API.Account acc_obj = null;
				var model_obj = model.get_item (i);
				if (accepts == typeof (API.Suggestion)) {
					var suggestion = model_obj as API.Suggestion;
					if (suggestion != null)
						acc_obj = suggestion.account as API.Account;
				} else {
					acc_obj = model_obj as API.Account;
				}

				if (acc_obj == null) continue;
				if (acc_obj.tuba_rs == null && acc_obj.id != accounts.active.id) {
					ids_to_rs += acc_obj.id;
				}
			}

			if (ids_to_rs.length > 0) {
				API.Relationship.request_many.begin (ids_to_rs, (obj, res) => {
					try {
						Gee.HashMap<string, API.Relationship> relationships = API.Relationship.request_many.end (res);

						if (relationships.size > 0) {
							for (uint i = 0; i < model.n_items; i++) {
								API.Account acc_obj = null;
								var model_obj = model.get_item (i);
								if (accepts == typeof (API.Suggestion)) {
									var suggestion = model_obj as API.Suggestion;
									if (suggestion != null)
										acc_obj = suggestion.account as API.Account;
								} else {
									acc_obj = model_obj as API.Account;
								}

								if (acc_obj == null) continue;
								if (relationships.has_key (acc_obj.id)) {
									acc_obj.tuba_rs = relationships.get (acc_obj.id);
								}
							}
						}
					} catch (Error e) {
						warning (e.message);
					}
				});
			}
		}
		base.on_content_changed ();
	}
}
