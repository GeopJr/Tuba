// Blurhash decoding in pure Vala inspired by
// https://github.com/woltapp/blurhash and https://github.com/mad-gooze/fast-blurhash/
public class Tuba.Blurhash {
	struct AverageColor {
		int r;
		int g;
		int b;
	}

	struct ColorSRGB {
		float r;
		float g;
		float b;
	}

	public class Base83 {
		const char[] CHARACTERS = {
			'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '#', '$', '%', '*', '+', ',', '-', '.', ':', ';', '=', '?', '@', '[', ']', '^', '_', '{', '|', '}', '~'
		};

		// Unused, but works
		//  public static string encode (int value, int length) {
		//  	StringBuilder res = new StringBuilder ();

		//  	for (int i = 1; i <= length; i++) {
		//  		int digit = (int) (value / Math.pow (83, length - i) % 83);
		//  		res.append_c (CHARACTERS[digit]);
		//  	}

		//  	return res.str;
		//  }

		public static int decode (string value) {
			int res = 0;

			for (int i = 0; i < value.length; i++) {
				char character = value[i];

				int index = -1;
				for (int j = 0; j < 83; j++) {
					if (CHARACTERS[j] == character) {
						index = j;
						break;
					}
				}
				if (index == -1) return 0;

				res = (int)((uint)res * 83 + index);
			}

			return res;
		}
	}

	// Decodes a Base83 string partially from `start` to `end`.
	// WARNING: sanitize start and end manually, this is only used
	//			here and only on valid blurhashes.
	private static int decode_partial (string str, int start, int end) {
		if (start > end) return 0;

		int str_length = str.length;
		if (end >= str_length) end = str_length;

		return Base83.decode (str.slice (start, end));
	}

	private static int linear_to_srgb (float value) {
		float v = value.clamp (0f, 1f);
		if (v <= 0.0031308) return (int) (v * 12.92f * 255 + 0.5);

		return (int) ((1.055 * Math.powf (v, 1 / 2.4f) - 0.055) * 255 + 0.5);
	}

	private static float srgb_to_linear (int value) {
		float v = value / 255f;
		if (v <= 0.04045) return v / 12.92f;

		return Math.powf ((v + 0.055f) / 1.055f, 2.4f);
	}

	private static float sign_pow (float value, float exp) {
		return Math.copysignf (Math.powf (Math.fabsf (value), exp), value);
	}

	public static bool is_valid_blurhash (string blurhash, out int size_flag, out int num_x, out int num_y, out int size) {
		size_flag = 0;
		num_y = 0;
		num_x = 0;
		size = 0;

		int hash_length = blurhash.length;
		if (hash_length < 6) return false;

		size_flag = decode_partial (blurhash, 0, 1);
		num_y = (int) Math.floorf (size_flag / 9) + 1;
		num_x = (size_flag % 9) + 1;
		size = num_x * num_y;

		if (hash_length != 4 + 2 * size) return false;
		return true;
	}

	private static AverageColor get_blurhash_average_color (string blurhash) {
		int val = decode_partial (blurhash, 2, 6);
		return { val >> 16, (val >> 8) & 255, val & 255 };
	}

	private static ColorSRGB decode_ac (int value, float maximum_value) {
		int quant_r = (int)Math.floorf (value / (19 * 19));
		int quant_g = (int)Math.floorf (value / 19) % 19;
		int quant_b = (int)value % 19;

		return ColorSRGB () {
			r = sign_pow (((float)quant_r - 9) / 9, 2.0f) * maximum_value,
			g = sign_pow (((float)quant_g - 9) / 9, 2.0f) * maximum_value,
			b = sign_pow (((float)quant_b - 9) / 9, 2.0f) * maximum_value
		};
	}

	public static uint8[]? decode_to_data (string blurhash, int width, int height, int punch = 1, bool has_alpha = true) {
		int bytes_per_row = width * (has_alpha ? 4 : 3);
		uint8[] res = new uint8[bytes_per_row * height];

		int size_flag;
		int num_y;
		int num_x;
		int size;

		if (!is_valid_blurhash (blurhash, out size_flag, out num_x, out num_y, out size)) return null;
		if (punch < 1) punch = 1;

		float maximum_value = ((float)(decode_partial (blurhash, 1, 2) + 1)) / 166;
		float[] colors = new float[size * 3];

		AverageColor average_color = get_blurhash_average_color (blurhash);
		colors[0] = srgb_to_linear (average_color.r);
		colors[1] = srgb_to_linear (average_color.g);
		colors[2] = srgb_to_linear (average_color.b);

		for (int i = 1; i < size; i++) {
			int value = decode_partial (blurhash, 4 + i * 2, 6 + i * 2);

			ColorSRGB color = decode_ac (value, maximum_value);
			colors[i * 3] = color.r;
			colors[i * 3 + 1] = color.g;
			colors[i * 3 + 2] = color.b;
		}

		for (int y = 0; y < height; y++) {
			float yh = (float) (Math.PI * y) / height;
			for (int x = 0; x < width; x++) {
				float r = 0;
				float g = 0;
				float b = 0;
				float xw = (float) (Math.PI * x) / width;

				for (int j = 0; j < num_y; j++) {
					float basis_y = Math.cosf (yh * j);
					for (int i = 0; i < num_x; i++) {
						float basis = Math.cosf (xw * i) * basis_y;

						int color_index = (i + j * num_x) * 3;
						r += colors[color_index] * basis;
						g += colors[color_index + 1] * basis;
						b += colors[color_index + 2] * basis;
					}
				}

				int pixel_index = 4 * x + y * bytes_per_row;
				res[pixel_index] = (uint8) linear_to_srgb (r);
				res[pixel_index + 1] = (uint8) linear_to_srgb (g);
				res[pixel_index + 2] = (uint8) linear_to_srgb (b);

				if (has_alpha)
					res[pixel_index + 3] = (uint8) 255;
			}
		}

		return res;
	}

	public static Gdk.Pixbuf? blurhash_to_pixbuf (string blurhash, int width, int height) {
		uint8[]? data = decode_to_data (blurhash, width, height);
		if (data == null) return null;

		return new Gdk.Pixbuf.from_data (
			data,
			Gdk.Colorspace.RGB,
			true,
			8,
			width,
			height,
			4 * height
		);
	}
}
