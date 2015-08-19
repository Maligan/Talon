package browser.popups
{
	import starling.display.DisplayObject;
	import starling.display.Quad;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.utils.Color;

	public class ProfilePopup extends Popup
	{
		public function ProfilePopup()
		{
//			var view:DisplayObject = factory.produce("popup");
//			addChild(view);
//			addEventListener("hide", close);

			var view:DisplayObject = new Quad(100, 100, Color.WHITE);
			view.alignPivot();
			addChild(view);
			addEventListener(TouchEvent.TOUCH, onTouch);
		}

		private function onTouch(e:TouchEvent):void
		{
//			if (e.getTouch(this, TouchPhase.ENDED)) close();
		}
	}
}
