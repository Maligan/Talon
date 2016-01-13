package talon.starling
{
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.display.DisplayObject;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.rendering.Painter;
	import starling.utils.Color;

	import talon.Attribute;
	import talon.Node;
	import talon.utils.ITalonElement;

	public class TalonSprite extends Sprite implements ITalonElement
	{
		private var _node:Node;
		private var _bridge:DisplayObjectBridge;

		private var _quad:Quad;

		public function TalonSprite()
		{
			_node = new Node();
			_node.addListener(Event.RESIZE, onNodeResize);
			_bridge = new DisplayObjectBridge(this, node);
			_bridge.addAttributeChangeListener(Attribute.CLIPPING, refreshClipping);
		}

		//
		// Children
		//
		/** @inherit */
		public override function addChild(child:DisplayObject):DisplayObject
		{
			if (child is ITalonElement) attachChildElement(child as ITalonElement);
			return super.addChild(child);
		}

		/** @inherit */
		public override function removeChildAt(index:int, dispose:Boolean = false):DisplayObject
		{
			var child:DisplayObject = getChildAt(index);
			if (child is ITalonElement) detachChildElement(child as ITalonElement);
			return super.removeChildAt(index, dispose);
		}

		private function attachChildElement(child:ITalonElement):void
		{
			node.addChild(child.node);
		}

		private function detachChildElement(child:ITalonElement):void
		{
			node.removeChild(child.node);
		}

		private function sortByZIndex(child1:DisplayObject, child2:DisplayObject):int
		{
			var child1ZIndex:int = (child1 is ITalonElement) ? 0 : ITalonElement(child1).node.getAttributeCache(Attribute.Z_INDEX);
			var child2ZIndex:int = (child2 is ITalonElement) ? 0 : ITalonElement(child2).node.getAttributeCache(Attribute.Z_INDEX);

			var delta:int = child2ZIndex - child1ZIndex;
			if (delta != 0) return delta;

			// TODO: Poor logic, need hold base indexes
			return getChildIndex(child2) - getChildIndex(child1);
		}

		//
		// Bridge
		//
		private function onNodeResize():void
		{
			node.bounds.left = Math.round(node.bounds.left);
			node.bounds.right = Math.round(node.bounds.right);
			node.bounds.top = Math.round(node.bounds.top);
			node.bounds.bottom = Math.round(node.bounds.bottom);

			pivotX = int(node.pivot.x.toPixels(node.ppmm, node.ppem, node.ppdp, node.bounds.width));
			pivotY = int(node.pivot.y.toPixels(node.ppmm, node.ppem, node.ppdp, node.bounds.height));

			x = node.bounds.x + pivotX;
			y = node.bounds.y + pivotY;

			_bridge.resize(node.bounds.width, node.bounds.height);
			refreshClipping();
		}

		private function refreshClipping():void
		{
			/*
			var clippingString:String = _node.getAttributeCache(Attribute.CLIPPING);
			var clipping:Boolean = StringUtil.parseBoolean(clippingString);

			if (clipping && clipRect)
				clipRect.setTo(0, 0, node.bounds.width, node.bounds.height);
			else if (clipping && !clipRect)
				clipRect = new Rectangle(0, 0, node.bounds.width, node.bounds.height);
			else
				clipRect = null;
			*/
		}

		//
		// Background customization
		//
		public override function render(painter:Painter):void
		{
			// Background render
			_bridge.renderBackground(painter);

			// Children render
			super.render(painter);
		}

		public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle = null):Rectangle
		{
			return _bridge.getBoundsCustom(super.getBounds, targetSpace, resultRect);
		}

		public override function dispose():void
		{
			node.dispose();
			super.dispose();
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