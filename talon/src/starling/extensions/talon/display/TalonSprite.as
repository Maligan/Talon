package starling.extensions.talon.display
{
	import feathers.display.Scale9Image;
	import feathers.display.TiledImage;
	import feathers.textures.Scale9Textures;

	import flash.geom.Rectangle;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;

	import starling.display.DisplayObject;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.extensions.talon.core.GaugeQuad;
	import starling.extensions.talon.core.Node;
	import starling.extensions.talon.utils.Attributes;
	import starling.extensions.talon.utils.FillMode;
	import starling.extensions.talon.utils.parseColor;
	import starling.extensions.talon.utils.parseFilter;
	import starling.textures.Texture;

	public class TalonSprite extends Sprite implements ITalonTarget
	{
		private var _node:Node;
		private var _backgroundColor:Quad;
		private var _background9ScaleImage:Scale9Image;
		private var _backgroundTiledImage:TiledImage;

		public function TalonSprite()
		{
			_node = new Node();
			_node.addEventListener(Event.CHANGE, onBoxChange);
			_node.addEventListener(Event.RESIZE, onBoxResize);

			_backgroundColor = new Quad(1, 1, 0);
			_backgroundColor.visible = false;
			addChild(_backgroundColor);

			addEventListener(TouchEvent.TOUCH, onTouch);
		}

		private function onTouch(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(this);

			if (touch == null)
			{
				node.states = new <String>[];
			}
			else if (touch.phase == TouchPhase.HOVER)
			{
				node.states = new <String>["hover"];
			}
			else if (touch.phase == TouchPhase.BEGAN)
			{
				node.states = new <String>["active"]; // not hover
			}
			else if (touch.phase == TouchPhase.ENDED)
			{
				node.states = new <String>[];
				var onclick:String = node.getAttribute("onclick");
				if (onclick) dispatchEventWith(Event.TRIGGERED, true, onclick);
			}
		}

		public override function addChild(child:DisplayObject):DisplayObject
		{
			(child is ITalonTarget) && node.addChild(ITalonTarget(child).node);
			return super.addChild(child);
		}

		override public function removeChildAt(index:int, dispose:Boolean = false):DisplayObject
		{
			var child:DisplayObject = getChildAt(index);
			(child is ITalonTarget) && node.removeChild(ITalonTarget(child).node);
			return super.removeChildAt(index, dispose);
		}

		private function onBoxChange(e:Event):void
		{
			/**/ if (e.data == Attributes.ID) name = node.getAttribute(Attributes.ID);
			else if (e.data == Attributes.ALPHA) alpha = parseFloat(node.getAttribute(Attributes.ALPHA));
			else if (e.data == Attributes.BACKGROUND_COLOR)
			{
				var color:String = node.getAttribute(Attributes.BACKGROUND_COLOR);
				_backgroundColor.visible = color != "transparent";
				_backgroundColor.color = parseColor(color);
			}
			else if (e.data == Attributes.BACKGROUND_IMAGE || e.data == Attributes.BACKGROUND_TINT || e.data == Attributes.BACKGROUND_9SCALE || e.data == Attributes.BACKGROUND_FILL_MODE)
			{
				var image:String = node.getAttribute(Attributes.BACKGROUND_IMAGE);
				var imageResourceKey:String = null;

				var resourcePattern:RegExp = /resource\(["']?([^'"]*)["']?\)/;
				var split:Array = resourcePattern.exec(image);
				if (split != null) imageResourceKey = split[1];

				var texture:Texture = node.getResource(imageResourceKey);
				if (texture != null)
				{
					var tint:uint = parseColor(node.getAttribute(Attributes.BACKGROUND_TINT));
					var fillMode:String = node.getAttribute(Attributes.BACKGROUND_FILL_MODE);

					switch (fillMode)
					{
						case FillMode.SCALE:
							var texture9Scale:Rectangle = new Rectangle(0, 0, texture.width, texture.height);
							var texture9ScaleGauge:GaugeQuad = new GaugeQuad();

							texture9ScaleGauge.parse(_node.getAttribute(Attributes.BACKGROUND_9SCALE));
							texture9Scale.top += texture9ScaleGauge.top.toPixels(0, 0, node.pppt, 0, width, height, 0, 0);
							texture9Scale.right -= texture9ScaleGauge.right.toPixels(0, 0, node.pppt, 0, width, height, 0, 0);
							texture9Scale.bottom -= texture9ScaleGauge.bottom.toPixels(0, 0, node.pppt, 0, width, height, 0, 0);
							texture9Scale.left += texture9ScaleGauge.left.toPixels(0, 0, node.pppt, 0, width, height, 0, 0);

							var scale9Texture:Scale9Textures = new Scale9Textures(texture, texture9Scale);

							if (_background9ScaleImage)
							{
								_background9ScaleImage.textures = scale9Texture;
							}
							else
							{
								_background9ScaleImage = new Scale9Image(scale9Texture);
							}

							addChildAt(_background9ScaleImage, 1);
							_background9ScaleImage.color = tint;
							_backgroundTiledImage && _backgroundTiledImage.removeFromParent();
							break;
						case FillMode.REPEAT:
							if (_backgroundTiledImage)
							{
								_backgroundTiledImage.texture = texture;
							}
							else
							{
								_backgroundTiledImage = new TiledImage(texture);
							}

							addChildAt(_backgroundTiledImage, 1);
							_backgroundTiledImage.color = tint;
							_background9ScaleImage && _background9ScaleImage.removeFromParent();
							break;
					}

					onBoxResize(null)
				}
			}
			else if (e.data == Attributes.CURSOR)
			{
				var cursor:String = node.getAttribute(Attributes.CURSOR);
				cursor == MouseCursor.AUTO ? removeEventListener(TouchEvent.TOUCH, onCursorTouch) : addEventListener(TouchEvent.TOUCH, onCursorTouch);
			}
			else if (e.data == Attributes.FILTER)
			{
				var filterString:String = node.getAttribute(Attributes.FILTER);
				filter = parseFilter(filterString);
			}
		}

		private function onCursorTouch(e:TouchEvent):void
		{
			Mouse.cursor = e.interactsWith(this) ? (node.getAttribute(Attributes.CURSOR) || MouseCursor.AUTO) : MouseCursor.AUTO;
		}

		private function onBoxResize(e:Event):void
		{
			node.bounds.left = Math.round(node.bounds.left);
			node.bounds.right = Math.round(node.bounds.right);
			node.bounds.top = Math.round(node.bounds.top);
			node.bounds.bottom = Math.round(node.bounds.bottom);

			x = node.bounds.x;
			y = node.bounds.y;

			if (_backgroundColor)
			{
				_backgroundColor.width = node.bounds.width;
				_backgroundColor.height = node.bounds.height;
			}

			if (_background9ScaleImage)
			{
				_background9ScaleImage.width = node.bounds.width;
				_background9ScaleImage.height = node.bounds.height;
			}

			if (_backgroundTiledImage)
			{
				_backgroundTiledImage.width = node.bounds.width;
				_backgroundTiledImage.height = node.bounds.height;
			}


			clipRect = clipping ? new Rectangle(0, 0, node.bounds.width, node.bounds.height) : null;
		}

		private function get clipping():Boolean
		{
			return node.getAttribute(Attributes.CLIPPING) == "true";
		}

		public function get node():Node
		{
			return _node;
		}
	}
}