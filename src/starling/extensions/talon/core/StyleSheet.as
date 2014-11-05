package starling.extensions.talon.core
{
	import flash.utils.Dictionary;

	public class StyleSheet
	{
		private var _stylesBySelector:Dictionary;

		private var _selectors:Vector.<CSSSelector>;
		private var _selectorsByIdent:Dictionary;
		private var _selectorsCursor:Vector.<CSSSelector>;

		public function StyleSheet(source:String)
		{
			_stylesBySelector = new Dictionary();
			_selectors = new Vector.<CSSSelector>();
			_selectorsByIdent = new Dictionary();
			_selectorsCursor = new Vector.<CSSSelector>();
			parseCSS(source);
		}

		public function getStyle(node:*, name:String):String
		{
			var result:String = null;

			for each (var selector:CSSSelector in _selectors)
			{
				// TODO: Selector priority
				if (selector.match(node) === true)
				{
					var style:String = _stylesBySelector[selector][name];
					if (style != null)
					{
						result = style;
					}
				}
			}

			return result;
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

			resetCursorSelectors();
			var selectors:Array = input.substr(startIndex, endIndex).split(',');
			for each (var selector:String in selectors)
			{
				selector = trim(selector);
				addCursorSelector(selector);
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
					addCursorSelectorsProperty(name, value);
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
			return string.replace(/^\s*|\s*$/gm, '');
		}

		/** Remove CSS comments. */
		private function uncomment(string:String):String
		{
			return string.replace(/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+/g, '');
		}

		//
		// Parsing calls
		//
		private function resetCursorSelectors():void
		{
			_selectorsCursor.length = 0;
		}

		private function addCursorSelector(ident:String):void
		{
			var selector:CSSSelector = _selectorsByIdent[ident];
			if (selector == null)
			{
				selector = new CSSSelector(ident);
				_selectorsByIdent[selector];
				_selectors.push(selector);
			}

			_selectorsCursor.push(selector);
		}

		private function addCursorSelectorsProperty(name:String, value:String):void
		{
			for each (var selector:CSSSelector in _selectorsCursor)
			{
				var style:Object = _stylesBySelector[selector];
				if (style == null) style = _stylesBySelector[selector] = new Object();
				style[name] = value;
			}
		}
	}
}

class CSSSelector
{
	private var _class:String;

	public function CSSSelector(string:String)
	{
		if (string.indexOf('.') == 0)
		{
			_class = string.substr(1);
		}
	}

	public function match(node:*):Boolean
	{
		return node.style && node.style.indexOf(_class) != -1;
	}
}