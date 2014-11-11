package starling.extensions.talon.core
{
	import flash.utils.Dictionary;

	public final class StyleSheet
	{
		private var _stylesBySelector:Dictionary;

		private var _selectors:Vector.<StyleSelector>;
		private var _selectorsByIdent:Dictionary;
		private var _selectorsCursor:Vector.<StyleSelector>;

		public function StyleSheet()
		{
			_stylesBySelector = new Dictionary();
			_selectors = new Vector.<StyleSelector>();
			_selectorsByIdent = new Dictionary();
			_selectorsCursor = new Vector.<StyleSelector>();
		}

		/** Get an object that reflects the style of the node. */
		public function getStyle(node:Node, result:Object = null):Object
		{
			var style:Object = result || new Object();
			var priorities:Object = new Object();

			for each (var selector:StyleSelector in _selectors)
			{
				if (selector.match(node) !== true) continue;

				var styles:Object = _stylesBySelector[selector];
				for (var property:String in styles)
				{
					var value:String = styles[property];
					var priority:int = priorities[property];
					if (priority <= selector.priority)
					{
						style[property] = value;
						priorities[property] = selector.priority;
					}
				}
			}

			return style;
		}

		/** Parse css string and merge style selectors. */
		public function parse(css:String):void
		{
			parseCSS(css);
		}

		//
		// Recursive descent parser (BNF):
		//
		// <css>      ::= { <rule> }
		// <rule>     ::= <selector> {',' <selector>} '{' <style> '}'
		// <selector> ::= * | 'ident' | .'ident' | #'ident' | <selector> <selector> | 'ident':'ident'
		// <style>    ::= { 'ident' ':' 'ident' ';' }
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
			return string.replace(/\/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+\//g, '');1
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
			var selector:StyleSelector = _selectorsByIdent[ident];
			if (selector == null)
			{
				selector = new StyleSelector(ident);
				_selectorsByIdent[selector];
				_selectors.push(selector);
			}

			_selectorsCursor.push(selector);
		}

		private function addCursorSelectorsProperty(name:String, value:String):void
		{
			for each (var selector:StyleSelector in _selectorsCursor)
			{
				var style:Object = _stylesBySelector[selector];
				if (style == null) style = _stylesBySelector[selector] = new Object();
				style[name] = value;
			}
		}
	}
}

import starling.extensions.talon.core.Node;

class StyleSelector
{
	private var _parent:StyleSelector;
	private var _class:String;
	private var _id:String;
	private var _state:String;
	private var _general:Boolean;

	public function StyleSelector(string:String)
	{
		var split:Array = string.split(' ');
		var current:String = split.pop();

		if (split.length > 0)
		{
			_parent = new StyleSelector(split.join(' '))
		}

		while (current.length)
		{
			var next:int = Math.min(uint(current.indexOf('#', 1)), uint(current.indexOf('.', 1)), uint(current.indexOf(':', 1)));
			var name:String = current.substring(1, (next != -1) ? next : int.MAX_VALUE);

			var first:String = current.charAt(0);
			/**/ if (first == '.') _class = name;
			else if (first == '#') _id = name;
			else if (first == ':') _state = name;
			else if (first == '*') _general = true;

			current = current.substring(name.length + 1);
		}
	}

	public function match(node:Node):Boolean
	{
		if (node == null) return false;

		var byParent:Boolean = !_parent || (_parent && _parent.match(node.parent));
		var byState:Boolean = !_state || (node.states.indexOf(_state) != -1) || _general;
		var byClass:Boolean = !_class || ((node.getAttribute("class") || "").indexOf(_class) != -1) || _general;
		var byId:Boolean = !_id || (node.getAttribute("id") == _id) || _general;


		if (_state && byState)
		{
			trace(node.getAttribute("id"));
		}

		return byParent && byState && byClass && byId;
	}

	public function get priority():int
	{
		// TODO
		return 1;
	}
}