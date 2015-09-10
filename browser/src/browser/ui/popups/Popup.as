package browser.ui.popups
{
	import talon.utils.ITalonElement;
	import talon.starling.TalonSprite;

	public class Popup extends TalonSprite implements ITalonElement
	{
		public function Popup():void
		{
			node.position.parse("50%");
			node.pivot.parse("50%");
		}
	}
}