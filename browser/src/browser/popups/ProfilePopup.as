package browser.popups
{
	import starling.display.DisplayObject;

	public class ProfilePopup extends Popup
	{
		public function ProfilePopup()
		{
			var view:DisplayObject = factory.produce("popup");
			addChild(view);
			addEventListener("hide", close);
		}
	}
}
