package talon.utils
{
	import talon.Node;
	import talon.Style;

	public class StyleUtil
	{
		public static function match(node:Node, selector:String):int { return StyleSelector.match(node, selector) }
		
		public static function style(node:Node, styles:Vector.<Style>, out:Object = null):Object
		{
			out ||= new OrderedObject();

			var priorities:Object = {};
			for each (var style:Style in styles)
			{
				var priority:int = match(node, style.name);
				if (priority == -1) continue;

				var props:Object = style.values;
				for (var key:String in props)
				{
					var propPriority:int = priorities[key];
					if (propPriority <= priority)
					{
						priorities[key] = priority;
						out[key] = props[key];
					}
				}
			}

			return out;
		}
	}
}

import talon.Attribute;
import talon.Node;

class StyleSelector
{
	private static const _sSelectors:Object = {};

	/** Return match priority or -1 */
	public static function match(node:Node, source:String):int
	{
		var selector:StyleSelector = getSelector(source);
		return selector.match(node) ? selector.priority : -1;
	}

	private static function getSelector(source:String):StyleSelector
	{
		var selector:StyleSelector = _sSelectors[source];
		if (selector == null)
			selector = _sSelectors[source] = new StyleSelector(source);

		return selector;
	}

	private static function getPriorityMerge(b:int, c:int, d:int):int
	{
		return (b << 16) | (c << 8) | d;
	}

	private var _priority:int;
	private var _source:String;

	private var _ancestor:StyleSelector;
	private var _id:String;
	private var _type:String;
	private var _classes:Vector.<String>;
	private var _states:Vector.<Object>;

	/** @private */
	public function StyleSelector(source:String)
	{
		_source = source;

		_classes = new <String>[];
		_states = new <Object>[];

		var split:Array = _source.split(' ');
		var current:String = split.pop();

		// Parent selector
		if (split.length > 0) _ancestor = getSelector(split.join(' '));

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

	public function get source():String
	{
		return _source;
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