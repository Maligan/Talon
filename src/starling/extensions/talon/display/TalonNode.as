package starling.extensions.talon.display
{
	import feathers.display.Scale9Image;
	import feathers.textures.Scale9Textures;

	import flash.geom.Rectangle;

	import starling.display.DisplayObject;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
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

	public class TalonNode extends Sprite implements ITalonTarget
	{
		private var _background:Quad;
		private var _label:TextField;
		private var _node:Node;

		private var _image:Scale9Image;

		public function TalonNode()
		{
			_node = new Node();
			_node.addEventListener(Event.CHANGE, onBoxChange);
			_node.addEventListener(Event.RESIZE, onBoxResize);

			_background = new Quad(100, 100, 0);
			_background.useHandCursor = true;
			addChild(_background);

			_label = new TextField(0, 0, "", BitmapFont.MINI, -1);
			_label.hAlign = HAlign.LEFT;
			_label.vAlign = VAlign.TOP;
			_label.color = 0xFFFF00;
			_label.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
			_label.x = _label.y = 2;
			_label.visible = false;
			addChild(_label);

			addEventListener(TouchEvent.TOUCH, onTouch);
		}

		private function onTouch(e:TouchEvent):void
		{
			if (e.getTouch(this, TouchPhase.ENDED))
			{
				var click:String = node.getAttribute("click");
				if (click != null)
				{
					dispatchEventWith(Event.TRIGGERED, true, click);
				}
			}
		}

		public override function addChild(child:DisplayObject):DisplayObject
		{
			(child is ITalonTarget) && node.addChild(ITalonTarget(child).node);
			return super.addChild(child);
		}

		private function onBoxChange(e:Event):void
		{
			name = node.getAttribute("id");

			_label.text = node.getAttribute("id") ? ("#" + String(node.getAttribute("id")).toUpperCase()) : null;

			var image:String = node.getAttribute("backgroundImage");
			if (image != null)
			{
				if (_image == null && node.getResource(image))
				{
					var texture:Texture = node.getResource(image);
					var texture9Scale:Rectangle = new Rectangle(0, 0, texture.width, texture.height);
					var texture9ScaleGauge:GaugeQuad = new GaugeQuad();
					texture9ScaleGauge.parse(_node.getAttribute("background9Scale") || "auto");

					texture9Scale.top += texture9ScaleGauge.top.toPixels(0, 0, 0, 0);
					texture9Scale.right -= texture9ScaleGauge.right.toPixels(0, 0, 0, 0);
					texture9Scale.bottom -= texture9ScaleGauge.bottom.toPixels(0, 0, 0, 0);
					texture9Scale.left += texture9ScaleGauge.left.toPixels(0, 0, 0, 0);

					_image = new Scale9Image(new Scale9Textures(texture, texture9Scale));

					addChildAt(_image, 0);
				}

				if (_image != null)
				{
					_image.color = parseColor(node.getAttribute("backgroundChromeColor"));
				}
			}
			else
			{
				_background.visible = node.getAttribute("backgroundColor") != null;
				_background.color = parseColor(node.getAttribute("backgroundColor"));
			}


			useHandCursor = node.getAttribute("cursor") == "pointer";
		}

		private function onBoxResize(e:Event):void
		{
			onBoxChange(e);
			x = Math.round(node.bounds.x);
			y = Math.round(node.bounds.y);
			_background.width = Math.round(node.bounds.width);
			_background.height = Math.round(node.bounds.height);

			if (_image)
			{
				_image.width = Math.round(node.bounds.width);
				_image.height = Math.round(node.bounds.height);
			}

			clipRect = new Rectangle(0, 0, node.bounds.width, node.bounds.height);
		}

		public function get node():Node
		{
			return _node;
		}
	}
}