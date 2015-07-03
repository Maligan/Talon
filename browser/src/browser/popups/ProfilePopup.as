package browser.popups
{
	import starling.display.DisplayObject;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;

	public class ProfilePopup extends Popup
	{
		public function ProfilePopup()
		{
			var view:DisplayObject = factory.produce("popup");
			addChild(view);
			addEventListener("hide", close);

			addEventListener(TouchEvent.TOUCH, onTouch);
		}

		private function onTouch(e:TouchEvent):void
		{
			if (e.getTouch(this, TouchPhase.ENDED)) close();
		}
	}
}
