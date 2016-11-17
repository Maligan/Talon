package starling.extensions
{
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.display.DisplayObject;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.rendering.Painter;

	import talon.Attribute;
	import talon.Node;
	import talon.enums.TouchMode;
	import starling.extensions.ITalonElement;

	public class TalonSpriteElement extends Sprite implements ITalonElement
	{
		private static var _helperRect:Rectangle = new Rectangle();

		private var _node:Node;
		private var _bridge:TalonDisplayObjectBridge;

		public function TalonSpriteElement()
		{
			_node = new Node();
			_node.addTriggerListener(Event.RESIZE, onNodeResize);
			_bridge = new TalonDisplayObjectBridge(this, node);
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

		//
		// Bridge
		//
		private function onNodeResize():void
		{
			node.bounds.left = node.bounds.left;
			node.bounds.right = node.bounds.right;
			node.bounds.top = node.bounds.top;
			node.bounds.bottom = node.bounds.bottom;

			x = node.bounds.x - pivotX;
			y = node.bounds.y - pivotY;
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

		public override function hitTest(localPoint:Point):DisplayObject
		{
			var localX:Number = localPoint.x;
			var localY:Number = localPoint.y;

			var superHitTest:DisplayObject = super.hitTest(localPoint);
			if (superHitTest == null && _bridge.hasOpaqueBackground)
			{
				// Restore for hitTestMask()
				localPoint.setTo(localX, localY);
				// Make check like within super.hitTest()
				if (!visible || !touchable || !hitTestMask(localPoint)) return null;

				// Use getBoundsCustom(null, ...) directly - in this way there is no traveling via children
				_helperRect.setEmpty();
				var contains:Boolean = _bridge.getBoundsCustom(null, this, _helperRect).contains(localX, localY);
				if (contains) return this;
			}

			return superHitTest;
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

		public function get self():DisplayObject
		{
			return this;
		}
	}
}