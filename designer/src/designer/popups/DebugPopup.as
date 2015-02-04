package designer.popups
{
	import starling.display.DisplayObject;

	public class DebugPopup extends Popup
	{
		public function DebugPopup()
		{
			var view:DisplayObject = factory.build("popup");
			addChild(view);
			addEventListener("hide", hide);
		}
	}
}
