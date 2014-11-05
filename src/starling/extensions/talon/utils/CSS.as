package starling.extensions.talon.utils
{
	public class CSS
	{
		public function CSS(source:String)
		{
			parseCSS(source);
		}

		private function addCurrentSelector(selector:String):void
		{
			trace("Current selector:", selector);
		}

		private function addCurrentSelectorProperty(name:String, value:String):void
		{
			trace("*", name + ':', value);
		}

		//
		// Recursive descent parser (BNF):
		//
		// css      ::= { rule }
		// rule     ::= selector {',' selector} '{' style '}'
		// selector ::= * | 'ident' | .'ident' | #'ident' | 'ident' 'ident' | 'ident':'ident'
		// style    ::= { 'ident' ':' 'ident' ';' }
		//
		private function parseCSS(input:String):void
		{
			input = uncomment(input);
			input = trim(input);

			while (input.length != 0)
			{
				input = parseRule(input);
				input = trim(input);
			}
		}

		private function parseRule(input:String):String
		{
			input = parseSelector(input);
			input = parseStyle(input);
			return input;
		}

		private function parseSelector(input:String):String
		{
			var startIndex:int = 0;
			var endIndex:int = input.indexOf('{');

			var selectors:Array = input.substr(startIndex, endIndex).split(',');
			for each (var selector:String in selectors)
			{
				selector = trim(selector);
				addCurrentSelector(selector);
			}

			return input.substr(endIndex);
		}

		private function parseStyle(input:String):String
		{
			var startIndex:int = input.indexOf('{');
			var endIndex:int = input.indexOf('}');
			var style:Array = input.substring(startIndex + 1, endIndex).split(';');

			for each (var property:String in style)
			{
				property = trim(property);

				if (property.length > 0)
				{
					var splitProperty:Array = property.split(':');
					var name:String = trim(splitProperty[0]);
					var value:String = trim(splitProperty[1]);
					addCurrentSelectorProperty(name, value);
				}
			}

			return input.substr(endIndex + 1);
		}

		//
		// Utils
		//
		/** Remove white spaces from string start or end. */
		private function trim(string:String):String
		{
			return string.replace(/^\s*|\s*$/m, '');
		}

		/** Remove CSS comments. */
		private function uncomment(string:String):String
		{
			return string.replace(/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+/g, '');
		}
	}
}