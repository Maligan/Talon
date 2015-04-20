package talon.starling
{
	import starling.core.RenderSupport;
	import starling.events.Event;
	import starling.textures.Texture;
	import starling.utils.Color;

	import talon.Attribute;

	import talon.Node;
	import talon.types.GaugeQuad;
	import talon.utils.StringUtil;

	internal class TalonElementBackground
	{
		private var _node:Node;
		private var _filler:TextureFiller;
		private var _grid:GaugeQuad;

		public function TalonElementBackground(node:Node):void
		{
			_node = node;
			addAttributeChangeListener(Attribute.BACKGROUND_9SCALE, onBackground9ScaleChange);
			addAttributeChangeListener(Attribute.BACKGROUND_COLOR, onBackgroundColorChange);
			addAttributeChangeListener(Attribute.BACKGROUND_FILL_MODE, onBackgroundFillModeChange);
			addAttributeChangeListener(Attribute.BACKGROUND_IMAGE, onBackgroundImageChange);
			addAttributeChangeListener(Attribute.BACKGROUND_TINT, onBackgroundTintChange);

			_filler = new TextureFiller();
			_grid = new GaugeQuad();
		}

		//
		// Attribute listeners
		//
		private function addAttributeChangeListener(attribute:String, listener:Function):void
		{
			_node.getOrCreateAttribute(attribute).addEventListener(Event.CHANGE, listener);
		}

		private function onBackgroundFillModeChange(e:Event):void
		{
			_filler.fillMode = _node.getAttribute(Attribute.BACKGROUND_FILL_MODE);
		}

		private function onBackground9ScaleChange(e:Event):void
		{
			var textureWidth:int = _filler.texture ? _filler.texture.width : 0;
			var textureHeight:int = _filler.texture ? _filler.texture.height : 0;

			_grid.parse(_node.getAttribute(Attribute.BACKGROUND_9SCALE));

			_filler.setScaleOffsets
			(
				_grid.top.toPixels(_node.ppmm, _node.ppem, _node.ppdp, textureHeight),
				_grid.right.toPixels(_node.ppmm, _node.ppem, _node.ppdp, textureWidth),
				_grid.bottom.toPixels(_node.ppmm, _node.ppem, _node.ppdp, textureHeight),
				_grid.left.toPixels(_node.ppmm, _node.ppem, _node.ppdp, textureWidth)
			);
		}

		private function onBackgroundColorChange(e:Event):void
		{
			var value:String = _node.getAttribute(Attribute.BACKGROUND_COLOR);
			_filler.transparent = value == Attribute.TRANSPARENT;
			_filler.color = StringUtil.parseColor(value, _filler.color);
		}

		private function onBackgroundImageChange(e:Event):void
		{
			_filler.texture = _node.getAttribute(Attribute.BACKGROUND_IMAGE) as Texture;
		}

		private function onBackgroundTintChange(e:Event):void
		{
			_filler.tint = StringUtil.parseColor(_node.getAttribute(Attribute.BACKGROUND_COLOR), Color.WHITE);
		}

		//
		// Public methods
		//
		public function render(support:RenderSupport, parentAlpha:Number):void
		{
			_filler.render(support, parentAlpha);
		}

		public function resize(width:Number, height:Number):void
		{
			_filler.width = width;
			_filler.height = height;
		}
	}
}