package talon.utils
{
	/** @private */
	public class StringUniqueSet
	{
		private static const DELIMITER:String = " ";
		private static const ARRAY:Array = [];

		private var _container:Object = new Object();
		private var _change:Trigger = new Trigger();
		private var _locked:Boolean;
		private var _changed:Boolean;

		public function contains(string:String):Boolean
		{
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