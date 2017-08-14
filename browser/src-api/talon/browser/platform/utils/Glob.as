package talon.browser.platform.utils
{
	public class Glob
	{
		private static const _cache:Object = {};

		public static function match(string:String, patterns:String, result:Boolean = false):Boolean
		{
			var globs:Vector.<Glob> = _cache[patterns] ||= Vector.<Glob>(patterns.split(/\s*;\s*/).map(parse));

			for each (var glob:Glob in globs)
				if (glob.regexp.exec(string))
					return !glob.negate;

			return result;
		}

		private static function parse(string:String, index:int = 0, array:Array = null):Glob
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

		private var regexp:RegExp;
		private var negate:Boolean;
	}
}