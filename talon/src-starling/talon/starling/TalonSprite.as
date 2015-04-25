package talon.starling
{
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.core.RenderSupport;
	import starling.display.DisplayObject;
	import starling.display.Sprite;
	import starling.events.Event;

	import talon.Attribute;
	import talon.Node;
	import talon.utils.ITalonElement;

	public class TalonSprite extends Sprite implements ITalonElement
	{
		private var _node:Node;
		private var _background:DisplayObjectBridge;

		public function TalonSprite()
		{
			_node = new Node();
			_node.addEventListener(Event.RESIZE, onNodeResize);
			_background = new DisplayObjectBridge(this, node);
		}

		public override function addChild(child:DisplayObject):DisplayObject
		{
			(child is ITalonElement) && node.addChild(ITalonElement(child).node);
			return super.addChild(child);
		}

		override public function removeChildAt(index:int, dispose:Boolean = false):DisplayObject
		{
			var child:DisplayObject = getChildAt(index);
			(child is ITalonElement) && node.removeChild(ITalonElement(child).node);
			return super.removeChildAt(index, dispose);
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

		//
		// Background custom changes
		//
		public override function render(support:RenderSupport, parentAlpha:Number):void
		{
			// Background render
			_background.renderBackground(support, parentAlpha);

			// Children render
			super.render(support, parentAlpha);
		}

		public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle = null):Rectangle
		{
			return _background.getBoundsCustom(super.getBounds, targetSpace, resultRect);
		}

		public override function hitTest(localPoint:Point, forTouch:Boolean = false):DisplayObject
		{
			return _background.hitTestCustom(super.hitTest, localPoint, forTouch);
		}

		//
		// Property delegating
		//
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