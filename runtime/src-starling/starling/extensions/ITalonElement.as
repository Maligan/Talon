package starling.extensions
{
	import talon.Node;

	/** Interface created only for ITalonElement can identify other ITalonElement.*/
	public interface ITalonElement
	{
		function get node():Node

		function get manual():Boolean
		function set manual(value:Boolean):void
	}
}