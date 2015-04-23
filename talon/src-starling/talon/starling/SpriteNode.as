package talon.starling
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;

	import starling.core.RenderSupport;
	import starling.display.DisplayObject;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.filters.FragmentFilter;

	import talon.Attribute;
	import talon.Node;
	import talon.utils.ITalonNode;

	public class SpriteNode extends Sprite implements ITalonNode
	{
		private var _node:Node;
		private var _background:Background;

		public function SpriteNode()
		{
			_node = new Node();
			_node.addEventListener(Event.CHANGE, onNodeChange);
			_node.addEventListener(Event.RESIZE, onNodeResize);

			_background = new Background(this, node);

			addEventListener(TouchEvent.TOUCH, onTouch);
		}

		public function onTouch(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(this);

			if (touch == null)
			{
				node.states = new <String>[];
			}
			else if (touch.phase == TouchPhase.HOVER)
			{
				node.states = new <String>["hover"];
			}
			else if (touch.phase == TouchPhase.BEGAN)
			{
				node.states = new <String>["active"];
			}
			else if (touch.phase == TouchPhase.ENDED)
			{
				node.states = new <String>[];
				var onclick:String = node.getAttribute("onclick");
				if (onclick) dispatchEventWith(onclick, true);
			}
		}

		public override function addChild(child:DisplayObject):DisplayObject
		{
			(child is ITalonNode) && node.addChild(ITalonNode(child).node);
			return super.addChild(child);
		}

		override public function removeChildAt(index:int, dispose:Boolean = false):DisplayObject
		{
			var child:DisplayObject = getChildAt(index);
			(child is ITalonNode) && node.removeChild(ITalonNode(child).node);
			return super.removeChildAt(index, dispose);
		}

		private function onNodeChange(e:Event):void
		{
			/**/ if (e.data == Attribute.ID) name = node.getAttribute(Attribute.ID);
			else if (e.data == Attribute.ALPHA) alpha = parseFloat(node.getAttribute(Attribute.ALPHA));
			else if (e.data == Attribute.CURSOR)
			{
				var cursor:String = node.getAttribute(Attribute.CURSOR);
				cursor == MouseCursor.AUTO ? removeEventListener(TouchEvent.TOUCH, onCursorTouch) : addEventListener(TouchEvent.TOUCH, onCursorTouch);
			}
			else if (e.data == Attribute.FILTER)
			{
				filter = node.getAttribute(Attribute.FILTER) as FragmentFilter;
			}
		}

		private function onCursorTouch(e:TouchEvent):void
		{
			Mouse.cursor = e.interactsWith(this) ? (node.getAttribute(Attribute.CURSOR) || MouseCursor.AUTO) : MouseCursor.AUTO;
		}

		private function onNodeResize(e:Event):void
		{
			node.bounds.left = Math.round(node.bounds.left);
			node.bounds.right = Math.round(node.bounds.right);
			node.bounds.top = Math.round(node.bounds.top);
			node.bounds.bottom = Math.round(node.bounds.bottom);

			x = node.bounds.x;
			y = node.bounds.y;

			_background.resize(node.bounds.width, node.bounds.height);

			clipRect = clipping ? new Rectangle(0, 0, node.bounds.width, node.bounds.height) : null;
		}

		public override function render(support:RenderSupport, parentAlpha:Number):void
		{
			// Background render
			_background.render(support, parentAlpha);

			// Children render
			super.render(support, parentAlpha);
		}

		public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle = null):Rectangle
		{
			return _background.getBounds(targetSpace, resultRect, super.getBounds);
		}

		public override function hitTest(localPoint:Point, forTouch:Boolean = false):DisplayObject
		{
			return _background.hitTest(localPoint, forTouch, super.hitTest);
		}

		private function get clipping():Boolean
		{
			return node.getAttribute(Attribute.CLIPPING) == "true";
		}

		public function get node():Node
		{
			return _node;
		}
	}
}