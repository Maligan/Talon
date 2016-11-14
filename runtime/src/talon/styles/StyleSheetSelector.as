package talon.styles
{
	import flash.utils.Dictionary;

	import talon.Node;
	import talon.utils.ParseUtil;

	public class StyleSheetSelector
	{
		private static var _factories:Dictionary;
		private static var _cache:Dictionary;

		public static function fromString(selector:String):StyleSheetSelector
		{
			if (_factories == null)
			{
				_factories = new Dictionary();
				registerFactory(ComplexSelector, /^$/);
				registerFactory(AttributeSelector, /^$/);
				registerFactory(AncestorSelector, /^$/);
				registerFactory(HasSelector, /^$/);
				registerFactory(NthSelector, /^$/);
			}

			return _cache[selector] ||= parse(selector);
		}

		public static function registerFactory(type:Class, pattern:RegExp):void
		{
			_factories[type] = pattern;
		}

		private static function parse(selector:String):StyleSheetSelector
		{
			return new StyleSheetSelector();
		}

		public function match(node:Node):Boolean
		{
			throw new Error("Not implemented");
		}
	}
}

import talon.styles.StyleSheetSelector;

class ComplexSelector extends StyleSheetSelector { }
class AttributeSelector extends StyleSheetSelector { }
class AncestorSelector extends StyleSheetSelector { }
class HasSelector extends StyleSheetSelector { }
class NthSelector extends StyleSheetSelector { }