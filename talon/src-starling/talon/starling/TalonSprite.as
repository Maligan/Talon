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
	import talon.utils.StringUtil;

	public class TalonSprite extends Sprite implements ITalonElement
	{
		private var _node:Node;
		private var _bridge:DisplayObjectBridge;

		public function TalonSprite()
		{
			_node = new Node();
			_node.addEventListener(Event.RESIZE, onNodeResize);
			_bridge = new DisplayObjectBridge(this, node);
			_bridge.addAttributeChangeListener(Attribute.CLIPPING, refreshClipping);
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

			_bridge.resize(node.bounds.width, node.bounds.height);
			refreshClipping();
		}

		private function refreshClipping():void
		{
			var clippingString:String = _node.getAttribute(Attribute.CLIPPING);
			var clipping:Boolean = StringUtil.parseBoolean(clippingString);

			if (clipping && clipRect)
				clipRect.setTo(0, 0, node.bounds.width, node.bounds.height);
			else if (clipping && !clipRect)
				clipRect = new Rectangle(0, 0, node.bounds.width, node.bounds.height);
			else
				clipRect = null;
		}

		//
		// Background custom changes
		//
		public override function render(support:RenderSupport, parentAlpha:Number):void
		{
			// Background render
			_bridge.renderBackground(support, parentAlpha);

			// Children render
			super.render(support, parentAlpha);
		}

		public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle = null):Rectangle
		{
			return _bridge.getBoundsCustom(super.getBounds, targetSpace, resultRect);
		}

		public override function hitTest(localPoint:Point, forTouch:Boolean = false):DisplayObject
		{
			return _bridge.hitTestCustom(super.hitTest, localPoint, forTouch);
		}

		//
		// Properties
		//
		public function get node():Node
		{
			return _node;
		}
	}
}