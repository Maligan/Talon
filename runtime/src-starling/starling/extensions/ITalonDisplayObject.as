package starling.extensions
{
	import talon.core.Node;

	public interface ITalonDisplayObject
	{
		function query(selector:String = null):TalonQuery;

//		+ getAttribute()
//		+ setAttribute()
//		+ setResources()
//		+ setStyles()
//		+ bounds
		
		function get node():Node
	}
}