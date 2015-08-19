package talon.starling
{
	import starling.core.RenderSupport;
	import starling.display.Image;
	import starling.events.Event;
	import starling.textures.Texture;

	import talon.Attribute;

	import talon.Node;
	import talon.utils.ITalonElement;

	public class TalonImage extends Image implements ITalonElement
	{
		private static var EMPTY:Texture;

		private var _bridge:DisplayObjectBridge;
		private var _node:Node;

		public function TalonImage()
		{
			EMPTY ||= Texture.empty(1, 1);

			super(EMPTY);

			_node = new Node();
			_node.width.auto = measureWidth;
			_node.height.auto = measureHeight;
			_node.addListener(Event.RESIZE, onNodeResize);

			_bridge = new DisplayObjectBridge(this, node);
			_bridge.addAttributeChangeListener(Attribute.SRC, onSrcChange);
		}

		private function measureWidth(height:Number):Number { return measure(height, texture.height, texture.width); }
		private function measureHeight(width:Number):Number { return measure(width,  texture.width,  texture.height); }

		private function measure(knownDimension:Number, knownDimensionOfTexture:Number, measuredDimensionOfTexture:Number):Number
		{
			// If there is no texture - size is zero
			if (texture == EMPTY) return 0;
			// If no limit on image size - return original texture size
			if (knownDimension == Infinity) return measuredDimensionOfTexture;
			// Else calculate new size preserving texture aspect ratio
			return measuredDimensionOfTexture * (knownDimension/knownDimensionOfTexture);
		}

		private function onSrcChange():void
		{
			texture = node.getAttributeCache(Attribute.SRC) as Texture || EMPTY;
			readjustSize();
		}

		private function onNodeResize():void
		{
			x = Math.round(node.bounds.x);
			y = Math.round(node.bounds.y);
			width = Math.round(node.bounds.width);
			height = Math.round(node.bounds.height);

			_bridge.resize(node.bounds.width/scaleX, node.bounds.height/scaleY);
		}

		//
		// Background customization
		//
		public override function render(support:RenderSupport, parentAlpha:Number):void
		{
			// Background render
			_bridge.renderBackground(support, parentAlpha * this.alpha);

			// Self image render
			super.render(support, parentAlpha);
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