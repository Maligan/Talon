package
{
	import starling.events.Event;

	import starling.extensions.talon.core.Box;

	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;

	import starling.extensions.talon.core.GaugeQuad;

	import starling.extensions.talon.core.Layout;

	import starling.extensions.talon.core.Gauge;
	import starling.extensions.talon.layout.StackLayoutStrategy;
	import starling.utils.HAlign;
	import starling.utils.VAlign;

	public class Renderer extends Sprite
	{
		private const _root:Box = new Box();

		public function Renderer()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onResize);

			_root.attributes.direction = "right";
			_root.attributes.halign = HAlign.CENTER;
			_root.attributes.valign = VAlign.CENTER;

			_root.addEventListener(Event.CHANGE, onChange);
			_root.margin.bottom.amount = 20;
			_root.attributes.marginRight = "auto";
			_root.margin.parse("10px");
			_root.attributes.marginLeft = "auto";
			trace(_root.margin);
			trace(_root.margin.right);

			function onChange(e:Event):void
			{
				trace(e.data);
			}

			function fromXML(xml:XML):Box
			{
				var box:Box = new Box();

				for each (var attribute:XML in xml.attributes())
				{
					var name:String = attribute.name();
					var value:String = attribute.valueOf();
					box.attributes[name] = value;
				}

				for each (var childXML:XML in xml.children())
				{
					box.children.push(fromXML(childXML));
				}

				return box;
			}

//			Layout.registerMethod("stack", new StackLayoutMethod(), ["direction", "halign", "valign", "gap"]);

			var info:XML =
				<layout type="stack" gap="10px" padding="10px">
					<box width="64px" height="64px" background="#00FF00" />
					<label text="text1" />
					<box width="64px" height="64px" background="#FF0000" />
					<label text="text2" />
					<box width="64px" height="64px" background="#0000FF" />
				</layout>;

//			var info:XML = <layout type="stack" gap="10px" padding="10px" />;
			var tmp:Box = fromXML(info);

//			var builder:TalonBuilder = TalonBuilder.fromXML(null);
//			builder.addLibraryTexture("/path/to/image.png", null);
//			builder.addLibraryTexturesFromAtlas(null);
//			builder.addLibraryConstant("header", "Заголовок");
//			var box:Box = builder.getResult("AlertDialog");

//			var button:TalonButton = new TalonButton();
//			button.box.attributes.label = 100;

//			var left:Box = build(_root, "auto", "50%");
//			var right:Box = build(_root, "3*", "100%");
//
//			build(left, "10px", "10px");
//			build(left, "10px", "10px");
//
//			build(right, "100px", "10%");
//			build(right, "90px", "20%");
//			build(right, "80px", "30%");
//			build(right, "70px", "40%");
//			build(right, "60px", "50%");
//			build(right, "50px", "30%");
//			build(right, "*", "20%");
//
//			refresh();
		}

		private function onResize(e:Event):void
		{
			_root.width.setTo(stage.stageWidth, Gauge.PX);
			_root.height.setTo(stage.stageHeight, Gauge.PX);
		}

		private function draw(box:Box, dx:int = 0, dy:int = 0):void
		{
//			graphics.beginFill(box.backgroundColor);
//			graphics.drawRect(dx + box.bounds.x, dy + box.bounds.y, box.bounds.width, box.bounds.height);
			graphics.endFill();

//			for each (var child:Box in box.children)
//			{
//				draw(child, dx + box.bounds.x, dy + box.bounds.y);
//			}
		}
	}
}