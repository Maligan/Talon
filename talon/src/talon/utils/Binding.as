package talon.utils
{
	[ExcludeClass]
	public class Binding
	{
		public static function bind(fromTrigger:Trigger, from:Object, fromProperty:String, to:Object, toProperty:String):Binding
		{
			var fromPropertyValue:* = getProperty(from, fromProperty);
			var toPropertyValue:* = getProperty(to, toProperty);

			var getter:Function = fromPropertyValue is Function ? fromPropertyValue : getProperty;
			var getterArgs:Array = fromPropertyValue is Function ? null : [from, fromProperty];
			var setter:Function = toPropertyValue is Function ? toPropertyValue : setProperty;
			var setterArgs:Array = toPropertyValue is Function ? null : [to, toProperty];

			return new Binding
			(
				fromTrigger,
				getter, getterArgs,
				setter, setterArgs
			);
		}

		private static function getProperty(object:Object, property:String):*
		{
			return object[property];
		}

		private static function setProperty(object:Object, property:String, value:*):void
		{
			object[property] = value;
		}

		//
		// Implementation
		//
		private var _isSuppressed:Boolean;
		private var _trigger:Trigger;

		private var _getter:Function;
		private var _getterArgs:Array;

		private var _setter:Function;
		private var _setterArgs:Array;

		public function Binding(trigger:Trigger, getter:Function, getterArgs:Array, setter:Function, setterArgs:Array)
		{
			_trigger = trigger;
			_trigger.addListener(onTrigger);

			_getter = getter;
			_getterArgs = getterArgs || [];

			_setter = setter;
			_setterArgs = setterArgs || [];
		}

		private function onTrigger():void
		{
			trigger();
		}

		public function trigger():void
		{
			if (_isSuppressed === false)
			{
				_isSuppressed = true;
				setter(getter());
				_isSuppressed = false;
			}
		}

		private function getter():*
		{
			return _getter.apply(null, _getterArgs);
		}

		private function setter(value:*):void
		{
			try
			{
				_setterArgs[_setterArgs.length] = value;
				_setter.apply(null, _setterArgs);
			}
			finally
			{
				_setterArgs.length--;
			}
		}

		/** Dispose binding. */
		public function dispose():void
		{
			if (_trigger)
			{
				_trigger.removeListener(onTrigger);
				_trigger = null;
				_getter = null;
				_getterArgs = null;
				_setter = null;
				_setterArgs = null;
			}
		}
	}
}