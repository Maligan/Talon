package talon.utils
{
	[ExcludeClass]
	public class StringSet
	{
		private static const DELIM:String = ",";
		private static const ARRAY:Array = [];

		private var _container:Object = new Object();
		private var _change:Trigger = new Trigger();
		private var _locked:Boolean;
		private var _changed:Boolean;

		public function contains(string:String):Boolean
		{
			return _container[string] != null;
		}

		public function add(string:String):void
		{
			if (contains(string) === false)
			{
				_container[string] = string;
				dispatchChange();
			}
		}

		public function remove(string:String):void
		{
			if (contains(string) === true)
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

		public function parse(string:String):void
		{
			_container = new Object();

			if (string)
			{
				var split:Array = string.split(DELIM);
				for each (var element:String in split)
					_container[element] = element;
			}

			dispatchChange();
		}

		public function toString():String
		{
			for each (var element:String in _container)
				ARRAY[ARRAY.length] = element;

			var result:String = ARRAY.join(DELIM);
			ARRAY.length = 0;
			return result;
		}

		/** @private */
		public function get change():Trigger
		{
			return _change;
		}

		private function dispatchChange():void
		{
			if (_locked)
			{
				_changed = true;
			}
			else
			{
				_change.dispatch();
			}
		}
	}
}