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
	import starling.extensions.talon.core.Attribute;
	import starling.extensions.talon.core.GaugeQuad;
	import starling.extensions.talon.core.Node;
	import starling.extensions.talon.utils.FillMode;
	import starling.extensions.talon.utils.StringUtil;
	import starling.filters.FragmentFilter;
	import starling.textures.Texture;
	import starling.utils.Color;
	import starling.utils.Color;

	public class TalonSprite extends Sprite implements ITalonElement
	{
		private var _node:Node;
		private var _backgroundColor:Quad;
		private var _background9ScaleImage:Scale9Image;
		private var _backgroundTiledImage:TiledImage;

		public function TalonSprite()
		{
			_node = new Node();
			_node.addEventListener(Event.CHANGE, onNodeChange);
			_node.addEventListener(Event.RESIZE, onNodeResize);

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
				node.states = new <String>["active"];
			}
			else if (touch.phase == TouchPhase.ENDED)
			{
				node.states = new <String>[];
				var onclick:String = node.getAttribute("onclick");
				if (onclick) dispatchEventWith(onclick, true);
			}
		}

		public override function addChild(child:DisplayObject):DisplayObject
		{
			(child is ITalonElement) && node.addChild(ITalonElement(child).node);
			return super.addChild(child);
		}

		override public function removeChildAt(index:int, dispose:Boolean = false):DisplayObject
		{
			var child:DisplayObject = getChildAt(index);
			(child is ITalonElement) && node.removeChild(ITalonElement(child).node);
			return super.removeChildAt(index, dispose);
		}

		private function onNodeChange(e:Event):void
		{
			/**/ if (e.data == Attribute.ID) name = node.getAttribute(Attribute.ID);
			else if (e.data == Attribute.ALPHA) alpha = parseFloat(node.getAttribute(Attribute.ALPHA));
			else if (e.data == Attribute.BACKGROUND_COLOR)
			{
				var colorString:String = node.getAttribute(Attribute.BACKGROUND_COLOR);
				_backgroundColor.visible = colorString != "transparent";
				var color:uint = StringUtil.parseColor(colorString);
				_backgroundColor.color = color;

			}
			else if (e.data == Attribute.BACKGROUND_IMAGE || e.data == Attribute.BACKGROUND_TINT || e.data == Attribute.BACKGROUND_9SCALE || e.data == Attribute.BACKGROUND_FILL_MODE)
			{
				var texture:Texture = node.getAttribute(Attribute.BACKGROUND_IMAGE) as Texture;
				if (texture != null)
				{
					var tint:uint = StringUtil.parseColor(node.getAttribute(Attribute.BACKGROUND_TINT));
					var fillMode:String = node.getAttribute(Attribute.BACKGROUND_FILL_MODE);

					switch (fillMode)
					{
						case FillMode.SCALE:
							var texture9Scale:Rectangle = new Rectangle(0, 0, texture.width, texture.height);
							var texture9ScaleGauge:GaugeQuad = new GaugeQuad();

							texture9ScaleGauge.parse(_node.getAttribute(Attribute.BACKGROUND_9SCALE));
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

					onNodeResize(null)
				}
				else
				{
					_backgroundTiledImage && _backgroundTiledImage.removeFromParent();
					_background9ScaleImage && _background9ScaleImage.removeFromParent();
				}
			}
			else if (e.data == Attribute.CURSOR)
			{
				var cursor:String = node.getAttribute(Attribute.CURSOR);
				cursor == MouseCursor.AUTO ? removeEventListener(TouchEvent.TOUCH, onCursorTouch) : addEventListener(TouchEvent.TOUCH, onCursorTouch);
			}
			else if (e.data == Attribute.FILTER)
			{
				filter = node.getAttribute(Attribute.FILTER) as FragmentFilter;
			}
		}

		private function onCursorTouch(e:TouchEvent):void
		{
			Mouse.cursor = e.interactsWith(this) ? (node.getAttribute(Attribute.CURSOR) || MouseCursor.AUTO) : MouseCursor.AUTO;
		}

		private function onNodeResize(e:Event):void
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
			return node.getAttribute(Attribute.CLIPPING) == "true";
		}

		public function get node():Node
		{
			return _node;
		}
	}
}