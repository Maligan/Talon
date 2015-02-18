package talon.starling
{
	import feathers.display.Scale9Image;
	import feathers.display.TiledImage;
	import feathers.textures.Scale9Textures;

	import flash.geom.Rectangle;
	import flash.utils.Dictionary;

	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.textures.Texture;

	import talon.Attribute;
	import talon.GaugeQuad;
	import talon.Node;
	import talon.utils.FillMode;
	import talon.utils.StringUtil;

	internal class Background extends Sprite
	{
		private static const COLOR:uint         = 1 << 0;
		private static const TEXTURE:uint       = 1 << 1;
		private static const TINT:uint          = 1 << 2;
		private static const FILL_MODE:uint     = 1 << 3;
		private static const SCALE_9:uint       = 1 << 4;

		private var _node:Node;
		private var _invalidate:uint;
		private var _invalidateAttribute:Dictionary;

		private var _width:Number;
		private var _height:Number;

		private var _color:Quad;
		private var _imageClip:Image;
		private var _imageTexture:Texture;
		private var _image9Scale:Scale9Image;
		private var _image9ScaleTextures:Scale9Textures;
		private var _image9ScaleRectangle:Rectangle;
		private var _imageTiled:TiledImage;

		public function Background(node:Node)
		{
			_node = node;
			_node.addEventListener(Event.CHANGE, onNodeChange);

			_invalidateAttribute = new Dictionary();
			addAttributeListener(Attribute.BACKGROUND_FILL_MODE,   FILL_MODE);
			addAttributeListener(Attribute.BACKGROUND_IMAGE,       TEXTURE);
			addAttributeListener(Attribute.BACKGROUND_TINT,        TINT);
			addAttributeListener(Attribute.BACKGROUND_9SCALE,      SCALE_9);
			addAttributeListener(Attribute.BACKGROUND_COLOR,       COLOR);
		}

		private function addAttributeListener(name:String, flag:int):void
		{
			_invalidateAttribute[name] = flag;
		}

		private function onNodeChange(e:Event):void
		{
			var attributeName:String = String(e.data);
			var attributeFlag:int = int(_invalidateAttribute[attributeName]);
			if (attributeFlag != 0) _invalidate |= attributeFlag;
		}

		public function validate(forced:Boolean = false):void
		{
			if (forced) _invalidate = uint.MAX_VALUE;
			if (!_invalidate) return;


			// Background fillMode
			if (_invalidate || FILL_MODE)
			{
				// Create new
				var fillMode:String = _node.getAttribute(Attribute.BACKGROUND_FILL_MODE);
				if (fillMode == FillMode.SCALE)
				{
//					_image9ScaleTextures = new Scale9Textures(texture)
//					_image9Scale = new Scale9Image()
				}

				// Remove old
			}

			if (_invalidate && TEXTURE)     validateTexture();
			if (_invalidate && SCALE_9)     validate9Scale();
			if (_invalidate && FILL_MODE)   validateFillMode();
			if (_invalidate && TINT)        validateTint();
			if (_invalidate && COLOR)       validateColor();

			_invalidate = 0;
		}

		private function validateTexture():void
		{
			var image:String = _node.getAttribute(Attribute.BACKGROUND_IMAGE);
			var resourcePattern:RegExp = /resource\(["']?([^'"]*)["']?\)/;
			var split:Array = resourcePattern.exec(image);
			var imageResourceKey:String = null;
			if (split != null) imageResourceKey = split[1];

			_imageTexture = _node.getResource(imageResourceKey);
			_invalidate &= ~TEXTURE;

			// For create
			if (_imageTexture)
			{
				var hasImage:Boolean = _imageClip || _image9Scale || _imageTiled;
				if (!hasImage) _invalidate |= FILL_MODE;
			}
		}

		private function validate9Scale():void
		{
			if (_imageTexture != null)
			{
				var texture9ScaleGauge:GaugeQuad = new GaugeQuad();
				texture9ScaleGauge.parse(_node.getAttribute(Attribute.BACKGROUND_9SCALE));

//				_image9ScaleRectangle |= new Rectangle();
//				_image9ScaleRectangle.setTo(0, 0, _imageTexture.width, _imageTexture.height);
//				_image9ScaleRectangle.top += texture9ScaleGauge.top.toPixels(0, 0, _node.pppt, 0, width, height, 0, 0);
//				_image9ScaleRectangle.right -= texture9ScaleGauge.right.toPixels(0, 0, _node.pppt, 0, width, height, 0, 0);
//				_image9ScaleRectangle.bottom -= texture9ScaleGauge.bottom.toPixels(0, 0, _node.pppt, 0, width, height, 0, 0);
//				_image9ScaleRectangle.left += texture9ScaleGauge.left.toPixels(0, 0, _node.pppt, 0, width, height, 0, 0);
			}
		}

		private function validateFillMode():void
		{
			if (_imageTexture == null)
			{
				_image9Scale && _image9Scale.removeFromParent(true);
				_imageTiled && _imageTiled.removeFromParent(true);
				_imageClip && _imageClip.removeFromParent(true);
			}
			else
			{

			}

			_invalidate &= ~(FILL_MODE | TEXTURE);
		}

		private function validateTint():void
		{
			if (_image9Scale || _imageTiled || _imageClip)
			{
				var tintString:String = _node.getAttribute(Attribute.BACKGROUND_TINT);
				var tintValue:uint = StringUtil.parseColor(tintString);

				if (_image9Scale) _image9Scale.color = tintValue;
				if (_imageTiled) _imageTiled.color = tintValue;
				if (_imageClip) _imageClip.color = tintValue;
			}

			_invalidate &= ~TINT;
		}

		private function validateColor():void
		{
			var colorString:String = _node.getAttribute(Attribute.BACKGROUND_COLOR);
			var colorValue:uint = StringUtil.parseColor(colorString);
			var isTransparent:Boolean = colorString == "transparent";

			if (isTransparent && _color!=null)
			{
				_color.removeFromParent(true);
				_color = null;
			}
			else if (!isTransparent && _color!=null)
			{
				_color.color = colorValue;
			}
			else if (!isTransparent && _color==null)
			{
				_color = new Quad(_width, _height, StringUtil.parseColor(colorString));
				addChildAt(_color, 0);
			}

			_invalidate &= ~COLOR;
		}

		public function resize(width:Number, height:Number):void
		{
			_width = width;
			_height = height;

			validate();
		}

		public override function dispose():void
		{
			_node.removeEventListener(Event.CHANGE, onNodeChange);
			super.dispose();
		}
	}
}