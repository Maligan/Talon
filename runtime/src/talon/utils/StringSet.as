package talon.utils
{
	import talon.core.Attribute;
	import talon.core.Node;

	public class StringSet
	{
		private var _strings:Array = [];
		private var _change:Trigger = new Trigger();
		private var _ignore:Boolean;

		private var _node:Node;
		private var _attributeName:String;
		private var _attribute:Attribute;

		/** @private */
		public function StringSet(node:Node, attributeName:String)
		{
			_node = node;
			_attributeName = attributeName;
		}
		
		public function set(string:String, value:Boolean):void
		{
			initialize();
			
			var index:int = _strings.indexOf(string);
			if (value && index == -1)
			{
				_strings[_strings.length] = string;
				dispatchChange(true);
			}
			else if (!value && index != -1)
			{
				_strings.removeAt(index);
				dispatchChange(true);
			}
		}
		
		public function has(string:String):Boolean
		{
			initialize();
			
			return _strings.indexOf(string) != -1;
		}

		private function initialize():void
		{
			if (_attribute == null)
			{
				_attribute = _node.getOrCreateAttribute(_attributeName);
				_attribute.change.addListener(onChange);
				_strings = String(_attribute.valueCache).split(" ");
			}
		}

		private function onChange():void
		{
			if (_ignore) return;
			
			_strings = String(_attribute.valueCache).split(" ");
			dispatchChange(true);
		}

		private function dispatchChange(updateAttribute:Boolean):void
		{
			if (updateAttribute)
			{
				_ignore = true;
				_attribute.setted = value;
				_ignore = false;
			}
			
			_change.dispatch();
		}
		
		public function get value():String
		{
			initialize();
			return _strings.join(" ");
		}
		
		public function set value(string:String):void
		{
			initialize();
			_strings = string.split(" ");
			dispatchChange(true);
		}

		/** @private */
		public function get change():Trigger
		{
			return _change;
		}
	}
}