package starling.extensions
{
	import flash.geom.Point;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;

	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.events.EventDispatcher;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.utils.Pool;
	import starling.utils.StringUtil;

	import talon.utils.StyleUtil;

	use namespace flash_proxy;

	/** Utility class which allow make CSS query to display tree and batch changes. */
	public final dynamic class TalonQuery extends Proxy
	{
		private var _elements:Vector.<ITalonDisplayObject>;
		private var _elementsBackBuffer:Vector.<ITalonDisplayObject>;

		public function TalonQuery(element:ITalonDisplayObject = null):void
		{
			
			_elements = new <ITalonDisplayObject>[];
			_elementsBackBuffer = new <ITalonDisplayObject>[];
			if (element) reset(element);
		}

		public function reset(element:ITalonDisplayObject = null):TalonQuery
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
			if (selector == null) return this;
			
			// Select
			var result:Vector.<ITalonDisplayObject> = _elementsBackBuffer;

			for each (var element:ITalonDisplayObject in _elements)
				selectInternal(element, selector, result);

			// Swap
			_elementsBackBuffer = _elements;
			_elementsBackBuffer.length = 0;
			_elements = result;

			return this;
		}

		private function selectInternal(element:ITalonDisplayObject, selector:String, result:Vector.<ITalonDisplayObject>):void
		{
			if (element == null) return;

			// Check self
			if (StyleUtil.match(element.node, selector) != -1)
				result[result.length] = element;

			// Recursive
			var elementAsContainer:DisplayObjectContainer = element as DisplayObjectContainer;
			if (elementAsContainer)
				for (var i:int = 0; i < elementAsContainer.numChildren; i++)
					selectInternal(elementAsContainer.getChildAt(i) as ITalonDisplayObject, selector, result);
		}

		//
		// Common
		//
		
		public function set(name:String, value:*, ...args):TalonQuery
		{
			if (args.length)
			{
				args.unshift(value);
				value = StringUtil.format.apply(null, args);
			}
			
			for each (var element:ITalonDisplayObject in _elements)
				element.node.setAttribute(name, value);

			return this;
		}
		
		public function forEach(callback:Function, ...args):TalonQuery
		{
			for (var i:int = 0; i < _elements.length; i++)
			{
				if (args.length == 0)
				{
				   if (callback.length == 3) callback(_elements[i], i, _elements);
				   else if (callback.length == 2) callback(_elements[i], i);
				   else callback(_elements[i]);
				}
				else
				{
					args.unshift(_elements[i]);
					callback.apply(null, args);
				}
			}
			
			return this;
		}

		//
		// Event Listeners
		//

		public function onTap(listener:Function):TalonQuery
		{
			forEach(function(element:EventDispatcher):void
			{
				element.addEventListener(TouchEvent.TOUCH, function(e:TouchEvent):void
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
				})
			});

			return this;
		}
		
		//
		// Flash Proxy & Enumeration
		//
		public function get length():int { return _elements.length }
		
		public function indexOf(element:ITalonDisplayObject):int { return _elements.indexOf(element) }
		
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
			
			set(name, value);
		}
	}
}