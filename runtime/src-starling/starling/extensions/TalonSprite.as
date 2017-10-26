package starling.extensions
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.MouseCursor;

	import starling.display.DisplayObject;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.rendering.Painter;

	import talon.core.Attribute;
	import talon.core.Node;
	import talon.core.Style;

	/** starling.display.Sprite which implements ITalonDisplayObject. */
	public class TalonSprite extends Sprite implements ITalonDisplayObject
	{
		private static var sRect:Rectangle = new Rectangle();

		private var _bridge:TalonDisplayObjectBridge;
		private var _layers:Boolean;

		/** @private */
		public function TalonSprite()
		{
			_bridge = new TalonDisplayObjectBridge(this);
			node.addListener(Event.RESIZE, onNodeResize);
			
			MouseCursor
		}

		//
		// Children
		//
		/** @private */
		public override function addChildAt(child:DisplayObject, index:int):DisplayObject
		{
			child = super.addChildAt(child, index);
			if (child is ITalonDisplayObject) addChildNodeAt(child as ITalonDisplayObject, index);
			return child;
		}

		/** @private */
		public override function removeChildAt(index:int, dispose:Boolean = false):DisplayObject
		{
			var child:DisplayObject = super.removeChildAt(index, dispose);
			if (child is ITalonDisplayObject) removeChildNode(child as ITalonDisplayObject);
			return child;
		}

		private function addChildNodeAt(child:ITalonDisplayObject, index:int):void
		{
			node.addChild(child.node, index);

			child.node.addListener(Event.CHANGE, onChildChange);
			
			if (_layers || child.node.getAttributeCache(Attribute.LAYER) != 0)
			{
				_layers = true;
				sortChildren(byLayer);
			}
		}
		
		private function onChildChange(attribute:Attribute):void
		{
			if (attribute.name == Attribute.LAYER)
			{
				_layers = true;
				sortChildren(byLayer);
			}
		}

		private function removeChildNode(child:ITalonDisplayObject):void
		{
			node.removeChild(child.node);
			child.node.removeListener(Event.CHANGE, onChildChange);
		}
		
		private function byLayer(c1:DisplayObject, c2:DisplayObject):int
		{
			var l1:int = (c1 is ITalonDisplayObject) ? ITalonDisplayObject(c1).node.getAttributeCache(Attribute.LAYER) : 0;
			var l2:int = (c2 is ITalonDisplayObject) ? ITalonDisplayObject(c2).node.getAttributeCache(Attribute.LAYER) : 0;
			return l1 - l2;
		}

		//
		// Bridge
		//
		private function onNodeResize():void
		{
			// if in percents
			super.pivotX = node.pivotX.toPixels(node.bounds.width);
			super.pivotY = node.pivotY.toPixels(node.bounds.height);

			x = node.bounds.x + pivotX;
			y = node.bounds.y + pivotY;
		}

		//
		// Background customization
		//

		/** @private */
		public override function render(painter:Painter):void
		{
			_bridge.renderCustom(super.render, painter);
		}

		/** @private */
		public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle = null):Rectangle
		{
			return _bridge.getBoundsCustom(super.getBounds, targetSpace, resultRect);
		}

		/** @private */
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
				var contains:Boolean = _bridge.getBoundsCustom(null, this, sRect).contains(localX, localY);
				if (contains) return this;
			}

			return result;
		}

		/** @private */
		public override function dispose():void
		{
			_bridge.dispose();
			super.dispose();
		}

		//
		// ITalonDisplayObject
		//
		/** @private */
		public function get node():Node { return _bridge.node; }
		public function get rectangle():Rectangle { return node.bounds; }

		public function query(selector:String = null):TalonQuery { return new TalonQuery(this).select(selector); }
		
		public function setAttribute(name:String, value:String):void { node.setAttribute(name, value); }
		public function getAttribute(name:String):String { return node.getOrCreateAttribute(name).value; }
		public function setStyles(styles:Vector.<Style>):void { node.setStyles(styles); }
		public function setResources(resources:Object):void { node.setResources(resources); }
	}
}
