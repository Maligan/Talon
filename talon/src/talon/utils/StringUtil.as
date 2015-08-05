package talon.utils
{
	import starling.utils.Color;

	/** This is utility method to work with strings in different formats and notation. */
	public final class StringUtil
	{
		/**
		 * Parse color strings:
		 * white
		 * #FFFFFF
		 * rbg(255, 255, 255)
		 */
		public static function parseColor(string:String, rollback:Number = NaN):Number
		{
			var rgb:Array;

			if (string == null) return rollback;
			if (string.indexOf("#") == 0) return parseInt(string.substr(1), 16);
			if (Color[string.toUpperCase()] is uint) return Color[string.toUpperCase()];

			var method:Array = parseFunction(string);
			if (method && method[0]=="rgb" && method.length > 3) return Color.rgb(parseInt(method[1]), parseInt(method[2]), parseInt(method[3]));

			return rollback;
		}

		public static function parseAngle(string:String, rollback:Number = NaN):Number
		{
			var pattern:RegExp = /^(-?\d*\.?\d+)(deg|rad|)$/;
			var split:Array = pattern.exec(string);
			if (split == null) return rollback;

			var amount:Number = parseFloat(split[1]);
			var unit:String = split[2];
			switch (unit)
			{
				case "deg":
					return amount * Math.PI / 180;

				case "rad":
				default:
					return amount;
			}
		}

		public static function toHexRBG(color:uint):String
		{
			var string:String = color.toString(16);
			while (string.length < 6) string = "0" + string;
			return "#" + string;
		}

		/**
		 * Parse strings like:
		 * url(http://example.com/) to ['url', 'http://example.com/']
		 * rgb(128, 128, 128) to ['rgb', '128', '128', '128']
		 * method(arg1) to ['method', 'arg1']
		 * First item - function name, second and other - arguments
		 * Or return null if input string doesn't match css functional notation.
		 *
		 * CSS functional notation:
		 * The format of functional notation is: 'function('
		 * followed by optional white space
		 * followed by an optional single quote (') or double quote (") character
		 * followed by args divided by (,), followed by an optional single quote (') or double quote (") character
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
			const notation:RegExp = /([\w\d-$]+)\(\s*(["']?)(.*?)\2+\s*\)/;
			var exec:Array = notation.exec(string);
			if (exec == null) return null;

			// Last regexp group is arguments (split & trim)
			var args:Array = exec[3].split(/\s*,\s*/);
			// First regexp group is function name
			args.unshift(exec[1]);

			return args;
		}

		public static function parseResource(string:String):String
		{
			if (string == null) return null;
			if (string.length < 2) return null;
			if (string.charAt(0) != "$") return null;

			// Short notation: $resourceKey
			const notation:RegExp = /\$[\w\d-$]+/;
			if (notation.test(string)) return string.substring(1);

			// Functional notation: $("resourceKey")
			var split:Array = parseFunction(string);
			if (split && split.length > 1) return split[1];

			return null;
		}

		public static function parseAlign(string:String):Number
		{
			switch (string)
			{
				case "left":
				case "top":
					return 0.0;
				case "center":
					return 0.5;
				case "right":
				case "bottom":
					return 1.0;
				default:
					return 0.0;
			}
		}

		public static function parseBoolean(string:String):Boolean
		{
			return string == "true";
		}
	}
}