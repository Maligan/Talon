package starling.extensions
{
	import starling.display.DisplayObject;

	import talon.Node;

	/** Interface created only for ITalonElement can identify other ITalonElement.*/
	public interface ITalonElement
	{
		function get node():Node
		function get self():DisplayObject;
	}
}