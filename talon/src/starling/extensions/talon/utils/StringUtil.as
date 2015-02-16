package starling.extensions.talon.utils
{
	import starling.utils.Color;
	import starling.utils.HAlign;
	import starling.utils.VAlign;

	/** This is utility method to work with strings in different formats and notation. */
	public final class StringUtil
	{
		/**
		 * Parse color strings:
		 * white
		 * #FFFFFF
		 * rbg(255, 255, 255)
		 */
		public static function parseColor(string:String):Number
		{
			var rgb:Array;

			if (string == null) return NaN;
			if (string.indexOf("#") == 0) return parseInt(string.substr(1), 16);
			if (Color[string.toUpperCase()] is uint) return Color[string.toUpperCase()];

			var method:Array = parseFunction(string);
			if (method && method[0]=="rgb") return Color.rgb(parseInt(method[1]), parseInt(method[2]), parseInt(method[3]));

			return NaN;
		}

		/**
		 * Parse strings like:
		 * url(http://example.com/) to ['url', 'http://example.com/']
		 * rgb(128, 128, 128) to ['rgb', '128', '128', '128']
		 * resource(background-image) to ['resource', 'background-image']
		 * method(arg1) to ['method', 'arg1']
		 * First item - function name, second and other - arguments
		 * Or return null if input string doesn't match css functional notation.
		 *
		 * CSS functional notation:
		 * The format of functional notation is: 'function('
		 * followed by optional white space
		 * followed by an optional single quote (') or double quote (") character
		 * followed by the URI itself, followed by an optional single quote (') or double quote (") character
		 * followed by optional white space followed by ')'.
		 * The two quote characters must be the same.
		 */
		public static function parseFunction(string:String):Array
		{
			if (string == null) return null;

			// Optimize negative cases
			var indexOfOpen:int = string.indexOf("(");
			if (indexOfOpen == -1) return null;

			// Regexp parsing
			const notation:RegExp = /([\w-]+)\(\s*(["']?)(.*?)\2*\s*\)/;
			var exec:Array = notation.exec(string);
			if (exec == null) return null;

			// Last regexp group is arguments (split & trim)
			var args:Array = exec[3].split(/\s*,\s*/);
			// First regexp group is function name
			args.unshift(exec[1]);

			return args;
		}

		public static function parseAlign(string:String):Number
		{
			switch (string)
			{
				case HAlign.LEFT:
				case VAlign.TOP:
					return 0.0;
				case HAlign.CENTER:
				case VAlign.CENTER:
					return 0.5;
				case HAlign.RIGHT:
				case VAlign.BOTTOM:
					return 1.0;
				default:
					return 0.0;
			}
		}
	}
}