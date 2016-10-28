package talon.browser.platform.utils
{
	public class Locale
	{
		private var _language:String;
		private var _values:Object = {};

		public function merge(values:Object, language:String):void
		{
			var inner:Object = _values[language] ||= {};

			for (var key:String in values)
				inner[key] = values[key];
		}

		public function get(key:String):String
		{
			return _values[_language] ? (_values[_language][key] || key) : key;
		}

		public function get language():String { return _language; }
		public function set language(value:String):void { _language = value; }
	}
}
