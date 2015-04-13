package browser.utils
{
	public class Glob
	{
		private var _source:String;
		private var _regexp:RegExp;
		private var _invert:Boolean;

		public function Glob(source:String):void
		{
			_source = source;
			_invert = source.length && source.charAt(0) == "!";
			_regexp = parse(_invert ? source.substring(1) : source);
		}

		public function match(string:String):Boolean
		{
			// Reset regexp inner counter
			_regexp.lastIndex = 0;
			return _regexp.test(string);
		}

		public function get invert():Boolean
		{
			return _invert;
		}

		//
		// Parsing
		//
		private function parse(string:String):RegExp
		{
			return new RegExp(regExpEscape(string).replace(/\\\*/g, '.*').replace(/\\\?/g, '.'), 'g');
		}

		private function regExpEscape(string:String, delimiter:String = null):String
		{
			// http://kevin.vanzonneveld.net
			// +   original by: booeyOH
			// +   improved by: Ates Goral (http://magnetiq.com)
			// +   improved by: Kevin van Zonneveld (http://kevin.vanzonneveld.net)
			// +   bugfixed by: Onno Marsman
			// +   improved by: Brett Zamir (http://brett-zamir.me)
			// *     example 1: preg_quote("$40");
			// *     returns 1: '\$40'
			// *     example 2: preg_quote("*RRRING* Hello?");
			// *     returns 2: '\*RRRING\* Hello\?'
			// *     example 3: preg_quote("\\.+*?[^]$(){}=!<>|:");
			// *     returns 3: '\\\.\+\*\?\[\^\]\$\(\)\{\}\=\!\<\>\|\:'
			return (string + '').replace(new RegExp('[.\\\\+*?\\[\\^\\]$(){}=!<>|:\\' + (delimiter || '') + '-]', 'g'), '\\$&');
		}
	}
}
