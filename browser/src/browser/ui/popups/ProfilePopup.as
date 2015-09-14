package browser.ui.popups
{
	import starling.display.DisplayObject;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;

	public class ProfilePopup extends Popup
	{
		private var _manager:PopupManager;

		public override function initialize(manager:PopupManager):void
		{
			_manager = manager;

			var view:DisplayObject = _manager.factory.produce("PopupBase");
			addChild(view);

			view.addEventListener(TouchEvent.TOUCH, onTouch);
		}

		private function onTouch(e:TouchEvent):void
		{
			e.getTouch(getChildAt(0), TouchPhase.ENDED) && _manager.close(this);
		}
	}
}
