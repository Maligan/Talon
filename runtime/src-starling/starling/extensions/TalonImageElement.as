package starling.extensions
{
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.events.Event;
	import starling.rendering.Painter;
	import starling.textures.Texture;

	import talon.Attribute;
	import talon.Node;
	import starling.extensions.ITalonElement;

	public class TalonImageElement extends Quad implements ITalonElement
	{
		private static var _emptyTexture:Texture;

		private var _bridge:TalonDisplayObjectBridge;
		private var _node:Node;

		public function TalonImageElement()
		{
			super(1, 1);

			if (_emptyTexture == null)
			{
				_emptyTexture = Texture.empty(1, 1);
				_emptyTexture.root.dispose();
			}

			_node = new Node();
			_node.width.auto = measureWidth;
			_node.height.auto = measureHeight;
			_node.addTriggerListener(Event.RESIZE, onNodeResize);

			_bridge = new TalonDisplayObjectBridge(this, node);
			_bridge.addAttributeChangeListener(Attribute.SOURCE, onSourceChange);

			texture = _emptyTexture;
			pixelSnapping = true;
		}

		private function measureWidth(height:Number):Number { return measure(height, texture.height, texture.width); }
		private function measureHeight(width:Number):Number { return measure(width,  texture.width,  texture.height); }

		private function measure(knownDimension:Number, knownDimensionOfTexture:Number, measuredDimensionOfTexture:Number):Number
		{
			// If there is no texture - size is zero
			if (texture == _emptyTexture) return 0;
			// If no limit on image size - return original texture size
			if (knownDimension == Infinity) return measuredDimensionOfTexture;
			// Else calculate new size preserving texture aspect ratio
			return measuredDimensionOfTexture * (knownDimension/knownDimensionOfTexture);
		}

		private function onSourceChange():void
		{
			texture = node.getAttributeCache(Attribute.SOURCE) as Texture || _emptyTexture;
			readjustSize();
		}

		private function onNodeResize():void
		{
			var rotationStash:Number = rotation;
			if (rotationStash) rotation = 0;

			pivotX = node.pivotX.toPixels(node.ppmm, node.ppem, node.ppdp, node.bounds.width);
			pivotY = node.pivotY.toPixels(node.ppmm, node.ppem, node.ppdp, node.bounds.height);

			x = node.bounds.x + pivotX;
			y = node.bounds.y + pivotY;

			width = node.bounds.width;
			height = node.bounds.height;

			if (rotationStash) rotation = rotationStash;
		}

		//
		// Background customization
		//
		public override function render(painter:Painter):void
		{
			// FIXME: Image with scale
			_bridge.renderCustom(super.render, painter);
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