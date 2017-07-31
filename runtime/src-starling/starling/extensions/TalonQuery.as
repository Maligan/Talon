package starling.extensions
{
	import flash.geom.Point;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;

	import starling.animation.Juggler;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.utils.Pool;

	import talon.utils.StyleSheet;

	use namespace flash_proxy;

	public final dynamic class TalonQuery extends Proxy
	{
		private var _elements:Vector.<ITalonElement>;
		private var _elementsBackBuffer:Vector.<ITalonElement>;
		private var _elementsAreBusy:Boolean;

		public function TalonQuery(element:ITalonElement = null):void
		{
			
			_elements = new <ITalonElement>[];
			_elementsBackBuffer = new <ITalonElement>[];
			if (element) reset(element);
		}

		public function reset(element:ITalonElement = null):TalonQuery
		{
			if (_elementsAreBusy) return clone().reset(element);
			else
			{
				_elements.length = 0;
				_elementsBackBuffer.length = 0;
				_elements[0] = element;
				return this;
			}
		}

		//
		// Selection
		//

		/** FIXME: Remember about num spaces */
		public function select(selector:String):TalonQuery
		{
			if (selector == null) return this;
			
			if (_elementsAreBusy) return clone().select(selector);
			else
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
		}

		private function selectInternal(element:ITalonElement, selector:String, result:Vector.<ITalonElement>):void
		{
			if (element == null) return;

			// Check self
			if (StyleSheet.match(element.node, selector))
				result[result.length] = element;

			// Recursive
			var elementAsContainer:DisplayObjectContainer = element as DisplayObjectContainer;
			if (elementAsContainer)
				for (var i:int = 0; i < elementAsContainer.numChildren; i++)
					selectInternal(elementAsContainer.getChildAt(i) as ITalonElement, selector, result);
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

		public function forEach(callback:Function):TalonQuery
		{
			_elementsAreBusy = true;

			for (var i:int = 0; i < _elements.length; i++)
				if (callback.length == 3) callback(_elements[i], i, _elements);
				else if (callback.length == 2) callback(_elements[i], i);
				else callback(_elements[i]);

			_elementsAreBusy = false;

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
				var target:DisplayObject = e.target as DisplayObject;
				var touch:Touch = e.getTouch(target, TouchPhase.ENDED);
				if (touch)
				{
					var local:Point = touch.getLocation(target, Pool.getPoint());
					var within:Boolean = target.hitTest(local);
					Pool.putPoint(local);

					if (within)
					{
						listener.length
							? listener(e)
							: listener();
					}
				}
			});

			return this;
		}
		
		//
		// Flash Proxy
		//
		public function get length():int { return _elements.length }
		
		// Enumeration of elements
		flash_proxy override function nextNameIndex(index:int):int { return index < _elements.length ? index+1 : 0; }
		flash_proxy override function nextName(index:int):String { return (index-1).toString(); }
		flash_proxy override function nextValue(index:int):* { return _elements[index-1]; }
		
		// Access to elements & attributes
		flash_proxy override function getProperty(name:*):*
		{
			if (name is String)
				return name < _elements.length ? _elements[name] : null;

			else if (_elements.length > 0)
				return _elements[0].node.getOrCreateAttribute(name).value;

			return null;
		}
		
		flash_proxy override function setProperty(name:*, value:*):void
		{
			if (name is String)
				throw new ArgumentError();
			
			setAttribute(name, value);
		}
	}
}