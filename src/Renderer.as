package
{
	import starling.extension.talon.core.Box;

	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;

	public class Renderer extends Sprite
	{
		public function Renderer()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_RIGHT;

//			var document:XML =
//				<box layout:type = "stack" width = "200px" height = "400px">
//					<box height = "*" />
//					<box height = "*" />
//					<box layout:type = "stack" layout.direction = "right">
//						<button id = "ok" width = "100%" />
//						<button id = "cancel" width = "100%" />
//					</box>
//				</box>;

			var b1:Box = new Box();
			var b2:Box = new Box();
			var b3:Box = new Box();
			var b4:Box = new Box();
			var b5:Box = new Box();

			b2.width.parse("150px");
			b2.height.parse("200px");

			b3.width.parse("120px");
			b3.height.parse("100px");

			b4.width.parse("20px");
			b4.height.parse("50px");

			b5.width.parse("30px");
			b5.height.parse("50px");

			b3.children.push(b4);
			b1.children.push(b2);
			b1.children.push(b3);
			b1.children.push(b5);

			var ppp:Number = 0;
			var em:Number = 0;
			b1.bounds.setTo(0, 0, b1.layout.measureWidth(ppp, em), b1.layout.measureHeight(ppp, em));
			b1.layout.arrange(ppp, ppp, b1.bounds.width, b1.bounds.height);

			draw(b1);
		}

		private function draw(box:Box, dx:int = 0, dy:int = 0):void
		{
			var color:uint = Math.random() * 0xFFFFFF;

			graphics.beginFill(color);
			graphics.drawRect(dx + box.bounds.x, dy + box.bounds.y, box.bounds.width, box.bounds.height);
			graphics.endFill();

			for each (var child:Box in box.children)
			{
				draw(child, dx + box.bounds.x, dy + box.bounds.y);
			}
		}
	}
}