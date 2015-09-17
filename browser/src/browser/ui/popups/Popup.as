package browser.ui.popups
{
	import starling.errors.AbstractMethodError;

	import talon.utils.ITalonElement;
	import talon.starling.TalonSprite;

	public class Popup extends TalonSprite implements ITalonElement
	{
		public function Popup():void
		{
			node.position.parse("50%");
			node.pivot.parse("50%");
		}

		public function initialize(manager:PopupManager):void
		{
			throw new AbstractMethodError();
		}
	}
}