package talon.utils
{
	import talon.Attribute;
	import talon.Node;

	/** @private */
	public class StringSet
	{
		private static const sArray:Array = [];

		private var _container:Vector.<String> = new Vector.<String>();
		private var _change:Trigger = new Trigger();
		private var _locked:Boolean;
		private var _changed:Boolean;

		private var _node:Node;
		private var _attributeName:String;
		private var _attribute:Attribute;

		public function StringSet(node:Node, attributeName:String)
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
				parse(_attribute.valueCache, false);
			}
		}

		private function onChange():void
		{
			parse(_attribute.valueCache);
		}

		public function toggle(string:String, value:Boolean):void
		{
			initialize();
			if (value) insert(string);
			else remove(string);
		}

		public function contains(string:String):Boolean
		{
			initialize();
			return _container.indexOf(string) != -1;
		}

		public function insert(string:String):void
		{
			if (!contains(string))
			{
				_container[_container.length] = string;
				dispatchChange();
			}
		}

		public function remove(string:String):void
		{
			initialize();

			var indexOf:int = _container.indexOf(string);
			if (indexOf != -1)
			{
				_container.removeAt(indexOf);
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

		public function parse(string:String, dispatch:Boolean = true):void
		{
			_container.length = 0;

			if (string)
			{
				var split:Array = string.split(" ");
				for each (var element:String in split)
					_container[_container.length] = element;
			}

			if (dispatch) dispatchChange();
		}

		public function toString():String
		{
			sArray.length = 0;

			for each (var element:String in _container)
				sArray[sArray.length] = element;

			return sArray.join(" ");
		}
	}
}