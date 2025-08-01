public class Tuba.Utils.Locales : GLib.Object {
	public class Locale : GLib.Object {
		public string locale { get; set; }
		public string en_name { get; set; }
		public string name { get; set; }

		public Locale (string? locale, string? en_name, string? name) {
			Object (locale: locale, en_name: en_name, name: name);
		}

		public static EqualFunc<string> compare = (a, b) => {
			return ((Locale) a).locale == ((Locale) b).locale;
		};
	}

	public GLib.ListStore list_store = new GLib.ListStore (typeof (Locale));

	construct {
		list_store.splice (0, 0, {
			new Locale ("aa", "Afar", "Afaraf"),
			new Locale ("ab", "Abkhaz", "аҧсуа бызшәа"),
			new Locale ("ae", "Avestan", "avesta"),
			new Locale ("af", "Afrikaans", "Afrikaans"),
			new Locale ("ak", "Akan", "Akan"),
			new Locale ("am", "Amharic", "አማርኛ"),
			new Locale ("an", "Aragonese", "aragonés"),
			new Locale ("ar", "Arabic", "اللغة العربية"),
			new Locale ("as", "Assamese", "অসমীয়া"),
			new Locale ("ast", "Asturian", "Asturianu"), // ISO-639-3
			new Locale ("av", "Avaric", "авар мацӀ"),
			new Locale ("ay", "Aymara", "aymar aru"),
			new Locale ("az", "Azerbaijani", "azərbaycan dili"),
			new Locale ("ba", "Bashkir", "башҡорт теле"),
			new Locale ("be", "Belarusian", "беларуская мова"),
			new Locale ("bg", "Bulgarian", "български език"),
			new Locale ("bh", "Bihari", "भोजपुरी"),
			new Locale ("bi", "Bislama", "Bislama"),
			new Locale ("bm", "Bambara", "bamanankan"),
			new Locale ("bn", "Bengali", "বাংলা"),
			new Locale ("bo", "Tibetan", "བོད་ཡིག"),
			new Locale ("br", "Breton", "brezhoneg"),
			new Locale ("bs", "Bosnian", "bosanski jezik"),
			new Locale ("ca", "Catalan", "Català"),
			new Locale ("ce", "Chechen", "нохчийн мотт"),
			new Locale ("ch", "Chamorro", "Chamoru"),
			new Locale ("ckb", "Sorani (Kurdish)", "سۆرانی"), // ISO-639-3
			new Locale ("cnr", "Montenegrin", "crnogorski"), // ISO-639-3
			new Locale ("co", "Corsican", "corsu"),
			new Locale ("cr", "Cree", "ᓀᐦᐃᔭᐍᐏᐣ"),
			new Locale ("cs", "Czech", "čeština"),
			new Locale ("cu", "Old Church Slavonic", "ѩзыкъ словѣньскъ"),
			new Locale ("cv", "Chuvash", "чӑваш чӗлхи"),
			new Locale ("cy", "Welsh", "Cymraeg"),
			new Locale ("da", "Danish", "dansk"),
			new Locale ("de", "German", "Deutsch"),
			new Locale ("dv", "Divehi", "Dhivehi"),
			new Locale ("dz", "Dzongkha", "རྫོང་ཁ"),
			new Locale ("ee", "Ewe", "Eʋegbe"),
			new Locale ("el", "Greek", "Ελληνικά"),
			new Locale ("en", "English", "English"),
			new Locale ("eo", "Esperanto", "Esperanto"),
			new Locale ("es", "Spanish", "Español"),
			new Locale ("et", "Estonian", "eesti"),
			new Locale ("eu", "Basque", "euskara"),
			new Locale ("fa", "Persian", "فارسی"),
			new Locale ("ff", "Fula", "Fulfulde"),
			new Locale ("fi", "Finnish", "suomi"),
			new Locale ("fj", "Fijian", "Vakaviti"),
			new Locale ("fo", "Faroese", "føroyskt"),
			new Locale ("fr", "French", "Français"),
			new Locale ("fy", "Western Frisian", "Frysk"),
			new Locale ("ga", "Irish", "Gaeilge"),
			new Locale ("gd", "Scottish Gaelic", "Gàidhlig"),
			new Locale ("gl", "Galician", "galego"),
			new Locale ("gu", "Gujarati", "ગુજરાતી"),
			new Locale ("gv", "Manx", "Gaelg"),
			new Locale ("ha", "Hausa", "هَوُسَ"),
			new Locale ("he", "Hebrew", "עברית"),
			new Locale ("hi", "Hindi", "हिन्दी"),
			new Locale ("ho", "Hiri Motu", "Hiri Motu"),
			new Locale ("hr", "Croatian", "Hrvatski"),
			new Locale ("ht", "Haitian", "Kreyòl ayisyen"),
			new Locale ("hu", "Hungarian", "magyar"),
			new Locale ("hy", "Armenian", "Հայերեն"),
			new Locale ("hz", "Herero", "Otjiherero"),
			new Locale ("ia", "Interlingua", "Interlingua"),
			new Locale ("id", "Indonesian", "Bahasa Indonesia"),
			new Locale ("ie", "Interlingue", "Interlingue"),
			new Locale ("ig", "Igbo", "Asụsụ Igbo"),
			new Locale ("ii", "Nuosu", "ꆈꌠ꒿ Nuosuhxop"),
			new Locale ("ik", "Inupiaq", "Iñupiaq"),
			new Locale ("io", "Ido", "Ido"),
			new Locale ("is", "Icelandic", "Íslenska"),
			new Locale ("it", "Italian", "Italiano"),
			new Locale ("iu", "Inuktitut", "ᐃᓄᒃᑎᑐᑦ"),
			new Locale ("ja", "Japanese", "日本語"),
			new Locale ("jbo", "Lojban", "la .lojban."), // ISO-639-3
			new Locale ("jv", "Javanese", "basa Jawa"),
			new Locale ("ka", "Georgian", "ქართული"),
			new Locale ("kab", "Kabyle", "Taqbaylit"), // ISO-639-3
			new Locale ("kg", "Kongo", "Kikongo"),
			new Locale ("ki", "Kikuyu", "Gĩkũyũ"),
			new Locale ("kj", "Kwanyama", "Kuanyama"),
			new Locale ("kk", "Kazakh", "қазақ тілі"),
			new Locale ("kl", "Kalaallisut", "kalaallisut"),
			new Locale ("km", "Khmer", "ខេមរភាសា"),
			new Locale ("kmr", "Kurmanji (Kurdish)", "Kurmancî"), // ISO-639-3
			new Locale ("kn", "Kannada", "ಕನ್ನಡ"),
			new Locale ("ko", "Korean", "한국어"),
			new Locale ("kr", "Kanuri", "Kanuri"),
			new Locale ("ks", "Kashmiri", "कश्मीरी"),
			new Locale ("ku", "Kurmanji (Kurdish)", "Kurmancî"),
			new Locale ("kv", "Komi", "коми кыв"),
			new Locale ("kw", "Cornish", "Kernewek"),
			new Locale ("ky", "Kyrgyz", "Кыргызча"),
			new Locale ("la", "Latin", "latine"),
			new Locale ("lb", "Luxembourgish", "Lëtzebuergesch"),
			new Locale ("ldn", "Láadan", "Láadan"), // ISO-639-3
			new Locale ("lfn", "Lingua Franca Nova", "lingua franca nova"), // ISO-639-3
			new Locale ("lg", "Ganda", "Luganda"),
			new Locale ("li", "Limburgish", "Limburgs"),
			new Locale ("ln", "Lingala", "Lingála"),
			new Locale ("lo", "Lao", "ລາວ"),
			new Locale ("lt", "Lithuanian", "lietuvių kalba"),
			new Locale ("lu", "Luba-Katanga", "Tshiluba"),
			new Locale ("lv", "Latvian", "latviešu valoda"),
			new Locale ("mg", "Malagasy", "fiteny malagasy"),
			new Locale ("mh", "Marshallese", "Kajin M̧ajeļ"),
			new Locale ("mi", "Māori", "te reo Māori"),
			new Locale ("mk", "Macedonian", "македонски јазик"),
			new Locale ("ml", "Malayalam", "മലയാളം"),
			new Locale ("mn", "Mongolian", "Монгол хэл"),
			new Locale ("mr", "Marathi", "मराठी"),
			new Locale ("ms", "Malay", "Bahasa Melayu"),
			new Locale ("mt", "Maltese", "Malti"),
			new Locale ("my", "Burmese", "ဗမာစာ"),
			new Locale ("na", "Nauru", "Ekakairũ Naoero"),
			new Locale ("nb", "Norwegian Bokmål", "Norsk bokmål"),
			new Locale ("nd", "Northern Ndebele", "isiNdebele"),
			new Locale ("ne", "Nepali", "नेपाली"),
			new Locale ("ng", "Ndonga", "Owambo"),
			new Locale ("nl", "Dutch", "Nederlands"),
			new Locale ("nn", "Norwegian Nynorsk", "Norsk Nynorsk"),
			new Locale ("no", "Norwegian", "Norsk"),
			new Locale ("nr", "Southern Ndebele", "isiNdebele"),
			new Locale ("nv", "Navajo", "Diné bizaad"),
			new Locale ("ny", "Chichewa", "chiCheŵa"),
			new Locale ("oc", "Occitan", "occitan"),
			new Locale ("oj", "Ojibwe", "ᐊᓂᔑᓈᐯᒧᐎᓐ"),
			new Locale ("om", "Oromo", "Afaan Oromoo"),
			new Locale ("or", "Oriya", "ଓଡ଼ିଆ"),
			new Locale ("os", "Ossetian", "ирон æвзаг"),
			new Locale ("pa", "Panjabi", "ਪੰਜਾਬੀ"),
			new Locale ("pi", "Pāli", "पाऴि"),
			new Locale ("pl", "Polish", "Polski"),
			new Locale ("ps", "Pashto", "پښتو"),
			new Locale ("pt", "Portuguese", "Português"),
			new Locale ("qu", "Quechua", "Runa Simi"),
			new Locale ("rm", "Romansh", "rumantsch grischun"),
			new Locale ("rn", "Kirundi", "Ikirundi"),
			new Locale ("ro", "Romanian", "Română"),
			new Locale ("ru", "Russian", "Русский"),
			new Locale ("rw", "Kinyarwanda", "Ikinyarwanda"),
			new Locale ("sa", "Sanskrit", "संस्कृतम्"),
			new Locale ("sc", "Sardinian", "sardu"),
			new Locale ("sco", "Scots", "Scots"), // ISO-639-3
			new Locale ("sd", "Sindhi", "सिन्धी"),
			new Locale ("se", "Northern Sami", "Davvisámegiella"),
			new Locale ("sg", "Sango", "yângâ tî sängö"),
			new Locale ("si", "Sinhala", "සිංහල"),
			new Locale ("sk", "Slovak", "slovenčina"),
			new Locale ("sl", "Slovenian", "slovenščina"),
			new Locale ("sma", "Southern Sami", "Åarjelsaemien Gïele"), // ISO-639-3
			new Locale ("smj", "Lule Sami", "Julevsámegiella"), // ISO-639-3
			new Locale ("sn", "Shona", "chiShona"),
			new Locale ("so", "Somali", "Soomaaliga"),
			new Locale ("sq", "Albanian", "Shqip"),
			new Locale ("sr", "Serbian", "српски језик"),
			new Locale ("ss", "Swati", "SiSwati"),
			new Locale ("st", "Southern Sotho", "Sesotho"),
			new Locale ("su", "Sundanese", "Basa Sunda"),
			new Locale ("sv", "Swedish", "Svenska"),
			new Locale ("sw", "Swahili", "Kiswahili"),
			new Locale ("szl", "Silesian", "ślůnsko godka"), // ISO-639-3
			new Locale ("ta", "Tamil", "தமிழ்"),
			new Locale ("tai", "Tai", "ภาษาไท or ภาษาไต"), // ISO-639-3
			new Locale ("te", "Telugu", "తెలుగు"),
			new Locale ("tg", "Tajik", "тоҷикӣ"),
			new Locale ("th", "Thai", "ไทย"),
			new Locale ("ti", "Tigrinya", "ትግርኛ"),
			new Locale ("tk", "Turkmen", "Türkmen"),
			new Locale ("tl", "Tagalog", "Wikang Tagalog"),
			new Locale ("tn", "Tswana", "Setswana"),
			new Locale ("to", "Tonga", "faka Tonga"),
			new Locale ("tok", "Toki Pona", "toki pona"), // ISO-639-3
			new Locale ("tr", "Turkish", "Türkçe"),
			new Locale ("ts", "Tsonga", "Xitsonga"),
			new Locale ("tt", "Tatar", "татар теле"),
			new Locale ("tw", "Twi", "Twi"),
			new Locale ("ty", "Tahitian", "Reo Tahiti"),
			new Locale ("ug", "Uyghur", "ئۇيغۇرچە‎"),
			new Locale ("uk", "Ukrainian", "Українська"),
			new Locale ("ur", "Urdu", "اردو"),
			new Locale ("uz", "Uzbek", "Ўзбек"),
			new Locale ("ve", "Venda", "Tshivenḓa"),
			new Locale ("vi", "Vietnamese", "Tiếng Việt"),
			new Locale ("vo", "Volapük", "Volapük"),
			new Locale ("wa", "Walloon", "walon"),
			new Locale ("wo", "Wolof", "Wollof"),
			new Locale ("xh", "Xhosa", "isiXhosa"),
			new Locale ("yi", "Yiddish", "ייִדיש"),
			new Locale ("yo", "Yoruba", "Yorùbá"),
			new Locale ("za", "Zhuang", "Saɯ cueŋƅ"),
			new Locale ("zba", "Balaibalan", "باليبلن"), // ISO-639-3
			new Locale ("zgh", "Standard Moroccan Tamazight", "ⵜⴰⵎⴰⵣⵉⵖⵜ"), // ISO-639-3
			new Locale ("zh", "Chinese", "中文"),
			new Locale ("zu", "Zulu", "isiZulu")
		});
	}
}
