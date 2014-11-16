package starling.extensions.talon.display
{
	import feathers.display.Scale9Image;
	import feathers.textures.Scale9Textures;

	import flash.geom.Point;

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
	import starling.extensions.talon.utils.parseColor;
	import starling.text.BitmapFont;
	import starling.text.TextField;
	import starling.text.TextFieldAutoSize;
	import starling.textures.Texture;
	import starling.utils.HAlign;
	import starling.utils.VAlign;

	public class TalonSprite extends Sprite implements ITalonTarget
	{
		private var _node:Node;
		private var _backgroundColor:Quad;
		private var _backgroundImage:Scale9Image;

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
				node.states = new <String>["hover", "active"];
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
			/**/ if (e.data == "id") name = node.getAttribute("id");
			else if (e.data == "backgroundColor")
			{
				var color:String = node.getAttribute("backgroundColor");
				_backgroundColor.visible = color != "transparent";
				_backgroundColor.color = parseColor(color);
			}
			else if (e.data == "backgroundImage" || e.data == "backgroundChromeColor" || e.data == "background9Scale")
			{
				var image:String = node.getAttribute("backgroundImage");
				var imageTexture:Texture = node.getResource(image);
				if (imageTexture != null)
				{
					var texture:Texture = node.getResource(image);
					var texture9Scale:Rectangle = new Rectangle(0, 0, texture.width, texture.height);
					var texture9ScaleGauge:GaugeQuad = new GaugeQuad();
					texture9ScaleGauge.parse(_node.getAttribute("background9Scale"));

					texture9Scale.top += texture9ScaleGauge.top.toPixels(0, 0, 0, 0, 0);
					texture9Scale.right -= texture9ScaleGauge.right.toPixels(0, 0, 0, 0, 0);
					texture9Scale.bottom -= texture9ScaleGauge.bottom.toPixels(0, 0, 0, 0, 0);
					texture9Scale.left += texture9ScaleGauge.left.toPixels(0, 0, 0, 0, 0);

					var scale9Texture:Scale9Textures = new Scale9Textures(texture, texture9Scale);

					if (_backgroundImage)
					{
						_backgroundImage.textures = scale9Texture;
					}
					else
					{
						_backgroundImage = new Scale9Image(scale9Texture);
						addChildAt(_backgroundImage, 1);
					}

					_backgroundImage.color = parseColor(node.getAttribute("backgroundChromeColor"));
				}
			}
			else if (e.data == "cursor")
			{
				var cursor:String = node.getAttribute("cursor");
				cursor == MouseCursor.AUTO ? removeEventListener(TouchEvent.TOUCH, onCursorTouch) : addEventListener(TouchEvent.TOUCH, onCursorTouch);
			}
		}

		private function onCursorTouch(e:TouchEvent):void
		{
			Mouse.cursor = e.interactsWith(this) ? node.getAttribute("cursor") : MouseCursor.AUTO;
		}

		private function onBoxResize(e:Event):void
		{
			x = Math.round(node.bounds.x);
			y = Math.round(node.bounds.y);

			if (_backgroundColor)
			{
				_backgroundColor.width = Math.round(node.bounds.width);
				_backgroundColor.height = Math.round(node.bounds.height);
			}

			if (_backgroundImage)
			{
				_backgroundImage.width = Math.round(node.bounds.width);
				_backgroundImage.height = Math.round(node.bounds.height);
			}

			clipRect = clipping ? new Rectangle(0, 0, node.bounds.width, node.bounds.height) : null;
		}

		private function get clipping():Boolean
		{
			return node.getAttribute("clipping") == "true";
		}

		public function get node():Node
		{
			return _node;
		}
	}
}