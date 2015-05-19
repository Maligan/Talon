package talon.utils
{
	import flash.utils.Dictionary;

	public class Binding
	{
		private static const _bindings:Dictionary = new Dictionary();

		public static function bind(sourceTrigger:Trigger, from:Object, fromProperty:String, to:Object, toProperty:String):Binding
		{
			var binding:Binding = new Binding
			(
				sourceTrigger,
				getProperty, [from, fromProperty],
				setProperty, [to, toProperty]
			);

			register(binding, from, to);
			return binding;
		}

		private static function getProperty(object:Object, property:String):*
		{
			return object[property];
		}

		private static function setProperty(object:Object, property:String, value:*):void
		{
			object[property] = value;
		}

		private static function register(binding:Binding, ...objects):void
		{
			for each (var object:Object in objects)
			{
				var bindings:Vector.<Binding> = _bindings[object];

				if (bindings == null)
					bindings = _bindings[object] = new Vector.<Binding>();

				bindings[bindings.length] = binding;
			}
		}

		/** Dispose all binding created via bind() method. */
		public static function dispose(object:Object):void
		{
			var bindings:Vector.<Binding> = _bindings[object];
			if (bindings != null)
			{
				while (bindings.length) bindings.pop().dispose();
				delete _bindings[object];
			}
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
			_trigger.removeListener(onTrigger);
			_trigger = null;
			_getter = null;
			_getterArgs = null;
			_setter = null;
			_setterArgs = null;
		}
	}
}