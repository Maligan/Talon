package starling.extensions.talon.display
{
	import feathers.display.Scale9Image;
	import feathers.textures.Scale3Textures;
	import feathers.textures.Scale9Textures;

	import flash.geom.Rectangle;
	import flash.utils.ByteArray;

	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.extensions.talon.core.Node;
	import starling.text.BitmapFont;
	import starling.text.TextField;
	import starling.text.TextFieldAutoSize;
	import starling.utils.HAlign;
	import starling.utils.VAlign;

	public class TalonComponentBase extends Sprite implements ITalonComponent
	{
		private var _background:Quad;
		private var _image:Scale9Image;
		private var _label:TextField;
		private var _node:Node;

		public function TalonComponentBase()
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
			addChild(_label);

			addEventListener(TouchEvent.TOUCH, onTouch);
		}

		private function onTouch(e:TouchEvent):void
		{
			if (e.getTouch(this, TouchPhase.HOVER) != null)
			{
				_background.color = 0x888888;
				_image && (_image.textures = node.getResource("/img/over.png"));
			}
			else if (e.getTouch(this, TouchPhase.BEGAN))
			{
				_image && (_image.textures = node.getResource("/img/down.png"));
			}
			else if (e.getTouch(this) == null)
			{
				_background.color = parseInt(node.getAttribute("backgroundColor"));
				_image && (_image.textures = node.getResource("/img/up.png"));
			}
			else if (e.getTouch(_background, TouchPhase.ENDED) != null)
			{
				trace("Click", _node.getAttribute("id"))
			}
		}

		public override function addChild(child:DisplayObject):DisplayObject
		{
			(child is ITalonComponent) && node.addChild(ITalonComponent(child).node);
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
					useHandCursor = true;
					_background.visible = false;
					_image = new Scale9Image(node.getResource(image));
					addChildAt(_image, 0);
				}
			}
			else
			{
				_background.visible = node.getAttribute("backgroundColor") != null;
				_background.color = parseInt(node.getAttribute("backgroundColor"));
			}
		}

		private function onBoxResize(e:Event):void
		{
			onBoxChange(e);
			x = Math.round(node.bounds.x);
			y = Math.round(node.bounds.y);
			_background.width = Math.ceil(node.bounds.width);
			_background.height = Math.ceil(node.bounds.height);

			if (_image)
			{
				_image.width = Math.ceil(node.bounds.width);
				_image.height = Math.ceil(node.bounds.height);
			}

			clipRect = new Rectangle(0, 0, node.bounds.width, node.bounds.height);
		}

		public function get node():Node
		{
			return _node;
		}
	}
}