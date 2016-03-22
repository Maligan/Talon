package talon.utils
{
	import flash.utils.Dictionary;

	/**
	 * Implementation of pull-model observer pattern.
	 *
	 * I strongly do not want introduce one more observer implementation, but I have no choice:
	 * - flash.events.EventDispatcher - Produces a lot of excess memory allocations/deallocations (String, Array, Event)
	 * - starling.events.EventDispatcher - Good alternate, but talon core must be absolutely independent from external libraries
	 * - Function (as simple callback) - Lack of functional
	 *
	 * I stash this class via [ExcludeClass] specially.
	 * Please, do not use this class - except if you understand what and why you do it.
	 */
	[ExcludeClass]
	public class Trigger
	{
		protected var _context:*;
		protected var _listeners:Vector.<Function>;
		protected var _listenersIndex:Dictionary;

		/** @param context - default value send to listeners while dispatch(). */
		public function Trigger(context:* = null)
		{
			_context = context;
			_listeners = new Vector.<Function>();
			_listenersIndex = new Dictionary();
		}

		/** Add listener to list which invoked by dispatch(). */
		public function addListener(listener:Function):void
		{
			var indexOf:int = _listenersIndex[listener] || -1;
			if (indexOf == -1)
			{
				var index:int = _listeners.length;
				_listeners[index] = listener;
				_listenersIndex[listener] = index;
			}
		}

		/** Remove listener from list which invoked by dispatch(). */
		public function removeListener(listener:Function):void
		{
			var indexOf:int = _listenersIndex[listener] || -1;
			if (indexOf != -1)
			{
				var lastIndex:int = _listeners.length - 1;
				var lastListener:Function = _listeners[lastIndex];
				_listeners[indexOf] = lastListener;
				_listeners.length--;
				_listenersIndex[lastListener] = indexOf;
				delete _listenersIndex[listener];
			}
		}

		/** Remove all listeners. */
		public function removeListeners():void
		{
			_listeners.length = 0;
			_listenersIndex = new Dictionary();
		}

		/** Invoke all listeners with argument - context (or default context setted from ctor).
		 *  Method is safe for any add listener & remove listener by itself, but occur errors for removeListeners(). */
		public function dispatch(context:* = null):void
		{
			context = context || _context;

			for (var i:int = 0; i < _listeners.length; i++)
//			var i:int = _listeners.length;
//			while (--i > -1)
//			var i:int = -1;
//			while (++i > _listeners.length)
			{
				_listeners[i].length == 0
					? _listeners[i]()
					: _listeners[i](context);
			}
		}
	}
}