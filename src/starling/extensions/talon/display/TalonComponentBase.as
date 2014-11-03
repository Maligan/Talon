package starling.extensions.talon.display
{
	import flash.geom.Rectangle;

	import starling.display.DisplayObject;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.extensions.talon.core.Node;

	public class TalonComponentBase extends Sprite implements TalonComponent
	{
		private var _background:Quad;
		private var _node:Node;

		public function TalonComponentBase()
		{
			_node = new Node();
			_node.addEventListener(Event.CHANGE, onBoxChange);
			_node.addEventListener(Event.RESIZE, onBoxResize);

			_background = new Quad(100, 100, 0);
			_background.useHandCursor = true;
			addChild(_background);

			addEventListener(TouchEvent.TOUCH, onTouch);
		}

		private function onTouch(e:TouchEvent):void
		{
			if (e.getTouch(_background, TouchPhase.HOVER) != null)
			{
				_background.color = 0x888888;
			}
			else if (e.getTouch(_background) == null)
			{
				_background.color = parseInt(node.attributes.backgroundColor);
			}
			else if (e.getTouch(_background, TouchPhase.ENDED) != null)
			{
				trace("Click", _node.attributes.id)
			}
		}

		public override function addChild(child:DisplayObject):DisplayObject
		{
			(child is TalonComponent) && node.children.push(TalonComponent(child).node);
			return super.addChild(child);
		}

		private function onBoxChange(e:Event):void
		{
			_background.visible = node.attributes.backgroundColor != null;
			_background.color = parseInt(node.attributes.backgroundColor);
		}

		private function onBoxResize(e:Event):void
		{
			x = node.layout.bounds.x;
			y = node.layout.bounds.y;
			_background.width = node.layout.bounds.width;
			_background.height = node.layout.bounds.height;

//			clipRect = new Rectangle(0, 0, node.layout.bounds.width, node.layout.bounds.height);
		}

		public function get node():Node
		{
			return _node;
		}
	}
}