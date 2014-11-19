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

		/** Get an object (containing key-value pairs) that reflects the style of the node. */
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
					var priority:int = priorities[property];
					if (priority <= selector.priority)
					{
						style[property] = styles[property];
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
			return string.replace(/\/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+\//g, '');
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
import starling.utils.Color;

class StyleSelector
{
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

		_priority = (_ancestor ? _ancestor.priority : 0) + Color.rgb(_id?1:0, _classes.length+_states.length, _type?1:0);
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
		return !_type || (node.getAttribute("type") == _type);
	}

	private function byAncestor(node:Node):Boolean
	{
		if (_ancestor == null) return true;
		if (node.parent == null) return false;

		while (node != null)
		{
			if (_ancestor.match(node.parent)) return true;
			node = node.parent;
		}

		return false;
	}

	private function byId(node:Node):Boolean
	{
		return !_id || (node.getAttribute("id") == _id);
	}

	private function byClasses(node:Node):Boolean
	{
		for each (var className:String in _classes)
		{
			if (node.classes.indexOf(className) == -1) return false;
		}

		return true;
	}

	private function byStates(node:Node):Boolean
	{
		for each (var stateName:String in _states)
		{
			if (node.states.indexOf(stateName) == -1) return false;
		}

		return true;
	}

	public function get priority():int
	{
		return _priority;
	}
}