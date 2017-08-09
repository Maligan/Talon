package talon.browser.platform.utils
{
	public class Glob
	{
		public static function parse(string:String):Glob
		{
			var glob:Glob = new Glob();
			glob.negate = string && string.length && string.charAt(0) == "!";
			glob.regexp = regexp(glob.negate ? string.substr(1) : string);
			return glob;
		}

		private static function regexp(string:String):RegExp
		{
			return new RegExp("^" + regexpQuote(string).replace(/\\\*/g, '.*').replace(/\\\?/g, '.') + "$");
		}

		private static function regexpQuote(string:String, delimiter:String = null):String
		{
			// http://kevin.vanzonneveld.net
			// +   original by: booeyOH
			// +   improved by: Ates Goral (http://magnetiq.com)
			// +   improved by: Kevin van Zonneveld (http://kevin.vanzonneveld.net)
			// +   bugfixed by: Onno Marsman
			// +   improved by: Brett Zamir (http://brett-zamir.me)
			// *     example 1: regexpQuote("$40");
			// *     returns 1: '\$40'
			// *     example 2: regexpQuote("*RRRING* Hello?");
			// *     returns 2: '\*RRRING\* Hello\?'
			// *     example 3: regexpQuote("\\.+*?[^]$(){}=!<>|:");
			// *     returns 3: '\\\.\+\*\?\[\^\]\$\(\)\{\}\=\!\<\>\|\:'
			return string.replace(new RegExp('[.\\\\+*?\\[\\^\\]$(){}=!<>|:\\' + (delimiter || '') + '-]', 'g'), '\\$&');
		}

		public static function matchPattern(string:String, pattern:String, result:Boolean = true):Boolean
		{
			var array:Array = pattern.split(";");

			for each (var pattern:String in array)
			{
				var glob:Glob = parse(pattern);
				if (glob.regexp.exec(string))
					return !glob.negate;
			}

			return result;
		}

		public var regexp:RegExp;
		public var negate:Boolean;
	}
}