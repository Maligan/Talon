package starling.extensions
{
	import starling.animation.Juggler;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;

	import talon.utils.ITalonElement;

	public class TalonQuery
	{
		private var _elements:Vector.<DisplayObject>;
		private var _elementsBackBuffer:Vector.<DisplayObject>;

		public function TalonQuery(element:DisplayObject = null):void
		{
			_elements = new <DisplayObject>[];
			_elementsBackBuffer = new <DisplayObject>[];
			if (element) reset(element);
		}

		public function reset(element:DisplayObject = null):TalonQuery
		{
			_elements.length = 0;
			_elementsBackBuffer.length = 0;
			_elements[0] = element;
			return this;
		}

		//
		// Selection
		//
		public function select(selector:String):TalonQuery
		{
			// Select
			var result:Vector.<DisplayObject> = _elementsBackBuffer;

			for each (var element:DisplayObject in _elements)
				selectInternal(element, selector, result);

			// Swap
			_elementsBackBuffer = _elements;
			_elementsBackBuffer.length = 0;
			_elements = result;

			return this;
		}

		private function selectInternal(element:DisplayObject, selector:String, result:Vector.<DisplayObject>):void
		{
			// Check self
			if (isMatch(selector, element))
				result[result.length] = element;

			// Recursive
			var elementAsContainer:DisplayObjectContainer = element as DisplayObjectContainer;
			if (elementAsContainer)
				for (var i:int = 0; i < elementAsContainer.numChildren; i++)
					selectInternal(elementAsContainer.getChildAt(i), selector, result);
		}

		private function isMatch(selector:String, element:DisplayObject):Boolean
		{
			var id:String = element.name;
			if (id == null) return false;
			return id.indexOf(selector.substr(1)) == 0;
		}

		//
		// Enumeration
		//
		public function get numElements():int { return _elements.length; }
		public function getElementAt(index:int):DisplayObject { return (index>-1 && index<_elements.length) ? _elements[index] : null; }
		public function getElementIndex(element:DisplayObject):int { return _elements.indexOf(element); }

		//
		// Common
		//
		public function setAttribute(name:String, value:*):TalonQuery
		{
			for each (var element:DisplayObject in _elements)
			{
				var talonElement:ITalonElement = element as ITalonElement;
				if (talonElement) talonElement.node.setAttribute(name, value);
			}

			return this;
		}

		public function tween(time:Number, properties:Object, juggler:Juggler = null):TalonQuery
		{
		   if (juggler == null)
		       juggler = Starling.juggler;

		   for each (var object:DisplayObject in _elements)
		       juggler.tween(object, time, properties);

			return this;
		}

		public function tweenKill(juggler:Juggler = null):TalonQuery
		{
			if (juggler == null)
				juggler = Starling.juggler;

			for each (var object:DisplayObject in _elements)
				juggler.removeTweens(object);

			return this;
		}

		public function clone():TalonQuery
		{
			var query:TalonQuery = new TalonQuery();
			query._elements = _elements.slice();
			return query;
		}

		//
		// Event Listeners
		//
		public function onEvent(type:String, listener:Function):TalonQuery
		{
			for each (var element:DisplayObject in _elements)
				element.addEventListener(type, listener);

			return this;
		}

		public function onTap(listener:Function, numTapsRequired:int = 1):TalonQuery
		{
			onEvent(TouchEvent.TOUCH, function(e:TouchEvent):void
			{
				if (e.getTouch(e.target as DisplayObject, TouchPhase.ENDED))
				{
					listener.length
						? listener(e)
						: listener();
				}
			});

			return this;
		}
	}
}