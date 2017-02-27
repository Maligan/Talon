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
		private var _manual:Boolean;

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
		public override function addChildAt(child:DisplayObject, index:int):DisplayObject
		{
			child = super.addChildAt(child, index);
			if (child is ITalonElement) addChildNodeAt(child as ITalonElement, index);
			return child;
		}

		/** @inherit */
		public override function removeChildAt(index:int, dispose:Boolean = false):DisplayObject
		{
			var child:DisplayObject = super.removeChildAt(index, dispose);
			if (child is ITalonElement) removeChildNode(child as ITalonElement);
			return child;
		}

		private function addChildNodeAt(child:ITalonElement, index:int):void
		{
			node.addChild(child.node, index);
		}

		private function removeChildNode(child:ITalonElement):void
		{
			node.removeChild(child.node);
		}

		//
		// Bridge
		//
		private function onNodeResize():void
		{
			// if in percents
			super.pivotX = node.pivotX.toPixels(node, node.bounds.width);
			super.pivotY = node.pivotY.toPixels(node, node.bounds.height);

			if (!manual)
			{
				x = node.bounds.x + pivotX;
				y = node.bounds.y + pivotY;
			}
		}

		//
		// Background customization
		//
		public override function render(painter:Painter):void
		{
			_bridge.renderCustom(super.render, painter);
		}

		public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle = null):Rectangle
		{
			return _bridge.getBoundsCustom(super.getBounds, targetSpace, resultRect);
		}

		public override function hitTest(localPoint:Point):DisplayObject
		{
			var localX:Number = localPoint.x;
			var localY:Number = localPoint.y;

			var result:DisplayObject = super.hitTest(localPoint);

			if (result == null && _bridge.hasOpaqueBackground)
			{
				// Restore for hitTestMask()
				localPoint.setTo(localX, localY);
				// Make check like within super.hitTest()
				if (!visible || !touchable || !hitTestMask(localPoint)) return null;

				// Use getBoundsCustom(null, ...) directly - in this way there is no traveling via children
				var contains:Boolean = _bridge.getBoundsCustom(null, this, _helperRect).contains(localX, localY);
				if (contains) return this;
			}

			return result;
		}

		public override function dispose():void
		{
			_bridge.dispose();
			super.dispose();
		}

		//
		// Properties
		//
		public function get node():Node
		{
			return _node;
		}

		public function get manual():Boolean
		{
			return _manual;
		}

		public function set manual(value:Boolean):void
		{
			_manual = value;
		}

		public override function set pivotX(value:Number):void { node.setAttribute(Attribute.PIVOT_X, value.toString()); }
		public override function set pivotY(value:Number):void { node.setAttribute(Attribute.PIVOT_Y, value.toString()); }
	}
}
