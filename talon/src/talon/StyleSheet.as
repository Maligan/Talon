package talon
{
	import flash.utils.Dictionary;

	/** Style Sheet Object. */
	public class StyleSheet
	{
		protected var _stylesBySelector:Dictionary;
		protected var _selectors:Vector.<StyleSelector>;
		protected var _selectorsByIdent:Dictionary;

		private var _parseSelectorsCursor:Vector.<StyleSelector>;

		/** @private */
		public function StyleSheet()
		{
			_stylesBySelector = new Dictionary();
			_selectors = new Vector.<StyleSelector>();
			_selectorsByIdent = new Dictionary();
			_parseSelectorsCursor = new Vector.<StyleSelector>();
		}

		/** Get an object (containing key-value pairs) that reflects the style of the node. */
		public function getStyle(node:Node, result:Object = null):Object
		{
			result ||= new Object();
			var priorities:Object = new Object();

			for each (var selector:StyleSelector in _selectors)
			{
				if (!selector.match(node)) continue;

				var styles:Object = _stylesBySelector[selector];
				for (var property:String in styles)
				{
					var priority:int = priorities[property];
					if (priority <= selector.priority)
					{
						result[property] = styles[property];
						priorities[property] = selector.priority;
					}
				}
			}

			return result;
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
		// <selector> ::= 'ident' | .'ident' | #'ident' | <selector> <selector> | 'ident':'ident'
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
		// Parsing calls
		//
		private function resetCursorSelectors():void
		{
			_parseSelectorsCursor.length = 0;
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

			_parseSelectorsCursor.push(selector);
		}

		private function addCursorSelectorsProperty(name:String, value:String):void
		{
			for each (var selector:StyleSelector in _parseSelectorsCursor)
			{
				var style:Object = _stylesBySelector[selector];
				if (style == null) style = _stylesBySelector[selector] = new Object();
				style[name] = value;
			}
		}

		//
		// Utils
		//
		/** Remove white spaces from string start or end. */
		protected function trim(string:String):String
		{
			return string.replace(/^\s*|\s*$/gm, '');
		}

		/** Remove CSS comments. */
		protected function uncomment(string:String):String
		{
			return string.replace(/\/\*([^*]|[\r\n]|(\*+([^*\/]|[\r\n])))*\*+\//g, '');
		}
	}
}

import talon.Attribute;
import talon.Node;

class StyleSelector
{
	private static function getPriorityMerge(b:int, c:int, d:int):int
	{
		return (b << 16) | (c << 8) | d;
	}

	private var _priority:int;

	private var _ancestor:StyleSelector;
	private var _id:String;
	private var _type:String;
	private var _classes:Vector.<String>;
	private var _states:Vector.<String>;

	public function StyleSelector(string:String)
	{
		_classes = new <String>[];
		_states = new <String>[];

		var split:Array = string.split(' ');
		var current:String = split.pop();

		// Parent selector
		if (split.length > 0) _ancestor = new StyleSelector(split.join(' '));

		// This selector
		var pattern:RegExp = /\*|[.#:]?[\w]+/;
		while (current.length)
		{
			var token:String = pattern.exec(current)[0];
			var tokenType:String = token.charAt(0);
			var tokenValue:String = token.substring(1);

			/**/ if (tokenType == '#') _id = tokenValue;
			else if (tokenType == '.') _classes.push(tokenValue);
			else if (tokenType == ':') _states.push(tokenValue);
			else if (tokenType != '*') _type = token;

			// Continue parse
			current = current.substring(token.length);
		}

		// CSS Selector Priority (@see http://www.w3.org/wiki/CSS/Training/Priority_level_of_selector) merged to one integer
		_priority = (_ancestor ? _ancestor.priority : 0) + getPriorityMerge(_id?1:0, _classes.length + _states.length, _type?1:0);
	}

	public function match(node:Node):Boolean
	{
		return node
			&& byId(node)
			&& byType(node)
			&& byAncestor(node)
			&& byClasses(node)
			&& byStates(node);
	}

	private function byType(node:Node):Boolean
	{
		return !_type || (node.getAttributeCache(Attribute.TYPE) == _type);
	}

	private function byAncestor(node:Node):Boolean
	{
		if (_ancestor == null) return true;

		node = node.parent;

		while (node)
		{
			if (_ancestor.match(node)) return true;
			node = node.parent;
		}

		return false;
	}

	private function byId(node:Node):Boolean
	{
		return !_id || (node.getAttributeCache(Attribute.ID) == _id);
	}

	private function byClasses(node:Node):Boolean
	{
		for each (var className:String in _classes)
		{
			if (!node.classes.contains(className)) return false;
		}

		return true;
	}

	private function byStates(node:Node):Boolean
	{
		for each (var stateName:String in _states)
		{
			if (!node.states.contains(stateName)) return false;
		}

		return true;
	}

	public function get priority():int
	{
		return _priority;
	}
}