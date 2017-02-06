package starling.extensions
{
	import starling.animation.Juggler;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;

	public class TalonQuery
	{
		private var _elements:Vector.<ITalonElement>;
		private var _elementsBackBuffer:Vector.<ITalonElement>;

		public function TalonQuery(element:ITalonElement = null):void
		{
			_elements = new <ITalonElement>[];
			_elementsBackBuffer = new <ITalonElement>[];
			if (element) reset(element);
		}

		public function reset(element:ITalonElement = null):TalonQuery
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
			var result:Vector.<ITalonElement> = _elementsBackBuffer;

			for each (var element:ITalonElement in _elements)
				selectInternal(element, selector, result);

			// Swap
			_elementsBackBuffer = _elements;
			_elementsBackBuffer.length = 0;
			_elements = result;

			return this;
		}

		private function selectInternal(element:ITalonElement, selector:String, result:Vector.<ITalonElement>):void
		{
			if (element == null) return;

			// Check self
			if (isMatch(selector, element))
				result[result.length] = element;

			// Recursive
			var elementAsContainer:DisplayObjectContainer = element as DisplayObjectContainer;
			if (elementAsContainer)
				for (var i:int = 0; i < elementAsContainer.numChildren; i++)
					selectInternal(elementAsContainer.getChildAt(i) as ITalonElement, selector, result);
		}

		private function isMatch(selector:String, element:ITalonElement):Boolean
		{
			var id:String = DisplayObject(element).name;
			if (id == null) return false;
			return id == selector.substr(1);
		}

		//
		// Enumeration
		//
		public function get numElements():int { return _elements.length; }
		public function getElementAt(index:int):ITalonElement { return (index>-1 && index<_elements.length) ? _elements[index] : null; }
		public function getElementIndex(element:ITalonElement):int { return _elements.indexOf(element); }

		//
		// Common
		//
		public function setAttribute(name:String, value:*):TalonQuery
		{
			for each (var element:ITalonElement in _elements)
				element.node.setAttribute(name, value);

			return this;
		}

		public function tween(time:Number, properties:Object, juggler:Juggler = null):TalonQuery
		{
		   if (juggler == null)
		       juggler = Starling.juggler;

		   for each (var element:ITalonElement in _elements)
		       juggler.tween(element, time, properties);

			return this;
		}

		public function tweenKill(juggler:Juggler = null):TalonQuery
		{
			if (juggler == null)
				juggler = Starling.juggler;

			for each (var element:ITalonElement in _elements)
				juggler.removeTweens(element);

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
			for each (var element:ITalonElement in _elements)
				DisplayObject(element).addEventListener(type, listener);

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