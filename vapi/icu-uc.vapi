// Based on icu-uc.vapi from Geary which is based on the one from the Dino project.

[CCode (cprefix="u_")]
namespace Icu {
	[CCode (cname = "UChar")]
	[IntegerType (rank = 5, min = 0, max = 65535)]
	struct Char {}

	[CCode (cname = "UErrorCode", cprefix = "U_", cheader_filename = "unicode/utypes.h")]
	enum ErrorCode {
		ZERO_ERROR,
		INVALID_CHAR_FOUND,
		INDEX_OUTOFBOUNDS_ERROR,
		BUFFER_OVERFLOW_ERROR,
		STRINGPREP_PROHIBITED_ERROR,
		UNASSIGNED_CODE_POINT_FOUND,
		IDNA_STD3_ASCII_RULES_ERROR;

		[CCode (cname = "u_errorName")]
		public unowned string errorName();

		[CCode (cname = "U_SUCCESS")]
		public bool is_success();

		[CCode (cname = "U_FAILURE")]
		public bool is_failure();
	}

	[CCode (cname = "UText", cprefix = "utext_", free_function = "utext_close", cheader_filename = "unicode/utext.h")]
	[Compact]
	class Text {
		[CCode (cname="utext_openUTF8")]
		public static Text open_utf8(Text* existing, [CCode (array_length_type = "int64_t")] uint8[] text, ref ErrorCode status);
	}

	[CCode (cname = "UBreakIterator", cprefix = "ubrk_", free_function = "ubrk_close", cheader_filename = "unicode/ubrk.h")]
	[Compact]
	class BreakIterator {

		[CCode (cname = "UBRK_DONE")]
		public const int32 DONE;

		[CCode (cname = "UBreakIteratorType", cprefix = "UBRK_")]
		public enum Type {
			CHARACTER,
			WORD,
			LINE,
			SENTENCE;
		}

		[CCode (cname = "UWordBreak", cprefix = "UBRK_WORD_")]
		enum WordBreak {
			NONE,
			NONE_LIMIT,
			NUMBER,
			NUMBER_LIMIT,
			LETTER,
			LETTER_LIMIT,
			KANA,
			KANA_LIMIT,
			IDEO,
			IDEO_LIMIT;
		}

		public static BreakIterator open(Type type, string locale, Char* text, int32 text_len, ref ErrorCode status);
		public int32 next();

		[CCode (cname="ubrk_setUText")]
		public void set_utext(Text text, ref ErrorCode status);
	}
}
