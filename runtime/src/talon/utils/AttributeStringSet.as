package talon.utils
{
	import talon.Attribute;
	import talon.Node;

	/** @private */
	public class AttributeStringSet
	{
		private static const DELIMITER:String = " ";
		private static const ARRAY:Array = [];

		private var _container:Object = new Object();
		private var _change:Trigger = new Trigger();
		private var _locked:Boolean;
		private var _changed:Boolean;

		private var _node:Node;
		private var _attributeName:String;
		private var _attribute:Attribute;

		public function AttributeStringSet(node:Node, attributeName:String)
		{
			_node = node;
			_attributeName = attributeName;
		}

		private function initialize():void
		{
			if (_attribute == null)
			{
				_attribute = _node.getOrCreateAttribute(_attributeName);
				_attribute.change.addListener(onChange);
				onChange();
			}
		}

		private function onChange():void
		{
			parse(_attribute.valueCache);
		}



		public function contains(string:String):Boolean
		{
			initialize();
			return _container[string] != null;
		}

		public function insert(string:String):void
		{
			if (!contains(string))
			{
				_container[string] = string;
				dispatchChange();
			}
		}

		public function remove(string:String):void
		{
			if (contains(string))
			{
				delete _container[string];
				dispatchChange();
			}
		}

		public function lock():void
		{
			_locked = true;
		}

		public function unlock():void
		{
			if (_locked)
			{
				var changed:Boolean = _changed;
				_locked = false;
				_changed = false;
				if (changed) dispatchChange();
			}
		}

		public function get change():Trigger
		{
			return _change;
		}

		private function dispatchChange():void
		{
			if (_locked)
				_changed = true;
			else
				_change.dispatch();
		}

		public function parse(string:String):void
		{
			_container = new Object();

			if (string)
			{
				var split:Array = string.split(DELIMITER);
				for each (var element:String in split)
					_container[element] = element;
			}

			dispatchChange();
		}

		public function toString():String
		{
			ARRAY.length = 0;

			for each (var element:String in _container)
				ARRAY[ARRAY.length] = element;

			return ARRAY.join(DELIMITER);
		}
	}
}