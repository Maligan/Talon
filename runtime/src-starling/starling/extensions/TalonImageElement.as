package starling.extensions
{
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.display.DisplayObject;
	import starling.display.Quad;
	import starling.events.Event;
	import starling.rendering.Painter;
	import starling.textures.Texture;
	import starling.utils.Pool;

	import talon.Attribute;
	import talon.Node;

	public class TalonImageElement extends Quad implements ITalonElement
	{
		private static var _sRectangle:Rectangle = new Rectangle();

		private var _bridge:TalonDisplayObjectBridge;
		private var _node:Node;

		public function TalonImageElement()
		{
			super(1, 1);

			_node = new Node();
			_node.width.auto = measureWidth;
			_node.height.auto = measureHeight;
			_node.addTriggerListener(Event.RESIZE, onNodeResize);

			_bridge = new TalonDisplayObjectBridge(this, node);
			_bridge.addAttributeChangeListener(Attribute.SOURCE, onSourceChange);

			pixelSnapping = true;
		}

		private function measureWidth(height:Number):Number
		{
			return (texture ? measure(height, texture.height, texture.width) : 0)
				 + node.paddingLeft.toPixels(node.ppmm, node.ppem, node.ppdp)
				 + node.paddingRight.toPixels(node.ppmm, node.ppem, node.ppdp);
		}

		private function measureHeight(width:Number):Number
		{
			return (texture ? measure(width,  texture.width,  texture.height) : 0)
				 + node.paddingTop.toPixels(node.ppmm, node.ppem, node.ppdp)
				 + node.paddingBottom.toPixels(node.ppmm, node.ppem, node.ppdp);
		}

		private function measure(knownDimension:Number, knownDimensionOfTexture:Number, measuredDimensionOfTexture:Number):Number
		{
			// If there is no texture - size is zero
			if (texture == null) return 0;
			// If no limit on image size - return original texture size
			if (knownDimension == Infinity) return measuredDimensionOfTexture;
			// Else calculate new size preserving texture aspect ratio
			return measuredDimensionOfTexture * (knownDimension/knownDimensionOfTexture);
		}

		private function onSourceChange():void
		{
			texture = node.getAttributeCache(Attribute.SOURCE) as Texture;
			readjustSize();
		}

		private function onNodeResize():void
		{
			pivotX = node.pivotX.toPixels(node.ppmm, node.ppem, node.ppdp, node.bounds.width);
			pivotY = node.pivotY.toPixels(node.ppmm, node.ppem, node.ppdp, node.bounds.height);

			x = node.bounds.x + pivotX;
			y = node.bounds.y + pivotY;

			var paddingLeft:Number = node.paddingLeft.toPixels(node.ppmm, node.ppem, node.ppdp);
			var paddingRight:Number = node.paddingRight.toPixels(node.ppmm, node.ppem, node.ppdp);
			var paddingTop:Number = node.paddingTop.toPixels(node.ppmm, node.ppem, node.ppdp);
			var paddingBottom:Number = node.paddingBottom.toPixels(node.ppmm, node.ppem, node.ppdp);

			readjustSize(node.bounds.width-paddingLeft-paddingRight, node.bounds.height-paddingTop-paddingBottom);

			// TODO: Call it within setupVertices ?
			offsetVertices(paddingLeft, paddingTop);
		}

		private function offsetVertices(offsetX:Number, offsetY:Number):void
		{
			var posAttr:String = "position";
			var point:Point = Pool.getPoint();

			for (var i:int = 0; i < vertexData.numVertices; i++)
			{
				point = vertexData.getPoint(i, posAttr, point);
				point.offset(offsetX, offsetY);
				vertexData.setPoint(i, posAttr, point.x, point.y);
			}

			Pool.putPoint(point);
		}

		public override function render(painter:Painter):void
		{
			_bridge.renderCustom(super.render, painter);
		}

		public override function getBounds(targetSpace:DisplayObject, out:Rectangle = null):Rectangle
		{
			return _bridge.getBoundsCustom(super.getBounds, targetSpace, out);
		}

		public override function hitTest(localPoint:Point):DisplayObject
		{
			return getBounds(this, _sRectangle).containsPoint(localPoint) ? this : null;
		}

		public override function dispose():void
		{
			node.dispose();
			super.dispose();
		}

		public function get node():Node
		{
			return _node;
		}
	}
}