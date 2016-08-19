package starling.extensions
{
	import starling.animation.Juggler;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;

	public class TalonQuery
	{
		private var _elements:Vector.<DisplayObject>;

		public function TalonQuery(base:DisplayObject)
		{
			_elements = new <DisplayObject>[];
			reset(base);
		}

		public function reset(base:DisplayObject):TalonQuery
		{
			_elements.length = 0;
			_elements[0] = base;
			return this;
		}

		public function select(selector:String):TalonQuery
		{
			if (_elements.length > 0)
			{
				var base:DisplayObject = _elements[0];
				_elements.length = 0;
				var child:DisplayObject = findObjectByName(base, selector.substr(1));
				if (child) _elements[0] = child;
			}

			return this;
		}

		public function forEach(callback:Function, ...args):TalonQuery
		{
			return this;
		}

		public function setAttribute(name:String, value:String):TalonQuery
		{
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

		public function clone():TalonQuery
		{
			return this;
		}

		public function onTap(listener:Function):TalonQuery
		{
			for each (var element:DisplayObject in _elements)
				element.addEventListener(TouchEvent.TOUCH, function(e:TouchEvent):void
				{
					if (e.getTouch(e.target as DisplayObject, TouchPhase.BEGAN))
						listener.length ? listener(e) : listener();
				})

			return this;
		}
	}
}

import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;

function findObjectByName(root:DisplayObject, name:String):DisplayObject
{
	if (root.name == name) return root;

	var rootAsContainer:DisplayObjectContainer = root as DisplayObjectContainer;
	if (rootAsContainer)
	{
		for (var i:int = 0; i < rootAsContainer.numChildren; i++)
		{
			var child:DisplayObject = findObjectByName(rootAsContainer.getChildAt(i), name);
			if (child) return child;
		}
	}

	return null;
}