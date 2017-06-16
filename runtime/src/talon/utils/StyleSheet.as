package talon.utils
{
	import flash.utils.Dictionary;

	import talon.*;

	/** Style Sheet Object. */
	public class StyleSheet
	{
		protected var _selectors:Vector.<StyleSelector>;
		protected var _selectorsStyles:Dictionary;
		protected var _selectorsByIdent:Dictionary;

		private var _parseSelectorsCursor:Vector.<StyleSelector>;

		/** @private */
		public function StyleSheet()
		{
			_selectorsStyles = new Dictionary();
			_selectors = new Vector.<StyleSelector>();
			_selectorsByIdent = new Dictionary();
			_parseSelectorsCursor = new Vector.<StyleSelector>();
		}

		/** Get an object (containing key-value pairs) that reflects the style of the node. */
		public function getStyle(node:Node, result:Object = null):Object
		{
			result ||= new OrderedObject();

			var priorities:Object = new Object();

			for each (var selector:StyleSelector in _selectors)
			{
				if (!selector.match(node)) continue;

				var styles:Object = _selectorsStyles[selector];
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
				var style:Object = _selectorsStyles[selector];
				if (style == null) style = _selectorsStyles[selector] = new OrderedObject();
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
	private var _states:Vector.<Object>;

	public function StyleSelector(string:String)
	{
		_classes = new <String>[];
		_states = new <Object>[];

		var split:Array = string.split(' ');
		var current:String = split.pop();

		// Parent selector
		if (split.length > 0) _ancestor = new StyleSelector(split.join(' '));

		// This selector
		var pattern:RegExp = /\*|[.#:]?[\w-()+-]+/;
		while (current.length)
		{
			var token:String = pattern.exec(current)[0];
			var tokenType:String = token.charAt(0);
			var tokenValue:String = token.substring(1);

			/**/ if (tokenType == '#') _id = tokenValue;
			else if (tokenType == '.') _classes.push(tokenValue);
			else if (tokenType == ':') _states.push(NthToken.fromString(tokenValue) || tokenValue);
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
			&& byStates(node)
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
		for each (var state:Object in _states)
		{
			if (state is String)
			{
				var stateName:String = state as String;
				if (node.states.contains(stateName) == false) return false;
			}
			else if (state is NthToken)
			{
				var stateNth:NthToken = state as NthToken;
				var parent:Node = node.parent;
				if (parent == null) return false;
				if (stateNth.match(parent.getChildIndex(node), parent.numChildren) == false) return false;
			}
		}

		return true;
	}

	public function get priority():int
	{
		return _priority;
	}
}

class NthToken
{
	public static const NTH:String = "nth-child";
	public static const NTH_LAST:String = "nth-last-child";
	public static const NTH_PATTERN:RegExp = new RegExp("(" + NTH + "|" + NTH_LAST + ")" + "\\((?:([+-]?\\d+)n)?([+-]?\\d+)?\\)");

	public static function fromString(state:String):NthToken
	{
		var stateSplit:Array = NTH_PATTERN.exec(state);
		if (stateSplit == null) return null;
		return new NthToken(stateSplit[1] == NTH_LAST, parseInt(stateSplit[2]), parseInt(stateSplit[3]));
	}

	private var _last:Boolean;
	private var _a:int;
	private var _b:int;

	public function NthToken(last:Boolean, a:int, b:int)
	{
		_last = last;
		_a = a;
		_b = b;
	}

	public function match(indexOf:int, numChildren:int):Boolean
	{
		// x is a number of element (not index)
		// NB! It begin from 1
		var x:int = _last ? (numChildren - indexOf) : (indexOf + 1);

		// x = a*n + b
		// n = (x - b) / a
		// if n is integer then match else false
		if (_a != 0)
			return (x - _b) % _a == 0;
		else
			return x == _b;
	}
}