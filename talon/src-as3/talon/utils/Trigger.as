package talon.utils
{
	/**
	 * Implementation of pull-model observer pattern.
	 *
	 * I strongly do not want introduce one more observer implementation, but I have no choice:
	 * - flash.events.EventDispatcher - Produces a lot of excess memory allocations/deallocations (String, Array, Event)
	 * - starling.events.EventDispatcher - Good alternate, but talon core must be absolutely independent from external libraries
	 * - Function (as simple callback) - Lack of functional
	 *
	 * I stash this class via [ExcludeClass] specially.
	 *
	 * Do not use this class - except if you understand what and why you do this.
	 */
	[ExcludeClass]
	public class Trigger
	{
		protected var _context:*;
		protected var _listeners:Vector.<Function>;

		/** @param context - default value send to listeners while dispatch(). */
		public function Trigger(context:* = null)
		{
			_context = context;
			_listeners = new Vector.<Function>();
		}

		/** Add listener to list witch invoked by dispatch(). */
		public function addListener(listener:Function):void
		{
			_listeners[_listeners.length] = listener;
		}

		/** Remove listener from list witch invoked by dispatch(). */
		public function removeListener(listener:Function):void
		{
			var indexOf:int = _listeners.indexOf(listener);
			if (indexOf != -1)
			{
				_listeners[indexOf] = _listeners[_listeners.length - 1];
				_listeners.length--;
			}
		}

		/** Remove all listeners. */
		public function removeListeners():void
		{
			_listeners.length = 0;
		}

		/** Invoke all listeners with argument - context (or default context setted from ctor). */
		public function dispatch(context:* = null):void
		{
			context = context || _context;

			var i:int = _listeners.length;

			while (--i > -1)
			{
				_listeners[i].length == 0
					? _listeners[i]()
					: _listeners[i](context);
			}
		}
	}
}